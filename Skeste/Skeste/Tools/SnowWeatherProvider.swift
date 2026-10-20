import Foundation
import CoreLocation
import WeatherKit

protocol SnowWeatherProviding {
    func fetch(template: SnowResort) async throws -> LiveSnowReport
}

struct WeatherKitSnowProvider: SnowWeatherProviding {
    func fetch(template: SnowResort) async throws -> LiveSnowReport {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-weatherStubOffline") {
            throw URLError(.notConnectedToInternet)
        }
        if arguments.contains("-weatherStubPermissionDenied") {
            throw WeatherError.permissionDenied
        }
        if let stub = SnowWeatherDebug.report(for: template) { return stub }
        #endif

        let location = CLLocation(latitude: template.latitude, longitude: template.longitude)
        let currentQuery = WeatherQuery<CurrentWeather>.current
        let hourlyQuery = WeatherQuery<Forecast<HourWeather>>.hourly
        let dailyQuery = WeatherQuery<Forecast<DayWeather>>.daily
        let (current, hourlyForecast, dailyForecast) = try await WeatherService.shared.weather(
            for: location,
            including: currentQuery,
            hourlyQuery,
            dailyQuery
        )

        let tempC = current.temperature.converted(to: .celsius).value
        let windKPH = current.wind.speed.converted(to: .kilometersPerHour).value
        let gustKPH = current.wind.gust?.converted(to: .kilometersPerHour).value
        let visibilityKM = current.visibility.converted(to: .kilometers).value
        let humidity = current.humidity * 100
        let cloudCover = current.cloudCover * 100
        let conditionText = Self.conditionLabel(current.condition)
        let timeZone = template.timeZone

        let calendar = Self.calendar(timeZone: timeZone)
        let allDays = Array(dailyForecast.prefix(7))
        let snowToday = allDays.first.map(Self.snowCM) ?? 0
        let days = allDays.map { day in
            SnowDay(
                day: Self.dayLabel(for: day.date, calendar: calendar),
                condition: Self.conditionLabel(day.condition),
                highC: Int(day.highTemperature.converted(to: .celsius).value.rounded()),
                lowC: Int(day.lowTemperature.converted(to: .celsius).value.rounded()),
                freshCM: Int(Self.snowCM(day).rounded()),
                symbol: day.symbolName
            )
        }

        let now = Date()
        let upcoming = Array(hourlyForecast.filter { $0.date >= now.addingTimeInterval(-3_600) }.prefix(24))
        let hours = upcoming.prefix(6).map { hour in
            SnowHour(
                time: Self.timeLabel(hour.date, timeZone: timeZone),
                tempC: Int(hour.temperature.converted(to: .celsius).value.rounded()),
                snowChance: Int((hour.precipitationChance * 100).rounded()),
                windKPH: Int(hour.wind.speed.converted(to: .kilometersPerHour).value.rounded()),
                symbol: hour.symbolName
            )
        }

        let window = Self.bestWindow(from: upcoming, timeZone: timeZone)
        let freezingLevelM = min(max(template.elevationM + Int((tempC / 6.5) * 1_000), 0), 6_000)
        let snowLineM = min(max(freezingLevelM - 150, 0), 6_000)

        let age = Self.snowAge(tempC: tempC, snowToday: snowToday)
        let texture = Self.snowTexture(tempC: tempC, humidity: humidity, snowToday: snowToday, age: age)
        let headline = Self.headline(
            tempC: tempC,
            windKPH: windKPH,
            snowToday: snowToday,
            condition: current.condition,
            conditionText: conditionText
        )
        let note = Self.conditionsNote(
            tempC: tempC,
            windKPH: windKPH,
            gustKPH: gustKPH,
            snowToday: snowToday,
            conditionText: conditionText
        )

