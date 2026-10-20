import UIKit
import SnapKit
import CoreMotion

final class BubbleLevelView: UIView {
    private let ball = UIView()
    private let crosshair = UIView()
    private var offset = CGPoint.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        layer.borderWidth = 1
        layer.borderColor = Palette.hairline.cgColor
        layer.cornerRadius = 38

        crosshair.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        crosshair.layer.cornerRadius = 3
        addSubview(crosshair)
        crosshair.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(6)
        }

        ball.backgroundColor = Palette.ice
        ball.layer.cornerRadius = 7
        ball.layer.borderWidth = 2
        ball.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        ball.applyGlow(color: Palette.cyan, radius: 7, opacity: 0.7)
        addSubview(ball)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setOffset(_ value: CGPoint) {
        offset = value
        setNeedsLayout()
    }

    func reset() {
        offset = .zero
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        let radius = min(bounds.width, bounds.height) / 2
        let maximum = max(0, radius - 12)
        let x = bounds.midX + min(max(offset.x, -1), 1) * maximum
        let y = bounds.midY + min(max(offset.y, -1), 1) * maximum
        ball.frame = CGRect(x: x - 7, y: y - 7, width: 14, height: 14)
    }
}

final class TerrainCheckRow: UIControl {
    private let circle = UIView()
    private let tick = UIImageView()
    private let label = UILabel(text: nil, font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
    var checked = false {
        didSet { updateVisual() }
    }

    init(text: String) {
        super.init(frame: .zero)
        circle.layer.cornerRadius = 9
        circle.layer.borderWidth = 1
        circle.layer.borderColor = Palette.hairline.cgColor
        addSubview(circle)
        circle.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }

        tick.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .bold))
        tick.tintColor = UIColor(hex: "0A0A0B")
        tick.contentMode = .center
        circle.addSubview(tick)
        tick.snp.makeConstraints { $0.center.equalToSuperview() }

        label.text = text
        label.lineSpacing(2)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(circle.snp.trailing).offset(10)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview().offset(-2)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(30) }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = text
        updateVisual()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateVisual() {
        circle.backgroundColor = checked ? Palette.lime : .clear
        circle.layer.borderColor = checked ? Palette.lime.cgColor : Palette.hairline.cgColor
        tick.isHidden = !checked
        label.textColor = checked ? Palette.secondary : Palette.text
        accessibilityValue = checked ? "Checked" : "Unchecked"
    }
}

final class TerrainCheckViewController: BaseViewController {
    private var input: TerrainInput
    private var assessment: TerrainAssessment
    private let sourceNote: String?
    private var checks = Array(repeating: false, count: 5)

    private let motionManager = CMMotionManager()
    private let bubble = BubbleLevelView()
    private let liveAngleLabel = UILabel(text: "--°", font: SkesteFont.display(34), color: Palette.text)
    private let sensorStatus = UILabel(text: "SENSOR READY", font: SkesteFont.demibold(7), color: Palette.lime)
    private let measureButton = GhostButton(title: "MEASURE", icon: "level", height: 42, tint: Palette.cyan, borderColor: Palette.cyan.withAlphaComponent(0.25))
    private let lockButton = GhostButton(title: "LOCK ANGLE", icon: "checkmark", height: 42, tint: Palette.lime, borderColor: Palette.lime.withAlphaComponent(0.25))
    private var recentAngles: [Double] = []
    private var isMeasuring = false

