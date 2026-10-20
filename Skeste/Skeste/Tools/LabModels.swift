import UIKit

// MARK: - Wax

enum SkiDiscipline: Int, CaseIterable {
    case alpine
    case touring
    case park

    var label: String {
        ["ALPINE", "TOURING", "PARK"][rawValue]
    }
}

struct WaxInput {
    var snowTempC: Double
    var airTempC: Double
    var humidity: Double
    var texture: SnowTexture
    var age: SnowAge
    var discipline: SkiDiscipline

    static func from(resort: SnowResort) -> WaxInput {
        WaxInput(snowTempC: resort.derivedSnowTempC,
                 airTempC: Double(resort.tempC),
                 humidity: Double(resort.humidity),
                 texture: resort.snowTexture,
                 age: resort.snowAge,
                 discipline: .alpine)
    }
}

struct WaxPlan {
    let family: String
    let subtitle: String
    let colors: [String]
    let base: String
    let top: String
    let edge: String
    let structure: String
    let brush: String
    let ironTemp: Int
    let cure: String
    let steps: [String]
    let why: String
    let confidence: String
    let confidenceColor: UIColor
    let alternative: String
    let familyIndex: Int
}

enum WaxAdvisor {
    private struct WaxFamily {
        let name: String
        let subtitle: String
        let colors: [String]
        let base: String
        let top: String
        let edge: String
        let structure: String
        let brush: String
        let iron: Int
        let cure: String
    }

    private static let families: [WaxFamily] = [
        WaxFamily(name: "POLAR BLUE", subtitle: "DRY, COLD SNOW", colors: ["CFE5FF", "5C7CFF"],
                  base: "Hard hydrocarbon base wax", top: "Cold glide block", edge: "88° / 2×2",
                  structure: "Fine linear", brush: "Stiff nylon → horsehair", iron: 155, cure: "20 min"),
        WaxFamily(name: "COLD BLUE", subtitle: "WINTER SNOW", colors: ["A8CEFF", "4C6BFF"],
                  base: "Medium-hard hydrocarbon", top: "Cold universal glide", edge: "88° / 2×2",
                  structure: "Fine linear", brush: "Nylon → horsehair", iron: 148, cure: "20 min"),
        WaxFamily(name: "VIOLET", subtitle: "ALL-DAY WINTER", colors: ["D3B6FF", "7652F0"],
                  base: "Medium hydrocarbon", top: "Mid-cold glide", edge: "88° / 2×2",
                  structure: "Medium linear", brush: "Nylon → horsehair", iron: 142, cure: "15 min"),
        WaxFamily(name: "RED", subtitle: "WARM WINTER", colors: ["FFB0BE", "FF3D6E"],
                  base: "Soft hydrocarbon", top: "Warm glide", edge: "88° / 1×1",
                  structure: "Open linear", brush: "Soft nylon → horsehair", iron: 132, cure: "15 min"),
        WaxFamily(name: "WARM YELLOW", subtitle: "SPRING / WET", colors: ["FFE392", "FFAA36"],
                  base: "Soft warm wax", top: "Wet glide + graphite", edge: "87.5° / 1×1",
                  structure: "Wide open", brush: "Soft nylon → horsehair", iron: 122, cure: "10 min")
    ]

