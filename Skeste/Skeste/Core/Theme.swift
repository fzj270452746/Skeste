import UIKit

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = CGFloat((value & 0xFF0000) >> 16) / 255
        let green = CGFloat((value & 0x00FF00) >> 8) / 255
        let blue = CGFloat(value & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

enum Palette {
    // Deep aurora canvas: electric blue, violet and magenta, held dark enough
    // for white type. Cards are glass; community tiles are full-saturation.
    static let canvas = UIColor(hex: "0B0A2A")
    static let ink = UIColor(hex: "0B0A1F")
    static let midnight = UIColor(hex: "141032")
    static let deep = UIColor(hex: "1A1040")
    static let slate = UIColor(hex: "241A55")
    static let surface = UIColor(hex: "1E1648")
    static let frost = UIColor(hex: "FFFFFF")
    static let text = UIColor(hex: "F8F7FF")
    static let secondary = UIColor(hex: "C7C2E8")
    static let muted = UIColor(hex: "8F89BC")
    static let magenta = UIColor(hex: "FF3FD8")
    static let pink = UIColor(hex: "FF7AD9")
    static let violet = UIColor(hex: "7B5BF5")
    static let indigo = UIColor(hex: "4B3FBF")
    static let cyan = UIColor(hex: "4CD7F6")
    static let ice = UIColor(hex: "A8E9FF")
    static let lime = UIColor(hex: "B7F36B")
    static let mint = UIColor(hex: "4FE0B0")
    static let amber = UIColor(hex: "FFD447")
    static let danger = UIColor(hex: "FF5A76")
    static let hairline = UIColor.white.withAlphaComponent(0.16)
    static let glass = UIColor.white.withAlphaComponent(0.07)
    static let glassStrong = UIColor.white.withAlphaComponent(0.12)
    static let shadow = UIColor(hex: "05030F").withAlphaComponent(0.55)
}

enum SkesteFont {
    /// Rounded geometric sans — the social-app voice of the new direction.
    private static func rounded(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }

    static func display(_ size: CGFloat) -> UIFont {
        rounded(size, weight: .heavy)
    }

    static func title(_ size: CGFloat) -> UIFont {
        rounded(size, weight: .bold)
    }

    static func demibold(_ size: CGFloat) -> UIFont {
        rounded(size, weight: .semibold)
    }

    static func medium(_ size: CGFloat) -> UIFont {
        rounded(size, weight: .medium)
    }

    static func body(_ size: CGFloat) -> UIFont {
        rounded(size, weight: .regular)
    }

    static func mono(_ size: CGFloat, weight: UIFont.Weight = .medium) -> UIFont {
        UIFont.monospacedSystemFont(ofSize: size, weight: weight)
    }
}

enum SkesteGradient {
    static let signature: [UIColor] = [UIColor(hex: "FF4FD8"), UIColor(hex: "8B5CF6")]
    static let aurora: [UIColor] = [Palette.cyan, Palette.magenta]
    static let lime: [UIColor] = [Palette.lime, Palette.mint]
    static let sunset: [UIColor] = [Palette.amber, UIColor(hex: "FF7A6B"), Palette.magenta]
    static let ice: [UIColor] = [Palette.ice, Palette.cyan, Palette.violet]
    static let darkFade: [UIColor] = [UIColor.clear, Palette.canvas]
}

extension UIColor {
    /// True when white text would be hard to read on this fill.
    var prefersDarkForeground: Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return false }
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue > 0.55
    }
}

extension UILabel {
    convenience init(text: String? = nil, font: UIFont, color: UIColor, lines: Int = 1) {
        self.init()
        self.text = text
        self.font = font
        self.textColor = color
        self.numberOfLines = lines
    }

    func tracked(_ spacing: CGFloat) {
        guard let text else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2
        paragraph.alignment = textAlignment
        attributedText = NSAttributedString(string: text, attributes: [
            .font: font as Any,
            .foregroundColor: textColor as Any,
            .kern: spacing,
            .paragraphStyle: paragraph
        ])
    }

    func richTracking(_ spacing: CGFloat, lineHeight: CGFloat? = nil) {
        guard let text else { return }
        let paragraph = NSMutableParagraphStyle()
        if let lineHeight {
            paragraph.minimumLineHeight = lineHeight
            paragraph.maximumLineHeight = lineHeight
        }
        paragraph.alignment = textAlignment
        attributedText = NSAttributedString(string: text, attributes: [
            .font: font as Any,
            .foregroundColor: textColor as Any,
            .kern: spacing,
            .paragraphStyle: paragraph
        ])
    }
}

extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }

    func applyGlass(cornerRadius: CGFloat, borderAlpha: CGFloat = 0.12, fill: UIColor = Palette.glass) {
        backgroundColor = fill
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(borderAlpha).cgColor
        clipsToBounds = true
    }

    func applyGlow(color: UIColor, radius: CGFloat = 18, opacity: Float = 0.4) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = .zero
    }

    func pulse(scale: CGFloat = 1.03, duration: CFTimeInterval = 1.4) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = scale
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "skeste.pulse")
    }
}

