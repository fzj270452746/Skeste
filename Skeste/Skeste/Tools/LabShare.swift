import UIKit

enum LabShare {
    static func present(items: [Any], from controller: UIViewController) {
        let presenter = (controller as? BaseViewController)?.topPresenter() ?? controller
        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX,
                                        y: presenter.view.bounds.maxY - 120,
                                        width: 1,
                                        height: 1)
        }
        presenter.present(activity, animated: true)
    }

    static func present(image: UIImage, text: String, from controller: UIViewController) {
        present(items: [image, text], from: controller)
    }

    static func postToFeed(caption: String, tags: [String], from controller: BaseViewController, completion: ((Bool) -> Void)? = nil) {
        controller.requireLogin {
            guard AppStore.shared.addPost(kind: .note, caption: caption, tags: tags, media: []) != nil else {
                SkesteToast.show("Could not post this to the feed.", style: .error)
                completion?(false)
                return
            }
            SkesteToast.show("Posted to the field notes.", style: .success)
            completion?(true)
        }
    }
}

enum LabShareCard {
    static func run(_ run: RunRecord, resortName: String) -> UIImage {
        render { context, size in
            drawBackground(context: context, size: size)
            let margin: CGFloat = 82
            draw("SKESTE", font: SkesteFont.display(30), color: Palette.text, at: CGPoint(x: margin, y: 74), kern: -0.8)
            draw("RIDGE LAB  /  RUN RECAP", font: SkesteFont.demibold(13), color: Palette.lime, at: CGPoint(x: margin, y: 116), kern: 2.4)
            draw(resortName.uppercased(), font: SkesteFont.demibold(15), color: Palette.secondary, at: CGPoint(x: margin, y: 184), kern: 1.8)

            draw("VERTICAL", font: SkesteFont.demibold(14), color: Palette.muted, at: CGPoint(x: margin, y: 318), kern: 2.6)
            let verticalText = "\(Int(run.verticalMeters.rounded()))"
            let verticalFont = SkesteFont.display(148)
            draw(verticalText, font: verticalFont, color: Palette.text, at: CGPoint(x: margin - 6, y: 336), kern: -5)
            let verticalWidth = (verticalText as NSString).size(withAttributes: [.font: verticalFont]).width
            draw("M", font: SkesteFont.display(40), color: Palette.cyan, at: CGPoint(x: margin + verticalWidth - 4, y: 420), kern: 1)

            let statsY: CGFloat = 610
            drawStat("DISTANCE", value: distance(run.distanceMeters), x: margin, y: statsY)
            drawStat("TIME", value: duration(run.duration), x: margin + 310, y: statsY)
            drawStat("TOP SPEED", value: "\(Int(run.topSpeedKPH.rounded())) KM/H", x: margin + 620, y: statsY)

            drawDivider(context: context, y: 742, width: size.width - margin * 2, x: margin)

            draw("SEASON", font: SkesteFont.demibold(12), color: Palette.muted, at: CGPoint(x: margin, y: 790), kern: 2)
            draw("\(Int(AppStore.shared.totalVertical.rounded())) m", font: SkesteFont.display(34), color: Palette.text, at: CGPoint(x: margin, y: 812))
            draw("\(AppStore.shared.runs.count) RUNS", font: SkesteFont.mono(15, weight: .bold), color: Palette.secondary, at: CGPoint(x: margin + 292, y: 826))

            draw("READ THE HILL.", font: SkesteFont.demibold(15), color: Palette.cyan, at: CGPoint(x: margin, y: size.height - 106), kern: 2)
            draw("SKESTE  ·  RIDGE LAB", font: SkesteFont.mono(11, weight: .medium), color: Palette.muted, at: CGPoint(x: margin, y: size.height - 74), kern: 1.4)
        }
    }

    static func brief(_ resort: SnowResort, wax: WaxPlan, terrain: TerrainAssessment, window: SnowWindow) -> UIImage {
        render { context, size in
            drawBackground(context: context, size: size)
            let margin: CGFloat = 82
            draw("FIELD BRIEF", font: SkesteFont.demibold(13), color: Palette.lime, at: CGPoint(x: margin, y: 78), kern: 2.6)
            draw(resort.name.uppercased() + ".", font: SkesteFont.display(58), color: Palette.text, at: CGPoint(x: margin - 3, y: 100), kern: -2)
            draw(resort.region, font: SkesteFont.medium(15), color: Palette.secondary, at: CGPoint(x: margin, y: 176), kern: 1.2)

            draw("\(resort.tempC)°", font: SkesteFont.display(118), color: Palette.text, at: CGPoint(x: margin - 5, y: 238), kern: -4)
            let snowText = resort.reportSource.isWeatherKitData
                ? "\(resort.freshCM) CM FORECAST TODAY"
                : "\(resort.freshCM) CM FRESH"
            draw("\(snowText)  ·  \(resort.windKPH) KM/H WIND", font: SkesteFont.demibold(16), color: Palette.ice, at: CGPoint(x: margin, y: 376), kern: 1.2)

            drawDivider(context: context, y: 460, width: size.width - margin * 2, x: margin)
            draw("TODAY'S CALL", font: SkesteFont.demibold(12), color: Palette.magenta, at: CGPoint(x: margin, y: 506), kern: 2.4)

            drawCall(label: "WAX", value: "\(wax.family) · \(wax.ironTemp)°C", detail: wax.subtitle, y: 566, margin: margin, tint: Palette.amber)
            drawCall(label: "TERRAIN", value: "\(terrain.level) · \(terrain.score)/100", detail: terrain.headline, y: 704, margin: margin, tint: terrain.color)
            drawCall(label: "WINDOW", value: window.label, detail: window.detail, y: 842, margin: margin, tint: Palette.cyan)

            drawDivider(context: context, y: 1000, width: size.width - margin * 2, x: margin)
            draw("READ THE HILL.", font: SkesteFont.demibold(15), color: Palette.cyan, at: CGPoint(x: margin, y: size.height - 120), kern: 2)
            draw("SKESTE  ·  RIDGE LAB", font: SkesteFont.mono(11, weight: .medium), color: Palette.muted, at: CGPoint(x: margin, y: size.height - 88), kern: 1.4)
            let credit = resort.reportSource.isWeatherKitData
                ? "WEATHER BY APPLE WEATHER  ·  AVALANCHE LEVEL REFERENCE"
                : "SAMPLE DATA  ·  AVALANCHE LEVEL REFERENCE"
            draw(credit, font: SkesteFont.mono(9, weight: .medium), color: Palette.muted, at: CGPoint(x: margin, y: size.height - 58), kern: 1.1)
        }
    }

