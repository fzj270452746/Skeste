import UIKit
import SnapKit

// MARK: - Sparkline

final class LabSparklineView: UIView {
    private let fill = CAShapeLayer()
    private let glow = CAShapeLayer()
    private let line = CAShapeLayer()
    private(set) var values: [Double] = []
    var tint: UIColor = Palette.cyan {
        didSet { applyTint() }
    }
    var showsFill: Bool = true {
        didSet { fill.isHidden = !showsFill }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        fill.fillColor = tint.withAlphaComponent(0.10).cgColor
        glow.fillColor = UIColor.clear.cgColor
        glow.strokeColor = tint.withAlphaComponent(0.35).cgColor
        glow.lineWidth = 5
        glow.lineCap = .round
        glow.shadowColor = tint.cgColor
        glow.shadowOpacity = 0.55
        glow.shadowRadius = 6
        glow.shadowOffset = .zero
        line.fillColor = UIColor.clear.cgColor
        line.strokeColor = tint.cgColor
        line.lineWidth = 2
        line.lineJoin = .round
        line.lineCap = .round
        layer.addSublayer(fill)
        layer.addSublayer(glow)
        layer.addSublayer(line)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValues(_ values: [Double], animated: Bool = false) {
        self.values = values.filter { $0.isFinite }
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.28)
            setNeedsLayout()
            layoutIfNeeded()
            CATransaction.commit()
        } else {
            setNeedsLayout()
        }
    }

    private func applyTint() {
        fill.fillColor = tint.withAlphaComponent(0.10).cgColor
        glow.strokeColor = tint.withAlphaComponent(0.35).cgColor
        glow.shadowColor = tint.cgColor
        line.strokeColor = tint.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !values.isEmpty, bounds.width > 2, bounds.height > 2 else {
            fill.path = nil
            glow.path = nil
            line.path = nil
            return
        }

        let points = values.count == 1 ? [values[0], values[0]] : values
        guard let minimum = points.min(), let maximum = points.max() else { return }
        let range = max(8, maximum - minimum)
        let path = UIBezierPath()
        for (index, value) in points.enumerated() {
            let x = bounds.width * CGFloat(index) / CGFloat(max(1, points.count - 1))
            let normalized = CGFloat((value - minimum) / range)
            let y = bounds.height - 4 - normalized * (bounds.height - 10)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        line.path = path.cgPath
        glow.path = path.cgPath

        let fillPath = UIBezierPath(cgPath: path.cgPath)
        fillPath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
        fillPath.addLine(to: CGPoint(x: 0, y: bounds.height))
        fillPath.close()
        fill.path = fillPath.cgPath
    }
}

// MARK: - Bar chart

final class LabBarChartView: UIView {
    private(set) var values: [Double] = []
    private(set) var labels: [String] = []
    var tint: UIColor = Palette.lime {
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

    func setValues(_ values: [Double], labels: [String] = []) {
        self.values = values
        self.labels = labels
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard !values.isEmpty else {
            drawText("NO DATA", at: CGPoint(x: 4, y: rect.midY - 5), color: Palette.muted, font: SkesteFont.mono(8, weight: .medium))
            return
        }

        let labelHeight: CGFloat = labels.isEmpty ? 4 : 16
        let chart = CGRect(x: 2, y: 6, width: rect.width - 4, height: rect.height - labelHeight - 8)
        let maximum = max(values.max() ?? 1, 1)
        let slot = chart.width / CGFloat(values.count)
        let barWidth = max(4, min(18, slot * 0.52))

        for (index, value) in values.enumerated() {
            let fraction = CGFloat(max(0, value) / maximum)
            let height = max(2, chart.height * fraction)
            let x = chart.minX + slot * CGFloat(index) + (slot - barWidth) / 2
            let barRect = CGRect(x: x, y: chart.maxY - height, width: barWidth, height: height)
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: barWidth / 2)
            let isLast = index == values.count - 1
            context.setFillColor(tint.withAlphaComponent(isLast ? 0.95 : 0.42).cgColor)
            context.addPath(path.cgPath)
            context.fillPath()

            if !labels.isEmpty, index < labels.count {
                drawCenteredText(labels[index],
                                 centerX: x + barWidth / 2,
                                 y: chart.maxY + 4,
                                 color: isLast ? tint : Palette.muted,
                                 font: SkesteFont.mono(7, weight: .medium))
            }
        }
    }

