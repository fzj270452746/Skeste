import UIKit
import SnapKit

final class SignalBarsView: UIView {
    private var bars: [UIView] = []
    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 3
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let heights: [CGFloat] = [8, 14, 22, 11, 18, 7]
        for (index, height) in heights.enumerated() {
            let bar = UIView()
            bar.backgroundColor = index % 2 == 0 ? Palette.lime : Palette.cyan
            bar.layer.cornerRadius = 1.5
            stack.addArrangedSubview(bar)
            bar.snp.makeConstraints { make in
                make.width.equalTo(3)
                make.height.equalTo(height)
            }
            bars.append(bar)
        }
        startAnimating()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startAnimating() {
        for (index, bar) in bars.enumerated() {
            let animation = CABasicAnimation(keyPath: "transform.scale.y")
            animation.fromValue = 0.55
            animation.toValue = 1.15
            animation.duration = 0.65 + Double(index) * 0.13
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            bar.layer.add(animation, forKey: "signal")
        }
    }
}

final class ConversationRowView: UIControl {
    private let avatar = AvatarView(size: 52, showsRing: true)
    private let nameLabel = UILabel(text: nil, font: SkesteFont.demibold(15), color: Palette.text)
    private let messageLabel = UILabel(text: nil, font: SkesteFont.body(12), color: Palette.secondary, lines: 1)
    private let timeLabel = UILabel(text: nil, font: SkesteFont.medium(9), color: Palette.muted)
    private let unreadBadge = UIView()
    private let unreadLabel = UILabel(text: nil, font: SkesteFont.mono(8, weight: .bold), color: UIColor(hex: "0A0A0B"))
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)))

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlass(cornerRadius: 14, borderAlpha: 0.08, fill: Palette.glass)
        addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
        }
        addSubview(nameLabel)
        addSubview(messageLabel)
        addSubview(timeLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(11)
            make.top.equalToSuperview().offset(15)
            make.trailing.lessThanOrEqualTo(timeLabel.snp.leading).offset(-8)
        }
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-34)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalToSuperview().offset(16)
        }
        chevron.tintColor = Palette.muted
        addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-16)
        }
        unreadBadge.backgroundColor = Palette.magenta
        unreadBadge.layer.cornerRadius = 9
        addSubview(unreadBadge)
        unreadBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(18)
        }
        unreadLabel.textAlignment = .center
        unreadBadge.addSubview(unreadLabel)
        unreadLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)) }
        snp.makeConstraints { $0.height.equalTo(78) }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.14) { self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity }
        }
    }

    func configure(conversation: Conversation, currentUserID: String) {
        guard let otherID = conversation.otherUserID(for: currentUserID),
              let user = AppStore.shared.user(withID: otherID) else { return }
        avatar.configure(user: user)
        nameLabel.text = user.displayName
        let last = AppStore.shared.lastMessage(in: conversation)
        messageLabel.text = last?.text ?? "Start the conversation."
        timeLabel.text = (last?.createdAt ?? conversation.updatedAt).chatTime
        let unread = conversation.unreadCount
        unreadBadge.isHidden = unread == 0
        unreadLabel.text = "\(unread)"
        chevron.isHidden = unread > 0
        accessibilityLabel = "\(user.displayName). \(messageLabel.text ?? "")"
    }
}

final class RiderSuggestionCard: UIControl {
    private let avatar = AvatarView(size: 62, showsRing: true)
    private let nameLabel = UILabel(text: nil, font: SkesteFont.demibold(12), color: Palette.text)
    private let handleLabel = UILabel(text: nil, font: SkesteFont.medium(9), color: Palette.muted)
    private let statusPill = SkesteTagLabel(text: "RIDE", tint: Palette.ice, fill: Palette.glassStrong)

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlass(cornerRadius: 14, borderAlpha: 0.09, fill: Palette.glass)
        addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(14)
        }
        nameLabel.textAlignment = .center
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(6)
            make.top.equalTo(avatar.snp.bottom).offset(8)
        }
        handleLabel.textAlignment = .center
        addSubview(handleLabel)
        handleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(6)
            make.top.equalTo(nameLabel.snp.bottom).offset(0)
        }
        statusPill.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        addSubview(statusPill)
        statusPill.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(handleLabel.snp.bottom).offset(7)
        }
        snp.makeConstraints { make in
            make.width.equalTo(112)
            make.height.equalTo(156)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(user: User) {
        avatar.configure(user: user)
        nameLabel.text = user.displayName.components(separatedBy: " ").first ?? user.displayName
        handleLabel.text = user.handle
        if AppStore.shared.canChat(with: user.id) {
            statusPill.text = "CIRCLE"
            statusPill.textColor = Palette.lime
        } else if AppStore.shared.hasIncomingRequest(from: user.id) {
            statusPill.text = "REQUEST"
            statusPill.textColor = Palette.amber
        } else {
            statusPill.text = "VIEW"
            statusPill.textColor = Palette.ice
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.14) { self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity }
        }
    }
}

