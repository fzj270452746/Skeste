import UIKit
import SnapKit

final class WaxLabViewController: BaseViewController {
    private var input: WaxInput
    private var plan: WaxPlan
    private let sourceNote: String?
    private let sourceKicker: String

    private let resultCard = LabCard()
    private let swatch = UIView()
    private let swatchGradient = CAGradientLayer()
    private let waxNameLabel = UILabel(text: nil, font: SkesteFont.display(24), color: Palette.text)
    private let waxSubtitleLabel = UILabel(text: nil, font: SkesteFont.demibold(8), color: Palette.muted)
    private let confidenceLabel = UILabel(text: nil, font: SkesteFont.demibold(7), color: Palette.lime)
    private let ironValue = UILabel(text: nil, font: SkesteFont.display(30), color: Palette.amber)
    private let ironCaption = UILabel(text: "IRON", font: SkesteFont.demibold(7), color: Palette.muted)
    private let cureValue = UILabel(text: nil, font: SkesteFont.demibold(10), color: Palette.secondary)
    private let baseRow = LabInfoRow(title: "BASE", value: "")
    private let topRow = LabInfoRow(title: "TOP COAT", value: "")
    private let edgeRow = LabInfoRow(title: "EDGE", value: "")
    private let structureRow = LabInfoRow(title: "STRUCTURE", value: "")
    private let brushRow = LabInfoRow(title: "BRUSH", value: "")
    private let stepList = LabStepListView()
    private let whyLabel = UILabel(text: nil, font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
    private let alternativeLabel = UILabel(text: nil, font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
    private let savedTitle = UILabel(text: "SAVED SETUPS", font: SkesteFont.demibold(8), color: Palette.muted)
    private let savedScroll = UIScrollView()
    private let savedRow = UIStackView()

    private lazy var snowSlider = LabSlider(title: "Snow temperature", value: input.snowTempC, range: -25...5, formatter: { "\(Int($0.rounded()))°C" }, tint: Palette.cyan)
    private lazy var airSlider = LabSlider(title: "Air temperature", value: input.airTempC, range: -25...5, formatter: { "\(Int($0.rounded()))°C" }, tint: Palette.ice)
    private lazy var humiditySlider = LabSlider(title: "Relative humidity", value: input.humidity, range: 20...100, formatter: { "\(Int($0.rounded()))%" }, tint: Palette.violet)
    private lazy var ageControl = SkSegmentedControl(items: ["FRESH", "SETTLED", "OLD", "SPRING"], selected: input.age.rawValue, compact: true)
    private lazy var textureControl = SkSegmentedControl(items: ["FRESH", "GROOMED", "WET", "ICY"], selected: input.texture.rawValue, compact: true)
    private lazy var disciplineControl = SkSegmentedControl(items: ["ALPINE", "TOURING", "PARK"], selected: input.discipline.rawValue, compact: true)

    init(input: WaxInput? = nil, sourceNote: String? = nil, sourceKicker: String = "LIVE") {
        let value = input ?? WaxInput(snowTempC: -5, airTempC: -4, humidity: 65, texture: .groomed, age: .settled, discipline: .alpine)
        self.input = value
        self.plan = WaxAdvisor.plan(for: value)
        self.sourceNote = sourceNote
        self.sourceKicker = sourceNote == nil ? "MANUAL" : sourceKicker
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        _ = LabHeader.add(to: self, title: "RIDGE LAB  /  WAX MATCH")
        let (_, stack) = LabHeader.addScroll(to: self)

        let kicker = UILabel(text: "TEMPERATURE  ·  AGE  ·  HUMIDITY", font: SkesteFont.demibold(8), color: Palette.amber)
        kicker.tracked(1.8)
        stack.addArrangedSubview(kicker)
        stack.setCustomSpacing(4, after: kicker)

        let title = UILabel(text: "WAX\nMATCH.", font: SkesteFont.display(32), color: Palette.text, lines: 2)
        title.richTracking(-0.8)
        stack.addArrangedSubview(title)
        stack.setCustomSpacing(6, after: title)

        let subtitle = UILabel(text: "A layered wax plan, not a single guess. Dial in the snow, the age of the crystals, and the way you ride — then save the setup for the next storm.", font: SkesteFont.body(12), color: Palette.secondary, lines: 0)
        subtitle.lineSpacing(3)
        stack.addArrangedSubview(subtitle)
        stack.setCustomSpacing(14, after: subtitle)

        let context = LabContextStripView(text: sourceNote ?? "MANUAL SETUP · ADJUST THE SNOW BELOW",
                                         tint: Palette.amber,
                                         kicker: sourceKicker)
        stack.addArrangedSubview(context)
        stack.setCustomSpacing(12, after: context)

        buildInputs(into: stack)
        buildResult(into: stack)
        buildFooter(into: stack)

        wireControls()
        applyPlan()
        rebuildSavedChips()
    }

    private func buildInputs(into stack: UIStackView) {
        let card = LabCard()
        stack.addArrangedSubview(card)
        stack.setCustomSpacing(12, after: card)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 0
        card.addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        content.addArrangedSubview(snowSlider)
        content.setCustomSpacing(10, after: snowSlider)
        content.addArrangedSubview(airSlider)
        content.setCustomSpacing(10, after: airSlider)
        content.addArrangedSubview(humiditySlider)
        content.setCustomSpacing(14, after: humiditySlider)

        content.addArrangedSubview(sectionLabel("SNOW AGE"))
        content.setCustomSpacing(6, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(ageControl)
        content.setCustomSpacing(12, after: ageControl)

        content.addArrangedSubview(sectionLabel("SURFACE"))
        content.setCustomSpacing(6, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(textureControl)
        content.setCustomSpacing(12, after: textureControl)

        content.addArrangedSubview(sectionLabel("DISCIPLINE"))
        content.setCustomSpacing(6, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(disciplineControl)
    }

    private func buildResult(into stack: UIStackView) {
        stack.addArrangedSubview(resultCard)
        stack.setCustomSpacing(16, after: resultCard)
        resultCard.applyGlass(cornerRadius: 18, borderAlpha: 0.12, fill: Palette.glass)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 0
        resultCard.addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let kickerRow = UIStackView()
        kickerRow.axis = .horizontal
        kickerRow.alignment = .center
        kickerRow.spacing = 8
        let resultKicker = UILabel(text: "YOUR MATCH", font: SkesteFont.demibold(8), color: Palette.lime)
        resultKicker.tracked(1.6)
        kickerRow.addArrangedSubview(resultKicker)
        confidenceLabel.textAlignment = .right
        kickerRow.addArrangedSubview(confidenceLabel)
        content.addArrangedSubview(kickerRow)
        content.setCustomSpacing(12, after: kickerRow)

        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .top
        header.spacing = 14

        swatch.layer.cornerRadius = 31
        swatch.layer.cornerCurve = .continuous
        swatch.layer.addSublayer(swatchGradient)
        swatch.snp.makeConstraints { $0.width.height.equalTo(62) }
        header.addArrangedSubview(swatch)
        swatchGradient.startPoint = CGPoint(x: 0, y: 0)
        swatchGradient.endPoint = CGPoint(x: 1, y: 1)
        swatchGradient.cornerRadius = 31

        let titles = UIStackView()
        titles.axis = .vertical
        titles.spacing = 0
        waxNameLabel.richTracking(-0.3)
        titles.addArrangedSubview(waxNameLabel)
        waxSubtitleLabel.tracked(1.1)
        titles.addArrangedSubview(waxSubtitleLabel)
        header.addArrangedSubview(titles)
        content.addArrangedSubview(header)
        content.setCustomSpacing(12, after: header)

        let ironCard = UIView()
        ironCard.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        ironCard.layer.cornerRadius = 12
        ironCard.layer.cornerCurve = .continuous
        let ironStack = UIStackView()
        ironStack.axis = .horizontal
        ironStack.alignment = .center
        ironStack.spacing = 10
        ironCard.addSubview(ironStack)
        ironStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)) }
        let ironBlock = UIStackView()
        ironBlock.axis = .vertical
        ironBlock.spacing = -4
        ironBlock.addArrangedSubview(ironValue)
        ironCaption.tracked(1.1)
        ironBlock.addArrangedSubview(ironCaption)
        ironStack.addArrangedSubview(ironBlock)
        let spacer = UIView()
        ironStack.addArrangedSubview(spacer)
        cureValue.textAlignment = .right
        ironStack.addArrangedSubview(cureValue)
        content.addArrangedSubview(ironCard)
        content.setCustomSpacing(14, after: ironCard)

        content.addArrangedSubview(divider())
        content.setCustomSpacing(12, after: content.arrangedSubviews.last!)

        let rows = UIStackView(arrangedSubviews: [baseRow, topRow, edgeRow, structureRow, brushRow])
        rows.axis = .vertical
        rows.spacing = 9
        content.addArrangedSubview(rows)
        content.setCustomSpacing(14, after: rows)

        content.addArrangedSubview(divider())
        content.setCustomSpacing(12, after: content.arrangedSubviews.last!)

        let application = sectionLabel("APPLICATION")
        content.addArrangedSubview(application)
        content.setCustomSpacing(8, after: application)
        content.addArrangedSubview(stepList)
        content.setCustomSpacing(14, after: stepList)

        content.addArrangedSubview(divider())
        content.setCustomSpacing(12, after: content.arrangedSubviews.last!)

        let why = sectionLabel("WHY THIS")
        content.addArrangedSubview(why)
        content.setCustomSpacing(5, after: why)
        whyLabel.lineSpacing(3)
        content.addArrangedSubview(whyLabel)
        content.setCustomSpacing(12, after: whyLabel)

        let alternative = sectionLabel("IF THE SNOW TURNS")
        content.addArrangedSubview(alternative)
        content.setCustomSpacing(5, after: alternative)
        alternativeLabel.lineSpacing(3)
        content.addArrangedSubview(alternativeLabel)
        content.setCustomSpacing(14, after: alternativeLabel)

        let save = GhostButton(title: "SAVE THIS SETUP", icon: "bookmark.fill", height: 44, tint: Palette.lime, borderColor: Palette.lime.withAlphaComponent(0.28))
        save.addAction(UIAction { [weak self] _ in self?.saveSetup() }, for: .touchUpInside)
        content.addArrangedSubview(save)
        content.setCustomSpacing(14, after: save)

        savedTitle.tracked(1.2)
        content.addArrangedSubview(savedTitle)
        content.setCustomSpacing(7, after: savedTitle)

        savedScroll.showsHorizontalScrollIndicator = false
        savedScroll.contentInsetAdjustmentBehavior = .never
        savedRow.axis = .horizontal
        savedRow.spacing = 7
        savedScroll.addSubview(savedRow)
        savedRow.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(savedScroll.snp.height)
        }
        savedScroll.snp.makeConstraints { $0.height.equalTo(34) }
        content.addArrangedSubview(savedScroll)
    }

    private func buildFooter(into stack: UIStackView) {
        let note = UILabel(text: "A clean base holds wax longer. Brush after every temperature change, and let the wax cure before you race. Snow age and texture are estimated; adjust above if conditions differ.", font: SkesteFont.body(10), color: Palette.muted, lines: 0)
        note.textAlignment = .center
        note.lineSpacing(2)
        stack.addArrangedSubview(note)
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let label = UILabel(text: text, font: SkesteFont.demibold(8), color: Palette.muted)
        label.tracked(1.3)
        return label
    }

    private func divider() -> UIView {
        let view = UIView()
        view.backgroundColor = Palette.hairline
        view.snp.makeConstraints { $0.height.equalTo(1) }
        return view
    }

    private func wireControls() {
        snowSlider.onChange = { [weak self] value in
            self?.input.snowTempC = value
            self?.updateRecommendation()
        }
        airSlider.onChange = { [weak self] value in
            self?.input.airTempC = value
            self?.updateRecommendation()
        }
        humiditySlider.onChange = { [weak self] value in
            self?.input.humidity = value
            self?.updateRecommendation()
        }
        ageControl.onChange = { [weak self] index in
            self?.input.age = SnowAge(rawValue: index) ?? .settled
            self?.updateRecommendation()
        }
        textureControl.onChange = { [weak self] index in
            self?.input.texture = SnowTexture(rawValue: index) ?? .groomed
            self?.updateRecommendation()
        }
        disciplineControl.onChange = { [weak self] index in
            self?.input.discipline = SkiDiscipline(rawValue: index) ?? .alpine
            self?.updateRecommendation()
        }
    }

    private func updateRecommendation() {
        plan = WaxAdvisor.plan(for: input)
        applyPlan()
        UIView.animate(withDuration: 0.16) {
            self.swatch.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        } completion: { _ in
            UIView.animate(withDuration: 0.22) {
                self.swatch.transform = .identity
            }
        }
    }

    private func applyPlan() {
        waxNameLabel.text = plan.family
        waxSubtitleLabel.text = plan.subtitle
        confidenceLabel.text = plan.confidence
        confidenceLabel.textColor = plan.confidenceColor
        ironValue.text = "\(plan.ironTemp)°C"
        cureValue.text = "CURE \(plan.cure.uppercased())"
        swatchGradient.colors = plan.colors.map { UIColor(hex: $0).cgColor }
        baseRow.setValue(plan.base)
        topRow.setValue(plan.top)
        edgeRow.setValue(plan.edge)
        structureRow.setValue(plan.structure)
        brushRow.setValue(plan.brush)
        stepList.setSteps(plan.steps, tint: Palette.cyan)
        whyLabel.text = plan.why
        alternativeLabel.text = plan.alternative
    }

    private func applyInputToControls() {
        snowSlider.setValue(input.snowTempC, notify: false)
        airSlider.setValue(input.airTempC, notify: false)
        humiditySlider.setValue(input.humidity, notify: false)
        ageControl.select(input.age.rawValue, notify: false)
        textureControl.select(input.texture.rawValue, notify: false)
        disciplineControl.select(input.discipline.rawValue, notify: false)
        updateRecommendation()
    }

    private func saveSetup() {
        let setup = SavedWaxSetup(id: UUID().uuidString,
                                  createdAt: Date(),
                                  snowTempC: input.snowTempC,
                                  airTempC: input.airTempC,
                                  humidity: input.humidity,
                                  textureIndex: input.texture.rawValue,
                                  ageIndex: input.age.rawValue,
                                  disciplineIndex: input.discipline.rawValue,
                                  family: plan.family,
                                  label: "\(plan.family.capitalized) · \(Int(input.snowTempC.rounded()))°C")
        LabPrefs.shared.saveWax(setup)
        rebuildSavedChips()
        SkesteHaptics.success()
        showToast("Wax setup saved to your kit.", style: .success)
    }

    private func rebuildSavedChips() {
        savedRow.arrangedSubviews.forEach {
            savedRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let setups = LabPrefs.shared.savedWax
        savedTitle.isHidden = setups.isEmpty
        savedScroll.isHidden = setups.isEmpty
        for setup in setups {
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = setup.label
            configuration.image = UIImage(systemName: "bookmark.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold))
            configuration.imagePadding = 5
            configuration.baseForegroundColor = Palette.text
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = SkesteFont.demibold(9)
                return outgoing
            }
            button.configuration = configuration
            button.backgroundColor = Palette.glass
            button.layer.cornerRadius = 12
            button.layer.cornerCurve = .continuous
            button.layer.borderWidth = 1
            button.layer.borderColor = Palette.hairline.cgColor
            button.addAction(UIAction { [weak self] _ in
                self?.load(setup)
            }, for: .touchUpInside)
            button.snp.makeConstraints { $0.height.equalTo(34) }
            savedRow.addArrangedSubview(button)
        }
    }

    private func load(_ setup: SavedWaxSetup) {
        input.snowTempC = setup.snowTempC
        input.airTempC = setup.airTempC
        input.humidity = setup.humidity
        input.texture = SnowTexture(rawValue: setup.textureIndex) ?? .groomed
        input.age = SnowAge(rawValue: setup.ageIndex) ?? .settled
        input.discipline = SkiDiscipline(rawValue: setup.disciplineIndex) ?? .alpine
        applyInputToControls()
        SkesteHaptics.light()
        showToast("Loaded \(setup.label).", style: .info)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        swatchGradient.frame = swatch.bounds
        swatchGradient.cornerRadius = 31
    }
}
