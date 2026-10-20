import Foundation

// MARK: - Live report source

enum SnowReportSource: String, Codable, Sendable {
    case live
    case cached
    case sample

    var label: String {
        switch self {
        case .live: return "LIVE"
        case .cached: return "CACHED"
        case .sample: return "SAMPLE"
        }
    }

    var isWeatherKitData: Bool { self != .sample }
}

// MARK: - Live report

struct LiveSnowReport: Codable, Equatable, Sendable {
    let resortName: String
    let fetchedAt: Date
    let observedAt: Date
    let tempC: Double
    let windKPH: Double
    let gustKPH: Double?
    let visibilityKM: Double
    let humidityPercent: Double
    let cloudCoverPercent: Double
    let conditionText: String
    let headline: String
    let conditionSymbol: String
    let isDaylight: Bool
    let snowTodayCM: Double
    let hours: [SnowHour]
    let days: [SnowDay]
    let window: SnowWindow
    let snowLineM: Int
    let freezingLevelM: Int
    let snowAgeDays: Int
    let textureIndex: Int
    let ageIndex: Int
    let conditionsNote: String
}

struct SnowAttribution: Codable, Equatable, Sendable {
    let serviceName: String
    let legalPageURLString: String
    let markURLString: String?
    let legalText: String?
}

struct SnowCacheEnvelope: Codable {
    static let currentVersion = 1

    var version: Int
    var savedAt: Date
    var reports: [String: LiveSnowReport]
    var attribution: SnowAttribution?
}

struct SnowStatus: Sendable {
    let source: SnowReportSource
    let updatedAt: Date?
    let isRefreshing: Bool
    let notice: String?
}

// MARK: - Merge

extension SnowResort {
    /// Returns a copy of the catalog template with live values applied. Fields
    /// that WeatherKit cannot supply (base depth, lifts, avalanche level) are
    /// intentionally left untouched and must not be rendered in live mode.
    func merging(_ report: LiveSnowReport, source: SnowReportSource) -> SnowResort {
        var out = self
        out.freshCM = Int(report.snowTodayCM.rounded())
        out.tempC = Int(report.tempC.rounded())
        out.windKPH = Int(report.windKPH.rounded())
        out.visibilityKM = max(0, Int(report.visibilityKM.rounded()))
        out.humidity = Int(report.humidityPercent.rounded())
        out.windGustKPH = report.gustKPH.map { Int($0.rounded()) }
        out.cloudCoverPercent = Int(report.cloudCoverPercent.rounded())
        out.snowLineM = report.snowLineM
        out.freezingLevelM = report.freezingLevelM
        out.snowAgeDays = report.snowAgeDays
        out.hours = report.hours
        out.days = report.days
        out.conditionOverride = report.headline
        out.conditionSymbolOverride = report.conditionSymbol
        out.textureOverride = SnowTexture(rawValue: report.textureIndex)
        out.ageOverride = SnowAge(rawValue: report.ageIndex)
        out.windowOverride = report.window
        out.conditionsNote = report.conditionsNote
        out.windMidKPH = out.windKPH
        out.windTopKPH = out.windKPH
        out.baseHistoryCM = []
        out.freshHistoryCM = []
        out.reportSource = source
        out.reportUpdatedAt = report.fetchedAt
        return out
    }
}