    private func drawCenteredText(_ text: String, centerX: CGFloat, y: CGFloat, color: UIColor, font: UIFont) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(at: CGPoint(x: centerX - size.width / 2, y: y), withAttributes: attributes)
    }

    private func drawText(_ text: String, at point: CGPoint, color: UIColor, font: UIFont) {
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }
}

// MARK: - 7-day history

final class LabHistoryChartView: UIView {
    private(set) var base: [Int] = []
    private(set) var fresh: [Int] = []
    private(set) var labels: [String] = []
    var showsBase = true {
        didSet { setNeedsDisplay() }
    }
    var freshLegend = "FRESH" {
        didSet { setNeedsDisplay() }
    }
    var baseLegend = "BASE" {
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

    func setData(base: [Int], fresh: [Int], labels: [String], showsBase: Bool? = nil) {
        self.base = base
        self.fresh = fresh
        self.labels = labels
        if let showsBase { self.showsBase = showsBase }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let count = showsBase
            ? min(base.count, fresh.count, max(labels.count, 1))
            : min(fresh.count, max(labels.count, 1))
        guard count > 0 else { return }

        drawLegend(in: rect)
        let chart = CGRect(x: 4, y: 22, width: rect.width - 8, height: rect.height - 46)
        let slot = chart.width / CGFloat(count)
        let barWidth = max(4, min(14, slot * 0.42))
        let freshMax = max(CGFloat(fresh.max() ?? 1), 1)

        for index in 0..<count {
            let fraction = CGFloat(max(0, fresh[index])) / freshMax
            let height = max(1, chart.height * fraction)
            let x = chart.minX + slot * CGFloat(index) + (slot - barWidth) / 2
            let barRect = CGRect(x: x, y: chart.maxY - height, width: barWidth, height: height)
            context.setFillColor(Palette.ice.withAlphaComponent(index == count - 1 ? 0.95 : 0.42).cgColor)
            context.addPath(UIBezierPath(roundedRect: barRect, cornerRadius: barWidth / 2).cgPath)
            context.fillPath()
        }

        if showsBase, base.count >= count {
            let baseMin = CGFloat(base.min() ?? 0)
            let baseMax = CGFloat(base.max() ?? 1)
            let baseRange = max(1, baseMax - baseMin)
            let linePath = UIBezierPath()
            for index in 0..<count {
                let x = chart.minX + slot * CGFloat(index) + slot / 2
                let normalized = (CGFloat(base[index]) - baseMin) / baseRange
                let y = chart.maxY - 6 - normalized * (chart.height - 14)
                if index == 0 {
                    linePath.move(to: CGPoint(x: x, y: y))
                } else {
                    linePath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.setStrokeColor(Palette.violet.cgColor)
            context.setLineWidth(2)
            context.setLineJoin(.round)
            context.setLineCap(.round)
            context.addPath(linePath.cgPath)
            context.strokePath()
        }

        for index in 0..<count where index < labels.count {
            drawCentered(labels[index], centerX: chart.minX + slot * CGFloat(index) + slot / 2, y: rect.height - 17, color: Palette.muted, font: SkesteFont.mono(7, weight: .medium))
        }
    }

    private func drawLegend(in rect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [.font: SkesteFont.demibold(7), .foregroundColor: Palette.muted]
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(Palette.ice.cgColor)
        context?.fill(CGRect(x: 4, y: 5, width: 6, height: 6))
        (freshLegend as NSString).draw(at: CGPoint(x: 14, y: 3), withAttributes: attributes)
        guard showsBase else { return }
        context?.setFillColor(Palette.violet.cgColor)
        context?.fill(CGRect(x: 62, y: 5, width: 6, height: 6))
        (baseLegend as NSString).draw(at: CGPoint(x: 72, y: 3), withAttributes: attributes)
    }

    private func drawCentered(_ text: String, centerX: CGFloat, y: CGFloat, color: UIColor, font: UIFont) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(at: CGPoint(x: centerX - size.width / 2, y: y), withAttributes: attributes)
    }
}

// MARK: - Breakdown

final class LabBreakdownRow: UIView {
    private let titleLabel = UILabel(text: nil, font: SkesteFont.demibold(7), color: Palette.muted)
    private let valueLabel = UILabel(text: nil, font: SkesteFont.mono(8, weight: .bold), color: Palette.secondary)
    private let track = UIView()
    private let fill = UIView()
    private var fraction: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.tracked(0.8)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.equalTo(64)
        }

        track.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        track.layer.cornerRadius = 3
        track.clipsToBounds = true
        addSubview(track)
        track.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
            make.height.equalTo(6)
        }

