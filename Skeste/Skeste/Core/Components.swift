import UIKit
import SnapKit
import AVFoundation

enum SkesteHaptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

final class GradientButton: UIControl {
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel(text: nil, font: SkesteFont.demibold(16), color: .white)
    private let iconView = UIImageView()
    private let contentStack = UIStackView()
    private var colors: [UIColor]
    private let heightValue: CGFloat
    private let cornerValue: CGFloat

    var title: String {
        get { titleLabel.text ?? "" }
        set {
            titleLabel.text = newValue
            accessibilityLabel = newValue
        }
    }

    init(title: String, icon: String? = nil, colors: [UIColor] = SkesteGradient.signature, height: CGFloat = 56, cornerRadius: CGFloat? = nil, fontSize: CGFloat = 16) {
        self.colors = colors
        self.heightValue = height
        self.cornerValue = cornerRadius ?? 8
        super.init(frame: .zero)
        clipsToBounds = true
        layer.cornerCurve = .continuous
        layer.addSublayer(gradientLayer)
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        titleLabel.text = title
        titleLabel.font = SkesteFont.demibold(fontSize)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.65

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 9
        contentStack.isUserInteractionEnabled = false
        addSubview(contentStack)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        if let icon {
            iconView.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .bold))
            contentStack.addArrangedSubview(iconView)
            iconView.snp.makeConstraints { $0.width.height.equalTo(20) }
        }
        contentStack.addArrangedSubview(titleLabel)
        contentStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(18)
            make.trailing.lessThanOrEqualToSuperview().offset(-18)
        }
        snp.makeConstraints { $0.height.equalTo(height) }
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        applyForeground()
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerValue
        layer.cornerRadius = cornerValue
    }

    private func applyForeground() {
        let foreground = (colors.first ?? Palette.magenta).prefersDarkForeground ? Palette.ink : Palette.frost
        titleLabel.textColor = foreground
        iconView.tintColor = foreground
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.16, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.alpha = self.isHighlighted ? 0.9 : 1
            }
        }
    }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1 : 0.45 }
    }

    override var isSelected: Bool {
        didSet { alpha = isSelected ? 0.82 : 1 }
    }

    func setColors(_ colors: [UIColor]) {
        self.colors = colors
        gradientLayer.colors = colors.map(\.cgColor)
        applyForeground()
    }
}

final class GhostButton: UIControl {
    private let titleLabel: UILabel
    private let iconView = UIImageView()
    private let stack = UIStackView()
    private let heightValue: CGFloat

    var title: String {
        get { titleLabel.text ?? "" }
        set {
            titleLabel.text = newValue
            accessibilityLabel = newValue
        }
    }

    init(title: String, icon: String? = nil, height: CGFloat = 52, tint: UIColor = Palette.text, fill: UIColor = Palette.glass, borderColor: UIColor = Palette.hairline) {
        titleLabel = UILabel(text: title, font: SkesteFont.demibold(15), color: tint)
        heightValue = height
        super.init(frame: .zero)
        applyGlass(cornerRadius: 8, borderAlpha: 1, fill: fill)
        layer.borderColor = borderColor.cgColor
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = tint
        if let icon {
            iconView.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
            stack.addArrangedSubview(iconView)
            iconView.snp.makeConstraints { $0.width.height.equalTo(18) }
        }
        stack.addArrangedSubview(titleLabel)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        snp.makeConstraints { $0.height.equalTo(height) }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.16) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
                self.backgroundColor = self.isHighlighted ? Palette.glassStrong : Palette.glass
            }
        }
    }
}

final class PillButton: UIControl {
    private let titleLabel: UILabel
    private let iconView = UIImageView()
    private let stack = UIStackView()
    private let selectedColors: [UIColor]
    private let gradientBackground = CAGradientLayer()

    override var isSelected: Bool {
        didSet { updateVisual() }
    }

    var title: String {
        get { titleLabel.text ?? "" }
        set { titleLabel.text = newValue }
    }

    init(title: String, icon: String? = nil, colors: [UIColor] = SkesteGradient.signature) {
        titleLabel = UILabel(text: title, font: SkesteFont.demibold(12), color: Palette.text, lines: 1)
        selectedColors = colors
        super.init(frame: .zero)
        layer.cornerRadius = 6
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.hairline.cgColor
        backgroundColor = Palette.glass
        gradientBackground.colors = colors.map(\.cgColor)
        gradientBackground.startPoint = CGPoint(x: 0, y: 0)
        gradientBackground.endPoint = CGPoint(x: 1, y: 1)
        gradientBackground.cornerRadius = 6
        layer.insertSublayer(gradientBackground, at: 0)

        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Palette.text
        if let icon {
            iconView.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))
            stack.addArrangedSubview(iconView)
            iconView.snp.makeConstraints { $0.width.height.equalTo(14) }
        }
        stack.addArrangedSubview(titleLabel)
        stack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.trailing.equalToSuperview().offset(-13)
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { $0.height.equalTo(36) }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title
        gradientBackground.opacity = 0
        updateVisual()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateVisual() {
        gradientBackground.opacity = isSelected ? 1 : 0
        if isSelected {
            gradientBackground.colors = selectedColors.map(\.cgColor)
            layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
            let foreground = (selectedColors.first ?? Palette.magenta).prefersDarkForeground ? Palette.ink : Palette.frost
            titleLabel.textColor = foreground
            if iconView.image != nil { iconView.tintColor = foreground }
        } else {
            layer.borderColor = Palette.hairline.cgColor
            titleLabel.textColor = Palette.text
            if iconView.image != nil { iconView.tintColor = Palette.text }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientBackground.frame = bounds
        gradientBackground.cornerRadius = 6
    }
}