    static func plan(for input: WaxInput) -> WaxPlan {
        let baseIndex = temperatureIndex(input.snowTempC)
        var index = baseIndex
        var adjustments = 0

        if input.age == .old {
            index -= 1
            adjustments += 1
        } else if input.age == .spring {
            index += 1
            adjustments += 1
        }

        if input.humidity > 80 {
            index += 1
            adjustments += 1
        } else if input.humidity < 35 {
            index -= 1
            adjustments += 1
        }

        if input.texture == .icy {
            index -= 1
            adjustments += 1
        } else if input.texture == .wet {
            index += 1
            adjustments += 1
        }

        if input.discipline == .touring {
            index -= 1
            adjustments += 1
        }

        let airDelta = input.airTempC - input.snowTempC
        if airDelta > 6 {
            index -= 1
            adjustments += 1
        } else if airDelta < -3 {
            index += 1
            adjustments += 1
        }

        index = min(max(index, 0), families.count - 1)
        let family = families[index]

        let confidence: String
        let confidenceColor: UIColor
        if adjustments == 0 {
            confidence = "HIGH CONFIDENCE"
            confidenceColor = Palette.lime
        } else if adjustments <= 2 {
            confidence = "MEDIUM CONFIDENCE"
            confidenceColor = Palette.amber
        } else {
            confidence = "EDGE OF THE WINDOW"
            confidenceColor = Palette.magenta
        }

        let textureReason: String
        switch input.texture {
        case .fresh: textureReason = "Sharp new crystals favor a slightly harder wax and a fine structure."
        case .groomed: textureReason = "A clean groomed surface rewards a polished linear structure."
        case .wet: textureReason = "Free water pushes the wax softer and the structure wider."
        case .icy: textureReason = "Abrasive ice calls for a harder wax and a sharp edge."
        }

        let disciplineReason: String
        switch input.discipline {
        case .alpine: disciplineReason = "Lift-served laps let you optimize for glide."
        case .touring: disciplineReason = "Skin-track time favors durability over pure glide."
        case .park: disciplineReason = "Park laps are low speed; a durable mid-range wax is enough."
        }

        let alternative: String
        if index > baseIndex {
            alternative = "If the snow turns colder or drier than expected, step back to \(families[max(0, index - 1)].name)."
        } else if index < baseIndex {
            alternative = "If the snow turns warmer or wetter than expected, step up to \(families[min(families.count - 1, index + 1)].name)."
        } else if index < families.count - 1 {
            alternative = "If the snow turns wetter, step up to \(families[index + 1].name)."
        } else {
            alternative = "If the snow stays cold and dry, step down to \(families[index - 1].name)."
        }

        let steps = [
            "Clean and brush the base; let it dry completely.",
            "Iron \(family.name.lowercased()) at \(family.iron)°C, keeping the iron moving.",
            "Scrape while warm, then cure \(family.cure).",
            "Brush \(family.brush.lowercased()), tip to tail.",
            "Finish with \(family.top.lowercased()) and one light pass."
        ]

        let why = "Snow at \(Int(input.snowTempC.rounded()))°C with \(Int(input.humidity.rounded()))% humidity and \(input.age.label.lowercased()) crystals. \(textureReason) \(disciplineReason)"

        return WaxPlan(family: family.name,
                       subtitle: family.subtitle,
                       colors: family.colors,
                       base: family.base,
                       top: family.top,
                       edge: family.edge,
                       structure: family.structure,
                       brush: family.brush,
                       ironTemp: family.iron,
                       cure: family.cure,
                       steps: steps,
                       why: why,
                       confidence: confidence,
                       confidenceColor: confidenceColor,
                       alternative: alternative,
                       familyIndex: index)
    }

    static func quickPlan(for resort: SnowResort) -> WaxPlan {
        plan(for: WaxInput.from(resort: resort))
    }

    private static func temperatureIndex(_ temperature: Double) -> Int {
        if temperature <= -15 { return 0 }
        if temperature <= -8 { return 1 }
        if temperature <= -3 { return 2 }
        if temperature <= 0 { return 3 }
        return 4
    }
}

// MARK: - Terrain

enum AvalancheProblem: Int, CaseIterable {
    case windSlab
    case stormSlab
    case persistentWeakLayer
    case wetLoose
    case none

    var label: String {
        ["WIND", "STORM", "PERSIST", "WET", "NONE"][rawValue]
    }

    var title: String {
        ["WIND SLAB", "STORM SLAB", "PERSISTENT WEAK LAYER", "WET LOOSE", "NO DOMINANT PROBLEM"][rawValue]
    }
}

struct TerrainInput {
    var slope: Double = 34
    var newSnow: Double = 25
    var aspectIndex: Int = 0
    var windIndex: Int = 1
    var warming: Bool = false
    var problem: AvalancheProblem = .windSlab
    var regionalLevel: Int = 3

