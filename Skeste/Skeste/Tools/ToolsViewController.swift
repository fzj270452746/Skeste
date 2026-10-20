import UIKit
import SnapKit

final class TopoLinesView: UIView {
    var lineColor: UIColor = UIColor.white.withAlphaComponent(0.07) {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(lineColor.cgColor)
        context.setLineWidth(1)
        for index in 0..<7 {
            let y = rect.height * (0.18 + CGFloat(index) * 0.11)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -10, y: y))
            path.addCurve(to: CGPoint(x: rect.width + 10, y: y + CGFloat(index % 3 - 1) * 14),
                          controlPoint1: CGPoint(x: rect.width * 0.28, y: y - 30 + CGFloat(index) * 5),
                          controlPoint2: CGPoint(x: rect.width * 0.68, y: y + 34 - CGFloat(index) * 4))
            context.addPath(path.cgPath)
            context.strokePath()
        }
    }
}

/// Glossy abstract shapes, echoing the 3D community art in the reference.
final class ToolArtView: UIView {
    private let blob = UIView()
    private let blobGradient = CAGradientLayer()
    private let sheen = CAGradientLayer()
    private let sphere = UIView()
    private let sphereGradient = CAGradientLayer()
    private let star = CAShapeLayer()
    private let rotation: CGFloat

    private struct Config {
        let blob: [UIColor]
        let accent: [UIColor]
        let rotation: CGFloat
    }

    init(variant: Int) {
        let config = Self.config(for: variant)
        rotation = config.rotation
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        blobGradient.colors = config.blob.map(\.cgColor)
        blobGradient.startPoint = CGPoint(x: 0.1, y: 0)
        blobGradient.endPoint = CGPoint(x: 0.9, y: 1)
        blob.layer.addSublayer(blobGradient)
        blob.layer.cornerRadius = 30
        blob.layer.cornerCurve = .continuous
        blob.clipsToBounds = true
        addSubview(blob)

        sheen.colors = [
            UIColor.white.withAlphaComponent(0.6).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor
        ]
        sheen.startPoint = CGPoint(x: 0.2, y: 0)
        sheen.endPoint = CGPoint(x: 0.8, y: 1)
        blob.layer.addSublayer(sheen)

        sphereGradient.colors = config.accent.map(\.cgColor)
        sphereGradient.startPoint = CGPoint(x: 0, y: 0)
        sphereGradient.endPoint = CGPoint(x: 1, y: 1)
        sphere.layer.addSublayer(sphereGradient)
        sphere.layer.cornerRadius = 16
        sphere.layer.cornerCurve = .continuous
        sphere.clipsToBounds = true
        addSubview(sphere)

        star.fillColor = UIColor.white.withAlphaComponent(0.92).cgColor
        star.shadowColor = UIColor.black.cgColor
        star.shadowOpacity = 0.18
        star.shadowRadius = 6
        star.shadowOffset = .zero
        layer.addSublayer(star)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func config(for variant: Int) -> Config {
        switch variant % 4 {
        case 0:
            return Config(blob: [UIColor(hex: "4B7BFF"), UIColor(hex: "A855F7")], accent: [UIColor(hex: "FF8AD9"), UIColor(hex: "FF3FD8")], rotation: -0.34)
        case 1:
            return Config(blob: [UIColor(hex: "FF4FD8"), UIColor(hex: "7B5BF5")], accent: [UIColor(hex: "A8E9FF"), UIColor(hex: "4CD7F6")], rotation: 0.4)
        case 2:
            return Config(blob: [UIColor(hex: "FFD447"), UIColor(hex: "FF7A6B")], accent: [UIColor(hex: "4CD7F6"), UIColor(hex: "7B5BF5")], rotation: -0.5)
        default:
            return Config(blob: [UIColor(hex: "4CD7F6"), UIColor(hex: "7B5BF5")], accent: [UIColor(hex: "FF8AD9"), UIColor(hex: "FF3FD8")], rotation: 0.26)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        blob.bounds = CGRect(x: 0, y: 0, width: 68, height: 68)
        blob.center = CGPoint(x: bounds.width * 0.48, y: bounds.height * 0.58)
        blob.transform = CGAffineTransform(rotationAngle: rotation)
        blobGradient.frame = blob.bounds
        sheen.frame = blob.bounds
        sphere.frame = CGRect(x: bounds.width * 0.62, y: bounds.height * 0.12, width: 32, height: 32)
        sphereGradient.frame = sphere.bounds
        sphere.layer.cornerRadius = 16

        let starRect = CGRect(x: bounds.width * 0.1, y: bounds.height * 0.08, width: 36, height: 36)
        star.path = Self.starPath(in: starRect).cgPath
        star.frame = bounds
        CATransaction.commit()
    }

    private static func starPath(in rect: CGRect) -> UIBezierPath {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: center.y), controlPoint: CGPoint(x: center.x + 5, y: center.y - 5))
        path.addQuadCurve(to: CGPoint(x: center.x, y: rect.maxY), controlPoint: CGPoint(x: center.x + 5, y: center.y + 5))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: center.y), controlPoint: CGPoint(x: center.x - 5, y: center.y + 5))
        path.addQuadCurve(to: CGPoint(x: center.x, y: rect.minY), controlPoint: CGPoint(x: center.x - 5, y: center.y - 5))
        path.close()
        return path
    }
}