enum SkesteControls {
    static func iconButton(symbol: String, diameter: CGFloat = 42, tint: UIColor = Palette.text) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = Palette.glass
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = Palette.hairline.cgColor
        button.tintColor = tint
        button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)), for: .normal)
        button.snp.makeConstraints { $0.width.height.equalTo(diameter) }
        return button
    }

    static func textButton(_ title: String, tint: UIColor = Palette.cyan, size: CGFloat = 12) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title.uppercased(), for: .normal)
        button.setTitleColor(tint, for: .normal)
        button.titleLabel?.font = SkesteFont.demibold(size)
        button.titleLabel?.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }

    static func actionIcon(symbol: String, title: String, tint: UIColor = Palette.text) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        configuration.title = title
        configuration.imagePadding = 5
        configuration.baseForegroundColor = tint
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 2, bottom: 6, trailing: 2)
        let button = UIButton(configuration: configuration)
        button.titleLabel?.font = SkesteFont.demibold(12)
        return button
    }
}

final class AvatarView: UIView {
    private let imageView = UIImageView()
    private let initialsLabel = UILabel(text: nil, font: SkesteFont.title(22), color: .white)
    private let fallbackGradient = CAGradientLayer()
    private let ringGradient = CAGradientLayer()
    private let ringMask = CAShapeLayer()
    private let sizeValue: CGFloat
    private let showsRing: Bool
    private let gradientInset: CGFloat = 3