    static func from(resort: SnowResort) -> TerrainInput {
        let problem: AvalancheProblem
        if resort.windBandIndex > 0 {
            problem = .windSlab
        } else if resort.freshCM >= 20 {
            problem = .stormSlab
        } else if resort.snowAge == .old {
            problem = .persistentWeakLayer
        } else {
            problem = .none
        }
        return TerrainInput(slope: 34,
                            newSnow: Double(resort.freshCM),
                            aspectIndex: 0,
                            windIndex: resort.windBandIndex,
                            warming: resort.tempC >= 0,
                            problem: problem,
                            regionalLevel: resort.avalancheLevel)
    }
}

struct TerrainBreakdownItem {
    let label: String
    let value: Double
    let maximum: Double
    let color: UIColor
}

struct TerrainAssessment {
    let score: Int
    let level: String
    let color: UIColor
    let headline: String
    let description: String
    let breakdown: [TerrainBreakdownItem]
    let advice: [String]
    let problemNote: String
}

enum TerrainAdvisor {
    static func assess(_ input: TerrainInput) -> TerrainAssessment {
        let clampedSlope = min(max(input.slope, 0), 90)
        let slopePoints = min(max((clampedSlope - 18) / 32, 0), 1) * 26
        let snowPoints = min(max(input.newSnow / 60, 0), 1) * 18
        let windPoints: Double = [0, 8, 16][min(max(input.windIndex, 0), 2)]
        let aspectPoints: Double = [10, 8, 2, 5][min(max(input.aspectIndex, 0), 3)]
        let warmingPoints: Double = input.warming ? 8 : 0
        let regionalIndex = min(max(input.regionalLevel - 1, 0), 4)
        let regionalPoints: Double = [2, 5, 8, 10, 12][regionalIndex]

        let problemPoints: Double
        switch input.problem {
        case .windSlab: problemPoints = input.windIndex > 0 ? 10 : 3
        case .stormSlab: problemPoints = input.newSnow >= 20 ? 10 : 5
        case .persistentWeakLayer: problemPoints = 10
        case .wetLoose: problemPoints = input.warming ? 10 : 5
        case .none: problemPoints = 0
        }

        let rawScore = slopePoints + snowPoints + windPoints + aspectPoints + warmingPoints + regionalPoints + problemPoints
        let score = Int(min(max(rawScore, 0), 100).rounded())

        let level: String
        let color: UIColor
        let headline: String
        let description: String
        if score < 25 {
            level = "LOW"
            color = Palette.lime
            headline = "The main ingredients are not aligned."
            description = "Isolated wind pockets can still hold a surprise. Stay alert in exposed terrain."
        } else if score < 50 {
            level = "MODERATE"
            color = Palette.mint
            headline = "A specific problem is waiting in specific terrain."
            description = "Human-triggered avalanches are possible. Choose supported slopes and watch the wind."
        } else if score < 72 {
            level = "HIGH"
            color = Palette.amber
            headline = "Human-triggered slides are likely."
            description = "Keep to low-angle terrain and avoid loaded lee features and convex rollovers."
        } else {
            level = "EXTREME"
            color = Palette.danger
            headline = "Do not travel in avalanche terrain."
            description = "Natural activity is likely. Stay on low-angle, supported ground well away from runout zones."
        }

        var advice: [String] = []
        if clampedSlope >= 35 {
            advice.append("At \(Int(clampedSlope.rounded()))°, the slope is steep enough to produce a slide. Avoid convex rollovers and terrain traps.")
        } else {
            advice.append("At \(Int(clampedSlope.rounded()))°, exposure is lower, but small slopes and gullies can still slide.")
        }
        if input.windIndex > 0, input.aspectIndex == 0 || input.aspectIndex == 1 {
            advice.append("North and east aspects are loaded by the current wind pattern. Look for fresh cornices, pillows, and shooting cracks.")
        }
        if input.newSnow >= 25 {
            advice.append("\(Int(input.newSnow.rounded())) cm of recent snow is a significant load. Give the snowpack time to settle.")
        } else if input.newSnow == 0 {
            advice.append("No recent snow means older weak layers deserve the attention. Dig down and test the structure.")
        }
        if input.warming {
            advice.append("Warming can make the surface wet and loose. Watch for roller balls, pinwheels, and natural wet slides.")
        }

        let problemNote: String
        switch input.problem {
        case .windSlab:
            problemNote = "Wind slab: fresh cornices and shooting cracks are the tell. Avoid lee slopes and cross-loaded gullies."
        case .stormSlab:
            problemNote = "Storm slab: the new snow has not bonded yet. Give it time and stay off steep convex rolls."
        case .persistentWeakLayer:
            problemNote = "Persistent weak layer: assume the old layer is still reactive. Low-angle, supported terrain only."
        case .wetLoose:
            problemNote = "Wet loose: warmth is the trigger. Move early and stay out of sun-exposed steeps and terrain traps."
        case .none:
            problemNote = "No single problem dominates today, but isolated wind pockets still exist."
        }

        advice.append("Ride one at a time through exposed sections and keep your partners in sight.")

        let breakdown = [
            TerrainBreakdownItem(label: "SLOPE", value: slopePoints, maximum: 26, color: Palette.amber),
            TerrainBreakdownItem(label: "NEW SNOW", value: snowPoints, maximum: 18, color: Palette.ice),
            TerrainBreakdownItem(label: "WIND", value: windPoints, maximum: 16, color: Palette.cyan),
            TerrainBreakdownItem(label: "ASPECT", value: aspectPoints, maximum: 10, color: Palette.violet),
            TerrainBreakdownItem(label: "WARMING", value: warmingPoints, maximum: 8, color: Palette.danger),
            TerrainBreakdownItem(label: "REGION", value: regionalPoints, maximum: 12, color: Palette.mint),
            TerrainBreakdownItem(label: "PROBLEM", value: problemPoints, maximum: 10, color: Palette.magenta)
        ]

        return TerrainAssessment(score: score,
                                 level: level,
                                 color: color,
                                 headline: headline,
                                 description: description,
                                 breakdown: breakdown,
                                 advice: advice,
                                 problemNote: problemNote)
    }

