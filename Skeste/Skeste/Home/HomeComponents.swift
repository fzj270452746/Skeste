import UIKit
import SnapKit

final class HomeHeaderView: UIView {
    var onAccountTapped: (() -> Void)?
    private let avatar = AvatarView(size: 38, showsRing: true)
    private let guestIcon = UIImageView()
    private let accountButton = UIControl()
    private let greetingLabel = UILabel(text: nil, font: SkesteFont.medium(12), color: Palette.secondary)
    private let statusLabel = UILabel(text: nil, font: SkesteFont.demibold(8), color: Palette.lime)
    private let wordmark = UILabel(text: "SKESTE", font: SkesteFont.display(36), color: Palette.text)

    override init(frame: CGRect) {
        super.init(frame: frame)
        let accent = UIView()
        accent.backgroundColor = Palette.magenta
        accent.layer.cornerRadius = 1
        addSubview(accent)
        accent.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(4)
            make.width.equalTo(2)
            make.height.equalTo(38)
        }

        let kicker = UILabel(text: "THE ALPINE SOCIAL  /  ISSUE 026", font: SkesteFont.demibold(8), color: Palette.secondary)
        kicker.tracked(1.8)
        addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.leading.equalTo(accent.snp.trailing).offset(10)
            make.top.equalToSuperview()
        }

        wordmark.richTracking(0.4)
        addSubview(wordmark)
        wordmark.snp.makeConstraints { make in
            make.leading.equalTo(kicker)
            make.top.equalTo(kicker.snp.bottom).offset(1)
        }

        greetingLabel.text = "Find your line. Find your people."
        addSubview(greetingLabel)
        greetingLabel.snp.makeConstraints { make in
            make.leading.equalTo(kicker)
            make.top.equalTo(wordmark.snp.bottom).offset(-2)
            make.trailing.lessThanOrEqualToSuperview().offset(-70)
        }

        statusLabel.text = "ON THE RIDGE"
        statusLabel.tracked(1.4)
        addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(kicker)
            make.top.equalTo(greetingLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }
        let statusDot = UIView()
        statusDot.backgroundColor = Palette.lime
        statusDot.layer.cornerRadius = 2.5
        addSubview(statusDot)
        statusDot.snp.makeConstraints { make in
            make.trailing.equalTo(statusLabel.snp.leading).offset(-5)
            make.centerY.equalTo(statusLabel)
            make.width.height.equalTo(5)
        }

        accountButton.backgroundColor = Palette.glass
        accountButton.layer.cornerRadius = 12
        accountButton.layer.cornerCurve = .continuous
        accountButton.layer.borderWidth = 1
        accountButton.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        accountButton.addAction(UIAction { [weak self] _ in
            self?.onAccountTapped?()
        }, for: .touchUpInside)
        addSubview(accountButton)
        accountButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(2)
            make.width.height.equalTo(44)
        }

        accountButton.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        guestIcon.image = UIImage(systemName: "person.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
        guestIcon.tintColor = Palette.text
        guestIcon.contentMode = .scaleAspectFit
        accountButton.addSubview(guestIcon)
        guestIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(21)
        }

        let online = UIView()
        online.backgroundColor = Palette.lime
        online.layer.cornerRadius = 4
        online.layer.borderWidth = 2
        online.layer.borderColor = Palette.deep.cgColor
        addSubview(online)
        online.snp.makeConstraints { make in
            make.width.height.equalTo(9)
            make.trailing.equalTo(accountButton).offset(-1)
            make.bottom.equalTo(accountButton).offset(-1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(user: User?) {
        if let user {
            avatar.isHidden = false
            guestIcon.isHidden = true
            avatar.configure(user: user)
            greetingLabel.text = "Welcome back, \(user.displayName.components(separatedBy: " ").first ?? user.displayName)."
        } else {
            avatar.isHidden = true
            guestIcon.isHidden = false
            greetingLabel.text = "Find your line. Find your people."
        }
    }
}

final class ConditionsStripView: UIView {
    var onTap: (() -> Void)?
    private let resortLabel = UILabel(text: nil, font: SkesteFont.demibold(13), color: Palette.text)
    private let updatedLabel = UILabel(text: "SAMPLE DATA", font: SkesteFont.demibold(8), color: Palette.muted)
    private let tempLabel = UILabel(text: "—", font: SkesteFont.display(28), color: Palette.text)
    private let snowLabel = UILabel(text: "—", font: SkesteFont.display(20), color: Palette.ice)
    private let windLabel = UILabel(text: "—", font: SkesteFont.display(20), color: Palette.text)
    private let snowKicker = UILabel(text: "SNOW TODAY", font: SkesteFont.demibold(7), color: Palette.muted)
    private let windKicker = UILabel(text: "WIND KM/H", font: SkesteFont.demibold(7), color: Palette.muted)

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlass(cornerRadius: 14, borderAlpha: 0.10, fill: Palette.glass)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "Open Snow Desk"

        let iconHost = UIView()
        iconHost.backgroundColor = Palette.glassStrong
        iconHost.layer.cornerRadius = 10
        iconHost.layer.cornerCurve = .continuous
        iconHost.layer.borderWidth = 1
        iconHost.layer.borderColor = Palette.hairline.cgColor
        addSubview(iconHost)
        iconHost.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(12)
            make.width.height.equalTo(36)
        }
        let icon = UIImageView(image: UIImage(systemName: "snowflake", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)))
        icon.tintColor = Palette.cyan
        iconHost.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(20) }

        let pulse = UILabel(text: "MOUNTAIN PULSE", font: SkesteFont.demibold(8), color: Palette.lime)
        pulse.tracked(1.4)
        addSubview(pulse)
        pulse.snp.makeConstraints { make in
            make.leading.equalTo(iconHost.snp.trailing).offset(9)
            make.top.equalTo(iconHost).offset(1)
        }

        addSubview(resortLabel)
        resortLabel.snp.makeConstraints { make in
            make.leading.equalTo(pulse)
            make.top.equalTo(pulse.snp.bottom).offset(2)
        }

        addSubview(updatedLabel)
        updatedLabel.tracked(1.1)
        updatedLabel.snp.makeConstraints { make in
            make.leading.equalTo(pulse)
            make.top.equalTo(resortLabel.snp.bottom).offset(1)
        }

        let arrow = UIImageView(image: UIImage(systemName: "arrow.up.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold)))
        arrow.tintColor = Palette.secondary
        addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(14)
        }

        let metrics = UIStackView()
        metrics.axis = .horizontal
        metrics.distribution = .fillEqually
        metrics.alignment = .center
        metrics.spacing = 10
        addSubview(metrics)
        metrics.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalTo(iconHost.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-12)
        }

        let tempColumn = metricColumn(value: tempLabel, kicker: UILabel(text: "AIR", font: SkesteFont.demibold(7), color: Palette.muted))
        snowKicker.textAlignment = .center
        let snowColumn = UIStackView(arrangedSubviews: [snowLabel, snowKicker])
        snowColumn.axis = .vertical
        snowColumn.alignment = .center
        snowColumn.spacing = 0
        windKicker.textAlignment = .center
        let windColumn = UIStackView(arrangedSubviews: [windLabel, windKicker])
        windColumn.axis = .vertical
        windColumn.alignment = .center
        windColumn.spacing = 0

        metrics.addArrangedSubview(tempColumn)
        metrics.addArrangedSubview(snowColumn)
        metrics.addArrangedSubview(windColumn)
        resortLabel.text = "—"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func metricColumn(value: UILabel, kicker: UILabel) -> UIStackView {
        kicker.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [value, kicker])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 0
        return stack
    }

    func configure(resort: String) {
        let template = SnowLibrary.resort(named: resort)
        let key = template?.name ?? SnowLibrary.resorts[0].name
        let data = SnowReportStore.shared.resort(named: key)
        resortLabel.text = template == nil ? key : resort
        tempLabel.text = "\(data.tempC)°"
        snowLabel.text = "\(data.freshCM)cm"
        windLabel.text = "\(data.windKPH)"
        snowKicker.text = data.reportSource.isWeatherKitData ? "SNOW TODAY" : "FRESH / 24H"

        switch data.reportSource {
        case .live:
            updatedLabel.text = "LIVE \(timeLabel(data.reportUpdatedAt, timeZone: data.timeZone)) LOCAL · APPLE WEATHER"
            updatedLabel.textColor = Palette.muted
        case .cached:
            updatedLabel.text = "LAST LIVE \(timeLabel(data.reportUpdatedAt, timeZone: data.timeZone)) LOCAL · APPLE WEATHER"
            updatedLabel.textColor = Palette.amber
        case .sample:
            updatedLabel.text = "SAMPLE DATA"
            updatedLabel.textColor = Palette.amber
        }
        accessibilityLabel = "Open Snow Desk. \(data.name), \(data.tempC) degrees, \(data.freshCM) centimeters snow, wind \(data.windKPH) kilometers per hour. \(updatedLabel.text ?? "")"
    }

    private func timeLabel(_ date: Date?, timeZone: TimeZone) -> String {
        guard let date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    @objc private func tapped() {
        SkesteHaptics.light()
        onTap?()
    }

    override func accessibilityActivate() -> Bool {
        tapped()
        return true
    }
}