final class ToolGradientTile: UIControl {
    private let gradient = CAGradientLayer()
    private let kickerLabel = UILabel(text: nil, font: SkesteFont.demibold(8), color: UIColor(hex: "0A0A0B").withAlphaComponent(0.58))
    private let titleLabel = UILabel(text: nil, font: SkesteFont.display(22), color: UIColor(hex: "0A0A0B"), lines: 2)
    private let detailLabel = UILabel(text: nil, font: SkesteFont.medium(11), color: UIColor(hex: "0A0A0B").withAlphaComponent(0.66), lines: 2)
    private let art: ToolArtView
    private let arrow = UIImageView()

    init(kicker: String, title: String, detail: String, symbol: String, colors: [UIColor], variant: Int) {
        art = ToolArtView(variant: variant)
        super.init(frame: .zero)
        gradient.colors = colors.map(\.cgColor)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        clipsToBounds = true

        addSubview(art)
        art.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-6)
            make.top.equalToSuperview().offset(86)
            make.width.height.equalTo(88)
        }

        kickerLabel.text = kicker.uppercased()
        kickerLabel.tracked(1.4)
        addSubview(kickerLabel)
        kickerLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
        }
        titleLabel.text = title
        titleLabel.richTracking(-0.4)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(kickerLabel.snp.bottom).offset(2)
        }
        detailLabel.text = detail
        addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-15)
        }
        arrow.image = UIImage(systemName: "arrow.up.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))
        arrow.tintColor = UIColor(hex: "0A0A0B").withAlphaComponent(0.6)
        addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(17)
            make.width.height.equalTo(14)
        }
        snp.makeConstraints { $0.height.equalTo(198) }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title
        applyForeground(colors: colors)
        _ = symbol
    }

    private func applyForeground(colors: [UIColor]) {
        let isLightTile = colors.first?.prefersDarkForeground ?? false
        let foreground = isLightTile ? UIColor(hex: "0A0A1A") : UIColor.white
        kickerLabel.textColor = foreground.withAlphaComponent(0.58)
        titleLabel.textColor = foreground
        titleLabel.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        titleLabel.layer.shadowOpacity = 1
        titleLabel.layer.shadowRadius = 3
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 1)
        detailLabel.textColor = foreground.withAlphaComponent(0.7)
        arrow.tintColor = foreground.withAlphaComponent(0.6)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.16) { self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity }
        }
    }
}