    static func decision(score: Int, checks: Int) -> (label: String, color: UIColor, detail: String) {
        if score >= 70 {
            return ("NO-GO", Palette.danger, "The risk is beyond what this tool can support today.")
        }
        if score < 30, checks >= 4 {
            return ("GO", Palette.lime, "Conditions and your field checks line up.")
        }
        if score < 55 || checks >= 3 {
            return ("CAUTION", Palette.amber, "Go only with a conservative plan and an escape route.")
        }
        return ("NO-GO", Palette.danger, "Too many boxes are unchecked for the current risk.")
    }
}

// MARK: - Fit

struct FitInput {
    var heightCM: Double = 175
    var weightKG: Double = 75
    var soleMM: Double = 315
    var styleIndex: Int = 0
    var abilityIndex: Int = 1
}

struct SkiPick {
    let name: String
    let lengthCM: Int
    let waistMM: Int
    let radiusM: Double
    let profile: String
    let match: Int
}

struct FitResult {
    let lengthCM: Int
    let lengthRange: ClosedRange<Int>
    let waistMM: Int
    let radiusM: Double
    let flex: Int
    let profile: String
    let din: Double
    let dinRange: ClosedRange<Double>
    let soleNote: String
    let picks: [SkiPick]
    let explanation: String
    let styleName: String
    let abilityName: String
}

enum FitAdvisor {
    static let styleNames = ["ALL MTN", "FREERIDE", "PARK", "TOURING"]
    static let styleLongNames = ["all-mountain", "freeride", "park", "touring"]
    static let abilityNames = ["NEW", "SOLID", "EXPERT"]

    private struct PickTemplate {
        let name: String
        let waist: Int
        let profile: String
        let lengthOffset: Int
        let bonus: Int
    }