        fill.layer.cornerRadius = 3
        track.addSubview(fill)

        valueLabel.textAlignment = .right
        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.equalTo(track.snp.trailing).offset(8)
            make.width.equalTo(28)
        }
        snp.makeConstraints { $0.height.equalTo(16) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ item: TerrainBreakdownItem) {
        titleLabel.text = item.label
        valueLabel.text = "\(Int(item.value.rounded()))"
        fill.backgroundColor = item.color
        fraction = CGFloat(min(max(item.value / max(item.maximum, 1), 0), 1))
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = track.bounds.width * fraction
        fill.frame = CGRect(x: 0, y: 0, width: width, height: track.bounds.height)
    }
}

final class LabBreakdownView: UIView {
    private let stack = UIStackView()
    private var rows: [LabBreakdownRow] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.spacing = 5
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setItems(_ items: [TerrainBreakdownItem]) {
        if rows.count != items.count {
            stack.arrangedSubviews.forEach {
                stack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            rows = items.map { _ in
                let row = LabBreakdownRow()
                stack.addArrangedSubview(row)
                return row
            }
        }
        for (index, item) in items.enumerated() where index < rows.count {
            rows[index].configure(item)
        }
    }
}

// MARK: - Ring gauge

final class LabRingGaugeView: UIView {
    private let track = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let scoreLabel = UILabel(text: "0", font: SkesteFont.display(34), color: Palette.text)
    private let captionLabel = UILabel(text: "FIELD RISK", font: SkesteFont.demibold(7), color: Palette.muted)
    private var progress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        track.fillColor = UIColor.clear.cgColor
        track.strokeColor = Palette.hairline.cgColor
        track.lineWidth = 9
        track.lineCap = .round
        layer.addSublayer(track)

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = Palette.amber.cgColor
        progressLayer.lineWidth = 9
        progressLayer.lineCap = .round
        layer.addSublayer(progressLayer)

        scoreLabel.textAlignment = .center
        addSubview(scoreLabel)
        scoreLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-6)
        }

        captionLabel.tracked(1.1)
        captionLabel.textAlignment = .center
        addSubview(captionLabel)
        captionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(scoreLabel.snp.bottom).offset(-2)
        }
        snp.makeConstraints { $0.height.equalTo(132) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProgress(_ value: CGFloat, color: UIColor, score: Int, caption: String, animated: Bool) {
        progress = min(max(value, 0), 1)
        progressLayer.strokeColor = color.cgColor
        scoreLabel.text = "\(score)"
        scoreLabel.textColor = color
        captionLabel.text = caption
        if animated {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.presentation()?.strokeEnd ?? 0
            animation.toValue = progress
            animation.duration = 0.35
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            progressLayer.add(animation, forKey: "ring")
        }
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = min(bounds.width, bounds.height) / 2 - 8
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        track.path = path.cgPath
        progressLayer.path = path.cgPath
        progressLayer.strokeEnd = progress
    }
}

// MARK: - Aspect compass

