import Foundation

struct SnowHour: Codable, Equatable, Sendable {
    let time: String
    let tempC: Int
    let snowChance: Int
    let windKPH: Int
    let symbol: String
}

struct SnowDay: Codable, Equatable, Sendable {
    let day: String
    let condition: String
    let highC: Int
    let lowC: Int
    let freshCM: Int
    let symbol: String
}

enum SnowTexture: Int, CaseIterable, Codable, Sendable {
    case fresh
    case groomed
    case wet
    case icy

    var label: String {
        ["FRESH", "GROOMED", "WET", "ICY"][rawValue]
    }

    var shortLabel: String {
        ["FRESH", "GROOMED", "WET", "ICY"][rawValue]
    }
}

enum SnowAge: Int, CaseIterable, Codable, Sendable {
    case fresh
    case settled
    case old
    case spring

    var label: String {
        ["FRESH", "SETTLED", "OLD", "SPRING"][rawValue]
    }
}

struct SnowWindow: Codable, Equatable, Sendable {
    let label: String
    let detail: String
}

struct SnowResort: Sendable {
    let name: String
    let region: String
    let baseCM: Int
    var freshCM: Int
    var tempC: Int
    var windKPH: Int
    var visibilityKM: Int
    let avalancheLevel: Int
    let liftsOpen: Int
    let liftsTotal: Int
    var note: String
    var hours: [SnowHour]
    var days: [SnowDay]
    var snowLineM: Int = 2_200
    var freezingLevelM: Int = 2_600
    var humidity: Int = 62
    var windMidKPH: Int = 30
    var windTopKPH: Int = 55
    var snowAgeDays: Int = 1
    var baseHistoryCM: [Int] = []
    var freshHistoryCM: [Int] = []

    // Live-weather metadata and overrides. All defaulted so the seven catalog
    // literals below remain source-compatible.
    var latitude: Double = 0
    var longitude: Double = 0
    var elevationM: Int = 0
    var timeZoneID: String = "UTC"
    var reportSource: SnowReportSource = .sample
    var reportUpdatedAt: Date?
    var conditionOverride: String?
    var conditionSymbolOverride: String?
    var textureOverride: SnowTexture?
    var ageOverride: SnowAge?
    var windowOverride: SnowWindow?
    var conditionsNote: String?
    var windGustKPH: Int?
    var cloudCoverPercent: Int?

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneID) ?? .current
    }

    /// Surface snow usually runs a couple of degrees colder than the air.
    var derivedSnowTempC: Double {
        Double(tempC) - 2
    }

    var snowTexture: SnowTexture {
        if let override = textureOverride { return override }
        if freshCM >= 15 { return .fresh }
        if tempC >= 2 { return .wet }
        if freshCM <= 2, baseCM >= 150, tempC <= 0 { return .icy }
        return .groomed
    }

    var snowAge: SnowAge {
        if let override = ageOverride { return override }
        if tempC >= 2 { return .spring }
        if snowAgeDays <= 1 { return .fresh }
        if snowAgeDays <= 3 { return .settled }
        return .old
    }

    var windBandIndex: Int {
        if windKPH < 10 { return 0 }
        if windKPH < 20 { return 1 }
        return 2
    }

    var conditionHeadline: String {
        if let override = conditionOverride, !override.isEmpty { return override }
        if freshCM >= 20 { return "POWDER DAY" }
        if windKPH >= 20 { return "WIND LOADING" }
        if tempC >= 2 { return "SPRING SNOW" }
        if freshCM >= 6 { return "FRESH TRACKS" }
        return "SETTLED SNOW"
    }

    var conditionSymbol: String {
        if let override = conditionSymbolOverride { return override }
        if freshCM >= 20 { return "cloud.snow.fill" }
        if windKPH >= 20 { return "wind.snow" }
        if tempC >= 2 { return "sun.max.fill" }
        if freshCM >= 6 { return "snowflake" }
        return "cloud.sun.fill"
    }

    var bestWindow: SnowWindow {
        if let override = windowOverride { return override }
        let daytime = hours.filter { hour in
            guard let value = Int(hour.time.prefix(2)) else { return false }
            return value >= 8 && value <= 17
        }
        guard daytime.count >= 2 else {
            return SnowWindow(label: daytime.first?.time ?? "--", detail: "No daylight window in this report.")
        }

        var bestStart = 0
        var bestEnd = 1
        var bestScore = Double.greatestFiniteMagnitude
        for start in 0..<(daytime.count - 1) {
            let first = daytime[start]
            let second = daytime[start + 1]
            let chance = (Double(first.snowChance) + Double(second.snowChance)) / 2
            let wind = (Double(first.windKPH) + Double(second.windKPH)) / 2
            let score = chance + wind * 1.4
            if score < bestScore {
                bestScore = score
                bestStart = start
                bestEnd = start + 1
            }
        }

        let start = daytime[bestStart]
        let end = daytime[bestEnd]
        let chance = Int((Double(start.snowChance) + Double(end.snowChance)) / 2)
        let wind = Int((Double(start.windKPH) + Double(end.windKPH)) / 2)
        return SnowWindow(label: "\(start.time) – \(end.time)",
                          detail: "\(chance)% precip · \(wind) km/h wind")
    }
}