    private static let pickTemplates: [[PickTemplate]] = [
        [PickTemplate(name: "DAILY DRIVER", waist: 94, profile: "All-mountain rocker", lengthOffset: 0, bonus: 2),
         PickTemplate(name: "STORM SKI", waist: 104, profile: "Rocker / camber / rocker", lengthOffset: 5, bonus: -1),
         PickTemplate(name: "CARVER", waist: 84, profile: "Full camber", lengthOffset: -5, bonus: -4)],
        [PickTemplate(name: "FREERIDE CHARGER", waist: 108, profile: "Rocker / camber / rocker", lengthOffset: 5, bonus: 2),
         PickTemplate(name: "POWDER TOURER", waist: 112, profile: "Full rocker", lengthOffset: 0, bonus: 0),
         PickTemplate(name: "BIG MOUNTAIN", waist: 116, profile: "Tapered rocker", lengthOffset: 10, bonus: -3)],
        [PickTemplate(name: "PARK TWIN", waist: 88, profile: "Twin tip / full rocker", lengthOffset: 0, bonus: 2),
         PickTemplate(name: "ALL-MTN TWIN", waist: 92, profile: "Twin rocker", lengthOffset: 5, bonus: 0),
         PickTemplate(name: "JIB STICK", waist: 84, profile: "Twin tip", lengthOffset: -5, bonus: -4)],
        [PickTemplate(name: "TOUR LIGHT", waist: 98, profile: "Light rocker / flat tail", lengthOffset: 0, bonus: 2),
         PickTemplate(name: "POWDER TOUR", waist: 104, profile: "Rocker / camber", lengthOffset: 5, bonus: 0),
         PickTemplate(name: "MOUNTAINEER", waist: 88, profile: "Flat tail", lengthOffset: -5, bonus: -4)]
    ]

    private static let styleOffsets: [Double] = [0, 6, -8, -3]
    private static let abilityOffsets: [Double] = [-6, 0, 5]
    private static let waists = [94, 104, 88, 99]
    private static let profiles = ["All-mountain rocker", "Rocker / camber / rocker", "Twin tip / full rocker", "Light rocker / flat tail"]
    private static let flexBases = [100, 120, 95, 110]

    static func fit(_ input: FitInput) -> FitResult {
        let style = min(max(input.styleIndex, 0), 3)
        let ability = min(max(input.abilityIndex, 0), 2)

        let raw = input.heightCM + styleOffsets[style] + abilityOffsets[ability]
        let length = Int(min(max((raw / 5).rounded() * 5, 140), 195))
        let range = max(140, length - 4)...min(195, length + 6)

        let waist = waists[style]
        let radius = 14 + (Double(waist) - 84) * 0.22 + (Double(length) - 160) * 0.035
        let flex = Int((Double(flexBases[style]) + (input.weightKG - 75) / 8).rounded())

        let din = releaseValue(weight: input.weightKG, height: input.heightCM, soleMM: input.soleMM, ability: ability)
        let dinRange = max(1, din - 0.5)...min(16, din + 0.5)

        let soleNote: String
        if input.soleMM < 270 {
            soleNote = "Short sole (+) · more leverage"
        } else if input.soleMM <= 310 {
            soleNote = "Neutral sole length"
        } else if input.soleMM <= 330 {
            soleNote = "Long sole (−) · more leverage"
        } else {
            soleNote = "Very long sole (−−)"
        }

        let weightPenalty = Int(abs(input.weightKG - 75) / 10)
        let abilityPenalty = abs(ability - 1) * 4
        let picks = pickTemplates[style].map { template -> SkiPick in
            let pickLength = Int(min(max(Double(length + template.lengthOffset), 140), 195))
            let pickRadius = 14 + (Double(template.waist) - 84) * 0.22 + (Double(pickLength) - 160) * 0.035
            let match = min(max(96 + template.bonus - abilityPenalty - weightPenalty, 70), 99)
            return SkiPick(name: template.name,
                           lengthCM: pickLength,
                           waistMM: template.waist,
                           radiusM: pickRadius,
                           profile: template.profile,
                           match: match)
        }

        let article = style == 0 ? "an" : "a"
        let explanation = "At \(Int(input.heightCM.rounded())) cm and \(Int(input.weightKG.rounded())) kg with \(article) \(styleLongNames[style]) focus, start around \(length) cm. Your \(Int(input.soleMM.rounded())) mm boot lands at DIN \(formatDIN(din)) (range \(formatDIN(dinRange.lowerBound))–\(formatDIN(dinRange.upperBound)))."

        return FitResult(lengthCM: length,
                         lengthRange: range,
                         waistMM: waist,
                         radiusM: radius,
                         flex: flex,
                         profile: profiles[style],
                         din: din,
                         dinRange: dinRange,
                         soleNote: soleNote,
                         picks: picks,
                         explanation: explanation,
                         styleName: styleNames[style],
                         abilityName: abilityNames[ability])
    }