final class AspectCompassView: UIView {
    private var aspectIndex: Int = 0
    private var color: UIColor = Palette.amber

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setAspect(_ index: Int, color: UIColor) {
        aspectIndex = min(max(index, 0), 3)
        self.color = color
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 20

        let angles: [CGFloat] = [-90, 0, 90, 180]
        let selected = angles[aspectIndex] * .pi / 180

        let wedge = UIBezierPath()
        wedge.move(to: center)
        wedge.addArc(withCenter: center, radius: radius, startAngle: selected - .pi / 4, endAngle: selected + .pi / 4, clockwise: true)
        wedge.close()
        color.withAlphaComponent(0.18).setFill()
        wedge.fill()
        color.withAlphaComponent(0.7).setStroke()
        wedge.lineWidth = 1.5
        wedge.stroke()

        let circle = UIBezierPath(ovalIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        Palette.hairline.setStroke()
        circle.lineWidth = 1
        circle.stroke()

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.10).cgColor)
        context.setLineWidth(0.7)
        context.move(to: CGPoint(x: center.x - radius, y: center.y))
        context.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        context.move(to: CGPoint(x: center.x, y: center.y - radius))
        context.addLine(to: CGPoint(x: center.x, y: center.y + radius))
        context.strokePath()

        let arrow = UIBezierPath()
        let tip = CGPoint(x: center.x + cos(selected) * (radius - 10), y: center.y + sin(selected) * (radius - 10))
        arrow.move(to: center)
        arrow.addLine(to: tip)
        color.setStroke()
        arrow.lineWidth = 2
        arrow.lineCapStyle = .round
        arrow.stroke()

        let cardinal: [(String, CGPoint)] = [
            ("N", CGPoint(x: center.x, y: center.y - radius - 14)),
            ("E", CGPoint(x: center.x + radius + 13, y: center.y)),
            ("S", CGPoint(x: center.x, y: center.y + radius + 6)),
            ("W", CGPoint(x: center.x - radius - 16, y: center.y))
        ]
        for (text, point) in cardinal {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: SkesteFont.demibold(8),
                .foregroundColor: Palette.muted
            ]
            let size = (text as NSString).size(withAttributes: attributes)
            (text as NSString).draw(at: CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2), withAttributes: attributes)
        }

        let label = ["N", "E", "S", "W"][aspectIndex]
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: SkesteFont.display(18),
            .foregroundColor: color
        ]
        let size = (label as NSString).size(withAttributes: labelAttributes)
        (label as NSString).draw(at: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2), withAttributes: labelAttributes)
    }
}

// MARK: - Slope profile

final class SlopeProfileView: UIView {
    private var slope: Double = 34
    private var color: UIColor = Palette.amber

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSlope(_ value: Double, color: UIColor) {
        slope = min(max(value, 0), 60)
        self.color = color
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let baselineY = rect.height - 24
        let start = CGPoint(x: 34, y: baselineY)
        let endX = rect.width - 10
        let visualAngle = min(slope, 42)
        let rad = CGFloat(visualAngle) * .pi / 180
        let rise = min(tan(rad) * (endX - start.x), baselineY - 34)
        let end = CGPoint(x: endX, y: baselineY - rise)

        let shape = UIBezierPath()
        shape.move(to: start)
        shape.addLine(to: end)
        shape.addLine(to: CGPoint(x: endX, y: baselineY))
        shape.close()
        color.withAlphaComponent(0.12).setFill()
        shape.fill()

        let baseLine = UIBezierPath()
        baseLine.move(to: CGPoint(x: 6, y: baselineY))
        baseLine.addLine(to: CGPoint(x: rect.width - 6, y: baselineY))
        UIColor.white.withAlphaComponent(0.14).setStroke()
        baseLine.lineWidth = 1
        baseLine.setLineDash([3, 4], count: 2, phase: 0)
        baseLine.stroke()

        let slopeLine = UIBezierPath()
        slopeLine.move(to: start)
        slopeLine.addLine(to: end)
        color.setStroke()
        slopeLine.lineWidth = 2
        slopeLine.lineCapStyle = .round
        slopeLine.stroke()

        let arc = UIBezierPath(arcCenter: start, radius: 22, startAngle: -rad, endAngle: 0, clockwise: true)
        arc.lineWidth = 1
        color.withAlphaComponent(0.8).setStroke()
        arc.stroke()

        let markerPoint = CGPoint(x: start.x + (end.x - start.x) * 0.62, y: start.y + (end.y - start.y) * 0.62)
        context.saveGState()
        context.translateBy(x: markerPoint.x, y: markerPoint.y)
        context.rotate(by: -rad)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1.6)
        context.setLineCap(.round)
        context.move(to: CGPoint(x: 0, y: 0))
        context.addLine(to: CGPoint(x: 0, y: -9))
        context.move(to: CGPoint(x: 0, y: -3))
        context.addLine(to: CGPoint(x: -4, y: 2))
        context.addLine(to: CGPoint(x: -2, y: 7))
        context.move(to: CGPoint(x: 0, y: -3))
        context.addLine(to: CGPoint(x: 4, y: 2))
        context.addLine(to: CGPoint(x: 2, y: 7))
        context.strokePath()
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: -2.5, y: -13, width: 5, height: 5))
        context.restoreGState()

        let label = "SLOPE ANGLE"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: SkesteFont.demibold(7),
            .foregroundColor: Palette.muted
        ]
        (label as NSString).draw(at: CGPoint(x: 10, y: 6), withAttributes: attributes)

        let valueText = "\(Int(slope.rounded()))°"
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: SkesteFont.display(19),
            .foregroundColor: color
        ]
        (valueText as NSString).draw(at: CGPoint(x: 10, y: 14), withAttributes: valueAttributes)
    }
}