    init(size: CGFloat, showsRing: Bool = true) {
        sizeValue = size
        self.showsRing = showsRing
        super.init(frame: .zero)
        clipsToBounds = false
        backgroundColor = Palette.surface
        layer.cornerRadius = size / 2

        fallbackGradient.colors = SkesteGradient.signature.map(\.cgColor)
        fallbackGradient.startPoint = CGPoint(x: 0, y: 0)
        fallbackGradient.endPoint = CGPoint(x: 1, y: 1)
        fallbackGradient.cornerRadius = size / 2
        layer.addSublayer(fallbackGradient)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = max(0, (size - gradientInset * 2) / 2)
        addSubview(imageView)

        initialsLabel.textAlignment = .center
        initialsLabel.font = SkesteFont.title(size * 0.34)
        addSubview(initialsLabel)

        if showsRing {
            ringGradient.colors = [Palette.magenta, Palette.amber].map(\.cgColor)
            ringGradient.startPoint = CGPoint(x: 0, y: 0)
            ringGradient.endPoint = CGPoint(x: 1, y: 1)
            ringGradient.mask = ringMask
            layer.addSublayer(ringGradient)
        }

        snp.makeConstraints { $0.width.height.equalTo(size) }
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(gradientInset)
        }
        initialsLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        isAccessibilityElement = true
        accessibilityTraits = .image
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fallbackGradient.frame = bounds
        fallbackGradient.cornerRadius = bounds.width / 2
        imageView.layer.cornerRadius = max(0, (bounds.width - gradientInset * 2) / 2)
        if showsRing {
            ringGradient.frame = bounds
            let path = UIBezierPath(ovalIn: bounds.insetBy(dx: 0.9, dy: 0.9))
            ringMask.path = path.cgPath
            ringMask.fillColor = UIColor.clear.cgColor
            ringMask.strokeColor = UIColor.white.cgColor
            ringMask.lineWidth = 1.8
        }
    }

    func configure(user: User?, accent: [UIColor]? = nil) {
        guard let user else {
            imageView.image = nil
            initialsLabel.text = "S"
            setAccent(accent ?? SkesteGradient.signature)
            return
        }
        initialsLabel.text = initials(from: user.displayName)
        imageView.image = AssetResolver.avatar(for: user)
        imageView.isHidden = imageView.image == nil
        initialsLabel.isHidden = imageView.image != nil
        let colors = accent ?? userAccent(for: user)
        fallbackGradient.colors = colors.map(\.cgColor)
        if showsRing {
            ringGradient.colors = [colors.first ?? Palette.magenta, colors.first ?? Palette.magenta].map(\.cgColor)
        }
        accessibilityLabel = user.displayName
    }

    func configure(imageName: String, initials: String = "S", accent: [UIColor]? = nil) {
        imageView.image = AssetResolver.image(named: imageName)
        imageView.isHidden = imageView.image == nil
        initialsLabel.text = initials
        initialsLabel.isHidden = imageView.image != nil
        setAccent(accent ?? SkesteGradient.signature)
    }

    private func setAccent(_ colors: [UIColor]) {
        fallbackGradient.colors = colors.map(\.cgColor)
        if showsRing {
            ringGradient.colors = [colors.first ?? Palette.magenta, colors.first ?? Palette.magenta].map(\.cgColor)
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    private func userAccent(for user: User) -> [UIColor] {
        let palettes: [[UIColor]] = [
            [Palette.magenta, Palette.surface],
            [Palette.indigo, Palette.slate],
            [Palette.cyan, Palette.indigo],
            [Palette.amber, Palette.surface],
            [Palette.violet, Palette.slate]
        ]
        return palettes[Int(StableHash.of(user.id) % UInt64(palettes.count))]
    }
}

class SkesteTagLabel: UILabel {
    var insets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

    convenience init(text: String, tint: UIColor = Palette.secondary, fill: UIColor = Palette.glass) {
        self.init(frame: .zero)
        self.text = text.uppercased()
        font = SkesteFont.demibold(9)
        textColor = tint
        backgroundColor = fill
        layer.cornerRadius = 11
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        clipsToBounds = true
        textAlignment = .center
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}

final class ScreenHeaderView: UIView {
    private let backButton: UIButton
    let titleLabel: UILabel
    let subtitleLabel: UILabel
    let trailingButton: UIButton?
    private let titleStack = UIStackView()

    init(title: String, subtitle: String? = nil, showsBack: Bool = true, trailingSymbol: String? = nil, onBack: (() -> Void)? = nil) {
        backButton = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        titleLabel = UILabel(text: title.uppercased(), font: SkesteFont.demibold(10), color: Palette.secondary)
        subtitleLabel = UILabel(text: subtitle, font: SkesteFont.display(19), color: Palette.text)
        trailingButton = trailingSymbol.map { SkesteControls.iconButton(symbol: $0, diameter: 40) }
        super.init(frame: .zero)

        backButton.isHidden = !showsBack
        addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        titleStack.axis = .vertical
        titleStack.alignment = .center
        titleStack.spacing = 1
        titleStack.addArrangedSubview(titleLabel)
        if let subtitle {
            subtitleLabel.text = subtitle
            titleStack.addArrangedSubview(subtitleLabel)
        } else {
            subtitleLabel.isHidden = true
        }
        addSubview(titleStack)
        titleStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().offset(-48)
        }

        if let trailingButton {
            addSubview(trailingButton)
            trailingButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
            }
        }

        snp.makeConstraints { $0.height.greaterThanOrEqualTo(46) }
        backButton.addAction(UIAction { _ in
            onBack?()
        }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SectionHeadingView: UIView {
    private let kickerLabel: UILabel
    let titleLabel: UILabel
    private let actionButton: UIButton?

    init(kicker: String, title: String, actionTitle: String? = nil, onAction: (() -> Void)? = nil) {
        kickerLabel = UILabel(text: kicker.uppercased(), font: SkesteFont.demibold(8), color: Palette.magenta)
        titleLabel = UILabel(text: title, font: SkesteFont.display(24), color: Palette.text)
        if let actionTitle {
            actionButton = SkesteControls.textButton(actionTitle, tint: Palette.secondary, size: 9)
        } else {
            actionButton = nil
        }
        super.init(frame: .zero)

        kickerLabel.attributedText = NSAttributedString(string: kicker.uppercased(), attributes: [
            .font: SkesteFont.demibold(8),
            .foregroundColor: Palette.magenta,
            .kern: 2.0
        ])
        addSubview(kickerLabel)
        addSubview(titleLabel)

        kickerLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(kickerLabel.snp.bottom).offset(5)
            make.bottom.equalToSuperview()
        }

        if let actionButton, let onAction {
            addSubview(actionButton)
            actionButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
                make.bottom.equalToSuperview().offset(-4)
            }
            actionButton.addAction(UIAction { _ in onAction() }, for: .touchUpInside)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SkSegmentedControl: UIView {
    private let titles: [String]
    private let buttons: [UIButton]
    private let highlight = UIView()
    private let highlightGradient = CAGradientLayer()
    private let stack = UIStackView()
    private(set) var selectedIndex: Int = 0
    var onChange: ((Int) -> Void)?

    init(items: [String], selected: Int = 0, compact: Bool = false) {
        titles = items
        var generated: [UIButton] = []
        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(item, for: .normal)
            button.titleLabel?.font = SkesteFont.demibold(compact ? 11 : 13)
            button.tag = index
            generated.append(button)
        }
        buttons = generated
        selectedIndex = min(max(0, selected), max(0, items.count - 1))
        super.init(frame: .zero)
        applyGlass(cornerRadius: compact ? 8 : 10, borderAlpha: 0.1, fill: Palette.glass)

        highlightGradient.colors = SkesteGradient.signature.map(\.cgColor)
        highlightGradient.startPoint = CGPoint(x: 0, y: 0)
        highlightGradient.endPoint = CGPoint(x: 1, y: 1)
        highlight.layer.insertSublayer(highlightGradient, at: 0)
        highlight.layer.cornerCurve = .continuous
        highlight.isUserInteractionEnabled = false
        addSubview(highlight)

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(3)
        }
        for (index, button) in buttons.enumerated() {
            stack.addArrangedSubview(button)
            button.addAction(UIAction { [weak self] _ in
                self?.select(index, notify: true)
            }, for: .touchUpInside)
        }
        snp.makeConstraints { $0.height.equalTo(compact ? 36 : 46) }
        updateColors()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func select(_ index: Int, notify: Bool) {
        guard index >= 0, index < buttons.count else { return }
        guard index != selectedIndex else { return }
        selectedIndex = index
        updateColors()
        setNeedsLayout()
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            self.layoutIfNeeded()
        }
        if notify { onChange?(index) }
        SkesteHaptics.light()
    }

    private func updateColors() {
        for (index, button) in buttons.enumerated() {
            if index == selectedIndex {
                button.setTitleColor(.white, for: .normal)
            } else {
                button.setTitleColor(Palette.secondary, for: .normal)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !buttons.isEmpty, stack.bounds.width > 0 else { return }
        let inset: CGFloat = 3
        let buttonWidth = (bounds.width - inset * 2) / CGFloat(buttons.count)
        let height = bounds.height - inset * 2
        let frame = CGRect(x: inset + CGFloat(selectedIndex) * buttonWidth, y: inset, width: buttonWidth, height: height)
        highlight.frame = frame
        highlightGradient.frame = highlight.bounds
        highlight.layer.cornerRadius = 6
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 46)
    }
}

enum SkesteToastStyle {
    case info
    case success
    case error

    var symbol: String {
        switch self {
        case .info: return "sparkles"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }

    var tint: UIColor {
        switch self {
        case .info: return Palette.cyan
        case .success: return Palette.lime
        case .error: return Palette.danger
        }
    }
}

final class SkesteToast {
    private static var activeToast: UIView?

    static func show(_ message: String, style: SkesteToastStyle = .info) {
        DispatchQueue.main.async {
            guard let window = activeWindow() else { return }
            activeToast?.removeFromSuperview()

            let container = UIView()
            container.backgroundColor = Palette.ink.withAlphaComponent(0.96)
            container.layer.cornerRadius = 10
            container.layer.cornerCurve = .continuous
            container.layer.borderWidth = 1
            container.layer.borderColor = style.tint.withAlphaComponent(0.32).cgColor
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.45
            container.layer.shadowRadius = 18
            container.layer.shadowOffset = CGSize(width: 0, height: 8)
            container.alpha = 0
            container.transform = CGAffineTransform(translationX: 0, y: 18)

            let icon = UIImageView(image: UIImage(systemName: style.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
            icon.tintColor = style.tint
            icon.contentMode = .scaleAspectFit
            let label = UILabel(text: message, font: SkesteFont.medium(13), color: Palette.frost, lines: 3)
            label.numberOfLines = 3

            let stack = UIStackView(arrangedSubviews: [icon, label])
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 9
            container.addSubview(stack)
            stack.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().offset(-16)
                make.top.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-12)
            }
            icon.snp.makeConstraints { $0.width.height.equalTo(18) }
            window.addSubview(container)
            container.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.leading.greaterThanOrEqualToSuperview().offset(24)
                make.trailing.lessThanOrEqualToSuperview().offset(-24)
                make.bottom.equalTo(window.safeAreaLayoutGuide.snp.bottom).offset(-(AppLayout.tabBarClearance + 8))
            }
            window.layoutIfNeeded()
            activeToast = container

            UIView.animate(withDuration: 0.38, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.6, options: [.curveEaseOut]) {
                container.alpha = 1
                container.transform = .identity
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.35) {
                guard container.superview != nil else { return }
                UIView.animate(withDuration: 0.28, animations: {
                    container.alpha = 0
                    container.transform = CGAffineTransform(translationX: 0, y: 12)
                }, completion: { _ in
                    container.removeFromSuperview()
                    if activeToast === container { activeToast = nil }
                })
            }
        }
    }

    private static func activeWindow() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first(where: { $0.isKeyWindow }) ?? windows.first
    }
}

final class LoadingOrbitView: UIView {
    private let track = CAShapeLayer()
    private let arc = CAShapeLayer()
    private let dashed = CAShapeLayer()
    private let snowflake = UIImageView()
    private let halo = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        halo.type = .radial
        halo.colors = [Palette.cyan.withAlphaComponent(0.16).cgColor, Palette.magenta.withAlphaComponent(0.08).cgColor, UIColor.clear.cgColor]
        halo.locations = [0, 0.55, 1]
        halo.startPoint = CGPoint(x: 0.5, y: 0.5)
        halo.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(halo)

        track.fillColor = UIColor.clear.cgColor
        track.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
        track.lineWidth = 1
        layer.addSublayer(track)

        dashed.fillColor = UIColor.clear.cgColor
        dashed.strokeColor = Palette.magenta.withAlphaComponent(0.5).cgColor
        dashed.lineWidth = 1
        dashed.lineDashPattern = [2, 5]
        layer.addSublayer(dashed)

        arc.fillColor = UIColor.clear.cgColor
        arc.strokeColor = Palette.cyan.cgColor
        arc.lineWidth = 2
        arc.lineCap = .round
        arc.strokeStart = 0
        arc.strokeEnd = 0.55
        arc.shadowColor = Palette.cyan.cgColor
        arc.shadowOpacity = 0.8
        arc.shadowRadius = 7
        arc.shadowOffset = .zero
        layer.addSublayer(arc)

        snowflake.image = UIImage(systemName: "snowflake", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium))
        snowflake.tintColor = Palette.ice
        snowflake.contentMode = .scaleAspectFit
        addSubview(snowflake)
        snowflake.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(34)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        halo.frame = bounds
        halo.cornerRadius = bounds.width / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        for layer in [track, arc, dashed] {
            layer.frame = bounds
        }
        track.path = UIBezierPath(arcCenter: center, radius: min(bounds.width, bounds.height) / 2 - 2, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        arc.path = UIBezierPath(arcCenter: center, radius: min(bounds.width, bounds.height) / 2 - 2, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true).cgPath
        dashed.path = UIBezierPath(arcCenter: center, radius: min(bounds.width, bounds.height) / 2 - 13, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
    }

    func startAnimating() {
        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = CGFloat.pi * 2
        spin.duration = 1.4
        spin.repeatCount = .infinity
        arc.add(spin, forKey: "orbit.arc")
        let reverse = CABasicAnimation(keyPath: "transform.rotation.z")
        reverse.fromValue = 0
        reverse.toValue = -CGFloat.pi * 2
        reverse.duration = 9
        reverse.repeatCount = .infinity
        dashed.add(reverse, forKey: "orbit.dashed")
        snowflake.pulse(scale: 1.08, duration: 0.8)
    }
}

final class SkesteLoadingView: UIView {
    private let messageLabel: UILabel
    private let progress = GradientProgressBar()
    private let orbit = LoadingOrbitView()
    private let card = UIView()
    private var didDismiss = false

    static func present(in window: UIWindow? = nil) -> SkesteLoadingView {
        let target = window ?? activeWindow() ?? UIWindow()
        let view = SkesteLoadingView()
        target.addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview() }
        target.layoutIfNeeded()
        view.appear()
        return view
    }

    override init(frame: CGRect) {
        let messages = [
            "Reading the mountain…",
            "Waxing the edges…",
            "Clipping in…",
            "Tracking the storm…",
            "Finding your line…",
            "Checking the ridge…"
        ]
        messageLabel = UILabel(text: messages.randomElement(), font: SkesteFont.demibold(13), color: Palette.secondary)
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "05030F").withAlphaComponent(0.55)
        alpha = 0

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.layer.cornerRadius = 18
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        addSubview(blur)
        blur.snp.makeConstraints { make in
            make.width.equalTo(250)
            make.height.equalTo(226)
            make.center.equalToSuperview()
        }

        card.backgroundColor = UIColor(hex: "141032").withAlphaComponent(0.88)
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.hairline.cgColor
        addSubview(card)
        card.snp.makeConstraints { $0.edges.equalTo(blur) }

        card.addSubview(orbit)
        orbit.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(25)
            make.width.height.equalTo(92)
        }

        let brand = UILabel(text: "SKESTE", font: SkesteFont.display(22), color: Palette.text)
        brand.textAlignment = .center
        card.addSubview(brand)
        brand.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(orbit.snp.bottom).offset(10)
        }
        messageLabel.textAlignment = .center
        card.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(brand.snp.bottom).offset(1)
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        card.addSubview(progress)
        progress.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(34)
            make.trailing.equalToSuperview().offset(-34)
            make.top.equalTo(messageLabel.snp.bottom).offset(19)
            make.height.equalTo(3)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func appear() {
        UIView.animate(withDuration: 0.22) { self.alpha = 1 }
        orbit.startAnimating()
        layoutIfNeeded()
        DispatchQueue.main.async {
            self.progress.setProgress(1, animated: true)
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        guard !didDismiss else { return }
        didDismiss = true
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }

    private static func activeWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })
    }
}