    private static func releaseValue(weight: Double, height: Double, soleMM: Double, ability: Int) -> Double {
        // A practical approximation of the ISO 11088 release value.
        let weightBase = weight / 10 - 0.5
        let heightAdjust = (height - 160) / 20
        let abilityAdjust: Double = [-1.5, 0, 1.5][min(max(ability, 0), 2)]

        let soleAdjust: Double
        if soleMM < 270 {
            soleAdjust = 0.5
        } else if soleMM <= 310 {
            soleAdjust = 0
        } else if soleMM <= 330 {
            soleAdjust = -0.5
        } else {
            soleAdjust = -1
        }

        let raw = weightBase + heightAdjust + abilityAdjust + soleAdjust
        return min(max((raw * 2).rounded() / 2, 1), 16)
    }
}

func formatDIN(_ value: Double) -> String {
    if value == value.rounded() {
        return String(format: "%.0f", value)
    }
    return String(format: "%.1f", value)
}

// MARK: - Preferences

struct SavedWaxSetup: Codable, Equatable {
    var id: String
    var createdAt: Date
    var snowTempC: Double
    var airTempC: Double
    var humidity: Double
    var textureIndex: Int
    var ageIndex: Int
    var disciplineIndex: Int
    var family: String
    var label: String
}

struct SavedQuiver: Codable, Equatable {
    var id: String
    var createdAt: Date
    var heightCM: Double
    var weightKG: Double
    var soleMM: Double
    var styleIndex: Int
    var abilityIndex: Int
    var lengthCM: Int
    var waistMM: Int
    var din: Double
    var label: String
}

private struct LabStorage: Codable {
    var favoriteResorts: [String] = []
    var usesFahrenheit: Bool = false
    var savedWax: [SavedWaxSetup] = []
    var savedQuivers: [SavedQuiver] = []
    var lastWax: SavedWaxSetup?
    var lastFit: SavedQuiver?
}

final class LabPrefs {
    static let shared = LabPrefs()

    private let storageKey = "skeste.lab.prefs.v1"
    private var storage: LabStorage
    private(set) var revision: Int = 0

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(LabStorage.self, from: data) {
            storage = decoded
        } else {
            storage = LabStorage()
        }
    }

    var favoriteResorts: [String] { storage.favoriteResorts }
    var savedWax: [SavedWaxSetup] { storage.savedWax }
    var savedQuivers: [SavedQuiver] { storage.savedQuivers }
    var lastWax: SavedWaxSetup? { storage.lastWax }
    var lastFit: SavedQuiver? { storage.lastFit }

    var usesFahrenheit: Bool {
        get { storage.usesFahrenheit }
        set {
            guard storage.usesFahrenheit != newValue else { return }
            storage.usesFahrenheit = newValue
            persist()
        }
    }

    func isFavorite(_ name: String) -> Bool {
        storage.favoriteResorts.contains(name)
    }

    func toggleFavorite(_ name: String) {
        if let index = storage.favoriteResorts.firstIndex(of: name) {
            storage.favoriteResorts.remove(at: index)
        } else {
            storage.favoriteResorts.append(name)
        }
        persist()
    }

    func saveWax(_ setup: SavedWaxSetup) {
        storage.savedWax.removeAll(where: { $0.label == setup.label })
        storage.savedWax.insert(setup, at: 0)
        if storage.savedWax.count > 5 {
            storage.savedWax = Array(storage.savedWax.prefix(5))
        }
        storage.lastWax = setup
        persist()
    }

    func saveQuiver(_ setup: SavedQuiver) {
        storage.savedQuivers.removeAll(where: { $0.label == setup.label })
        storage.savedQuivers.insert(setup, at: 0)
        if storage.savedQuivers.count > 5 {
            storage.savedQuivers = Array(storage.savedQuivers.prefix(5))
        }
        storage.lastFit = setup
        persist()
    }

    private func persist() {
        revision += 1
        if let data = try? JSONEncoder().encode(storage) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