enum SnowLibrary {
    private static let chamonix = SnowResort(name: "Chamonix", region: "FRANCE  ·  MONT BLANC", baseCM: 185, freshCM: 18, tempC: -4, windKPH: 12, visibilityKM: 8, avalancheLevel: 3, liftsOpen: 42, liftsTotal: 49,
                   note: "Wind slabs are forming on north-facing slopes above 2,400 m. The lower trees are holding soft snow.",
                   hours: [
                    SnowHour(time: "06:00", tempC: -7, snowChance: 10, windKPH: 8, symbol: "moon.stars.fill"),
                    SnowHour(time: "09:00", tempC: -5, snowChance: 15, windKPH: 11, symbol: "snowflake"),
                    SnowHour(time: "12:00", tempC: -3, snowChance: 20, windKPH: 14, symbol: "cloud.sun.fill"),
                    SnowHour(time: "15:00", tempC: -2, snowChance: 35, windKPH: 16, symbol: "cloud.snow.fill"),
                    SnowHour(time: "18:00", tempC: -4, snowChance: 55, windKPH: 18, symbol: "cloud.snow.fill"),
                    SnowHour(time: "21:00", tempC: -6, snowChance: 65, windKPH: 20, symbol: "snowflake")
                   ],
                   days: [
                    SnowDay(day: "TOMORROW", condition: "Snow showers", highC: -2, lowC: -8, freshCM: 14, symbol: "cloud.snow.fill"),
                    SnowDay(day: "THU", condition: "Clearing", highC: 0, lowC: -7, freshCM: 6, symbol: "cloud.sun.fill"),
                    SnowDay(day: "FRI", condition: "Bluebird", highC: 2, lowC: -5, freshCM: 0, symbol: "sun.max.fill")
                   ],
                   snowLineM: 2_400, freezingLevelM: 2_600, humidity: 68, windMidKPH: 34, windTopKPH: 62, snowAgeDays: 1,
                   baseHistoryCM: [168, 171, 176, 180, 185, 185, 185],
                   freshHistoryCM: [0, 4, 9, 14, 18, 6, 2],
                   latitude: 45.9237, longitude: 6.8694, elevationM: 1_035, timeZoneID: "Europe/Paris")