    private let ring = LabRingGaugeView()
    private let levelLabel = UILabel(text: nil, font: SkesteFont.display(30), color: Palette.amber)
    private let headlineLabel = UILabel(text: nil, font: SkesteFont.demibold(11), color: Palette.text, lines: 0)
    private let descriptionLabel = UILabel(text: nil, font: SkesteFont.body(10), color: Palette.secondary, lines: 0)
    private let decisionChip = UIView()
    private let decisionLabel = UILabel(text: nil, font: SkesteFont.demibold(9), color: Palette.amber)
    private let decisionDetail = UILabel(text: nil, font: SkesteFont.body(9), color: Palette.secondary, lines: 0)
    private let breakdown = LabBreakdownView()
    private let slopeProfile = SlopeProfileView()
    private let compass = AspectCompassView()
    private let adviceLabel = UILabel(text: nil, font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
    private let checksProgress = UILabel(text: "0/5", font: SkesteFont.mono(9, weight: .bold), color: Palette.muted)
    private let checksStack = UIStackView()
    private var checkRows: [TerrainCheckRow] = []

    private lazy var slopeSlider = LabSlider(title: "Slope angle", value: input.slope, range: 0...55, formatter: { "\(Int($0.rounded()))°" }, tint: Palette.amber)
    private lazy var snowSlider = LabSlider(title: "New snow / 24h", value: input.newSnow, range: 0...60, formatter: { "\(Int($0.rounded())) cm" }, tint: Palette.ice)
    private lazy var problemControl = SkSegmentedControl(items: AvalancheProblem.allCases.map(\.label), selected: input.problem.rawValue, compact: true)
    private lazy var aspectControl = SkSegmentedControl(items: ["N", "E", "S", "W"], selected: input.aspectIndex, compact: true)
    private lazy var windControl = SkSegmentedControl(items: ["NONE", "MODERATE", "HIGH"], selected: input.windIndex, compact: true)
    private let warmingSwitch = UISwitch()

    init(input: TerrainInput? = nil, sourceNote: String? = nil) {
        let value = input ?? TerrainInput()
        self.input = value
        self.assessment = TerrainAdvisor.assess(value)
        self.sourceNote = sourceNote
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        _ = LabHeader.add(to: self, title: "RIDGE LAB  /  TERRAIN CHECK")
        let (_, stack) = LabHeader.addScroll(to: self)

        let kicker = UILabel(text: "SLOPE  ·  SNOW  ·  WIND  ·  THE HUMAN", font: SkesteFont.demibold(8), color: Palette.magenta)
        kicker.tracked(1.8)
        stack.addArrangedSubview(kicker)
        stack.setCustomSpacing(4, after: kicker)

        let title = UILabel(text: "READ THE\nTERRAIN.", font: SkesteFont.display(32), color: Palette.text, lines: 2)
        title.richTracking(-0.8)
        stack.addArrangedSubview(title)
        stack.setCustomSpacing(6, after: title)

        let subtitle = UILabel(text: "A field decision aid for slope angle, aspect, wind loading, new snow, and the avalanche problem of the day. It does not replace an avalanche forecast or training.", font: SkesteFont.body(12), color: Palette.secondary, lines: 0)
        subtitle.lineSpacing(3)
        stack.addArrangedSubview(subtitle)
        stack.setCustomSpacing(14, after: subtitle)

        let context = LabContextStripView(text: sourceNote ?? "MANUAL ASSESSMENT · SET THE TERRAIN BELOW",
                                         tint: Palette.magenta,
                                         kicker: sourceNote == nil ? "MANUAL" : "REFERENCE")
        stack.addArrangedSubview(context)
        stack.setCustomSpacing(12, after: context)

        buildInputs(into: stack)
        buildInclinometer(into: stack)
        buildResult(into: stack)
        buildFooter(into: stack)

        wireControls()
        update(animated: false)
        updateSensorAvailability()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopMeasuring()
    }

    deinit {
        motionManager.stopDeviceMotionUpdates()
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

        content.addArrangedSubview(slopeSlider)
        content.setCustomSpacing(10, after: slopeSlider)
        content.addArrangedSubview(snowSlider)
        content.setCustomSpacing(14, after: snowSlider)

        content.addArrangedSubview(sectionLabel("AVALANCHE PROBLEM"))
        content.setCustomSpacing(6, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(problemControl)
        content.setCustomSpacing(12, after: problemControl)

        content.addArrangedSubview(sectionLabel("ASPECT"))
        content.setCustomSpacing(6, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(aspectControl)
        content.setCustomSpacing(12, after: aspectControl)

        content.addArrangedSubview(sectionLabel("WIND LOADING"))
        content.setCustomSpacing(6, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(windControl)
        content.setCustomSpacing(14, after: windControl)

        let warmingRow = UIStackView()
        warmingRow.axis = .horizontal
        warmingRow.alignment = .center
        warmingRow.spacing = 10
        let warmingLabel = UILabel(text: "RECENT WARMING", font: SkesteFont.demibold(8), color: Palette.muted)
        warmingLabel.tracked(1.3)
        warmingRow.addArrangedSubview(warmingLabel)
        warmingSwitch.onTintColor = Palette.amber
        warmingSwitch.thumbTintColor = .white
        warmingRow.addArrangedSubview(warmingSwitch)
        content.addArrangedSubview(warmingRow)
        content.setCustomSpacing(12, after: warmingRow)

        let regionRow = UIStackView()
        regionRow.axis = .horizontal
        regionRow.alignment = .center
        regionRow.spacing = 8
        let regionLabel = UILabel(text: "REGIONAL LEVEL", font: SkesteFont.demibold(8), color: Palette.muted)
        regionLabel.tracked(1.3)
        regionRow.addArrangedSubview(regionLabel)
        let regionValue = UILabel(text: "L\(input.regionalLevel)", font: SkesteFont.mono(10, weight: .bold), color: Palette.secondary)
        regionRow.addArrangedSubview(regionValue)
        let meter = LabLevelMeterView()
        meter.setLevel(input.regionalLevel)
        meter.snp.makeConstraints { $0.width.equalTo(84) }
        regionRow.addArrangedSubview(meter)
        content.addArrangedSubview(regionRow)
    }

    private func buildInclinometer(into stack: UIStackView) {
        let card = LabCard()
        stack.addArrangedSubview(card)
        stack.setCustomSpacing(12, after: card)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 0
        card.addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let top = UIStackView()
        top.axis = .horizontal
        top.alignment = .center
        top.spacing = 8
        let kicker = UILabel(text: "INCLINOMETER", font: SkesteFont.demibold(8), color: Palette.cyan)
        kicker.tracked(1.4)
        top.addArrangedSubview(kicker)
        let spacer = UIView()
        top.addArrangedSubview(spacer)
        sensorStatus.tracked(1.0)
        top.addArrangedSubview(sensorStatus)
        content.addArrangedSubview(top)
        content.setCustomSpacing(10, after: top)

        let body = UIStackView()
        body.axis = .horizontal
        body.alignment = .center
        body.spacing = 14
        bubble.snp.makeConstraints { $0.width.height.equalTo(76) }
        body.addArrangedSubview(bubble)
        let reading = UIStackView()
        reading.axis = .vertical
        reading.spacing = 0
        reading.addArrangedSubview(liveAngleLabel)
        let readingCaption = UILabel(text: "LIVE SLOPE ANGLE", font: SkesteFont.demibold(7), color: Palette.muted)
        readingCaption.tracked(1.1)
        reading.addArrangedSubview(readingCaption)
        body.addArrangedSubview(reading)
        content.addArrangedSubview(body)
        content.setCustomSpacing(10, after: body)

        let note = UILabel(text: "Lay the phone flat on the snow, screen up, pointing downhill. Keep still until the angle settles.", font: SkesteFont.body(9), color: Palette.muted, lines: 0)
        note.lineSpacing(2)
        content.addArrangedSubview(note)
        content.setCustomSpacing(10, after: note)

        let buttons = UIStackView()
        buttons.axis = .horizontal
        buttons.spacing = 8
        buttons.distribution = .fillEqually
        measureButton.addAction(UIAction { [weak self] _ in self?.toggleMeasuring() }, for: .touchUpInside)
        lockButton.addAction(UIAction { [weak self] _ in self?.lockAngle() }, for: .touchUpInside)
        lockButton.isEnabled = false
        lockButton.alpha = 0.45
        buttons.addArrangedSubview(measureButton)
        buttons.addArrangedSubview(lockButton)
        content.addArrangedSubview(buttons)
    }

    private func buildResult(into stack: UIStackView) {
        let result = LabCard()
        stack.addArrangedSubview(result)
        stack.setCustomSpacing(14, after: result)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 0
        result.addSubview(content)
        content.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let kickerRow = UIStackView()
        kickerRow.axis = .horizontal
        kickerRow.alignment = .center
        kickerRow.spacing = 8
        let resultKicker = UILabel(text: "FIELD RISK", font: SkesteFont.demibold(8), color: Palette.magenta)
        resultKicker.tracked(1.6)
        kickerRow.addArrangedSubview(resultKicker)
        let region = UILabel(text: "REGION L\(input.regionalLevel) · REFERENCE", font: SkesteFont.demibold(7), color: Palette.muted)
        region.tracked(1.0)
        region.textAlignment = .right
        kickerRow.addArrangedSubview(region)
        content.addArrangedSubview(kickerRow)
        content.setCustomSpacing(8, after: kickerRow)

        let top = UIStackView()
        top.axis = .horizontal
        top.alignment = .center
        top.spacing = 12
        ring.snp.makeConstraints { $0.width.equalTo(128) }
        top.addArrangedSubview(ring)
        let info = UIStackView()
        info.axis = .vertical
        info.spacing = 0
        levelLabel.richTracking(-0.4)
        info.addArrangedSubview(levelLabel)
        headlineLabel.lineSpacing(2)
        info.addArrangedSubview(headlineLabel)
        info.setCustomSpacing(4, after: headlineLabel)
        descriptionLabel.lineSpacing(2)
        info.addArrangedSubview(descriptionLabel)
        top.addArrangedSubview(info)
        content.addArrangedSubview(top)
        content.setCustomSpacing(12, after: top)

        decisionChip.backgroundColor = Palette.amber.withAlphaComponent(0.12)
        decisionChip.layer.cornerRadius = 11
        decisionChip.layer.cornerCurve = .continuous
        decisionChip.layer.borderWidth = 1
        decisionChip.layer.borderColor = Palette.amber.withAlphaComponent(0.35).cgColor
        let chipContent = UIStackView()
        chipContent.axis = .vertical
        chipContent.spacing = 1
        decisionChip.addSubview(chipContent)
        chipContent.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)) }
        decisionLabel.tracked(1.2)
        chipContent.addArrangedSubview(decisionLabel)
        decisionDetail.lineSpacing(2)
        chipContent.addArrangedSubview(decisionDetail)
        content.addArrangedSubview(decisionChip)
        content.setCustomSpacing(14, after: decisionChip)

        content.addArrangedSubview(divider())
        content.setCustomSpacing(10, after: content.arrangedSubviews.last!)

        content.addArrangedSubview(sectionLabel("CONTRIBUTIONS"))
        content.setCustomSpacing(8, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(breakdown)
        content.setCustomSpacing(14, after: breakdown)

        content.addArrangedSubview(sectionLabel("SLOPE + ASPECT"))
        content.setCustomSpacing(8, after: content.arrangedSubviews.last!)
        let visuals = UIStackView()
        visuals.axis = .horizontal
        visuals.spacing = 8
        visuals.distribution = .fillEqually
        visuals.addArrangedSubview(visualCard(title: "SLOPE PROFILE", view: slopeProfile))
        visuals.addArrangedSubview(visualCard(title: "ASPECT", view: compass))
        content.addArrangedSubview(visuals)
        content.setCustomSpacing(14, after: visuals)

        content.addArrangedSubview(divider())
        content.setCustomSpacing(10, after: content.arrangedSubviews.last!)
        content.addArrangedSubview(sectionLabel("WHAT TO WATCH"))
        content.setCustomSpacing(7, after: content.arrangedSubviews.last!)
        adviceLabel.lineSpacing(3)
        content.addArrangedSubview(adviceLabel)
        content.setCustomSpacing(14, after: adviceLabel)

        content.addArrangedSubview(divider())
        content.setCustomSpacing(10, after: content.arrangedSubviews.last!)

        let checklistHeader = UIStackView()
        checklistHeader.axis = .horizontal
        checklistHeader.alignment = .center
        checklistHeader.spacing = 8
        checklistHeader.addArrangedSubview(sectionLabel("FIELD CHECKLIST"))
        checksProgress.textAlignment = .right
        checklistHeader.addArrangedSubview(checksProgress)
        content.addArrangedSubview(checklistHeader)
        content.setCustomSpacing(8, after: checklistHeader)

        checksStack.axis = .vertical
        checksStack.spacing = 7
        content.addArrangedSubview(checksStack)

        let checkTexts = [
            "Everyone has a transceiver, probe, and shovel.",
            "We checked today's forecast and the regional danger.",
            "We have an escape route and a plan B.",
            "We will ride one at a time in exposed terrain.",
            "The slope matches our ability and the group's."
        ]
        for (index, text) in checkTexts.enumerated() {
            let row = TerrainCheckRow(text: text)
            row.addAction(UIAction { [weak self] _ in self?.toggleCheck(index) }, for: .touchUpInside)
            checksStack.addArrangedSubview(row)
            checkRows.append(row)
        }
    }

    private func visualCard(title: String, view: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous
        card.clipsToBounds = true

        let label = UILabel(text: title, font: SkesteFont.demibold(7), color: Palette.muted)
        label.tracked(1.0)
        card.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(10)
        }
        card.addSubview(view)
        view.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(6)
            make.top.equalTo(label.snp.bottom).offset(4)
            make.height.equalTo(122)
            make.bottom.equalToSuperview().offset(-4)
        }
        return card
    }