// MARK: - Range bar

final class LabRangeBarView: UIView {
    private var lowerBound: Double = 140
    private var upperBound: Double = 195
    private var recommended: ClosedRange<Double> = 168...184
    private var current: Double = 178
    private var color: UIColor = Palette.lime

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setRange(lower: Double, upper: Double, recommended: ClosedRange<Double>, current: Double, color: UIColor) {
        lowerBound = lower
        upperBound = max(upper, lower + 1)
        self.recommended = recommended
        self.current = current
        self.color = color
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let trackRect = CGRect(x: 4, y: 14, width: rect.width - 8, height: 6)
        let trackPath = UIBezierPath(roundedRect: trackRect, cornerRadius: 3)
        UIColor.white.withAlphaComponent(0.09).setFill()
        trackPath.fill()

        func x(for value: Double) -> CGFloat {
            let fraction = (value - lowerBound) / (upperBound - lowerBound)
            return trackRect.minX + trackRect.width * CGFloat(min(max(fraction, 0), 1))
        }

        let recommendedRect = CGRect(x: x(for: recommended.lowerBound),
                                     y: trackRect.minY,
                                     width: max(6, x(for: recommended.upperBound) - x(for: recommended.lowerBound)),
                                     height: trackRect.height)
        let rangePath = UIBezierPath(roundedRect: recommendedRect, cornerRadius: 3)
        color.withAlphaComponent(0.55).setFill()
        rangePath.fill()

        let markerX = x(for: current)
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: CGRect(x: markerX - 5, y: trackRect.midY - 5, width: 10, height: 10))
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2)
        context.strokeEllipse(in: CGRect(x: markerX - 5, y: trackRect.midY - 5, width: 10, height: 10))

        let minimumText = "\(Int(lowerBound))"
        let maximumText = "\(Int(upperBound))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: SkesteFont.mono(7, weight: .medium),
            .foregroundColor: Palette.muted
        ]
        (minimumText as NSString).draw(at: CGPoint(x: trackRect.minX, y: trackRect.maxY + 2), withAttributes: attributes)
        let maximumSize = (maximumText as NSString).size(withAttributes: attributes)
        (maximumText as NSString).draw(at: CGPoint(x: trackRect.maxX - maximumSize.width, y: trackRect.maxY + 2), withAttributes: attributes)

        let rangeText = "\(Int(recommended.lowerBound))–\(Int(recommended.upperBound)) cm"
        let rangeAttributes: [NSAttributedString.Key: Any] = [
            .font: SkesteFont.demibold(8),
            .foregroundColor: color
        ]
        let rangeSize = (rangeText as NSString).size(withAttributes: rangeAttributes)
        (rangeText as NSString).draw(at: CGPoint(x: trackRect.midX - rangeSize.width / 2, y: trackRect.maxY + 2), withAttributes: rangeAttributes)
    }
}