        return LiveSnowReport(
            resortName: template.name,
            fetchedAt: now,
            observedAt: current.date,
            tempC: tempC,
            windKPH: windKPH,
            gustKPH: gustKPH,
            visibilityKM: visibilityKM,
            humidityPercent: humidity,
            cloudCoverPercent: cloudCover,
            conditionText: conditionText,
            headline: headline,
            conditionSymbol: current.symbolName,
            isDaylight: current.isDaylight,
            snowTodayCM: snowToday,
            hours: hours,
            days: days,
            window: window,
            snowLineM: snowLineM,
            freezingLevelM: freezingLevelM,
            snowAgeDays: Self.ageDays(age),
            textureIndex: texture.rawValue,
            ageIndex: age.rawValue,
            conditionsNote: note
        )
    }

    // MARK: - WeatherKit mapping helpers

    private static func snowCM(_ day: DayWeather) -> Double {
        if #available(iOS 18.0, *) {
            return day.precipitationAmountByType.snowfallAmount.amount
                .converted(to: .centimeters).value
        }
        return day.snowfallAmount.converted(to: .centimeters).value
    }

    private static func calendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static func timeLabel(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func dayLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "TODAY" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "TOMORROW"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private static func bestWindow(from hours: [HourWeather], timeZone: TimeZone) -> SnowWindow {
        let daylight = hours.filter(\.isDaylight)
        guard daylight.count >= 2 else {
            return SnowWindow(label: "—", detail: "No daylight window in the next 24 hours.")
        }

        var bestIndex = 0
        var bestScore = Double.greatestFiniteMagnitude
        for index in 0..<(daylight.count - 1) {
            let first = daylight[index]
            let second = daylight[index + 1]
            let chance = (first.precipitationChance + second.precipitationChance) / 2 * 100
            let wind = (first.wind.speed.converted(to: .kilometersPerHour).value
                        + second.wind.speed.converted(to: .kilometersPerHour).value) / 2
            let score = chance + wind * 1.4
            if score < bestScore {
                bestScore = score
                bestIndex = index
            }
        }

        let start = daylight[bestIndex]
        let endDate = daylight[bestIndex + 1].date.addingTimeInterval(3_600)
        let chance = Int(((start.precipitationChance + daylight[bestIndex + 1].precipitationChance) / 2 * 100).rounded())
        let wind = Int(((start.wind.speed.converted(to: .kilometersPerHour).value
                         + daylight[bestIndex + 1].wind.speed.converted(to: .kilometersPerHour).value) / 2).rounded())

        let calendar = calendar(timeZone: timeZone)
        let prefix = calendar.isDateInToday(start.date) ? "" : "TOMORROW "
        return SnowWindow(
            label: "\(prefix)\(timeLabel(start.date, timeZone: timeZone)) – \(timeLabel(endDate, timeZone: timeZone))",
            detail: "\(chance)% precip · \(wind) km/h wind"
        )
    }

    private static func snowAge(tempC: Double, snowToday: Double) -> SnowAge {
        if tempC >= 2 { return .spring }
        if snowToday >= 3 { return .fresh }
        if snowToday >= 1 { return .settled }
        return .old
    }

    private static func snowTexture(tempC: Double, humidity: Double, snowToday: Double, age: SnowAge) -> SnowTexture {
        if snowToday >= 8 { return .fresh }
        if tempC >= 2.5 { return .wet }
        if age == .old && humidity < 45 { return .icy }
        return .groomed
    }

    private static func ageDays(_ age: SnowAge) -> Int {
        switch age {
        case .fresh: return 0
        case .settled: return 2
        case .old: return 5
        case .spring: return 1
        }
    }

    private static func headline(tempC: Double, windKPH: Double, snowToday: Double, condition: WeatherCondition, conditionText: String) -> String {
        if snowToday >= 20 { return "POWDER DAY" }
        if windKPH >= 35 { return "WIND LOADING" }
        if tempC >= 2 { return "SPRING SNOW" }
        if isSnow(condition) { return "SNOWING" }
        return conditionText.uppercased()
    }

    private static func conditionsNote(tempC: Double, windKPH: Double, gustKPH: Double?, snowToday: Double, conditionText: String) -> String {
        let gust = gustKPH ?? windKPH
        if snowToday >= 10 {
            return "Forecast calls for \(Int(snowToday.rounded())) cm today. Expect a soft surface and wind-affected snow in exposed terrain."
        }
        if gust >= 60 {
            return "Forecast gusts to \(Int(gust.rounded())) km/h. Expect wind loading and possible lift holds."
        }
        if tempC >= 2 {
            return "Warm at resort level (\(Int(tempC.rounded()))°C). Expect wet surface snow and an overnight refreeze."
        }
        return "\(conditionText) and \(Int(tempC.rounded()))°C at resort level. \(Int(snowToday.rounded())) cm possible today; read the surface before trusting the number."
    }

    private static func isSnow(_ condition: WeatherCondition) -> Bool {
        switch condition {
        case .snow, .heavySnow, .flurries, .blowingSnow, .blizzard, .wintryMix, .sunFlurries:
            return true
        default:
            return false
        }
    }

    private static func conditionLabel(_ condition: WeatherCondition) -> String {
        switch condition {
        case .blizzard: return "Blizzard"
        case .blowingDust: return "Blowing dust"
        case .blowingSnow: return "Blowing snow"
        case .breezy: return "Breezy"
        case .clear: return "Clear"
        case .cloudy: return "Cloudy"
        case .drizzle: return "Drizzle"
        case .flurries: return "Flurries"
        case .foggy: return "Foggy"
        case .freezingDrizzle: return "Freezing drizzle"
        case .freezingRain: return "Freezing rain"
        case .frigid: return "Frigid"
        case .hail: return "Hail"
        case .haze: return "Haze"
        case .heavyRain: return "Heavy rain"
        case .heavySnow: return "Heavy snow"
        case .hot: return "Hot"
        case .hurricane: return "Hurricane"
        case .isolatedThunderstorms: return "Isolated storms"
        case .mostlyClear: return "Mostly clear"
        case .mostlyCloudy: return "Mostly cloudy"
        case .partlyCloudy: return "Partly cloudy"
        case .rain: return "Rain"
        case .scatteredThunderstorms: return "Scattered storms"
        case .sleet: return "Sleet"
        case .smoky: return "Smoky"
        case .snow: return "Snow"
        case .strongStorms: return "Strong storms"
        case .sunFlurries: return "Sun and flurries"
        case .sunShowers: return "Sun showers"
        case .thunderstorms: return "Thunderstorms"
        case .tropicalStorm: return "Tropical storm"
        case .windy: return "Windy"
        case .wintryMix: return "Wintry mix"
        @unknown default: return "Mountain weather"
        }
    }

    static func userMessage(for error: Error) -> (text: String, permissionDenied: Bool) {
        if let weatherError = error as? WeatherError, weatherError == .permissionDenied {
            return ("WeatherKit isn't enabled for this build. Showing fallback data.", true)
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return ("No connection. Showing saved weather if available.", false)
        }
        let message = error.localizedDescription.lowercased()
        if message.contains("permission") || message.contains("entitlement") {
            return ("WeatherKit isn't enabled for this build. Showing fallback data.", true)
        }
        return ("Live weather is unavailable right now. Showing saved or fallback data.", false)
    }
}