final class RideRequestRow: UIView {
    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?
    private let avatar = AvatarView(size: 42, showsRing: true)
    private let name = UILabel(text: nil, font: SkesteFont.demibold(13), color: Palette.text)
    private let detail = UILabel(text: nil, font: SkesteFont.body(10), color: Palette.muted, lines: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlass(cornerRadius: 20, borderAlpha: 0.08, fill: Palette.glass)
        addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }
        addSubview(name)
        name.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(12)
        }
        addSubview(detail)
        detail.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(name.snp.bottom).offset(2)
            make.trailing.lessThanOrEqualToSuperview().offset(-132)
        }
        let accept = UIButton(type: .system)
        accept.setTitle("ACCEPT", for: .normal)
        accept.setTitleColor(.white, for: .normal)
        accept.titleLabel?.font = SkesteFont.demibold(9)
        accept.backgroundColor = Palette.magenta
        accept.layer.cornerRadius = 14
        accept.addAction(UIAction { [weak self] _ in self?.onAccept?() }, for: .touchUpInside)
        addSubview(accept)
        accept.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.width.equalTo(62)
            make.height.equalTo(28)
        }
        let decline = UIButton(type: .system)
        decline.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)), for: .normal)
        decline.tintColor = Palette.secondary
        decline.addAction(UIAction { [weak self] _ in self?.onDecline?() }, for: .touchUpInside)
        addSubview(decline)
        decline.snp.makeConstraints { make in
            make.trailing.equalTo(accept.snp.leading).offset(-2)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }
        snp.makeConstraints { $0.height.equalTo(64) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(user: User) {
        avatar.configure(user: user)
        name.text = user.displayName
        detail.text = "wants to join your ride circle"
    }
}