    private static func render(_ drawBlock: (CGContext, CGSize) -> Void) -> UIImage {
        let size = CGSize(width: 1080, height: 1350)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { rendererContext in
            drawBlock(rendererContext.cgContext, size)
        }
    }

    private static func drawBackground(context: CGContext, size: CGSize) {
        let colors = [UIColor(hex: "07103A").cgColor,
                      UIColor(hex: "1B0B5C").cgColor,
                      UIColor(hex: "340A55").cgColor,
                      UIColor(hex: "08061F").cgColor] as CFArray
        let locations: [CGFloat] = [0, 0.38, 0.72, 1]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            context.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: 0),
                                       end: CGPoint(x: size.width, y: size.height),
                                       options: [])
        } else {
            UIColor(hex: "0B0A2A").setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        context.setFillColor(Palette.magenta.withAlphaComponent(0.16).cgColor)
        context.fillEllipse(in: CGRect(x: -260, y: -280, width: 900, height: 900))
        context.setFillColor(Palette.cyan.withAlphaComponent(0.13).cgColor)
        context.fillEllipse(in: CGRect(x: 500, y: 160, width: 900, height: 900))
        context.setFillColor(Palette.violet.withAlphaComponent(0.13).cgColor)
        context.fillEllipse(in: CGRect(x: -320, y: 780, width: 1000, height: 1000))

        for index in 0..<7 {
            let y = 200 + CGFloat(index) * 150
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -40, y: y))
            path.addCurve(to: CGPoint(x: size.width + 40, y: y + CGFloat(index % 3 - 1) * 42),
                          controlPoint1: CGPoint(x: size.width * 0.28, y: y - 90),
                          controlPoint2: CGPoint(x: size.width * 0.68, y: y + 96))
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.035).cgColor)
            context.setLineWidth(1.2)
            context.addPath(path.cgPath)
            context.strokePath()
        }

        let mountain = UIBezierPath()
        mountain.move(to: CGPoint(x: 0, y: size.height))
        mountain.addLine(to: CGPoint(x: 0, y: 1120))
        mountain.addLine(to: CGPoint(x: 170, y: 930))
        mountain.addLine(to: CGPoint(x: 310, y: 1060))
        mountain.addLine(to: CGPoint(x: 470, y: 850))
        mountain.addLine(to: CGPoint(x: 620, y: 1010))
        mountain.addLine(to: CGPoint(x: 790, y: 900))
        mountain.addLine(to: CGPoint(x: size.width, y: 1080))
        mountain.addLine(to: CGPoint(x: size.width, y: size.height))
        mountain.close()
        UIColor.black.withAlphaComponent(0.20).setFill()
        mountain.fill()
    }

    private static func drawStat(_ title: String, value: String, x: CGFloat, y: CGFloat) {
        draw(title, font: SkesteFont.demibold(11), color: Palette.muted, at: CGPoint(x: x, y: y), kern: 2)
        draw(value, font: SkesteFont.display(27), color: Palette.text, at: CGPoint(x: x, y: y + 24))
    }

    private static func drawCall(label: String, value: String, detail: String, y: CGFloat, margin: CGFloat, tint: UIColor) {
        draw(label, font: SkesteFont.demibold(12), color: tint, at: CGPoint(x: margin, y: y), kern: 2.2)
        draw(value, font: SkesteFont.display(29), color: Palette.text, at: CGPoint(x: margin, y: y + 24))
        draw(detail, font: SkesteFont.medium(14), color: Palette.secondary, at: CGPoint(x: margin, y: y + 66))
    }

    private static func drawDivider(context: CGContext, y: CGFloat, width: CGFloat, x: CGFloat) {
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.14).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x + width, y: y))
        context.strokePath()
    }

    private static func draw(_ text: String, font: UIFont, color: UIColor, at point: CGPoint, kern: CGFloat = 0) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .kern: kern
        ]
        (text as NSString).draw(at: point, withAttributes: attributes)
    }

    private static func duration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private static func distance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f KM", meters / 1000)
        }
        return "\(Int(meters.rounded())) M"
    }
}