    private static let whistler = SnowResort(name: "Whistler", region: "CANADA  ·  COAST MOUNTAINS", baseCM: 240, freshCM: 28, tempC: -6, windKPH: 19, visibilityKM: 6, avalancheLevel: 3, liftsOpen: 27, liftsTotal: 31,
                   note: "Storm snow is upside down. Stick to supported terrain and watch for shooting cracks near ridge lines.",
                   hours: [
                    SnowHour(time: "06:00", tempC: -8, snowChance: 70, windKPH: 20, symbol: "cloud.snow.fill"),
                    SnowHour(time: "09:00", tempC: -7, snowChance: 80, windKPH: 22, symbol: "cloud.snow.fill"),
                    SnowHour(time: "12:00", tempC: -6, snowChance: 60, windKPH: 24, symbol: "snowflake"),
                    SnowHour(time: "15:00", tempC: -5, snowChance: 45, windKPH: 20, symbol: "cloud.sun.fill"),
                    SnowHour(time: "18:00", tempC: -6, snowChance: 30, windKPH: 16, symbol: "cloud.moon.fill"),
                    SnowHour(time: "21:00", tempC: -8, snowChance: 20, windKPH: 13, symbol: "moon.stars.fill")
                   ],
                   days: [
                    SnowDay(day: "TOMORROW", condition: "Storm easing", highC: -4, lowC: -10, freshCM: 12, symbol: "cloud.snow.fill"),
                    SnowDay(day: "THU", condition: "Cloud + sun", highC: -2, lowC: -8, freshCM: 4, symbol: "cloud.sun.fill"),
                    SnowDay(day: "FRI", condition: "High cloud", highC: 0, lowC: -6, freshCM: 2, symbol: "cloud.fill")
                   ],
                   snowLineM: 1_800, freezingLevelM: 2_100, humidity: 82, windMidKPH: 42, windTopKPH: 70, snowAgeDays: 0,
                   baseHistoryCM: [212, 220, 228, 236, 240, 244, 240],
                   freshHistoryCM: [8, 16, 22, 28, 20, 10, 4],
                   latitude: 50.1163, longitude: -122.9574, elevationM: 675, timeZoneID: "America/Vancouver")

    private static let stAnton = SnowResort(name: "St. Anton", region: "AUSTRIA  ·  ARLBERG", baseCM: 165, freshCM: 12, tempC: -2, windKPH: 9, visibilityKM: 10, avalancheLevel: 2, liftsOpen: 81, liftsTotal: 88,
                   note: "Good travel conditions. The surface is variable below 1,800 m where the sun has been working on it.",
                   hours: [
                    SnowHour(time: "06:00", tempC: -5, snowChance: 5, windKPH: 5, symbol: "moon.stars.fill"),
                    SnowHour(time: "09:00", tempC: -3, snowChance: 10, windKPH: 7, symbol: "sun.max.fill"),
                    SnowHour(time: "12:00", tempC: 0, snowChance: 10, windKPH: 9, symbol: "sun.max.fill"),
                    SnowHour(time: "15:00", tempC: 1, snowChance: 20, windKPH: 12, symbol: "cloud.sun.fill"),
                    SnowHour(time: "18:00", tempC: -2, snowChance: 25, windKPH: 10, symbol: "cloud.moon.fill"),
                    SnowHour(time: "21:00", tempC: -4, snowChance: 20, windKPH: 8, symbol: "moon.stars.fill")
                   ],
                   days: [
                    SnowDay(day: "TOMORROW", condition: "Mostly sunny", highC: 1, lowC: -6, freshCM: 0, symbol: "sun.max.fill"),
                    SnowDay(day: "THU", condition: "PM flurries", highC: 0, lowC: -7, freshCM: 5, symbol: "cloud.snow.fill"),
                    SnowDay(day: "FRI", condition: "Cold front", highC: -3, lowC: -11, freshCM: 11, symbol: "wind.snow")
                   ],
                   snowLineM: 1_900, freezingLevelM: 2_300, humidity: 55, windMidKPH: 22, windTopKPH: 38, snowAgeDays: 2,
                   baseHistoryCM: [152, 155, 158, 162, 165, 166, 165],
                   freshHistoryCM: [0, 2, 6, 8, 12, 3, 0],
                   latitude: 47.1290, longitude: 10.2650, elevationM: 1_304, timeZoneID: "Europe/Vienna")