// MARK: - Steps

final class LabStepListView: UIView {
    private let stack = UIStackView()
    private var stepCount = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .vertical
        stack.spacing = 10
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSteps(_ steps: [String], tint: UIColor = Palette.cyan) {
        if stepCount != steps.count {
            stack.arrangedSubviews.forEach {
                stack.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            stepCount = steps.count
        }
        if stack.arrangedSubviews.count != steps.count {
            for _ in steps {
                let row = makeRow(tint: tint)
                stack.addArrangedSubview(row)
            }
        }
        for (index, step) in steps.enumerated() where index < stack.arrangedSubviews.count {
            let row = stack.arrangedSubviews[index]
            if let number = row.viewWithTag(101) as? UILabel {
                number.text = "\(index + 1)"
                number.textColor = tint
            }
            if let label = row.viewWithTag(102) as? UILabel {
                label.text = step
            }
        }
    }

    private func makeRow(tint: UIColor) -> UIView {
        let row = UIView()
        let numberHost = UIView()
        numberHost.backgroundColor = tint.withAlphaComponent(0.10)
        numberHost.layer.cornerRadius = 11
        numberHost.layer.borderWidth = 1
        numberHost.layer.borderColor = tint.withAlphaComponent(0.35).cgColor
        row.addSubview(numberHost)
        numberHost.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.height.equalTo(22)
        }

        let number = UILabel(text: nil, font: SkesteFont.mono(9, weight: .bold), color: tint)
        number.tag = 101
        number.textAlignment = .center
        numberHost.addSubview(number)
        number.snp.makeConstraints { $0.center.equalToSuperview() }

        let label = UILabel(text: nil, font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
        label.tag = 102
        label.lineSpacing(2)
        row.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(numberHost.snp.trailing).offset(10)
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview()
        }
        return row
    }
}

// MARK: - Context strip

final class LabContextStripView: UIView {
    init(text: String, tint: UIColor = Palette.cyan, kicker: String = "LIVE") {
        super.init(frame: .zero)
        applyGlass(cornerRadius: 10, borderAlpha: 0.10, fill: Palette.glass)

        let dotHost = UIView()
        let dot = UIView()
        dot.backgroundColor = tint
        dot.layer.cornerRadius = 3
        dot.applyGlow(color: tint, radius: 6, opacity: 0.7)
        dotHost.addSubview(dot)
        dot.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(6) }
        dotHost.snp.makeConstraints { $0.width.height.equalTo(8) }

        let live = UILabel(text: kicker.uppercased(), font: SkesteFont.demibold(7), color: tint)
        live.tracked(1.2)
        live.setContentHuggingPriority(.required, for: .horizontal)
        live.setContentCompressionResistancePriority(.required, for: .horizontal)

        let label = UILabel(text: text, font: SkesteFont.medium(9), color: Palette.secondary)
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [dotHost, live, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        addSubview(row)
        row.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(11)
            make.centerY.equalToSuperview()
        }

        snp.makeConstraints { $0.height.equalTo(30) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Level meter

final class LabLevelMeterView: UIView {
    private let stack = UIStackView()
    private var segments: [UIView] = []
    private let colors = [Palette.lime, Palette.mint, Palette.amber, Palette.danger, UIColor(hex: "FF2D55")]

    override init(frame: CGRect) {
        super.init(frame: frame)
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        for _ in 0..<5 {
            let segment = UIView()
            segment.layer.cornerRadius = 3
            segment.backgroundColor = UIColor.white.withAlphaComponent(0.09)
            stack.addArrangedSubview(segment)
            segments.append(segment)
        }
        snp.makeConstraints { $0.height.equalTo(6) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLevel(_ level: Int) {
        let clamped = min(max(level, 0), 5)
        for (index, segment) in segments.enumerated() {
            if index < clamped {
                segment.backgroundColor = colors[index].withAlphaComponent(index == clamped - 1 ? 1 : 0.55)
            } else {
                segment.backgroundColor = UIColor.white.withAlphaComponent(0.09)
            }
        }
    }
}
