import Foundation
import WeatherKit

@MainActor
final class SnowReportStore {
    static let shared = SnowReportStore()

    private(set) var revision = 0
    private(set) var attribution: SnowAttribution?

    private let provider: SnowWeatherProviding
    private let cacheKey = "skeste.snow.cache.v1"
    private let freshTTL: TimeInterval = 10 * 60
    private let maxCacheAge: TimeInterval = 24 * 60 * 60
    private let retryCooldown: TimeInterval = 45

    private var reports: [String: LiveSnowReport] = [:]
    private var sessionLiveKeys: Set<String> = []
    private var inFlight: [String: Task<LiveSnowReport, Error>] = [:]
    private var requestIDs: [String: Int] = [:]
    private var lastAttempt: [String: Date] = [:]
    private var lastError: [String: String] = [:]
    private var weatherKitUnavailable = false

    private init(provider: SnowWeatherProviding = WeatherKitSnowProvider()) {
        self.provider = provider
        loadCache()
    }

    // MARK: - Snapshots

    var resorts: [SnowResort] {
        SnowLibrary.resorts.map(snapshot(for:))
    }

    func resort(named name: String) -> SnowResort {
        let template = SnowLibrary.resort(named: name) ?? SnowLibrary.resorts[0]
        return snapshot(for: template)
    }

    func status(for name: String) -> SnowStatus {
        let template = SnowLibrary.resort(named: name) ?? SnowLibrary.resorts[0]
        let key = template.name
        let report = reports[key]
        let age = report.map { Date().timeIntervalSince($0.fetchedAt) } ?? .greatestFiniteMagnitude
        let source: SnowReportSource
        if sessionLiveKeys.contains(key), age <= freshTTL {
            source = .live
        } else if age <= maxCacheAge {
            source = .cached
        } else {
            source = .sample
        }
        return SnowStatus(
            source: source,
            updatedAt: report?.fetchedAt,
            isRefreshing: inFlight[key] != nil,
            notice: lastError[key]
        )
    }

    private func snapshot(for template: SnowResort) -> SnowResort {
        guard let report = reports[template.name] else { return template }
        let age = Date().timeIntervalSince(report.fetchedAt)
        guard age <= maxCacheAge else { return template }
        let source: SnowReportSource = sessionLiveKeys.contains(template.name) && age <= freshTTL
            ? .live
            : .cached
        return template.merging(report, source: source)
    }

    // MARK: - Refresh

    func refreshIfNeeded(named name: String) {
        Task { await refresh(named: name) }
    }

    @discardableResult
    func refresh(named name: String, force: Bool = false) async -> Bool {
        guard let template = SnowLibrary.resort(named: name) else { return false }
        let key = template.name

        if !force, sessionLiveKeys.contains(key), let report = reports[key],
           Date().timeIntervalSince(report.fetchedAt) < freshTTL {
            return true
        }
        if !force, let last = lastAttempt[key],
           Date().timeIntervalSince(last) < retryCooldown {
            return lastError[key] == nil
        }
        if weatherKitUnavailable, !force {
            return false
        }
        if let existing = inFlight[key] {
            _ = await existing.result
            return lastError[key] == nil
        }

        lastAttempt[key] = Date()
        let requestID = (requestIDs[key] ?? 0) + 1
        requestIDs[key] = requestID

        let task = Task<LiveSnowReport, Error> {
            try await provider.fetch(template: template)
        }
        inFlight[key] = task
        defer {
            if requestIDs[key] == requestID { inFlight[key] = nil }
        }

        do {
            let report = try await task.value
            guard requestIDs[key] == requestID else { return false }
            reports[key] = report
            sessionLiveKeys.insert(key)
            lastError[key] = nil
            weatherKitUnavailable = false
            persist()
            revision += 1
            NotificationCenter.default.post(name: .skesteSnowChanged, object: key)
            await fetchAttributionIfNeeded()
            return true
        } catch {
            guard requestIDs[key] == requestID else { return false }
            let message = WeatherKitSnowProvider.userMessage(for: error)
            weatherKitUnavailable = message.permissionDenied
            if lastError[key] != message.text {
                lastError[key] = message.text
                revision += 1
                NotificationCenter.default.post(name: .skesteSnowChanged, object: key)
            }
            return false
        }
    }

    private func fetchAttributionIfNeeded() async {
        guard attribution == nil else { return }
        do {
            let value = try await WeatherService.shared.attribution
            var legalText: String?
            if #available(iOS 16.4, *) {
                legalText = value.legalAttributionText
            }
            attribution = SnowAttribution(
                serviceName: value.serviceName,
                legalPageURLString: value.legalPageURL.absoluteString,
                markURLString: value.combinedMarkDarkURL.absoluteString,
                legalText: legalText
            )
            persist()
            NotificationCenter.default.post(name: .skesteSnowChanged, object: nil)
        } catch {
            // Attribution is non-fatal: the UI falls back to text + a public link.
        }
    }

    // MARK: - Cache

    private func loadCache() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-snowClearCache") {
            UserDefaults.standard.removeObject(forKey: cacheKey)
        }
        #endif

        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let envelope = try? decoder.decode(SnowCacheEnvelope.self, from: data),
              envelope.version == SnowCacheEnvelope.currentVersion else {
            return
        }

        let validNames = Set(SnowLibrary.resorts.map(\.name))
        let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        reports = envelope.reports.filter { name, report in
            validNames.contains(name) && report.fetchedAt >= cutoff
        }
        attribution = envelope.attribution
    }

    private func persist() {
        let envelope = SnowCacheEnvelope(
            version: SnowCacheEnvelope.currentVersion,
            savedAt: Date(),
            reports: reports,
            attribution: attribution
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(envelope) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}

extension Notification.Name {
    static let skesteSnowChanged = Notification.Name("skeste.snow.changed")
}