final class PostActionButton: UIControl {
    private let iconView = UIImageView()
    private let countLabel = UILabel(text: "0", font: SkesteFont.demibold(11), color: Palette.secondary)
    private let stack = UIStackView()
    private let baseTint: UIColor
    private let activeTint: UIColor
    private(set) var isActive = false

    init(symbol: String, tint: UIColor, activeTint: UIColor) {
        baseTint = tint
        self.activeTint = activeTint
        super.init(frame: .zero)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 5
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        iconView.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        iconView.tintColor = tint
        iconView.contentMode = .scaleAspectFit
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(countLabel)
        iconView.snp.makeConstraints { $0.width.height.equalTo(18) }
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        snp.makeConstraints { make in
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(36)
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(count: Int, active: Bool, symbol: String? = nil) {
        countLabel.text = count > 0 ? count.compactCount : ""
        countLabel.isHidden = count == 0
        isActive = active
        if let symbol {
            iconView.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        }
        iconView.tintColor = active ? activeTint : baseTint
        countLabel.textColor = active ? activeTint : Palette.secondary
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.13) {
                self.alpha = self.isHighlighted ? 0.55 : 1
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
            }
        }
    }
}

final class AccentLineView: UIView {
    private let gradient = CAGradientLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.colors = SkesteGradient.signature.map(\.cgColor)
        layer.addSublayer(gradient)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        gradient.cornerRadius = bounds.height / 2
    }
    func setColors(_ colors: [UIColor]) {
        gradient.colors = colors.map(\.cgColor)
    }
}