    private func buildFooter(into stack: UIStackView) {
        let disclaimer = UILabel(text: "This terrain score is a decision aid, not an avalanche forecast. The danger level shown is a reference value, not a live bulletin. Carry rescue equipment, dig a pit, and make decisions with trained partners.", font: SkesteFont.body(10), color: Palette.muted, lines: 0)
        disclaimer.textAlignment = .center
        disclaimer.lineSpacing(2)
        stack.addArrangedSubview(disclaimer)
    }

    private func wireControls() {
        slopeSlider.onChange = { [weak self] value in
            self?.input.slope = value
            self?.update(animated: true)
        }
        snowSlider.onChange = { [weak self] value in
            self?.input.newSnow = value
            self?.update(animated: true)
        }
        problemControl.onChange = { [weak self] index in
            self?.input.problem = AvalancheProblem(rawValue: index) ?? .none
            self?.update(animated: true)
        }
        aspectControl.onChange = { [weak self] index in
            self?.input.aspectIndex = index
            self?.update(animated: true)
        }
        windControl.onChange = { [weak self] index in
            self?.input.windIndex = index
            self?.update(animated: true)
        }
        warmingSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.input.warming = self.warmingSwitch.isOn
            self.update(animated: true)
        }, for: .valueChanged)
        warmingSwitch.isOn = input.warming
    }

    private func update(animated: Bool) {
        assessment = TerrainAdvisor.assess(input)
        levelLabel.text = assessment.level
        levelLabel.textColor = assessment.color
        headlineLabel.text = assessment.headline
        descriptionLabel.text = assessment.description
        ring.setProgress(CGFloat(assessment.score) / 100, color: assessment.color, score: assessment.score, caption: "FIELD RISK", animated: animated)
        breakdown.setItems(assessment.breakdown)
        slopeProfile.setSlope(input.slope, color: assessment.color)
        compass.setAspect(input.aspectIndex, color: assessment.color)
        let tips = [assessment.problemNote] + assessment.advice
        adviceLabel.text = "•  " + tips.joined(separator: "\n\n•  ")
        updateDecision()
    }

    private func toggleCheck(_ index: Int) {
        guard index < checks.count else { return }
        checks[index].toggle()
        checkRows[index].checked = checks[index]
        SkesteHaptics.light()
        updateDecision()
    }

    private func updateDecision() {
        let checked = checks.filter { $0 }.count
        checksProgress.text = "\(checked)/5"
        let decision = TerrainAdvisor.decision(score: assessment.score, checks: checked)
        decisionLabel.text = decision.label
        decisionLabel.textColor = decision.color
        decisionDetail.text = decision.detail
        decisionChip.backgroundColor = decision.color.withAlphaComponent(0.12)
        decisionChip.layer.borderColor = decision.color.withAlphaComponent(0.35).cgColor
    }

    private func updateSensorAvailability() {
        if motionManager.isDeviceMotionAvailable {
            sensorStatus.text = "SENSOR READY"
            sensorStatus.textColor = Palette.lime
            measureButton.isEnabled = true
        } else {
            sensorStatus.text = "SENSOR UNAVAILABLE"
            sensorStatus.textColor = Palette.amber
            measureButton.isEnabled = false
            measureButton.alpha = 0.45
            lockButton.isEnabled = false
            lockButton.alpha = 0.45
            liveAngleLabel.text = "--°"
        }
    }

    private func toggleMeasuring() {
        if isMeasuring {
            stopMeasuring()
            return
        }
        guard motionManager.isDeviceMotionAvailable else {
            showToast("Motion sensor unavailable here. Adjust the angle manually.", style: .error)
            return
        }
        isMeasuring = true
        recentAngles.removeAll()
        measureButton.title = "STOP MEASURING"
        sensorStatus.text = "MEASURING"
        sensorStatus.textColor = Palette.cyan
        lockButton.isEnabled = false
        lockButton.alpha = 0.45
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let gravity = motion.gravity
            let angle = acos(min(1, abs(gravity.z))) * 180 / .pi
            self.liveAngleLabel.text = "\(Int(angle.rounded()))°"
            self.bubble.setOffset(CGPoint(x: CGFloat(gravity.x), y: CGFloat(-gravity.y)))
            self.recentAngles.append(angle)
            if self.recentAngles.count > 8 {
                self.recentAngles.removeFirst()
            }
            let stable = self.isStable()
            self.lockButton.isEnabled = stable
            self.lockButton.alpha = stable ? 1 : 0.45
            self.sensorStatus.text = stable ? "STABLE · LOCK IT" : "MEASURING"
            self.sensorStatus.textColor = stable ? Palette.lime : Palette.cyan
        }
        SkesteHaptics.medium()
    }

    private func stopMeasuring() {
        guard isMeasuring else { return }
        isMeasuring = false
        motionManager.stopDeviceMotionUpdates()
        measureButton.title = "MEASURE"
        liveAngleLabel.text = "--°"
        bubble.reset()
        recentAngles.removeAll()
        sensorStatus.text = motionManager.isDeviceMotionAvailable ? "SENSOR READY" : "SENSOR UNAVAILABLE"
        sensorStatus.textColor = motionManager.isDeviceMotionAvailable ? Palette.lime : Palette.amber
        lockButton.isEnabled = false
        lockButton.alpha = 0.45
    }

    private func isStable() -> Bool {
        guard recentAngles.count >= 6, let minimum = recentAngles.min(), let maximum = recentAngles.max() else { return false }
        return maximum - minimum < 1.5
    }

    private func lockAngle() {
        guard !recentAngles.isEmpty, let minimum = recentAngles.min(), let maximum = recentAngles.max(), maximum - minimum < 1.5 else {
            showToast("Hold still until the reading settles.", style: .error)
            return
        }
        let average = recentAngles.reduce(0, +) / Double(recentAngles.count)
        let locked = min(max(average, 0), 55)
        input.slope = locked
        slopeSlider.setValue(locked, notify: false)
        stopMeasuring()
        update(animated: true)
        SkesteHaptics.success()
        showToast("Slope locked at \(Int(locked.rounded()))°.", style: .success)
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