final class ChatsViewController: BaseViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var unreadTotal = 0

    override func setupView() {
        NotificationCenter.default.addObserver(self, selector: #selector(chatsChanged), name: .skesteChatsChanged, object: nil)
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
    }

    override func refreshView() {
        rebuild()
    }

    override func authDidChange() {
        rebuild()
    }

    override func contentDidChange() {
        rebuild()
    }

    @objc private func chatsChanged() {
        if isViewLoaded { rebuild() }
    }

    private func rebuild() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        buildHeader()
        guard AppStore.shared.isLoggedIn else {
            buildLockedState()
            return
        }
        let requests = AppStore.shared.incomingRequests
        if !requests.isEmpty {
            buildRequests(requests)
        }
        let suggestions = AppStore.shared.suggestions.filter { user in
            !AppStore.shared.incomingRequests.contains(where: { $0.id == user.id })
        }
        if !suggestions.isEmpty {
            buildSuggestions(suggestions)
        }
        buildConversations()
    }

    private func buildHeader() {
        let header = UIView()
        let top = UIStackView()
        top.axis = .horizontal
        top.alignment = .center
        top.spacing = 8
        let kicker = UILabel(text: "RIDE LINE  /  PRIVATE CIRCLE", font: SkesteFont.demibold(8), color: Palette.cyan)
        kicker.tracked(1.8)
        top.addArrangedSubview(kicker)
        top.addArrangedSubview(UIView())
        let signals = SignalBarsView()
        signals.snp.makeConstraints { make in
            make.width.equalTo(30)
            make.height.equalTo(22)
        }
        top.addArrangedSubview(signals)
        header.addSubview(top)
        top.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }

        let title = UILabel(text: "YOUR\nCIRCLE.", font: SkesteFont.display(36), color: Palette.text, lines: 2)
        title.richTracking(-0.9)
        header.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(top.snp.bottom).offset(8)
        }

        let badge = UIView()
        badge.backgroundColor = Palette.lime
        badge.layer.cornerRadius = 6
        header.addSubview(badge)
        badge.snp.makeConstraints { make in
            make.leading.equalTo(title.snp.trailing).offset(8)
            make.top.equalTo(title.snp.top).offset(7)
            make.width.height.equalTo(12)
        }

        unreadTotal = AppStore.shared.conversations.reduce(0) { $0 + $1.unreadCount }
        let subtitle = UILabel(text: AppStore.shared.isLoggedIn ? "Only friends you have added can reach you. Everything else stays on the mountain." : "A private line for the people you actually ride with.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        subtitle.lineSpacing(3)
        header.addSubview(subtitle)
        subtitle.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview().offset(-34)
            make.top.equalTo(title.snp.bottom).offset(6)
            make.bottom.equalToSuperview()
        }

        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(24, after: header)

        if AppStore.shared.isLoggedIn {
            let meta = UILabel(text: unreadTotal > 0 ? "\(unreadTotal) UNREAD SIGNAL\(unreadTotal == 1 ? "" : "S")" : "ALL SIGNALS READ", font: SkesteFont.mono(8, weight: .bold), color: unreadTotal > 0 ? Palette.lime : Palette.muted)
            meta.tracked(1.5)
            contentStack.addArrangedSubview(meta)
            contentStack.setCustomSpacing(20, after: meta)
        }
    }

    private func buildLockedState() {
        let wrap = UIView()
        let lock = UIImageView(image: UIImage(systemName: "lock.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .light)))
        lock.tintColor = Palette.cyan
        wrap.addSubview(lock)
        lock.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(30)
        }
        let kicker = UILabel(text: "MEMBERS ONLY", font: SkesteFont.demibold(9), color: Palette.magenta)
        kicker.tracked(2)
        kicker.textAlignment = .center
        wrap.addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.top.equalTo(lock.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
        let title = UILabel(text: "THE LINE IS QUIET.", font: SkesteFont.display(24), color: Palette.text, lines: 2)
        title.textAlignment = .center
        wrap.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalTo(kicker.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview()
        }
        let message = UILabel(text: "Sign in to see your conversations, ride requests, and the riders nearby who share your energy.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        message.textAlignment = .center
        message.lineSpacing(3)
        wrap.addSubview(message)
        message.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        let button = GradientButton(title: "ENTER THE CIRCLE", icon: "arrow.right", height: 54)
        button.addAction(UIAction { [weak self] _ in
            self?.requireLogin { [weak self] in
                self?.rebuild()
            }
        }, for: .touchUpInside)
        wrap.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(message.snp.bottom).offset(22)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.equalToSuperview()
        }
        let panel = UIView()
        panel.applyGlass(cornerRadius: 18, borderAlpha: 0.10, fill: Palette.glass)
        panel.addSubview(wrap)
        wrap.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 32, left: 22, bottom: 22, right: 22)) }
        contentStack.addArrangedSubview(panel)
        contentStack.setCustomSpacing(20, after: panel)

        let privacy = UILabel(text: "NO RANDOM CHATS  ·  NO STRANGERS  ·  JUST YOUR PEOPLE", font: SkesteFont.demibold(8), color: Palette.muted)
        privacy.tracked(1.2)
        privacy.textAlignment = .center
        contentStack.addArrangedSubview(privacy)
    }

    private func buildRequests(_ requests: [User]) {
        let heading = SectionHeadingView(kicker: "Waiting on you", title: "RIDE REQUESTS", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(12, after: heading)
        for user in requests {
            let row = RideRequestRow()
            row.configure(user: user)
            row.onAccept = { [weak self] in
                guard let self else { return }
                if let conversation = AppStore.shared.acceptFriendRequest(from: user.id) {
                    SkesteHaptics.success()
                    self.rebuild()
                    self.showToast("You're riding with \(user.displayName).", style: .success)
                    self.openConversation(conversation)
                }
            }
            row.onDecline = { [weak self] in
                AppStore.shared.declineFriendRequest(from: user.id)
                self?.rebuild()
            }
            contentStack.addArrangedSubview(row)
            contentStack.setCustomSpacing(8, after: row)
        }
        contentStack.setCustomSpacing(24, after: contentStack.arrangedSubviews.last ?? heading)
    }

    private func buildSuggestions(_ users: [User]) {
        let heading = SectionHeadingView(kicker: "Fresh energy", title: "DISCOVER RIDERS", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(12, after: heading)

        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.contentInsetAdjustmentBehavior = .never
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 9
        scroll.addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(scroll.snp.height)
        }
        for user in users {
            let card = RiderSuggestionCard()
            card.configure(user: user)
            card.addAction(UIAction { [weak self] _ in
                self?.push(UserProfileViewController(userID: user.id, source: .chats))
            }, for: .touchUpInside)
            row.addArrangedSubview(card)
        }
        contentStack.addArrangedSubview(scroll)
        scroll.snp.makeConstraints { $0.height.equalTo(156) }
        contentStack.setCustomSpacing(26, after: scroll)
    }

    private func buildConversations() {
        let conversations = AppStore.shared.conversations
        let heading = SectionHeadingView(kicker: "Your latest signals", title: "CONVERSATIONS", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(12, after: heading)

        if conversations.isEmpty {
            let wrap = UIView()
            wrap.applyGlass(cornerRadius: 22, borderAlpha: 0.08, fill: Palette.glass)
            let label = UILabel(text: "No conversations yet. Accept a ride request or follow a rider back to open a private line.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
            label.textAlignment = .center
            label.lineSpacing(3)
            wrap.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(22) }
            contentStack.addArrangedSubview(wrap)
            return
        }

        for conversation in conversations {
            let row = ConversationRowView()
            row.configure(conversation: conversation, currentUserID: AppStore.shared.currentUser?.id ?? "")
            row.addAction(UIAction { [weak self] _ in
                self?.openConversation(conversation)
            }, for: .touchUpInside)
            contentStack.addArrangedSubview(row)
            contentStack.setCustomSpacing(9, after: row)
        }
    }

    private func openConversation(_ conversation: Conversation) {
        AppStore.shared.markConversationRead(id: conversation.id)
        push(ChatDetailViewController(conversationID: conversation.id, source: .chats))
    }
}