final class SkesteAlertViewController: UIViewController {
    private let titleText: String
    private let messageText: String
    private let confirmTitle: String
    private let cancelTitle: String?
    private let destructive: Bool
    private let onConfirm: (() -> Void)?
    private let card = UIView()
    private var didChoose = false

    init(title: String, message: String, confirmTitle: String, cancelTitle: String? = "Cancel", destructive: Bool = false, onConfirm: (() -> Void)? = nil) {
        titleText = title
        messageText = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.destructive = destructive
        self.onConfirm = onConfirm
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "05030F").withAlphaComponent(0.62)

        card.backgroundColor = UIColor(hex: "141032").withAlphaComponent(0.98)
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.hairline.cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.5
        card.layer.shadowRadius = 30
        card.layer.shadowOffset = CGSize(width: 0, height: 18)
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
        }

        let accent = UIView()
        accent.backgroundColor = destructive ? Palette.danger : Palette.cyan
        accent.layer.cornerRadius = 1.5
        card.addSubview(accent)
        accent.snp.makeConstraints { make in
            make.width.equalTo(38)
            make.height.equalTo(3)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
        }

        let titleLabel = UILabel(text: titleText, font: SkesteFont.display(24), color: Palette.text, lines: 2)
        titleLabel.textAlignment = .center
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(accent.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }

        let messageLabel = UILabel(text: messageText, font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
        messageLabel.textAlignment = .center
        messageLabel.lineBreakMode = .byWordWrapping
        card.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
        }

        let confirm = GradientButton(
            title: confirmTitle,
            icon: destructive ? "exclamationmark.triangle.fill" : "arrow.right",
            colors: destructive ? [Palette.danger, UIColor(hex: "FF8B5E")] : SkesteGradient.signature,
            height: 52
        )
        confirm.addAction(UIAction { [weak self] _ in
            self?.choose(confirmed: true)
        }, for: .touchUpInside)
        card.addSubview(confirm)
        confirm.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-22)
            make.top.equalTo(messageLabel.snp.bottom).offset(24)
        }

        if let cancelTitle {
            let cancel = GhostButton(title: cancelTitle, height: 48)
            cancel.addAction(UIAction { [weak self] _ in
                self?.choose(confirmed: false)
            }, for: .touchUpInside)
            card.addSubview(cancel)
            cancel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(22)
                make.trailing.equalToSuperview().offset(-22)
                make.top.equalTo(confirm.snp.bottom).offset(10)
                make.bottom.equalToSuperview().offset(-22)
            }
        } else {
            confirm.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-22)
            }
        }

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        dismissTap.cancelsTouchesInView = false
        view.addGestureRecognizer(dismissTap)
    }

    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: view)
        if !card.frame.contains(point) {
            choose(confirmed: false)
        }
    }

    private func choose(confirmed: Bool) {
        guard !didChoose else { return }
        didChoose = true
        dismiss(animated: true) {
            if confirmed {
                self.onConfirm?()
            }
        }
    }
}

