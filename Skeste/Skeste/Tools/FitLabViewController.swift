import UIKit
import SnapKit

final class SkiProfileView: UIView {
    private let gradient = CAGradientLayer()
    private let binding = UIView()
    private let tip = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        let ski = UIView()
        ski.backgroundColor = .clear
        ski.layer.cornerRadius = 12
        ski.layer.cornerCurve = .continuous
        ski.clipsToBounds = true
        ski.transform = CGAffineTransform(rotationAngle: -0.18)
        addSubview(ski)
        ski.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(26)
            make.height.equalTo(198)
        }
        gradient.colors = [Palette.cyan.cgColor, Palette.violet.cgColor, Palette.magenta.cgColor]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        ski.layer.addSublayer(gradient)
        DispatchQueue.main.async {
            self.gradient.frame = ski.bounds
            self.gradient.cornerRadius = 12
        }
        binding.backgroundColor = UIColor(hex: "0A0A0B")
        binding.layer.cornerRadius = 5
        ski.addSubview(binding)
        binding.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(5)
            make.width.equalTo(38)
            make.height.equalTo(36)
        }
        tip.backgroundColor = Palette.lime
        tip.layer.cornerRadius = 3
        ski.addSubview(tip)
        tip.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(9)
            make.width.equalTo(12)
            make.height.equalTo(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FitLabViewController: BaseViewController {
    private var input: FitInput
    private var result: FitResult
    private let sourceNote: String?

    private let lengthLabel = UILabel(text: nil, font: SkesteFont.display(66), color: Palette.text)
    private let rangeBar = LabRangeBarView()
    private let waistRow = LabInfoRow(title: "WAIST", value: "")
    private let radiusRow = LabInfoRow(title: "TURN RADIUS", value: "")
    private let flexRow = LabInfoRow(title: "BOOT FLEX", value: "")
    private let profileRow = LabInfoRow(title: "PROFILE", value: "")
    private let dinValue = UILabel(text: nil, font: SkesteFont.display(36), color: Palette.lime)
    private let dinRange = UILabel(text: nil, font: SkesteFont.demibold(10), color: Palette.secondary)
    private let soleNote = UILabel(text: nil, font: SkesteFont.medium(9), color: Palette.muted)
    private let explanation = UILabel(text: nil, font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
    private let quiverStack = UIStackView()
    private let savedTitle = UILabel(text: "SAVED QUIVERS", font: SkesteFont.demibold(8), color: Palette.muted)
    private let savedScroll = UIScrollView()
    private let savedRow = UIStackView()
    private let styleLabel = UILabel(text: nil, font: SkesteFont.demibold(8), color: Palette.cyan)

    private lazy var heightSlider = LabSlider(title: "Your height", value: input.heightCM, range: 140...210, formatter: { "\(Int($0.rounded())) cm" }, tint: Palette.cyan)
    private lazy var weightSlider = LabSlider(title: "Your weight", value: input.weightKG, range: 40...120, formatter: { "\(Int($0.rounded())) kg" }, tint: Palette.ice)
    private lazy var soleSlider = LabSlider(title: "Boot sole length", value: input.soleMM, range: 250...360, formatter: { "\(Int($0.rounded())) mm" }, tint: Palette.violet)
    private lazy var styleControl = SkSegmentedControl(items: FitAdvisor.styleNames, selected: input.styleIndex, compact: true)
    private lazy var abilityControl = SkSegmentedControl(items: FitAdvisor.abilityNames, selected: input.abilityIndex, compact: true)

    init(input: FitInput? = nil, sourceNote: String? = nil) {
        let value = input ?? FitLabViewController.storedInput() ?? FitInput()
        self.input = value
        self.result = FitAdvisor.fit(value)
        self.sourceNote = sourceNote
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func storedInput() -> FitInput? {
        guard let stored = LabPrefs.shared.lastFit else { return nil }
        return FitInput(heightCM: stored.heightCM,
                        weightKG: stored.weightKG,
                        soleMM: stored.soleMM,
                        styleIndex: stored.styleIndex,
                        abilityIndex: stored.abilityIndex)
    }

    override func setupView() {
        _ = LabHeader.add(to: self, title: "RIDGE LAB  /  FIT LAB")
        let (_, stack) = LabHeader.addScroll(to: self)

        let kicker = UILabel(text: "HEIGHT  ·  WEIGHT  ·  BOOT  ·  TERRAIN", font: SkesteFont.demibold(8), color: Palette.lime)
        kicker.tracked(1.8)
        stack.addArrangedSubview(kicker)
        stack.setCustomSpacing(4, after: kicker)

        let title = UILabel(text: "FIT\nLAB.", font: SkesteFont.display(32), color: Palette.text, lines: 2)
        title.richTracking(-0.8)
        stack.addArrangedSubview(title)
        stack.setCustomSpacing(6, after: title)

        let subtitle = UILabel(text: "A first-pass ski and binding setup. Start with your body, your boot, and the way you ride, then take the numbers to a certified tech.", font: SkesteFont.body(12), color: Palette.secondary, lines: 0)
        subtitle.lineSpacing(3)
        stack.addArrangedSubview(subtitle)
        stack.setCustomSpacing(14, after: subtitle)

        let context = LabContextStripView(text: sourceNote ?? (LabPrefs.shared.lastFit == nil ? "MANUAL FIT · NO SAVED QUIVER YET" : "LOADED FROM YOUR LAST SAVED QUIVER"),
                                         tint: Palette.lime,
                                         kicker: LabPrefs.shared.lastFit == nil ? "MANUAL" : "SAVED")
        stack.addArrangedSubview(context)
        stack.setCustomSpacing(12, after: context)

        buildInputs(into: stack)
        buildResult(into: stack)
        buildFooter(into: stack)

        wireControls()
        applyResult()
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

        content.addArrangedSubview(heightSlider)
        content.setCustomSpacing(10, after: heightSlider)
        content.addArrangedSubview(weightSlider)
        content.setCustomSpacing(10, after: weightSlider)
        content.addArrangedSubview(soleSlider)
        content.setCustomSpacing(14, after: soleSlider)

        content.addArrangedSubview(sectionLabel("WHERE YOU RIDE"))
        content.setCustomSpacing(6, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(styleControl)
        content.setCustomSpacing(12, after: styleControl)

        content.addArrangedSubview(sectionLabel("YOUR LEVEL"))
        content.setCustomSpacing(6, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(abilityControl)
    }

    private func buildResult(into stack: UIStackView) {
        let card = LabCard()
        stack.addArrangedSubview(card)
        stack.setCustomSpacing(14, after: card)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 0
        card.addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let kickerRow = UIStackView()
        kickerRow.axis = .horizontal
        kickerRow.alignment = .center
        kickerRow.spacing = 8
        let kicker = UILabel(text: "YOUR STARTING POINT", font: SkesteFont.demibold(8), color: Palette.lime)
        kicker.tracked(1.6)
        kickerRow.addArrangedSubview(kicker)
        styleLabel.textAlignment = .right
        kickerRow.addArrangedSubview(styleLabel)
        content.addArrangedSubview(kickerRow)
        content.setCustomSpacing(8, after: kickerRow)

        let top = UIStackView()
        top.axis = .horizontal
        top.alignment = .top
        top.spacing = 8
        let left = UIStackView()
        left.axis = .vertical
        left.spacing = 0
        let lengthRow = UIStackView()
        lengthRow.axis = .horizontal
        lengthRow.alignment = .lastBaseline
        lengthRow.spacing = 4
        lengthLabel.richTracking(-2)
        lengthRow.addArrangedSubview(lengthLabel)
        let cm = UILabel(text: "CM", font: SkesteFont.demibold(9), color: Palette.cyan)
        cm.tracked(1.2)
        lengthRow.addArrangedSubview(cm)
        left.addArrangedSubview(lengthRow)
        let recommended = UILabel(text: "RECOMMENDED LENGTH", font: SkesteFont.demibold(7), color: Palette.muted)
        recommended.tracked(1.0)
        left.addArrangedSubview(recommended)
        left.setCustomSpacing(8, after: recommended)
        left.addArrangedSubview(rangeBar)
        rangeBar.snp.makeConstraints { $0.height.equalTo(48) }
        top.addArrangedSubview(left)

        let ski = SkiProfileView()
        ski.snp.makeConstraints { make in
            make.width.equalTo(140)
            make.height.equalTo(210)
        }
        top.addArrangedSubview(ski)
        content.addArrangedSubview(top)
        content.setCustomSpacing(12, after: top)

        let rows = UIStackView(arrangedSubviews: [waistRow, radiusRow, flexRow, profileRow])
        rows.axis = .vertical
        rows.spacing = 9
        content.addArrangedSubview(rows)
        content.setCustomSpacing(14, after: rows)

        content.addArrangedSubview(divider())
        content.setCustomSpacing(10, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(sectionLabel("BINDING SETUP"))
        content.setCustomSpacing(7, after: content.arrangedSubviews.last!)

        let bindingCard = UIView()
        bindingCard.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        bindingCard.layer.cornerRadius = 12
        bindingCard.layer.cornerCurve = .continuous
        let bindingContent = UIStackView()
        bindingContent.axis = .vertical
        bindingContent.spacing = 0
        bindingCard.addSubview(bindingContent)
        bindingContent.snp.makeConstraints { $0.edges.equalToSuperview().inset(12) }
        let bindingTop = UIStackView()
        bindingTop.axis = .horizontal
        bindingTop.alignment = .lastBaseline
        bindingTop.spacing = 8
        bindingTop.addArrangedSubview(dinValue)
        dinRange.textAlignment = .right
        bindingTop.addArrangedSubview(dinRange)
        bindingContent.addArrangedSubview(bindingTop)
        let dinCaption = UILabel(text: "RELEASE VALUE · TYPE \(["I", "II", "III"][min(max(input.abilityIndex, 0), 2)])", font: SkesteFont.demibold(7), color: Palette.muted)
        dinCaption.tracked(1.0)
        bindingContent.addArrangedSubview(dinCaption)
        bindingContent.setCustomSpacing(5, after: dinCaption)
        soleNote.lineSpacing(2)
        bindingContent.addArrangedSubview(soleNote)
        bindingContent.setCustomSpacing(7, after: soleNote)
        let bindingNote = UILabel(text: "Starting point only. A certified technician must verify release settings against the current ISO standard and your boot.", font: SkesteFont.body(8), color: Palette.muted, lines: 0)
        bindingNote.lineSpacing(2)
        bindingContent.addArrangedSubview(bindingNote)
        content.addArrangedSubview(bindingCard)
        content.setCustomSpacing(14, after: bindingCard)

        content.addArrangedSubview(divider())
        content.setCustomSpacing(10, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(sectionLabel("YOUR QUIVER"))
        content.setCustomSpacing(8, after: content.arrangedSubviews.last!)
        quiverStack.axis = .vertical
        quiverStack.spacing = 6
        content.addArrangedSubview(quiverStack)
        content.setCustomSpacing(14, after: quiverStack)

        content.addArrangedSubview(sectionLabel("WHY THIS"))
        content.setCustomSpacing(6, after: content.arrangedSubviews.last!)
        explanation.lineSpacing(3)
        content.addArrangedSubview(explanation)
        content.setCustomSpacing(14, after: explanation)

        let save = GhostButton(title: "SAVE TO QUIVER", icon: "bookmark.fill", height: 44, tint: Palette.lime, borderColor: Palette.lime.withAlphaComponent(0.28))
        save.addAction(UIAction { [weak self] _ in self?.saveQuiver() }, for: .touchUpInside)
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
        let note = UILabel(text: "Length is personal. Mounting point, rocker, snow, and the way you actually ski matter more than any one number.", font: SkesteFont.body(10), color: Palette.muted, lines: 0)
        note.textAlignment = .center
        note.lineSpacing(2)
        stack.addArrangedSubview(note)
    }

    private func wireControls() {
        heightSlider.onChange = { [weak self] value in
            self?.input.heightCM = value
            self?.updateResult()
        }
        weightSlider.onChange = { [weak self] value in
            self?.input.weightKG = value
            self?.updateResult()
        }
        soleSlider.onChange = { [weak self] value in
            self?.input.soleMM = value
            self?.updateResult()
        }
        styleControl.onChange = { [weak self] index in
            self?.input.styleIndex = index
            self?.updateResult()
        }
        abilityControl.onChange = { [weak self] index in
            self?.input.abilityIndex = index
            self?.updateResult()
        }
    }

    private func updateResult() {
        result = FitAdvisor.fit(input)
        applyResult()
    }

    private func applyResult() {
        lengthLabel.text = "\(result.lengthCM)"
        styleLabel.text = "\(result.styleName) · \(result.abilityName)"
        styleLabel.textColor = Palette.cyan
        waistRow.setValue("\(result.waistMM) mm")
        radiusRow.setValue(String(format: "%.1f m", result.radiusM))
        flexRow.setValue("\(result.flex)")
        profileRow.setValue(result.profile)
        dinValue.text = formatDIN(result.din)
        dinRange.text = "RANGE \(formatDIN(result.dinRange.lowerBound))–\(formatDIN(result.dinRange.upperBound))"
        soleNote.text = "SOLE \(Int(input.soleMM.rounded())) MM · \(result.soleNote.uppercased())"
        explanation.text = result.explanation
        rangeBar.setRange(lower: 140,
                          upper: 195,
                          recommended: Double(result.lengthRange.lowerBound)...Double(result.lengthRange.upperBound),
                          current: Double(result.lengthCM),
                          color: Palette.lime)
        rebuildQuiver()
    }

    private func rebuildQuiver() {
        quiverStack.arrangedSubviews.forEach {
            quiverStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for (index, pick) in result.picks.enumerated() {
            let row = UIView()
            row.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            row.layer.cornerRadius = 11
            row.layer.cornerCurve = .continuous

            let rank = UILabel(text: String(format: "%02d", index + 1), font: SkesteFont.mono(9, weight: .bold), color: index == 0 ? Palette.lime : Palette.muted)
            row.addSubview(rank)
            rank.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(10)
                make.centerY.equalToSuperview()
            }

            let name = UILabel(text: pick.name, font: SkesteFont.demibold(11), color: Palette.text)
            row.addSubview(name)
            name.snp.makeConstraints { make in
                make.leading.equalTo(rank.snp.trailing).offset(9)
                make.top.equalToSuperview().offset(8)
            }

            let dims = UILabel(text: "\(pick.lengthCM) CM · \(pick.waistMM) MM · \(String(format: "%.1f", pick.radiusM)) M · \(pick.profile)", font: SkesteFont.mono(7.5, weight: .medium), color: Palette.secondary)
            dims.lineBreakMode = .byTruncatingTail
            row.addSubview(dims)
            dims.snp.makeConstraints { make in
                make.leading.equalTo(name)
                make.trailing.equalToSuperview().offset(-72)
                make.top.equalTo(name.snp.bottom).offset(1)
                make.bottom.equalToSuperview().offset(-8)
            }

            let match = UILabel(text: "\(pick.match)%", font: SkesteFont.display(16), color: index == 0 ? Palette.lime : Palette.secondary)
            match.textAlignment = .right
            row.addSubview(match)
            match.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-10)
                make.centerY.equalToSuperview()
                make.width.equalTo(52)
            }
            quiverStack.addArrangedSubview(row)
        }
    }

    private func saveQuiver() {
        let setup = SavedQuiver(id: UUID().uuidString,
                                createdAt: Date(),
                                heightCM: input.heightCM,
                                weightKG: input.weightKG,
                                soleMM: input.soleMM,
                                styleIndex: input.styleIndex,
                                abilityIndex: input.abilityIndex,
                                lengthCM: result.lengthCM,
                                waistMM: result.waistMM,
                                din: result.din,
                                label: "\(result.lengthCM) cm · \(result.styleName)")
        LabPrefs.shared.saveQuiver(setup)
        rebuildSavedChips()
        SkesteHaptics.success()
        showToast("Quiver saved to your kit.", style: .success)
    }

    private func rebuildSavedChips() {
        savedRow.arrangedSubviews.forEach {
            savedRow.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let setups = LabPrefs.shared.savedQuivers
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
            button.addAction(UIAction { [weak self] _ in self?.load(setup) }, for: .touchUpInside)
            button.snp.makeConstraints { $0.height.equalTo(34) }
            savedRow.addArrangedSubview(button)
        }
    }

    private func load(_ setup: SavedQuiver) {
        input.heightCM = setup.heightCM
        input.weightKG = setup.weightKG
        input.soleMM = setup.soleMM
        input.styleIndex = setup.styleIndex
        input.abilityIndex = setup.abilityIndex
        heightSlider.setValue(input.heightCM, notify: false)
        weightSlider.setValue(input.weightKG, notify: false)
        soleSlider.setValue(input.soleMM, notify: false)
        styleControl.select(input.styleIndex, notify: false)
        abilityControl.select(input.abilityIndex, notify: false)
        updateResult()
        SkesteHaptics.light()
        showToast("Loaded \(setup.label).", style: .info)
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
}