    private static let jacksonHole = SnowResort(name: "Jackson Hole", region: "USA  ·  WYOMING", baseCM: 210, freshCM: 34, tempC: -9, windKPH: 24, visibilityKM: 5, avalancheLevel: 4, liftsOpen: 11, liftsTotal: 13,
                   note: "High danger above tree line. Keep it low, keep it supported, and check the morning forecast before committing.",
                   hours: [
                    SnowHour(time: "06:00", tempC: -12, snowChance: 65, windKPH: 26, symbol: "wind.snow"),
                    SnowHour(time: "09:00", tempC: -10, snowChance: 55, windKPH: 24, symbol: "cloud.snow.fill"),
                    SnowHour(time: "12:00", tempC: -9, snowChance: 40, windKPH: 21, symbol: "snowflake"),
                    SnowHour(time: "15:00", tempC: -8, snowChance: 30, windKPH: 18, symbol: "cloud.sun.fill"),
                    SnowHour(time: "18:00", tempC: -10, snowChance: 20, windKPH: 15, symbol: "cloud.moon.fill"),
                    SnowHour(time: "21:00", tempC: -13, snowChance: 10, windKPH: 12, symbol: "moon.stars.fill")
                   ],
                   days: [
                    SnowDay(day: "TOMORROW", condition: "Cold + clear", highC: -6, lowC: -16, freshCM: 2, symbol: "sun.max.fill"),
                    SnowDay(day: "THU", condition: "Next system", highC: -5, lowC: -13, freshCM: 18, symbol: "cloud.snow.fill"),
                    SnowDay(day: "FRI", condition: "Snow", highC: -7, lowC: -15, freshCM: 22, symbol: "cloud.snow.fill")
                   ],
                   snowLineM: 2_100, freezingLevelM: 2_500, humidity: 48, windMidKPH: 48, windTopKPH: 82, snowAgeDays: 0,
                   baseHistoryCM: [178, 186, 195, 204, 210, 212, 210],
                   freshHistoryCM: [12, 24, 30, 34, 18, 8, 4],
                   latitude: 43.5875, longitude: -110.8279, elevationM: 1_924, timeZoneID: "America/Denver")

    private static let are = SnowResort(name: "Åre", region: "SWEDEN  ·  JÄMTLAND", baseCM: 120, freshCM: 6, tempC: -1, windKPH: 7, visibilityKM: 12, avalancheLevel: 2, liftsOpen: 33, liftsTotal: 35,
                   note: "Firm and fast early. The north-facing glades are holding the softest snow.",
                   hours: [
                    SnowHour(time: "06:00", tempC: -4, snowChance: 15, windKPH: 5, symbol: "moon.stars.fill"),
                    SnowHour(time: "09:00", tempC: -2, snowChance: 20, windKPH: 6, symbol: "cloud.sun.fill"),
                    SnowHour(time: "12:00", tempC: 0, snowChance: 25, windKPH: 8, symbol: "cloud.sun.fill"),
                    SnowHour(time: "15:00", tempC: 0, snowChance: 35, windKPH: 9, symbol: "cloud.fill"),
                    SnowHour(time: "18:00", tempC: -2, snowChance: 30, windKPH: 8, symbol: "cloud.moon.fill"),
                    SnowHour(time: "21:00", tempC: -3, snowChance: 25, windKPH: 6, symbol: "snowflake")
                   ],
                   days: [
                    SnowDay(day: "TOMORROW", condition: "Light snow", highC: -1, lowC: -7, freshCM: 4, symbol: "cloud.snow.fill"),
                    SnowDay(day: "THU", condition: "Overcast", highC: 0, lowC: -6, freshCM: 1, symbol: "cloud.fill"),
                    SnowDay(day: "FRI", condition: "Bright", highC: 1, lowC: -5, freshCM: 0, symbol: "sun.max.fill")
                   ],
                   snowLineM: 1_200, freezingLevelM: 1_600, humidity: 72, windMidKPH: 18, windTopKPH: 30, snowAgeDays: 3,
                   baseHistoryCM: [110, 112, 115, 118, 120, 121, 120],
                   freshHistoryCM: [0, 2, 3, 4, 6, 2, 0],
                   latitude: 63.3990, longitude: 13.0810, elevationM: 400, timeZoneID: "Europe/Stockholm")