final class PostCardView: UIView {
    var onOpen: (() -> Void)?
    var onAuthor: (() -> Void)?
    var onLike: (() -> Void)?
    var onComment: (() -> Void)?
    var onGift: (() -> Void)?
    var onMore: (() -> Void)?

    private let card = UIView()
    private let topLine = AccentLineView()
    private let avatar = AvatarView(size: 34, showsRing: false)
    private let nameLabel = UILabel(text: nil, font: SkesteFont.demibold(13), color: Palette.text)
    private let metaLabel = UILabel(text: nil, font: SkesteFont.medium(10), color: Palette.muted)
    private let authorButton = UIControl()
    private let moreButton = SkesteControls.iconButton(symbol: "ellipsis", diameter: 30)
    private let captionLabel = UILabel(text: nil, font: SkesteFont.body(15), color: Palette.text, lines: 4)
    private let tagsLabel = UILabel(text: nil, font: SkesteFont.demibold(10), color: Palette.cyan)
    private let mediaContainer = UIView()
    private let mediaPreview = MediaPreviewView()
    private let mediaKindLabel = SkesteTagLabel(text: "LINE DROP", tint: .white, fill: UIColor(hex: "060607").withAlphaComponent(0.58))
    private let mediaCountLabel = SkesteTagLabel(text: "+2", tint: .white, fill: UIColor(hex: "060607").withAlphaComponent(0.58))
    private let likeButton = PostActionButton(symbol: "heart", tint: Palette.secondary, activeTint: Palette.magenta)
    private let commentButton = PostActionButton(symbol: "bubble.left", tint: Palette.secondary, activeTint: Palette.cyan)
    private let giftButton = PostActionButton(symbol: "gift", tint: Palette.secondary, activeTint: Palette.amber)
    private let indexLabel = UILabel(text: "01", font: SkesteFont.mono(9, weight: .bold), color: Palette.muted)
    private let kindLabel = UILabel(text: "FIELD NOTE", font: SkesteFont.demibold(8), color: Palette.muted)
    private var mediaAspect: NSLayoutConstraint?
    private var post: Post?

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.applyGlass(cornerRadius: 16, borderAlpha: 0.10, fill: Palette.glass)
        addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.addSubview(topLine)
        topLine.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
            make.top.equalToSuperview().offset(0)
            make.height.equalTo(2)
        }

        let header = UIView()
        card.addSubview(header)
        header.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalToSuperview().offset(14)
        }

        authorButton.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        let textStack = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        textStack.axis = .vertical
        textStack.spacing = 0
        textStack.isUserInteractionEnabled = false
        authorButton.addSubview(textStack)
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(9)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        authorButton.addAction(UIAction { [weak self] _ in
            self?.onAuthor?()
        }, for: .touchUpInside)
        header.addSubview(authorButton)
        moreButton.addAction(UIAction { [weak self] _ in
            self?.onMore?()
        }, for: .touchUpInside)
        header.addSubview(moreButton)
        authorButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualTo(moreButton.snp.leading).offset(-10)
        }
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        header.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(34)
        }

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 11
        card.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalTo(header.snp.bottom).offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        captionLabel.numberOfLines = 4
        captionLabel.isUserInteractionEnabled = true
        let captionTap = UITapGestureRecognizer(target: self, action: #selector(openTapped))
        captionLabel.addGestureRecognizer(captionTap)
        contentStack.addArrangedSubview(captionLabel)

        mediaContainer.layer.cornerRadius = 21
        mediaContainer.layer.cornerCurve = .continuous
        mediaContainer.clipsToBounds = true
        mediaPreview.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addSubview(mediaPreview)
        mediaPreview.snp.makeConstraints { $0.edges.equalToSuperview() }
        mediaKindLabel.insets = UIEdgeInsets(top: 6, left: 9, bottom: 6, right: 9)
        mediaContainer.addSubview(mediaKindLabel)
        mediaKindLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(10)
        }
        mediaCountLabel.insets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        mediaContainer.addSubview(mediaCountLabel)
        mediaCountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(10)
        }
        let mediaTap = UITapGestureRecognizer(target: self, action: #selector(openTapped))
        mediaContainer.addGestureRecognizer(mediaTap)
        mediaContainer.isUserInteractionEnabled = true
        contentStack.addArrangedSubview(mediaContainer)
        mediaAspect = NSLayoutConstraint(item: mediaContainer, attribute: .height, relatedBy: .equal, toItem: mediaContainer, attribute: .width, multiplier: 1.15, constant: 0)
        mediaAspect?.isActive = true

        contentStack.addArrangedSubview(tagsLabel)

        let footer = UIView()
        let actions = UIStackView()
        actions.axis = .horizontal
        actions.alignment = .center
        actions.spacing = 17
        footer.addSubview(actions)
        actions.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview().offset(-2)
        }
        likeButton.addAction(UIAction { [weak self] _ in self?.onLike?() }, for: .touchUpInside)
        commentButton.addAction(UIAction { [weak self] _ in self?.onComment?() }, for: .touchUpInside)
        giftButton.addAction(UIAction { [weak self] _ in self?.onGift?() }, for: .touchUpInside)
        actions.addArrangedSubview(likeButton)
        actions.addArrangedSubview(commentButton)
        actions.addArrangedSubview(giftButton)

        footer.addSubview(indexLabel)
        indexLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-1)
            make.top.equalToSuperview().offset(2)
        }
        kindLabel.tracked(1.2)
        footer.addSubview(kindLabel)
        kindLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-1)
            make.top.equalTo(indexLabel.snp.bottom).offset(1)
        }
        contentStack.addArrangedSubview(footer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func openTapped() {
        SkesteHaptics.light()
        onOpen?()
    }

    func configure(post: Post, index: Int) {
        self.post = post
        let author = AppStore.shared.user(withID: post.authorID)
        avatar.configure(user: author)
        nameLabel.text = author?.displayName ?? "Skeste Rider"
        metaLabel.text = "\(post.createdAt.skesteRelative)  ·  \(post.location)"
        indexLabel.text = String(format: "%02d", index + 1)
        kindLabel.text = post.kind == .reel ? "LINE DROP" : "FIELD NOTE"
        topLine.setColors(post.kind == .reel ? [Palette.magenta, Palette.magenta] : [Palette.cyan, Palette.cyan])

        if post.caption.isEmpty {
            captionLabel.isHidden = true
        } else {
            captionLabel.isHidden = false
            let lineSpacing: CGFloat = post.media.isEmpty ? 6 : 3
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = lineSpacing
            captionLabel.attributedText = NSAttributedString(string: post.caption, attributes: [
                .font: post.media.isEmpty ? SkesteFont.medium(19) : SkesteFont.body(15),
                .foregroundColor: Palette.text,
                .paragraphStyle: paragraph
            ])
            captionLabel.numberOfLines = post.media.isEmpty ? 0 : 4
        }

        tagsLabel.text = post.tags.prefix(4).map { "#\($0)" }.joined(separator: "   ")
        tagsLabel.isHidden = post.tags.isEmpty

        if let first = post.media.first {
            mediaContainer.isHidden = false
            mediaAspect?.isActive = false
            mediaAspect = NSLayoutConstraint(item: mediaContainer, attribute: .height, relatedBy: .equal, toItem: mediaContainer, attribute: .width, multiplier: post.kind == .reel ? 1.12 : 0.78, constant: 0)
            mediaAspect?.isActive = true
            mediaPreview.configure(with: first)
            mediaKindLabel.text = first.kind == .video ? "PLAY LINE" : "FIELD NOTE"
            mediaCountLabel.isHidden = post.media.count < 2
            mediaCountLabel.text = "+\(post.media.count - 1)"
        } else {
            mediaContainer.isHidden = true
            if let mediaAspect { mediaAspect.isActive = false }
        }

        likeButton.configure(count: post.likeCount, active: AppStore.shared.isLiked(postID: post.id), symbol: AppStore.shared.isLiked(postID: post.id) ? "heart.fill" : "heart")
        commentButton.configure(count: AppStore.shared.commentCount(for: post.id), active: false, symbol: "bubble.left")
        giftButton.configure(count: post.giftCount, active: false, symbol: "gift")
        accessibilityLabel = "\(author?.displayName ?? "Rider"), \(post.caption)"
    }

    @objc private func likeTapped() {
        onLike?()
    }
}