struct SkesteSheetAction {
    let title: String
    let symbol: String
    let destructive: Bool
    let handler: () -> Void

    init(title: String, symbol: String, destructive: Bool = false, handler: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.destructive = destructive
        self.handler = handler
    }
}

final class SkesteActionSheetViewController: UIViewController {
    private let heading: String
    private let message: String?
    private let actions: [SkesteSheetAction]
    private let sheet = UIView()
    private var didDismiss = false

    init(heading: String, message: String? = nil, actions: [SkesteSheetAction]) {
        self.heading = heading
        self.message = message
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "05030F").withAlphaComponent(0.55)

        sheet.backgroundColor = UIColor(hex: "141032").withAlphaComponent(0.98)
        sheet.layer.cornerRadius = 18
        sheet.layer.cornerCurve = .continuous
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.layer.borderWidth = 1
        sheet.layer.borderColor = Palette.hairline.cgColor
        view.addSubview(sheet)
        sheet.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }

        let handle = UIView()
        handle.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        handle.layer.cornerRadius = 2
        sheet.addSubview(handle)
        handle.snp.makeConstraints { make in
            make.width.equalTo(38)
            make.height.equalTo(4)
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
        }

        let headingLabel = UILabel(text: heading, font: SkesteFont.display(22), color: Palette.text, lines: 2)
        sheet.addSubview(headingLabel)
        headingLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-22)
            make.top.equalTo(handle.snp.bottom).offset(16)
        }

        var previous: UIView = headingLabel
        if let message {
            let messageLabel = UILabel(text: message, font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
            sheet.addSubview(messageLabel)
            messageLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(22)
                make.trailing.equalToSuperview().offset(-22)
                make.top.equalTo(headingLabel.snp.bottom).offset(4)
            }
            previous = messageLabel
        }

        for action in actions {
            let row = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.title = action.title
            config.image = UIImage(systemName: action.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
            config.imagePadding = 12
            config.baseForegroundColor = action.destructive ? Palette.danger : Palette.text
            config.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 18, bottom: 15, trailing: 18)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = SkesteFont.medium(15)
                return outgoing
            }
            row.configuration = config
            row.contentHorizontalAlignment = .leading
            row.backgroundColor = Palette.glassStrong
            row.layer.cornerRadius = 17
            row.layer.cornerCurve = .continuous
            row.layer.borderWidth = 1
            row.layer.borderColor = Palette.hairline.cgColor
            row.addAction(UIAction { [weak self] _ in
                self?.perform(action)
            }, for: .touchUpInside)
            sheet.addSubview(row)
            row.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(18)
                make.trailing.equalToSuperview().offset(-18)
                make.top.equalTo(previous.snp.bottom).offset(previous === headingLabel ? 18 : 10)
                make.height.equalTo(54)
            }
            previous = row
        }

        let cancel = GhostButton(title: "Close", height: 48)
        cancel.addAction(UIAction { [weak self] _ in
            self?.dismissSheet()
        }, for: .touchUpInside)
        sheet.addSubview(cancel)
        cancel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
            make.top.equalTo(previous.snp.bottom).offset(12)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-12)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        if !sheet.frame.contains(gesture.location(in: view)) {
            dismissSheet()
        }
    }

    private func perform(_ action: SkesteSheetAction) {
        guard !didDismiss else { return }
        didDismiss = true
        dismiss(animated: true) {
            action.handler()
        }
    }

    private func dismissSheet() {
        guard !didDismiss else { return }
        didDismiss = true
        dismiss(animated: true)
    }
}