    private static let cortina = SnowResort(name: "Cortina", region: "ITALY  ·  DOLOMITES", baseCM: 140, freshCM: 9, tempC: 0, windKPH: 6, visibilityKM: 11, avalancheLevel: 2, liftsOpen: 51, liftsTotal: 52,
                   note: "Spring-like temperatures below 1,900 m. Aspect matters today. Stay off loaded lee slopes.",
                   hours: [
                    SnowHour(time: "06:00", tempC: -3, snowChance: 10, windKPH: 4, symbol: "moon.stars.fill"),
                    SnowHour(time: "09:00", tempC: -1, snowChance: 10, windKPH: 5, symbol: "sun.max.fill"),
                    SnowHour(time: "12:00", tempC: 2, snowChance: 15, windKPH: 7, symbol: "sun.max.fill"),
                    SnowHour(time: "15:00", tempC: 2, snowChance: 20, windKPH: 8, symbol: "cloud.sun.fill"),
                    SnowHour(time: "18:00", tempC: 0, snowChance: 20, windKPH: 6, symbol: "cloud.moon.fill"),
                    SnowHour(time: "21:00", tempC: -2, snowChance: 15, windKPH: 5, symbol: "moon.stars.fill")
                   ],
                   days: [
                    SnowDay(day: "TOMORROW", condition: "Sunny", highC: 3, lowC: -4, freshCM: 0, symbol: "sun.max.fill"),
                    SnowDay(day: "THU", condition: "Sun + cloud", highC: 4, lowC: -3, freshCM: 0, symbol: "cloud.sun.fill"),
                    SnowDay(day: "FRI", condition: "Late snow", highC: 1, lowC: -5, freshCM: 7, symbol: "cloud.snow.fill")
                   ],
                   snowLineM: 1_700, freezingLevelM: 2_200, humidity: 58, windMidKPH: 16, windTopKPH: 28, snowAgeDays: 2,
                   baseHistoryCM: [128, 131, 134, 137, 140, 141, 140],
                   freshHistoryCM: [0, 1, 3, 5, 9, 3, 1],
                   latitude: 46.5405, longitude: 12.1357, elevationM: 1_224, timeZoneID: "Europe/Rome")

    private static let revelstoke = SnowResort(name: "Revelstoke", region: "CANADA  ·  COLUMBIA", baseCM: 260, freshCM: 41, tempC: -8, windKPH: 26, visibilityKM: 4, avalancheLevel: 4, liftsOpen: 5, liftsTotal: 7,
                   note: "Very high danger. Natural avalanche cycle is likely. Low-angle trees are the call, if you go at all.",
                   hours: [
                    SnowHour(time: "06:00", tempC: -11, snowChance: 85, windKPH: 28, symbol: "wind.snow"),
                    SnowHour(time: "09:00", tempC: -9, snowChance: 75, windKPH: 25, symbol: "cloud.snow.fill"),
                    SnowHour(time: "12:00", tempC: -8, snowChance: 60, windKPH: 23, symbol: "snowflake"),
                    SnowHour(time: "15:00", tempC: -7, snowChance: 55, windKPH: 20, symbol: "cloud.snow.fill"),
                    SnowHour(time: "18:00", tempC: -9, snowChance: 40, windKPH: 16, symbol: "cloud.moon.fill"),
                    SnowHour(time: "21:00", tempC: -11, snowChance: 30, windKPH: 12, symbol: "moon.stars.fill")
                   ],
                   days: [
                    SnowDay(day: "TOMORROW", condition: "Heavy storm", highC: -5, lowC: -12, freshCM: 28, symbol: "cloud.snow.fill"),
                    SnowDay(day: "THU", condition: "Snow easing", highC: -4, lowC: -11, freshCM: 12, symbol: "cloud.snow.fill"),
                    SnowDay(day: "FRI", condition: "Cold + dry", highC: -6, lowC: -15, freshCM: 0, symbol: "sun.max.fill")
                   ],
                   snowLineM: 1_500, freezingLevelM: 1_900, humidity: 88, windMidKPH: 52, windTopKPH: 90, snowAgeDays: 0,
                   baseHistoryCM: [225, 236, 248, 258, 260, 262, 260],
                   freshHistoryCM: [14, 25, 36, 41, 28, 12, 6],
                   latitude: 50.9981, longitude: -118.1957, elevationM: 512, timeZoneID: "America/Vancouver")

    static let resorts: [SnowResort] = [chamonix, whistler, stAnton, jacksonHole, are, cortina, revelstoke]

    static func canonicalName(_ name: String) -> String {
        let shortName = name.components(separatedBy: ",").first ?? name
        return shortName.trimmingCharacters(in: .whitespaces)
    }

    static func resort(named name: String) -> SnowResort? {
        let shortName = canonicalName(name)
        return resorts.first(where: { $0.name.lowercased() == shortName.lowercased() })
    }

    static func index(of name: String) -> Int? {
        let shortName = canonicalName(name)
        return resorts.firstIndex(where: { $0.name.lowercased() == shortName.lowercased() })
    }
}