final class SpotlightCell: UICollectionViewCell {
    static let reuseIdentifier = "SpotlightCell"

    var onOpen: (() -> Void)?
    var onAuthor: (() -> Void)?
    var onLike: (() -> Void)?
    var onComment: (() -> Void)?
    var onGift: (() -> Void)?

    private let card = UIView()
    private let media = MediaPreviewView()
    private let shade = CAGradientLayer()
    private let avatar = AvatarView(size: 36, showsRing: true)
    private let nameLabel = UILabel(text: nil, font: SkesteFont.demibold(13), color: .white)
    private let handleLabel = UILabel(text: nil, font: SkesteFont.medium(10), color: UIColor.white.withAlphaComponent(0.65))
    private let authorButton = UIControl()
    private let indexLabel = UILabel(text: "01", font: SkesteFont.mono(10, weight: .bold), color: .white)
    private let kindLabel = SkesteTagLabel(text: "FEATURED LINE", tint: .white, fill: UIColor(hex: "060607").withAlphaComponent(0.46))
    private let locationLabel = SkesteTagLabel(text: "CHAMONIX", tint: Palette.ice, fill: UIColor(hex: "060607").withAlphaComponent(0.38))
    private let captionLabel = UILabel(text: nil, font: SkesteFont.medium(20), color: .white, lines: 3)
    private let tagsLabel = UILabel(text: nil, font: SkesteFont.demibold(9), color: Palette.cyan)
    private let likeButton = PostActionButton(symbol: "heart", tint: .white, activeTint: Palette.magenta)
    private let commentButton = PostActionButton(symbol: "bubble.left", tint: .white, activeTint: Palette.cyan)
    private let giftButton = PostActionButton(symbol: "gift", tint: .white, activeTint: Palette.amber)
    private(set) var isActive = false
    private var post: Post?

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        card.clipsToBounds = true
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        media.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(media)
        media.snp.makeConstraints { $0.edges.equalToSuperview() }
        shade.colors = [
            UIColor(hex: "060607").withAlphaComponent(0.72).cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor(hex: "060607").withAlphaComponent(0.18).cgColor,
            UIColor(hex: "060607").withAlphaComponent(0.94).cgColor
        ]
        shade.locations = [0, 0.18, 0.42, 0.6, 1]
        card.layer.addSublayer(shade)