#if DEBUG
enum SnowWeatherDebug {
    static func report(for template: SnowResort) -> LiveSnowReport? {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-weatherStubSuccess") else { return nil }

        let now = Date()
        var hours: [SnowHour] = []
        for index in 0..<6 {
            let time = String(format: "%02d:00", (8 + index * 2) % 24)
            hours.append(SnowHour(
                time: time,
                tempC: template.tempC - index / 2,
                snowChance: min(90, 15 + index * 8),
                windKPH: template.windKPH + index,
                symbol: index % 3 == 0 ? "snowflake" : "cloud.sun.fill"
            ))
        }
        var days: [SnowDay] = []
        for index in 0..<7 {
            let day = index == 0 ? "TODAY" : (index == 1 ? "TOMORROW" : "D+\(index)")
            days.append(SnowDay(
                day: day,
                condition: index % 2 == 0 ? "Snow" : "Cloud + sun",
                highC: template.tempC + 1,
                lowC: template.tempC - 5,
                freshCM: max(0, 8 - index),
                symbol: index % 2 == 0 ? "cloud.snow.fill" : "cloud.sun.fill"
            ))
        }
        return LiveSnowReport(
            resortName: template.name,
            fetchedAt: now,
            observedAt: now,
            tempC: Double(template.tempC),
            windKPH: Double(template.windKPH),
            gustKPH: Double(template.windKPH + 18),
            visibilityKM: Double(template.visibilityKM),
            humidityPercent: Double(template.humidity),
            cloudCoverPercent: 65,
            conditionText: "Snow",
            headline: "SNOWING",
            conditionSymbol: "cloud.snow.fill",
            isDaylight: true,
            snowTodayCM: Double(template.freshCM),
            hours: hours,
            days: days,
            window: SnowWindow(label: "09:00 – 11:00", detail: "20% precip · 12 km/h wind"),
            snowLineM: template.snowLineM,
            freezingLevelM: template.freezingLevelM,
            snowAgeDays: 1,
            textureIndex: SnowTexture.fresh.rawValue,
            ageIndex: SnowAge.fresh.rawValue,
            conditionsNote: "Forecast calls for \(template.freshCM) cm today. Expect a soft surface and wind-affected snow in exposed terrain."
        )
    }
}
#endif