final class SkesteTextField: UIView {
    private let titleLabel: UILabel
    private let container = UIView()
    private let iconView = UIImageView()
    let textField = UITextField()
    private let revealButton = UIButton(type: .system)
    private var isSecure: Bool
    private let border = CAGradientLayer()
    private let borderMask = CAShapeLayer()

    var text: String { textField.text ?? "" }

    init(title: String, placeholder: String, icon: String, secure: Bool = false, keyboard: UIKeyboardType = .default) {
        titleLabel = UILabel(text: title.uppercased(), font: SkesteFont.demibold(9), color: Palette.muted)
        isSecure = secure
        super.init(frame: .zero)
        titleLabel.attributedText = NSAttributedString(string: title.uppercased(), attributes: [.font: SkesteFont.demibold(9), .foregroundColor: Palette.muted, .kern: 1.6])
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(2)
            make.top.equalToSuperview()
        }

        container.backgroundColor = Palette.glassStrong
        container.layer.cornerRadius = 10
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = Palette.hairline.cgColor
        addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.height.equalTo(52)
        }

        iconView.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium))
        iconView.tintColor = Palette.secondary
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        textField.font = SkesteFont.medium(15)
        textField.textColor = Palette.text
        textField.tintColor = Palette.magenta
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: Palette.muted, .font: SkesteFont.medium(15)])
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = keyboard
        textField.isSecureTextEntry = secure
        textField.returnKeyType = .done
        container.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(44)
            if secure {
                make.trailing.equalToSuperview().offset(-48)
            } else {
                make.trailing.equalToSuperview().offset(-16)
            }
        }

        if secure {
            revealButton.tintColor = Palette.secondary
            revealButton.setImage(UIImage(systemName: "eye", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)), for: .normal)
            revealButton.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.isSecure.toggle()
                self.textField.isSecureTextEntry = self.isSecure
                let symbol = self.isSecure ? "eye" : "eye.slash"
                self.revealButton.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)), for: .normal)
            }, for: .touchUpInside)
            container.addSubview(revealButton)
            revealButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-12)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(36)
            }
        }

        textField.addTarget(self, action: #selector(editingBegan), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingEnded), for: .editingDidEnd)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func editingBegan() {
        container.layer.borderColor = Palette.magenta.withAlphaComponent(0.7).cgColor
    }

    @objc private func editingEnded() {
        container.layer.borderColor = Palette.hairline.cgColor
    }
}

