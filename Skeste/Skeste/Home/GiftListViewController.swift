import UIKit
import SnapKit

/// Circular gift thumbnail used by the gift log and its summary row.
final class GiftBadgeView: UIView {
    private let gradient = CAGradientLayer()
    private let imageView = UIImageView()
    private let symbolView = UIImageView()
    private let ring = UIView()
    let gift: Gift

    init(gift: Gift, diameter: CGFloat = 46) {
        self.gift = gift
        super.init(frame: .zero)
        layer.cornerRadius = diameter / 2
        layer.cornerCurve = .continuous
        clipsToBounds = true

        gradient.colors = gift.colors.map { UIColor(hex: $0).cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)

        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(diameter * 0.12)
        }

        symbolView.image = UIImage(systemName: gift.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: diameter * 0.4, weight: .semibold))
        symbolView.tintColor = .white
        symbolView.contentMode = .scaleAspectFit
        addSubview(symbolView)
        symbolView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(diameter * 0.46)
        }

        if let image = AssetResolver.image(named: gift.imageName) {
            imageView.image = image
            imageView.isHidden = false
            symbolView.isHidden = true
        } else {
            imageView.isHidden = true
            symbolView.isHidden = false
        }

        snp.makeConstraints { make in
            make.width.height.equalTo(diameter)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}

final class GiftLogRow: UIView {
    init(record: GiftRecord, gift: Gift, sender: User?) {
        super.init(frame: .zero)
        applyGlass(cornerRadius: 18, borderAlpha: 0.09, fill: Palette.glass)

        let badge = GiftBadgeView(gift: gift, diameter: 46)
        addSubview(badge)
        badge.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }

        let name = UILabel(text: gift.name, font: SkesteFont.demibold(14), color: Palette.text)
        addSubview(name)
        name.snp.makeConstraints { make in
            make.leading.equalTo(badge.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(13)
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }

        let senderText = sender.map { "FROM \($0.handle.uppercased())" } ?? "FROM A RIDER"
        let senderLabel = UILabel(text: senderText, font: SkesteFont.demibold(8), color: Palette.secondary)
        senderLabel.tracked(1.2)
        addSubview(senderLabel)
        senderLabel.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(name.snp.bottom).offset(3)
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }

        let time = UILabel(text: record.createdAt.skesteRelative.uppercased(), font: SkesteFont.mono(8, weight: .bold), color: Palette.muted)
        addSubview(time)
        time.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-13)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(senderLabel.snp.trailing).offset(8)
        }

        // Keep the row from collapsing around the badge's fixed 46pt height.
        snp.makeConstraints { make in
            make.height.equalTo(72)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class GiftListViewController: UIViewController {
    var onSend: (() -> Void)?
    private let postID: String
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(postID: String) {
        self.postID = postID
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas
        view.overrideUserInterfaceStyle = .dark

        let gradient = CAGradientLayer()
        gradient.colors = [Palette.deep.cgColor, Palette.canvas.cgColor]
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 500)
        view.layer.insertSublayer(gradient, at: 0)

        let grabber = SheetGrabber()
        view.addSubview(grabber)
        grabber.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
        }

        let close = SkesteControls.iconButton(symbol: "xmark", diameter: 34)
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(18)
        }

        let records = AppStore.shared.gifts(for: postID)
        let senders = AppStore.shared.giftSenders(for: postID)

        let kicker = UILabel(text: "STOKE RECEIVED", font: SkesteFont.demibold(9), color: Palette.amber)
        kicker.tracked(2.2)
        view.addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalToSuperview().offset(32)
        }

        let title = UILabel(text: "GIFT LOG", font: SkesteFont.display(26), color: Palette.text)
        title.richTracking(-0.5)
        view.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalTo(kicker.snp.bottom).offset(2)
        }

        let subtitle = UILabel(text: subtitleText(giftCount: records.count, senderCount: senders.count), font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        view.addSubview(subtitle)
        subtitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-22)
            make.top.equalTo(title.snp.bottom).offset(2)
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(subtitle.snp.bottom).offset(16)
        }

        contentStack.axis = .vertical
        contentStack.spacing = 8
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 30, right: 20))
            make.width.equalTo(scrollView.snp.width).offset(-40)
        }

        if records.isEmpty {
            contentStack.addArrangedSubview(emptyState())
        } else {
            contentStack.addArrangedSubview(summary(count: records.count, senders: senders))
            for record in records {
                guard let gift = Gift.gift(withID: record.giftID) else { continue }
                let row = GiftLogRow(record: record, gift: gift, sender: AppStore.shared.user(withID: record.senderID))
                contentStack.addArrangedSubview(row)
            }
        }

        let send = GradientButton(title: "SEND STOKE", icon: "gift.fill", colors: [Palette.amber, Palette.magenta], height: 48, fontSize: 13)
        send.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.dismiss(animated: true) { [weak self] in self?.onSend?() }
        }, for: .touchUpInside)
        contentStack.addArrangedSubview(send)
        contentStack.setCustomSpacing(18, after: contentStack.arrangedSubviews[contentStack.arrangedSubviews.count - 2])
    }

    private func subtitleText(giftCount: Int, senderCount: Int) -> String {
        guard giftCount > 0 else { return "No gifts on this line yet. Be the first to send some stoke." }
        let riders = senderCount == 1 ? "1 rider" : "\(senderCount) riders"
        return "\(giftCount) gift\(giftCount == 1 ? "" : "s") from \(riders). Newest first."
    }

    private func summary(count: Int, senders: [User]) -> UIView {
        let wrap = UIView()
        wrap.applyGlass(cornerRadius: 20, borderAlpha: 0.1, fill: Palette.glass)

        let badgeRow = UIStackView()
        badgeRow.axis = .horizontal
        badgeRow.spacing = -12
        badgeRow.alignment = .center
        let recentGifts = AppStore.shared.gifts(for: postID).compactMap { Gift.gift(withID: $0.giftID) }
        var previousBadge: GiftBadgeView?
        for gift in recentGifts.prefix(4) {
            let badge = GiftBadgeView(gift: gift, diameter: 36)
            badge.layer.borderWidth = 2
            badge.layer.borderColor = Palette.canvas.cgColor
            badgeRow.addArrangedSubview(badge)
            previousBadge = badge
        }
        if previousBadge == nil {
            let placeholder = GiftBadgeView(gift: Gift.catalog[0], diameter: 36)
            badgeRow.addArrangedSubview(placeholder)
        }
        wrap.addSubview(badgeRow)
        badgeRow.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
        }

        let headline = UILabel(text: "\(count) DROP\(count == 1 ? "" : "S")", font: SkesteFont.display(19), color: Palette.text)
        wrap.addSubview(headline)
        headline.snp.makeConstraints { make in
            make.leading.equalTo(badgeRow.snp.trailing).offset(13)
            make.top.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualToSuperview().offset(-14)
        }

        let names = senders.prefix(2).map { "@\($0.username)" }.joined(separator: ", ")
        let detail = UILabel(text: senders.count > 2 ? "\(names) +\(senders.count - 2) more" : names, font: SkesteFont.medium(10), color: Palette.muted)
        wrap.addSubview(detail)
        detail.snp.makeConstraints { make in
            make.leading.equalTo(headline)
            make.top.equalTo(headline.snp.bottom).offset(2)
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-12)
        }

        return wrap
    }

    private func emptyState() -> UIView {
        let wrap = UIView()
        wrap.applyGlass(cornerRadius: 22, borderAlpha: 0.1, fill: Palette.glass)

        let icon = UIImageView(image: UIImage(systemName: "gift", withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .semibold)))
        icon.tintColor = Palette.amber
        wrap.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(26)
            make.width.height.equalTo(30)
        }

        let title = UILabel(text: "NO STOKE YET", font: SkesteFont.demibold(11), color: Palette.text)
        title.tracked(1.4)
        wrap.addSubview(title)
        title.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(icon.snp.bottom).offset(10)
        }

        let note = UILabel(text: "Gifts sent to this line show up here, newest first.", font: SkesteFont.body(12), color: Palette.muted, lines: 0)
        note.textAlignment = .center
        wrap.addSubview(note)
        note.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(26)
            make.top.equalTo(title.snp.bottom).offset(5)
            make.bottom.equalToSuperview().offset(-24)
        }

        return wrap
    }
}