final class ToolsViewController: BaseViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var lastSignature = ""
    private let store = SnowReportStore.shared

    override func setupView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-(AppLayout.tabBarClearance + 20))
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }
        rebuild()
        store.refreshIfNeeded(named: currentResortKey())
    }

    override func refreshView() {
        store.refreshIfNeeded(named: currentResortKey())
        if signature() != lastSignature { rebuild() }
    }

    override func authDidChange() {
        rebuild()
        store.refreshIfNeeded(named: currentResortKey())
    }

    override func snowDidChange(resortName: String?) {
        guard isViewLoaded, view.window != nil else { return }
        guard resortName == nil || resortName == currentResortKey() else { return }
        if signature() != lastSignature { rebuild() }
    }

    #if DEBUG
    // Simulator preview hooks: `-openWax`, `-openTerrain`, `-openFit`,
    // `-openSnowDesk`, `-openRunTracker`, and `-openRunLog`.
    private var didRunToolPreview = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didRunToolPreview else { return }
        didRunToolPreview = true
        let arguments = ProcessInfo.processInfo.arguments
        let resort = currentResort()
        if arguments.contains("-openWax") {
            push(WaxLabViewController(input: WaxInput.from(resort: resort),
                                      sourceNote: waxSourceNote(resort),
                                      sourceKicker: resort.reportSource.label))
        } else if arguments.contains("-openTerrain") {
            push(TerrainCheckViewController(input: TerrainInput.from(resort: resort), sourceNote: terrainSourceNote(resort)))
        } else if arguments.contains("-openFit") {
            push(FitLabViewController())
        } else if arguments.contains("-openSnowDesk") {
            push(SnowDeskViewController())
        } else if arguments.contains("-openRunTracker") {
            push(RunTrackerViewController())
        } else if arguments.contains("-openRunLog") {
            push(RunLogViewController())
        }
    }
    #endif

    private func signature() -> String {
        let prefs = LabPrefs.shared
        let resort = currentResort()
        let stamp = resort.reportUpdatedAt?.timeIntervalSince1970 ?? 0
        return "\(AppStore.shared.runs.count)-\(Int(AppStore.shared.totalVertical))-\(AppStore.shared.currentUser?.homeResort ?? "guest")-\(prefs.revision)-\(prefs.savedWax.count)-\(prefs.savedQuivers.count)-\(resort.reportSource.rawValue)-\(stamp)"
    }

    private func rebuild() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let kicker = UILabel(text: "RIDGE LAB  /  TOOLS FOR THE HILL", font: SkesteFont.demibold(8), color: Palette.cyan)
        kicker.tracked(1.8)
        contentStack.addArrangedSubview(kicker)
        contentStack.setCustomSpacing(5, after: kicker)

        let title = UILabel(text: "READ\nTHE HILL.", font: SkesteFont.display(34), color: Palette.text, lines: 2)
        title.richTracking(-0.8)
        contentStack.addArrangedSubview(title)
        contentStack.setCustomSpacing(6, after: title)

        let subtitle = UILabel(text: "Five field instruments for the way you ride. Live snow, wax, terrain, fit, and a season log that remembers every descent.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        subtitle.lineSpacing(3)
        contentStack.addArrangedSubview(subtitle)
        contentStack.setCustomSpacing(20, after: subtitle)

        buildBriefCard()
        buildSeasonCard()
        buildToolGrid()
        buildSafetyNote()
        lastSignature = signature()
    }

    // MARK: - Field brief

    private func buildBriefCard() {
        let resort = currentResort()
        let wax = WaxAdvisor.quickPlan(for: resort)
        let terrainInput = TerrainInput.from(resort: resort)
        let terrain = TerrainAdvisor.assess(terrainInput)
        let window = resort.bestWindow

        let card = UIView()
        card.applyGlass(cornerRadius: 22, borderAlpha: 0.14, fill: Palette.glass)
        let topo = TopoLinesView()
        topo.lineColor = Palette.cyan.withAlphaComponent(0.07)
        card.addSubview(topo)
        topo.snp.makeConstraints { $0.edges.equalToSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .top
        header.spacing = 12
        stack.addArrangedSubview(header)

        let left = UIStackView()
        left.axis = .vertical
        left.spacing = 0
        header.addArrangedSubview(left)

        let sourceText: String
        switch resort.reportSource {
        case .live: sourceText = "LIVE"
        case .cached: sourceText = "CACHED"
        case .sample: sourceText = "SAMPLE DATA"
        }
        let kickerText = "FIELD BRIEF  ·  \(sourceText)" + (resort.reportSource.isWeatherKitData ? "  ·  APPLE WEATHER" : "")
        let kicker = UILabel(text: kickerText, font: SkesteFont.demibold(8), color: resort.reportSource == .sample ? Palette.amber : Palette.lime)
        kicker.tracked(1.6)
        left.addArrangedSubview(kicker)
        left.setCustomSpacing(3, after: kicker)

        let name = UILabel(text: resort.name, font: SkesteFont.display(28), color: Palette.text)
        name.richTracking(-0.5)
        left.addArrangedSubview(name)

        let region = UILabel(text: resort.region, font: SkesteFont.medium(9), color: Palette.muted)
        region.tracked(0.6)
        left.addArrangedSubview(region)
        left.setCustomSpacing(8, after: region)

        let metrics = UIStackView()
        metrics.axis = .horizontal
        metrics.spacing = 14
        metrics.alignment = .top
        let snowLabel = resort.reportSource.isWeatherKitData ? "SNOW TODAY" : "NEW / 24H"
        metrics.addArrangedSubview(metric("\(resort.freshCM) CM", snowLabel, Palette.ice))
        metrics.addArrangedSubview(metric("\(resort.windKPH)", "WIND KM/H", Palette.text))
        metrics.addArrangedSubview(metric("\(resort.visibilityKM) KM", "VISIBILITY", Palette.text))
        left.addArrangedSubview(metrics)

        let right = UIStackView()
        right.axis = .vertical
        right.alignment = .trailing
        right.spacing = 0
        header.addArrangedSubview(right)

        let temp = UILabel(text: "\(resort.tempC)°", font: SkesteFont.display(60), color: Palette.text)
        right.addArrangedSubview(temp)
        let air = UILabel(text: "AIR TEMP", font: SkesteFont.demibold(7), color: Palette.muted)
        air.tracked(1.2)
        right.addArrangedSubview(air)

        let condition = UIStackView()
        condition.axis = .horizontal
        condition.alignment = .center
        condition.spacing = 5
        let conditionIcon = UIImageView(image: UIImage(systemName: resort.conditionSymbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)))
        conditionIcon.tintColor = resort.freshCM >= 20 ? Palette.ice : Palette.amber
        conditionIcon.snp.makeConstraints { $0.width.height.equalTo(14) }
        let conditionLabel = UILabel(text: resort.conditionHeadline, font: SkesteFont.demibold(7), color: resort.freshCM >= 20 ? Palette.ice : Palette.amber)
        conditionLabel.tracked(1.0)
        condition.addArrangedSubview(conditionIcon)
        condition.addArrangedSubview(conditionLabel)
        right.addArrangedSubview(condition)
        right.setCustomSpacing(6, after: condition)

        let level = LabLevelMeterView()
        level.setLevel(resort.avalancheLevel)
        level.snp.makeConstraints { $0.width.equalTo(68) }
        right.addArrangedSubview(level)
        let levelLabel = UILabel(text: "AVALANCHE L\(resort.avalancheLevel) · REF", font: SkesteFont.demibold(7), color: Palette.muted)
        levelLabel.tracked(0.8)
        right.addArrangedSubview(levelLabel)
        right.setCustomSpacing(3, after: level)

        let divider = UIView()
        divider.backgroundColor = Palette.hairline
        stack.addArrangedSubview(divider)
        divider.snp.makeConstraints { $0.height.equalTo(1) }
        stack.setCustomSpacing(14, after: divider)

        let callKicker = UILabel(text: "TODAY'S CALL", font: SkesteFont.demibold(8), color: Palette.magenta)
        callKicker.tracked(1.7)
        stack.addArrangedSubview(callKicker)
        stack.setCustomSpacing(6, after: callKicker)

        let waxNote = waxSourceNote(resort)
        let terrainNote = terrainSourceNote(resort)
        let waxRow = makeCallRow(symbol: "thermometer.snowflake", tint: Palette.amber,
                                 title: "WAX",
                                 value: "\(wax.family.capitalized)  ·  iron \(wax.ironTemp)°C",
                                 detail: wax.subtitle) { [weak self] in
            self?.push(WaxLabViewController(input: WaxInput.from(resort: resort),
                                            sourceNote: waxNote,
                                            sourceKicker: resort.reportSource.label))
        }
        stack.addArrangedSubview(waxRow)
        stack.setCustomSpacing(4, after: waxRow)

        let terrainRow = makeCallRow(symbol: "exclamationmark.triangle.fill", tint: terrain.color,
                                     title: "TERRAIN",
                                     value: "\(terrain.level.capitalized)  ·  \(terrain.score)/100",
                                     detail: terrain.headline) { [weak self] in
            self?.push(TerrainCheckViewController(input: terrainInput, sourceNote: terrainNote))
        }
        stack.addArrangedSubview(terrainRow)
        stack.setCustomSpacing(4, after: terrainRow)

        let windowRow = makeCallRow(symbol: "sun.max.fill", tint: Palette.cyan,
                                    title: "WINDOW",
                                    value: window.label,
                                    detail: window.detail) { [weak self] in
            self?.push(SnowDeskViewController())
        }
        stack.addArrangedSubview(windowRow)
        stack.setCustomSpacing(12, after: windowRow)

        let footer = UIStackView()
        footer.axis = .horizontal
        footer.alignment = .center
        footer.spacing = 10
        stack.addArrangedSubview(footer)

        let share = GhostButton(title: "SHARE BRIEF", icon: "square.and.arrow.up", height: 44, tint: Palette.cyan, borderColor: Palette.cyan.withAlphaComponent(0.28))
        share.addAction(UIAction { [weak self] _ in
            self?.shareBrief(resort: resort, wax: wax, terrain: terrain, window: window)
        }, for: .touchUpInside)
        footer.addArrangedSubview(share)

        let open = SkesteControls.textButton("SNOW DESK →", tint: Palette.lime, size: 9)
        open.addAction(UIAction { [weak self] _ in self?.push(SnowDeskViewController()) }, for: .touchUpInside)
        footer.addArrangedSubview(open)

        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(14, after: card)
    }

    private func metric(_ value: String, _ label: String, _ color: UIColor) -> UIStackView {
        let valueLabel = UILabel(text: value, font: SkesteFont.display(19), color: color)
        let labelLabel = UILabel(text: label, font: SkesteFont.demibold(7), color: Palette.muted)
        labelLabel.tracked(0.9)
        let stack = UIStackView(arrangedSubviews: [valueLabel, labelLabel])
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }

    private func makeCallRow(symbol: String, tint: UIColor, title: String, value: String, detail: String, action: @escaping () -> Void) -> UIControl {
        let row = UIControl()
        row.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        row.layer.cornerRadius = 12
        row.layer.cornerCurve = .continuous

        let iconHost = UIView()
        iconHost.backgroundColor = tint.withAlphaComponent(0.12)
        iconHost.layer.cornerRadius = 10
        row.addSubview(iconHost)
        iconHost.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(9)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
        icon.tintColor = tint
        iconHost.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(16) }

        let titleLabel = UILabel(text: title, font: SkesteFont.demibold(7), color: Palette.muted)
        titleLabel.tracked(1.1)
        row.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconHost.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(8)
        }

        let valueLabel = UILabel(text: value, font: SkesteFont.demibold(14), color: Palette.text)
        row.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(-1)
        }

        let detailLabel = UILabel(text: detail, font: SkesteFont.medium(9), color: Palette.secondary)
        detailLabel.lineBreakMode = .byTruncatingTail
        row.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().offset(-30)
            make.top.equalTo(valueLabel.snp.bottom).offset(0)
            make.bottom.equalToSuperview().offset(-8)
        }

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)))
        chevron.tintColor = Palette.muted
        row.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(10)
        }

        row.addAction(UIAction { _ in
            SkesteHaptics.light()
            action()
        }, for: .touchUpInside)
        row.isAccessibilityElement = true
        row.accessibilityTraits = .button
        row.accessibilityLabel = "\(title), \(value)"
        return row
    }

    private func shareBrief(resort: SnowResort, wax: WaxPlan, terrain: TerrainAssessment, window: SnowWindow) {
        let image = LabShareCard.brief(resort, wax: wax, terrain: terrain, window: window)
        let weather = resort.reportSource.isWeatherKitData
            ? " Weather by Apple Weather. Avalanche level is for reference only."
            : " Avalanche level is for reference only."
        let caption = "Today's call at \(resort.name): \(wax.family.capitalized) wax, \(terrain.level.lowercased()) terrain, best window \(window.label). Logged with Ridge Lab.\(weather)"
        let sheet = SkesteActionSheetViewController(heading: "SHARE THE BRIEF", message: "Send today's call to your circle.", actions: [
            SkesteSheetAction(title: "Share card", symbol: "square.and.arrow.up") { [weak self] in
                guard let self else { return }
                LabShare.present(image: image, text: caption, from: self)
            },
            SkesteSheetAction(title: "Post to field notes", symbol: "paperplane.fill") { [weak self] in
                guard let self else { return }
                LabShare.postToFeed(caption: caption, tags: ["RidgeLab", resort.name, "FieldBrief"], from: self)
            }
        ])
        present(sheet, animated: true)
        SkesteHaptics.light()
    }

    // MARK: - Season

    private func buildSeasonCard() {
        let runs = AppStore.shared.runs
        let card = UIView()
        card.applyGlass(cornerRadius: 20, borderAlpha: 0.08, fill: Palette.glass)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let top = UIStackView()
        top.axis = .horizontal
        top.alignment = .center
        top.spacing = 8
        stack.addArrangedSubview(top)
        stack.setCustomSpacing(10, after: top)

        let kicker = UILabel(text: "SEASON LOG  ·  \(seasonLabel())", font: SkesteFont.demibold(8), color: Palette.lime)
        kicker.tracked(1.4)
        top.addArrangedSubview(kicker)

        let open = SkesteControls.textButton("OPEN LOG →", tint: Palette.secondary, size: 8)
        open.addAction(UIAction { [weak self] _ in self?.push(RunLogViewController()) }, for: .touchUpInside)
        top.addArrangedSubview(open)

        if runs.isEmpty {
            let empty = UILabel(text: "No descents logged yet. Start a tracked run and the mountain starts keeping score.", font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
            empty.lineSpacing(2)
            stack.addArrangedSubview(empty)
            stack.setCustomSpacing(10, after: empty)
            let start = GhostButton(title: "START A RUN", icon: "play.fill", height: 42, tint: Palette.lime, borderColor: Palette.lime.withAlphaComponent(0.25))
            start.addAction(UIAction { [weak self] _ in self?.push(RunTrackerViewController()) }, for: .touchUpInside)
            stack.addArrangedSubview(start)
        } else {
            let body = UIStackView()
            body.axis = .horizontal
            body.alignment = .bottom
            body.spacing = 14
            stack.addArrangedSubview(body)

            let numbers = UIStackView()
            numbers.axis = .vertical
            numbers.spacing = 0
            body.addArrangedSubview(numbers)

            let vertical = UILabel(text: "\(Int(AppStore.shared.totalVertical.rounded())) m", font: SkesteFont.display(36), color: Palette.text)
            vertical.richTracking(-1)
            numbers.addArrangedSubview(vertical)
            let verticalLabel = UILabel(text: "TOTAL VERTICAL", font: SkesteFont.demibold(7), color: Palette.muted)
            verticalLabel.tracked(1.0)
            numbers.addArrangedSubview(verticalLabel)
            let runCountLabel = runs.count == 1 ? "1 RUN" : "\(runs.count) RUNS"
            let meta = UILabel(text: "\(runCountLabel)  ·  \(Int((runs.map(\.topSpeedKPH).max() ?? 0).rounded())) KM/H TOP", font: SkesteFont.mono(8, weight: .medium), color: Palette.secondary)
            numbers.addArrangedSubview(meta)
            numbers.setCustomSpacing(4, after: verticalLabel)

            let spark = LabSparklineView()
            spark.tint = Palette.lime
            spark.setValues(Array(runs.prefix(8)).reversed().map(\.verticalMeters))
            spark.snp.makeConstraints { make in
                make.height.equalTo(52)
                make.width.equalTo(120)
            }
            body.addArrangedSubview(spark)
        }

        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(24, after: card)
    }

    // MARK: - Tools

    private func buildToolGrid() {
        let heading = SectionHeadingView(kicker: "Official instruments", title: "THE KIT", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(12, after: heading)

        let resort = currentResort()
        let wax = WaxAdvisor.quickPlan(for: resort)
        let terrain = TerrainAdvisor.assess(TerrainInput.from(resort: resort))
        let runs = AppStore.shared.runs
        let fit = LabPrefs.shared.lastFit

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 10
        contentStack.addArrangedSubview(grid)

        let waxNote = waxSourceNote(resort)
        let terrainNote = terrainSourceNote(resort)
        let rowOne = UIStackView()
        rowOne.axis = .horizontal
        rowOne.spacing = 10
        rowOne.distribution = .fillEqually
        let runWord = runs.count == 1 ? "run" : "runs"
        let trackerDetail = runs.isEmpty ? "Ready to log" : "\(runs.count) \(runWord) · \(Int(AppStore.shared.totalVertical.rounded())) m"
        let tracker = ToolGradientTile(kicker: "TOOL 01", title: "RUN\nTRACKER", detail: trackerDetail, symbol: "figure.skiing.downhill", colors: [UIColor(hex: "FFD447"), UIColor(hex: "FFB84D")], variant: 0)
        tracker.addAction(UIAction { [weak self] _ in self?.push(RunTrackerViewController()) }, for: .touchUpInside)
        let waxDetail = "\(wax.family.capitalized) · \(Int(resort.derivedSnowTempC.rounded()))°C"
        let waxTile = ToolGradientTile(kicker: "TOOL 02", title: "WAX\nMATCH", detail: waxDetail, symbol: "thermometer.snowflake", colors: [UIColor(hex: "FF8A7A"), UIColor(hex: "FF5A6B")], variant: 1)
        waxTile.addAction(UIAction { [weak self] _ in self?.push(WaxLabViewController(input: WaxInput.from(resort: resort),
                                                                                     sourceNote: waxNote,
                                                                                     sourceKicker: resort.reportSource.label)) }, for: .touchUpInside)
        rowOne.addArrangedSubview(tracker)
        rowOne.addArrangedSubview(waxTile)
        grid.addArrangedSubview(rowOne)

        let rowTwo = UIStackView()
        rowTwo.axis = .horizontal
        rowTwo.spacing = 10
        rowTwo.distribution = .fillEqually
        let terrainDetail = "\(terrain.level.capitalized) · \(terrain.score)/100"
        let terrainTile = ToolGradientTile(kicker: "TOOL 03", title: "TERRAIN\nCHECK", detail: terrainDetail, symbol: "exclamationmark.triangle.fill", colors: [UIColor(hex: "8B6BFF"), UIColor(hex: "5B3FE0")], variant: 2)
        terrainTile.addAction(UIAction { [weak self] _ in self?.push(TerrainCheckViewController(input: TerrainInput.from(resort: resort), sourceNote: terrainNote)) }, for: .touchUpInside)
        let fitDetail = fit.map { "\($0.lengthCM) cm · \(FitAdvisor.styleNames[min(max($0.styleIndex, 0), 3)])" } ?? "Find your ski"
        let fitTile = ToolGradientTile(kicker: "TOOL 04", title: "FIT\nLAB", detail: fitDetail, symbol: "ruler.fill", colors: [UIColor(hex: "4FE0B0"), UIColor(hex: "2FC79A")], variant: 3)
        fitTile.addAction(UIAction { [weak self] _ in self?.push(FitLabViewController()) }, for: .touchUpInside)
        rowTwo.addArrangedSubview(terrainTile)
        rowTwo.addArrangedSubview(fitTile)
        grid.addArrangedSubview(rowTwo)
    }

    private func buildSafetyNote() {
        let note = UIView()
        note.applyGlass(cornerRadius: 14, borderAlpha: 0.08, fill: Palette.glass)
        let icon = UIImageView(image: UIImage(systemName: "checkmark.shield.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)))
        icon.tintColor = Palette.lime
        note.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
            make.width.height.equalTo(18)
        }
        let attribution = currentResort().reportSource.isWeatherKitData ? " Weather data by Apple Weather." : ""
        let text = UILabel(text: "Mountain decisions belong to you and your partners. Carry a transceiver, probe, and shovel. Check the daily forecast. Ride within your ability.\(attribution) Avalanche levels are reference values, not live bulletins.", font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
        text.lineSpacing(3)
        note.addSubview(text)
        text.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(9)
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalToSuperview().offset(13)
            make.bottom.equalToSuperview().offset(-13)
        }
        contentStack.addArrangedSubview(note)
    }

    private func seasonLabel() -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        if month >= 7 {
            return "\(year)/\(String((year + 1) % 100).leftPad2())"
        }
        return "\(year - 1)/\(String(year % 100).leftPad2())"
    }

    private func currentResortKey() -> String {
        if let name = AppStore.shared.currentUser?.homeResort,
           let resort = SnowLibrary.resort(named: name) {
            return resort.name
        }
        return SnowLibrary.resorts[0].name
    }

    private func currentResort() -> SnowResort {
        store.resort(named: currentResortKey())
    }

    private func waxSourceNote(_ resort: SnowResort) -> String {
        let credit = resort.reportSource.isWeatherKitData ? " · Apple Weather" : ""
        return "\(resort.name) · \(resort.tempC)°C air · \(resort.freshCM) cm forecast\(credit)"
    }

    private func terrainSourceNote(_ resort: SnowResort) -> String {
        let credit = resort.reportSource.isWeatherKitData ? " · Apple Weather" : ""
        return "\(resort.name) · L\(resort.avalancheLevel) · \(resort.freshCM) cm forecast\(credit)"
    }
}

private extension String {
    func leftPad2() -> String {
        count >= 2 ? self : String(repeating: "0", count: 2 - count) + self
    }
}