extension CAGradientLayer {
    static func skeste(colors: [UIColor], start: CGPoint = CGPoint(x: 0, y: 0.5), end: CGPoint = CGPoint(x: 1, y: 0.5)) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = colors.map(\.cgColor)
        layer.startPoint = start
        layer.endPoint = end
        return layer
    }
}

/// Deep aurora canvas: electric blue and violet fields, magenta and cyan
/// light bleeding in from the edges, a fine starfield and film grain.
/// The glows drift slowly, like a long-exposure sky.
final class AuroraBackgroundView: UIView {
    private let baseGradient = CAGradientLayer()
    private let pinkGlow = AuroraGlowView(color: UIColor(hex: "FF3FD8"), alpha: 0.5)
    private let blueGlow = AuroraGlowView(color: UIColor(hex: "4CD7F6"), alpha: 0.44)
    private let violetGlow = AuroraGlowView(color: UIColor(hex: "7B5BF5"), alpha: 0.5)
    private let limeGlow = AuroraGlowView(color: UIColor(hex: "B7F36B"), alpha: 0.16)
    private let stars = StarFieldView()
    private let grain = GrainFieldView()
    private var glows: [AuroraGlowView] { [pinkGlow, blueGlow, violetGlow, limeGlow] }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = Palette.canvas

        baseGradient.colors = [
            UIColor(hex: "07103A").cgColor,
            UIColor(hex: "1B0B5C").cgColor,
            UIColor(hex: "340A55").cgColor,
            UIColor(hex: "08061F").cgColor
        ]
        baseGradient.locations = [0, 0.36, 0.68, 1]
        baseGradient.startPoint = CGPoint(x: 0.08, y: 0)
        baseGradient.endPoint = CGPoint(x: 0.92, y: 1)
        layer.addSublayer(baseGradient)

        glows.forEach { addSubview($0) }
        addSubview(stars)
        addSubview(grain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        baseGradient.frame = bounds
        let width = bounds.width
        let height = bounds.height
        pinkGlow.frame = CGRect(x: -width * 0.55, y: -height * 0.12, width: width * 1.55, height: width * 1.55)
        blueGlow.frame = CGRect(x: width * 0.18, y: -height * 0.08, width: width * 1.4, height: width * 1.4)
        violetGlow.frame = CGRect(x: -width * 0.35, y: height * 0.34, width: width * 1.5, height: width * 1.5)
        limeGlow.frame = CGRect(x: width * 0.42, y: height * 0.78, width: width * 1.1, height: width * 1.1)
        stars.frame = bounds
        grain.frame = bounds
        CATransaction.commit()
    }

    func startAnimating() {
        guard pinkGlow.layer.animation(forKey: "aurora.drift") == nil else { return }
        pinkGlow.drift(dx: 18, dy: 26, duration: 16, delay: 0)
        blueGlow.drift(dx: -22, dy: 18, duration: 19, delay: 1.2)
        violetGlow.drift(dx: 16, dy: -24, duration: 22, delay: 0.6)
        limeGlow.drift(dx: -14, dy: -16, duration: 24, delay: 2.1)
    }

    func stopAnimating() {
        glows.forEach { $0.layer.removeAnimation(forKey: "aurora.drift") }
    }
}

/// A single soft radial light source.
private final class AuroraGlowView: UIView {
    private let gradient = CAGradientLayer()

    init(color: UIColor, alpha: CGFloat) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        gradient.type = .radial
        gradient.colors = [
            color.withAlphaComponent(alpha).cgColor,
            color.withAlphaComponent(alpha * 0.45).cgColor,
            color.withAlphaComponent(0).cgColor
        ]
        gradient.locations = [0, 0.42, 1]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    func drift(dx: CGFloat, dy: CGFloat, duration: CFTimeInterval, delay: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "transform.translation")
        animation.fromValue = CGPoint.zero
        animation.toValue = CGPoint(x: dx, y: dy)
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timeOffset = delay
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(animation, forKey: "aurora.drift")
    }
}

/// Sparse, deterministic starfield with a few four-point sparkles.
private final class StarFieldView: UIView {
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
        for index in 0..<150 {
            let x = Self.unit(index &* 3 &+ 1) * rect.width
            let y = Self.unit(index &* 3 &+ 2) * rect.height
            let radius = 0.4 + Self.unit(index &* 5 &+ 3) * 1.5
            let alpha = 0.08 + Self.unit(index &* 7 &+ 4) * 0.38
            let color: UIColor
            switch index % 11 {
            case 0: color = Palette.pink
            case 1: color = Palette.cyan
            default: color = .white
            }
            context.setFillColor(color.withAlphaComponent(alpha).cgColor)
            context.fillEllipse(in: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
        }
        // A handful of larger sparkles.
        for index in 0..<7 {
            let x = Self.unit(index &* 11 &+ 31) * rect.width
            let y = Self.unit(index &* 13 &+ 37) * rect.height * 0.9
            let size = 3.5 + Self.unit(index &* 17 &+ 41) * 4
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
            context.setLineWidth(0.7)
            context.move(to: CGPoint(x: x - size, y: y))
            context.addLine(to: CGPoint(x: x + size, y: y))
            context.move(to: CGPoint(x: x, y: y - size))
            context.addLine(to: CGPoint(x: x, y: y + size))
            context.strokePath()
        }
    }

