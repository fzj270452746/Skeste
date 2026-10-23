import UIKit
import SnapKit

final class AboutViewController: BaseViewController {
    override func setupView() {
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel(text: "ABOUT SKESTE", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.9)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(back.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview()
        }
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-40)
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }

        let mark = SkesteMarkView()
        mark.snp.makeConstraints { $0.width.height.equalTo(76) }
        let markWrap = UIView()
        markWrap.addSubview(mark)
        mark.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        stack.addArrangedSubview(markWrap)
        stack.setCustomSpacing(18, after: markWrap)

        let kicker = UILabel(text: "FIND YOUR LINE", font: SkesteFont.demibold(9), color: Palette.secondary)
        kicker.tracked(2.4)
        kicker.textAlignment = .center
        stack.addArrangedSubview(kicker)
        stack.setCustomSpacing(4, after: kicker)

        let title = UILabel(text: "A MOUNTAIN\nSOCIAL.", font: SkesteFont.display(32), color: Palette.text, lines: 2)
        title.textAlignment = .center
        title.richTracking(-0.7)
        stack.addArrangedSubview(title)
        stack.setCustomSpacing(12, after: title)

        let intro = UILabel(text: "Skeste is a home for the people who wake up early, read the forecast like a love letter, and still get butterflies at the top of a new line. The feed is built for motion. The tools are built for the mountain. The coach line is built for trust.", font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
        intro.textAlignment = .center
        intro.lineSpacing(4)
        stack.addArrangedSubview(intro)
        stack.setCustomSpacing(26, after: intro)

        addFeature(stack, symbol: "play.rectangle.fill", kicker: "THE DROP", title: "Lines worth watching", body: "A living edit of ski and snowboard moments from the ridge: full-send lines, quiet dawn laps, and the stories behind them.")
        addFeature(stack, symbol: "scope", kicker: "RIDGE LAB", title: "Tools with a purpose", body: "Snow Desk, live run tracking, wax matching, terrain checks, and ski fitting. Five real tools made for the way you ride.")
        addFeature(stack, symbol: "video.fill", kicker: "COACH LINE", title: "Learn from a guide", body: "Browse certified coaches, describe the technique or terrain you want to work on, and meet over a private video session once they accept.")
        addFeature(stack, symbol: "sparkles", kicker: "SEND THE STOKE", title: "Support the line", body: "Eight mountain gifts let you back the riders who make you check the forecast. Purchases are handled securely through the App Store.")

        let legalCard = UIView()
        legalCard.applyGlass(cornerRadius: 24, borderAlpha: 0.1, fill: Palette.glass)
        let legalStack = UIStackView()
        legalStack.axis = .vertical
        legalStack.spacing = 0
        legalCard.addSubview(legalStack)
        legalStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)) }
        let terms = UIButton(type: .system)
        terms.contentHorizontalAlignment = .left
        terms.setTitle("Terms of Service", for: .normal)
        terms.setTitleColor(Palette.text, for: .normal)
        terms.titleLabel?.font = SkesteFont.medium(14)
        terms.contentEdgeInsets = UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10)
        terms.addAction(UIAction { [weak self] _ in self?.presentLegal(.terms) }, for: .touchUpInside)
        let privacy = UIButton(type: .system)
        privacy.contentHorizontalAlignment = .left
        privacy.setTitle("Privacy Policy", for: .normal)
        privacy.setTitleColor(Palette.text, for: .normal)
        privacy.titleLabel?.font = SkesteFont.medium(14)
        privacy.contentEdgeInsets = UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10)
        privacy.addAction(UIAction { [weak self] _ in self?.presentLegal(.privacy) }, for: .touchUpInside)
        let eula = UIButton(type: .system)
        eula.contentHorizontalAlignment = .left
        eula.setTitle("EULA", for: .normal)
        eula.setTitleColor(Palette.text, for: .normal)
        eula.titleLabel?.font = SkesteFont.medium(14)
        eula.contentEdgeInsets = UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 10)
        eula.addAction(UIAction { [weak self] _ in self?.presentLegal(.eula) }, for: .touchUpInside)
        legalStack.addArrangedSubview(terms)
        legalStack.addArrangedSubview(privacy)
        legalStack.addArrangedSubview(eula)
        stack.addArrangedSubview(legalCard)
        stack.setCustomSpacing(24, after: legalCard)

        let version = UILabel(text: "VERSION 1.0 (1)\nMADE FOR THE MOUNTAIN", font: SkesteFont.demibold(8), color: Palette.muted, lines: 2)
        version.tracked(1.4)
        version.textAlignment = .center
        stack.addArrangedSubview(version)
        stack.setCustomSpacing(4, after: version)
        let copyright = UILabel(text: "© 2026 SKESTE. ALL RIGHTS RESERVED.", font: SkesteFont.medium(8), color: Palette.muted)
        copyright.tracked(1.1)
        copyright.textAlignment = .center
        stack.addArrangedSubview(copyright)
    }

    private func addFeature(_ stack: UIStackView, symbol: String, kicker: String, title: String, body: String) {
        let card = UIView()
        card.applyGlass(cornerRadius: 14, borderAlpha: 0.08, fill: Palette.glass)
        let iconHost = UIView()
        iconHost.backgroundColor = Palette.glassStrong
        iconHost.layer.cornerRadius = 10
        iconHost.layer.cornerCurve = .continuous
        card.addSubview(iconHost)
        iconHost.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(16)
            make.width.height.equalTo(38)
        }
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)))
        icon.tintColor = Palette.cyan
        iconHost.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(20) }

        let kickerLabel = UILabel(text: kicker, font: SkesteFont.demibold(8), color: Palette.magenta)
        kickerLabel.tracked(1.7)
        card.addSubview(kickerLabel)
        kickerLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconHost.snp.trailing).offset(11)
            make.top.equalTo(iconHost).offset(2)
        }
        let titleLabel = UILabel(text: title, font: SkesteFont.demibold(16), color: Palette.text)
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(kickerLabel)
            make.top.equalTo(kickerLabel.snp.bottom).offset(1)
            make.trailing.equalToSuperview().offset(-16)
        }
        let bodyLabel = UILabel(text: body, font: SkesteFont.body(12), color: Palette.secondary, lines: 0)
        bodyLabel.lineSpacing(3)
        card.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(iconHost.snp.bottom).offset(12)
            make.bottom.equalToSuperview().offset(-15)
        }
        stack.addArrangedSubview(card)
        stack.setCustomSpacing(10, after: card)
    }
}