final class SkesteTextView: UIView {
    private let titleLabel: UILabel
    let textView = UITextView()
    private let placeholderLabel: UILabel

    var text: String { textView.text ?? "" }

    init(title: String, placeholder: String, minHeight: CGFloat = 120) {
        titleLabel = UILabel(text: title.uppercased(), font: SkesteFont.demibold(9), color: Palette.muted)
        placeholderLabel = UILabel(text: placeholder, font: SkesteFont.medium(15), color: Palette.muted, lines: 0)
        super.init(frame: .zero)
        titleLabel.attributedText = NSAttributedString(string: title.uppercased(), attributes: [.font: SkesteFont.demibold(9), .foregroundColor: Palette.muted, .kern: 1.6])
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(2)
            make.top.equalToSuperview()
        }

        textView.backgroundColor = Palette.glassStrong
        textView.layer.cornerRadius = 10
        textView.layer.cornerCurve = .continuous
        textView.layer.borderWidth = 1
        textView.layer.borderColor = Palette.hairline.cgColor
        textView.font = SkesteFont.body(15)
        textView.textColor = Palette.text
        textView.tintColor = Palette.magenta
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        textView.isScrollEnabled = true
        textView.delegate = self
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.height.greaterThanOrEqualTo(minHeight)
        }

        placeholderLabel.isUserInteractionEnabled = false
        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.leading.equalTo(textView).offset(17)
            make.trailing.equalTo(textView).offset(-17)
            make.top.equalTo(textView).offset(18)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String) {
        textView.text = text
        placeholderLabel.isHidden = !text.isEmpty
    }
}

extension SkesteTextView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

final class EmptyStateView: UIView {
    private let actionButton: GradientButton?