    private static func unit(_ seed: Int) -> CGFloat {
        var value = UInt64(bitPattern: Int64(seed)) &* 6364136223846793005 &+ 1442695040888963407
        value ^= value >> 33
        value = value &* 0xff51afd7ed558ccd
        value ^= value >> 33
        return CGFloat(value % 10_000) / 10_000
    }
}

/// Deterministic, very low-contrast film grain.
private final class GrainFieldView: UIView {
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
        for index in 0..<1900 {
            let x = Self.unit(index &* 2 &+ 1) * rect.width
            let y = Self.unit(index &* 2 &+ 2) * rect.height
            let size = 0.5 + Self.unit(index &* 5 &+ 3) * 0.9
            let alpha = 0.008 + Self.unit(index &* 7 &+ 4) * 0.020
            context.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
            context.fill(CGRect(x: x, y: y, width: size, height: size))
        }
    }

    private static func unit(_ seed: Int) -> CGFloat {
        var value = UInt64(bitPattern: Int64(seed)) &* 6364136223846793005 &+ 1442695040888963407
        value ^= value >> 33
        value = value &* 0xff51afd7ed558ccd
        value ^= value >> 33
        return CGFloat(value % 10_000) / 10_000
    }
}

/// Fine contour lines, like a topo sheet laid over dark paper.
private final class TopoFieldView: UIView {
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
        context.setLineWidth(0.7)
        context.setLineCap(.round)
        for index in 0..<11 {
            let base = rect.height * (0.08 + CGFloat(index) * 0.088)
            let amplitude = CGFloat((index % 4) + 1) * 7.5
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -12, y: base + amplitude * 0.4))
            let step = (rect.width + 24) / 4
            for segment in 0..<4 {
                let startX = -12 + step * CGFloat(segment)
                let endX = startX + step
                let direction: CGFloat = (index + segment) % 2 == 0 ? 1 : -1
                path.addCurve(
                    to: CGPoint(x: endX, y: base + direction * amplitude * 0.55),
                    controlPoint1: CGPoint(x: startX + step * 0.32, y: base - direction * amplitude),
                    controlPoint2: CGPoint(x: startX + step * 0.7, y: base + direction * amplitude * 1.15)
                )
            }
            let stroke: UIColor
            let alpha: CGFloat
            switch index % 3 {
            case 0:
                stroke = Palette.ink
                alpha = 0.055
            case 1:
                stroke = Palette.ink
                alpha = 0.038
            default:
                stroke = Palette.ink
                alpha = 0.028
            }
            context.setStrokeColor(stroke.withAlphaComponent(alpha).cgColor)
            context.addPath(path.cgPath)
            context.strokePath()
        }

        // A single survey tick, not a glowing accent.
        context.setStrokeColor(UIColor(hex: "151517").withAlphaComponent(0.07).cgColor)
        context.setLineWidth(0.7)
        let tickY = rect.height * 0.62
        for index in 0..<9 {
            let x = rect.width * (0.08 + CGFloat(index) * 0.105)
            context.move(to: CGPoint(x: x, y: tickY - 3))
            context.addLine(to: CGPoint(x: x, y: tickY + 3))
        }
        context.strokePath()
    }
}

final class GridOverlayView: UIView {
    var lineColor: UIColor = UIColor.white.withAlphaComponent(0.05) {
        didSet { setNeedsDisplay() }
    }
    var spacing: CGFloat = 42 {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(lineColor.cgColor)
        context.setLineWidth(0.5)
        var x: CGFloat = 0
        while x < rect.width {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: rect.height))
            x += spacing
        }
        var y: CGFloat = 0
        while y < rect.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y))
            y += spacing
        }
        context.strokePath()
    }
}


extension UILabel {
    func lineSpacing(_ spacing: CGFloat) {
        guard let text else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = spacing
        attributedText = NSAttributedString(string: text, attributes: [
            .font: font as Any,
            .foregroundColor: textColor as Any,
            .paragraphStyle: paragraph
        ])
    }
}

extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let text else { return }
        attributedText = NSAttributedString(string: text, attributes: [
            .font: font as Any,
            .foregroundColor: textColor as Any,
            .kern: spacing
        ])
    }
}


enum StableHash {
    static func of(_ string: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }
}