        let topRow = UIStackView(arrangedSubviews: [kindLabel, locationLabel])
        topRow.axis = .horizontal
        topRow.spacing = 7
        card.addSubview(topRow)
        topRow.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(15)
            make.top.equalToSuperview().offset(15)
        }

        indexLabel.attributedText = NSAttributedString(string: "01", attributes: [.font: SkesteFont.mono(10, weight: .bold), .foregroundColor: UIColor.white, .kern: 1.4])
        card.addSubview(indexLabel)
        indexLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(18)
        }

        let bottomStack = UIStackView()
        bottomStack.axis = .vertical
        bottomStack.spacing = 10
        card.addSubview(bottomStack)
        bottomStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }

        tagsLabel.text = "#FREERIDE  #FIRSTLIGHT"
        bottomStack.addArrangedSubview(tagsLabel)

        let captionTap = UITapGestureRecognizer(target: self, action: #selector(openTapped))
        captionLabel.addGestureRecognizer(captionTap)
        captionLabel.isUserInteractionEnabled = true
        bottomStack.addArrangedSubview(captionLabel)

        authorButton.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        let authorText = UIStackView(arrangedSubviews: [nameLabel, handleLabel])
        authorText.axis = .vertical
        authorText.spacing = 0
        authorText.isUserInteractionEnabled = false
        authorButton.addSubview(authorText)
        authorText.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(9)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        authorButton.addAction(UIAction { [weak self] _ in
            self?.onAuthor?()
        }, for: .touchUpInside)
        authorButton.snp.makeConstraints { $0.height.equalTo(36) }

        let actions = UIStackView()
        actions.axis = .horizontal
        actions.alignment = .center
        actions.spacing = 17
        likeButton.addAction(UIAction { [weak self] _ in self?.onLike?() }, for: .touchUpInside)
        commentButton.addAction(UIAction { [weak self] _ in self?.onComment?() }, for: .touchUpInside)
        giftButton.addAction(UIAction { [weak self] _ in self?.onGift?() }, for: .touchUpInside)
        actions.addArrangedSubview(likeButton)
        actions.addArrangedSubview(commentButton)
        actions.addArrangedSubview(giftButton)
        let spacer = UIView()
        actions.addArrangedSubview(spacer)

        let openButton = UIButton(type: .system)
        openButton.setImage(UIImage(systemName: "arrow.up.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)), for: .normal)
        openButton.tintColor = Palette.ink
        openButton.backgroundColor = Palette.frost
        openButton.layer.cornerRadius = 10
        openButton.addAction(UIAction { [weak self] _ in self?.onOpen?() }, for: .touchUpInside)
        openButton.snp.makeConstraints { $0.width.height.equalTo(38) }
        actions.addArrangedSubview(openButton)

        let footer = UIStackView(arrangedSubviews: [authorButton, actions])
        footer.axis = .vertical
        footer.spacing = 8
        bottomStack.addArrangedSubview(footer)

        let mediaTap = UITapGestureRecognizer(target: self, action: #selector(openTapped))
        media.addGestureRecognizer(mediaTap)
        media.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shade.frame = card.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        media.setPlaybackActive(false)
    }

    @objc private func openTapped() {
        onOpen?()
    }

    func configure(post: Post, index: Int, active: Bool) {
        self.post = post
        self.isActive = active
        let author = AppStore.shared.user(withID: post.authorID)
        avatar.configure(user: author)
        nameLabel.text = author?.displayName ?? "Skeste Rider"
        handleLabel.text = "\(author?.handle ?? "@skeste")  ·  \(post.createdAt.skesteRelative)"
        captionLabel.text = post.caption
        tagsLabel.text = post.tags.prefix(3).map { "#\($0.uppercased())" }.joined(separator: "  ")
        locationLabel.text = post.location.uppercased()
        indexLabel.attributedText = NSAttributedString(string: String(format: "%02d", index + 1), attributes: [.font: SkesteFont.mono(10, weight: .bold), .foregroundColor: UIColor.white, .kern: 1.4])
        if let first = post.media.first {
            media.configure(with: first, allowsPlayback: active)
        }
        likeButton.configure(count: post.likeCount, active: AppStore.shared.isLiked(postID: post.id), symbol: AppStore.shared.isLiked(postID: post.id) ? "heart.fill" : "heart")
        commentButton.configure(count: AppStore.shared.commentCount(for: post.id), active: false, symbol: "bubble.left")
        giftButton.configure(count: post.giftCount, active: false, symbol: "gift")
    }

    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        media.setPlaybackActive(active)
    }
}