    init(symbol: String, kicker: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        if let actionTitle {
            actionButton = GradientButton(title: actionTitle, icon: "arrow.right", height: 50)
        } else {
            actionButton = nil
        }
        super.init(frame: .zero)

        let iconBackground = UIView()
        iconBackground.backgroundColor = Palette.glassStrong
        iconBackground.layer.cornerRadius = 34
        iconBackground.layer.cornerCurve = .continuous
        iconBackground.layer.borderWidth = 1
        iconBackground.layer.borderColor = Palette.hairline.cgColor
        addSubview(iconBackground)
        iconBackground.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(68)
        }
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .light)))
        icon.tintColor = Palette.cyan
        icon.contentMode = .scaleAspectFit
        iconBackground.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(32) }

        let kickerLabel = UILabel(text: kicker.uppercased(), font: SkesteFont.demibold(9), color: Palette.magenta)
        kickerLabel.attributedText = NSAttributedString(string: kicker.uppercased(), attributes: [.font: SkesteFont.demibold(9), .foregroundColor: Palette.magenta, .kern: 2.2])
        kickerLabel.textAlignment = .center
        addSubview(kickerLabel)
        kickerLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBackground.snp.bottom).offset(18)
            make.centerX.equalToSuperview()
        }

        let titleLabel = UILabel(text: title, font: SkesteFont.display(24), color: Palette.text, lines: 2)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(kickerLabel.snp.bottom).offset(5)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }

        let messageLabel = UILabel(text: message, font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
        messageLabel.textAlignment = .center
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }

        if let actionButton, let action {
            addSubview(actionButton)
            actionButton.snp.makeConstraints { make in
                make.top.equalTo(messageLabel.snp.bottom).offset(22)
                make.centerX.equalToSuperview()
                make.width.equalTo(220)
                make.bottom.equalToSuperview()
            }
            actionButton.addAction(UIAction { _ in action() }, for: .touchUpInside)
        } else {
            messageLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class GradientProgressBar: UIView {
    private let trackLayer = CALayer()
    private let gradientLayer = CAGradientLayer()
    private let maskLayer = CALayer()
    private(set) var progress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        trackLayer.backgroundColor = Palette.hairline.cgColor
        layer.addSublayer(trackLayer)
        gradientLayer.colors = SkesteGradient.signature.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        maskLayer.backgroundColor = UIColor.white.cgColor
        gradientLayer.mask = maskLayer
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        trackLayer.frame = bounds
        trackLayer.cornerRadius = bounds.height / 2
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = bounds.height / 2
        maskLayer.frame = CGRect(x: 0, y: 0, width: bounds.width * progress, height: bounds.height)
    }

    func setProgress(_ value: CGFloat, animated: Bool) {
        progress = min(max(value, 0), 1)
        if animated {
            let animation = CABasicAnimation(keyPath: "bounds.size.width")
            animation.fromValue = maskLayer.bounds.width
            animation.toValue = bounds.width * progress
            animation.duration = 0.45
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            maskLayer.add(animation, forKey: "progress")
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}

final class SkesteMarkView: UIView {
    private let logo = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        logo.image = UIImage(named: "skete_logo")
        logo.contentMode = .scaleAspectFit
        addSubview(logo)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        logo.frame = bounds
    }
}

final class SheetGrabber: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white.withAlphaComponent(0.22)
        layer.cornerRadius = 2
        snp.makeConstraints { make in
            make.width.equalTo(38)
            make.height.equalTo(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class GiftBurstView: UIView {
    static func show(gift: Gift, in window: UIWindow? = nil) {
        guard let target = window ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap(\.windows).first(where: { $0.isKeyWindow }) else { return }
        let burst = GiftBurstView(frame: target.bounds)
        burst.isUserInteractionEnabled = false
        target.addSubview(burst)

        let iconContainer = UIView(frame: CGRect(x: 0, y: 0, width: 86, height: 86))
        iconContainer.center = CGPoint(x: target.bounds.midX, y: target.bounds.midY - 40)
        iconContainer.layer.cornerRadius = 43
        iconContainer.backgroundColor = UIColor(hex: "141032")
        iconContainer.layer.borderWidth = 1
        iconContainer.layer.borderColor = gift.colors.first.map { UIColor(hex: $0).cgColor } ?? Palette.cyan.cgColor
        iconContainer.applyGlow(color: gift.colors.first.map { UIColor(hex: $0) } ?? Palette.cyan, radius: 30, opacity: 0.65)
        burst.addSubview(iconContainer)

        let icon = UIImageView(frame: iconContainer.bounds.insetBy(dx: 21, dy: 21))
        icon.image = AssetResolver.image(named: gift.imageName) ?? UIImage(systemName: gift.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 34, weight: .semibold))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        iconContainer.addSubview(icon)

        let label = UILabel(frame: CGRect(x: 20, y: iconContainer.frame.maxY + 14, width: target.bounds.width - 40, height: 24))
        label.text = "\(gift.name) sent"
        label.font = SkesteFont.demibold(14)
        label.textColor = .white
        label.textAlignment = .center
        burst.addSubview(label)

        for index in 0..<8 {
            let spark = UIView(frame: CGRect(x: iconContainer.center.x, y: iconContainer.center.y, width: 5, height: 5))
            spark.backgroundColor = [Palette.lime, Palette.cyan, Palette.magenta, Palette.amber][index % 4]
            spark.layer.cornerRadius = 2.5
            burst.addSubview(spark)
            let angle = CGFloat(index) / 8 * .pi * 2
            let distance: CGFloat = 92
            UIView.animate(withDuration: 0.6, delay: Double(index) * 0.025, options: [.curveEaseOut]) {
                spark.center = CGPoint(x: iconContainer.center.x + cos(angle) * distance, y: iconContainer.center.y + sin(angle) * distance)
                spark.alpha = 0
            }
        }

        iconContainer.transform = CGAffineTransform(scaleX: 0.58, y: 0.58)
        label.alpha = 0
        UIView.animate(withDuration: 0.48, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            iconContainer.transform = .identity
            label.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            UIView.animate(withDuration: 0.35, animations: {
                burst.alpha = 0
                iconContainer.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
            }, completion: { _ in
                burst.removeFromSuperview()
            })
        }
    }
}
