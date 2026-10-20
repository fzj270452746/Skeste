import UIKit
import SnapKit

final class MessageRowView: UIView {
    private let bubble = UIView()
    private let bubbleGradient = CAGradientLayer()
    private let messageLabel = UILabel(text: nil, font: SkesteFont.body(14), color: Palette.text, lines: 0)
    private let timeLabel = UILabel(text: nil, font: SkesteFont.medium(8), color: Palette.muted)
    private let avatar = AvatarView(size: 28, showsRing: false)
    private let isOutgoing: Bool

    init(message: ChatMessage, sender: User?, isOutgoing: Bool) {
        self.isOutgoing = isOutgoing
        super.init(frame: .zero)
        messageLabel.text = message.text
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 128
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        messageLabel.attributedText = NSAttributedString(string: message.text, attributes: [
            .font: SkesteFont.body(14),
            .foregroundColor: Palette.text,
            .paragraphStyle: paragraph
        ])
        timeLabel.text = message.createdAt.chatTime

        bubble.layer.cornerRadius = 19
        bubble.layer.cornerCurve = .continuous
        bubble.clipsToBounds = true
        addSubview(bubble)
        bubble.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))
        }
        addSubview(timeLabel)

        if isOutgoing {
            bubbleGradient.colors = SkesteGradient.signature.map(\.cgColor)
            bubbleGradient.startPoint = CGPoint(x: 0, y: 0)
            bubbleGradient.endPoint = CGPoint(x: 1, y: 1)
            bubble.layer.insertSublayer(bubbleGradient, at: 0)
            bubble.layer.borderWidth = 1
            bubble.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
            bubble.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-4)
                make.top.equalToSuperview().offset(2)
                make.leading.greaterThanOrEqualToSuperview().offset(60)
            }
            timeLabel.snp.makeConstraints { make in
                make.trailing.equalTo(bubble)
                make.top.equalTo(bubble.snp.bottom).offset(3)
                make.bottom.equalToSuperview()
            }
        } else {
            bubble.backgroundColor = Palette.glass
            bubble.layer.borderWidth = 1
            bubble.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
            avatar.configure(user: sender)
            addSubview(avatar)
            avatar.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.bottom.equalTo(bubble).offset(2)
            }
            bubble.snp.makeConstraints { make in
                make.leading.equalTo(avatar.snp.trailing).offset(8)
                make.top.equalToSuperview()
                make.trailing.lessThanOrEqualToSuperview().offset(-40)
            }
            timeLabel.snp.makeConstraints { make in
                make.leading.equalTo(bubble).offset(4)
                make.top.equalTo(bubble.snp.bottom).offset(3)
                make.bottom.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bubbleGradient.frame = bubble.bounds
        bubbleGradient.cornerRadius = 19
    }
}

final class ChatDetailViewController: BaseViewController {
    private let conversationID: String
    private let source: RootTab
    private let scrollView = UIScrollView()
    private let messagesStack = UIStackView()
    private let inputBar = UIView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private var inputBottomConstraint: Constraint?
    private var didBuild = false

    init(conversationID: String, source: RootTab) {
        self.conversationID = conversationID
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        guard let conversation = AppStore.shared.conversation(withID: conversationID) else {
            showEmptyChat()
            return
        }
        _ = conversation
        buildHeader()
        buildMessages()
        buildInput()
        registerKeyboard()
        AppStore.shared.markConversationRead(id: conversationID)
        reloadMessages(scrollToBottom: true)
        didBuild = true
    }

    override func refreshView() {
        guard didBuild else { return }
        if AppStore.shared.conversation(withID: conversationID) == nil {
            navigationController?.popViewController(animated: true)
            return
        }
        reloadMessages(scrollToBottom: true)
    }

    override func authDidChange() {
        guard AppStore.shared.isLoggedIn else {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        reloadMessages(scrollToBottom: true)
    }

    private func showEmptyChat() {
        let label = UILabel(text: "This private line is no longer available.", font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
        label.textAlignment = .center
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(30)
        }
    }

    private func currentConversation() -> Conversation? {
        AppStore.shared.conversation(withID: conversationID)
    }

    private func peer() -> User? {
        guard let conversation = currentConversation(), let current = AppStore.shared.currentUser?.id, let other = conversation.otherUserID(for: current) else { return nil }
        return AppStore.shared.user(withID: other)
    }

    private func buildHeader() {
        let header = UIView()
        header.backgroundColor = Palette.canvas.withAlphaComponent(0.94)
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.height.equalTo(58)
        }
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 38)
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        header.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }

        let user = peer()
        let avatar = AvatarView(size: 38, showsRing: true)
        avatar.configure(user: user)
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        header.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalTo(back.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }

        let name = UILabel(text: user?.displayName ?? "Private Line", font: SkesteFont.demibold(14), color: Palette.text)
        let status = UILabel(text: "PRIVATE LINE  ·  YOUR CIRCLE", font: SkesteFont.demibold(8), color: Palette.lime)
        status.tracked(1.2)
        let stack = UIStackView(arrangedSubviews: [name, status])
        stack.axis = .vertical
        stack.spacing = 0
        stack.isUserInteractionEnabled = false
        header.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(9)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-102)
        }

        let more = SkesteControls.iconButton(symbol: "ellipsis", diameter: 38)
        more.addAction(UIAction { [weak self] _ in self?.showMore() }, for: .touchUpInside)
        header.addSubview(more)
        more.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }

        let video = SkesteControls.iconButton(symbol: "video.fill", diameter: 38)
        video.tintColor = Palette.cyan
        video.addAction(UIAction { [weak self] _ in self?.startVideoCall() }, for: .touchUpInside)
        header.addSubview(video)
        video.snp.makeConstraints { make in
            make.trailing.equalTo(more.snp.leading).offset(-7)
            make.centerY.equalToSuperview()
        }

        let hairline = UIView()
        hairline.backgroundColor = Palette.hairline
        view.addSubview(hairline)
        hairline.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(header.snp.bottom)
            make.height.equalTo(1)
        }
    }

    private func buildMessages() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(59)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        messagesStack.axis = .vertical
        messagesStack.spacing = 10
        scrollView.addSubview(messagesStack)
        messagesStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-100)
            make.width.equalTo(scrollView.snp.width).offset(-32)
        }
    }

    private func buildInput() {
        inputBar.backgroundColor = Palette.midnight
        inputBar.layer.cornerRadius = 14
        inputBar.layer.cornerCurve = .continuous
        inputBar.layer.borderWidth = 1
        inputBar.layer.borderColor = Palette.hairline.cgColor
        view.addSubview(inputBar)
        inputBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.trailing.equalToSuperview().offset(-14)
            make.height.equalTo(62)
            inputBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-6).constraint
        }

        inputField.attributedPlaceholder = NSAttributedString(string: "Send a signal…", attributes: [.foregroundColor: Palette.muted, .font: SkesteFont.body(14)])
        inputField.font = SkesteFont.body(14)
        inputField.textColor = Palette.text
        inputField.tintColor = Palette.cyan
        inputField.backgroundColor = Palette.glassStrong
        inputField.layer.cornerRadius = 10
        inputField.layer.cornerCurve = .continuous
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        inputField.leftViewMode = .always
        inputField.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        sendButton.backgroundColor = Palette.hairline
        sendButton.layer.cornerRadius = 10
        sendButton.setImage(UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)), for: .normal)
        sendButton.tintColor = Palette.muted
        sendButton.addAction(UIAction { [weak self] _ in self?.send() }, for: .touchUpInside)
        inputBar.addSubview(sendButton)
        inputBar.addSubview(inputField)
        inputField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(11)
            make.centerY.equalToSuperview()
            make.height.equalTo(42)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
        }
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-11)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(38)
        }
    }

    @objc private func fieldChanged() {
        let hasText = !(inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        sendButton.backgroundColor = hasText ? Palette.magenta : Palette.hairline
        sendButton.tintColor = hasText ? .white : Palette.muted
    }

    private func registerKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHidden(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardChanged(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY)
        let offset = -(max(0, overlap - view.safeAreaInsets.bottom))
        inputBottomConstraint?.update(offset: offset)
        scrollView.contentInset.bottom = overlap
        UIView.animate(withDuration: 0.24) { self.view.layoutIfNeeded() }
        scrollMessagesToBottom(animated: true)
    }

    @objc private func keyboardHidden(_ note: Notification) {
        inputBottomConstraint?.update(offset: -6)
        scrollView.contentInset.bottom = 0
        UIView.animate(withDuration: 0.24) { self.view.layoutIfNeeded() }
    }

    private func reloadMessages(scrollToBottom: Bool) {
        guard let conversation = currentConversation(), let current = AppStore.shared.currentUser?.id else { return }
        messagesStack.arrangedSubviews.forEach {
            messagesStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let tag = SkesteTagLabel(text: "PRIVATE  ·  \(peer()?.displayName.uppercased() ?? "RIDE CIRCLE")", tint: Palette.ice, fill: Palette.glass)
        tag.textAlignment = .center
        let tagWrap = UIView()
        tagWrap.addSubview(tag)
        tag.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        messagesStack.addArrangedSubview(tagWrap)
        messagesStack.setCustomSpacing(22, after: tagWrap)

        if conversation.messages.isEmpty {
            let empty = UILabel(text: "This line is yours. Say hey.", font: SkesteFont.body(13), color: Palette.muted)
            empty.textAlignment = .center
            messagesStack.addArrangedSubview(empty)
            scrollMessagesToBottom(animated: false)
            return
        }
        for message in conversation.messages {
            let row = MessageRowView(message: message, sender: AppStore.shared.user(withID: message.senderID), isOutgoing: message.senderID == current)
            messagesStack.addArrangedSubview(row)
            messagesStack.setCustomSpacing(9, after: row)
        }
        if scrollToBottom {
            DispatchQueue.main.async { self.scrollMessagesToBottom(animated: false) }
        }
    }

    private func scrollMessagesToBottom(animated: Bool) {
        view.layoutIfNeeded()
        let bottom = max(0, scrollView.contentSize.height - scrollView.bounds.height + scrollView.contentInset.bottom)
        if bottom > 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: bottom), animated: animated)
        }
    }

    private func send() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        guard let other = peer(), AppStore.shared.canChat(with: other.id) else {
            showToast("This rider is outside your circle.", style: .error)
            return
        }
        AppStore.shared.sendMessage(conversationID: conversationID, text: text)
        inputField.text = ""
        fieldChanged()
        SkesteHaptics.light()
        reloadMessages(scrollToBottom: true)
    }

    @objc private func avatarTapped() {
        guard let user = peer() else { return }
        push(UserProfileViewController(userID: user.id, source: .chats))
    }

    private func startVideoCall() {
        guard let user = peer() else { return }
        let call = VideoCallViewController(peer: user)
        call.modalPresentationStyle = .fullScreen
        present(call, animated: true)
    }

    private func showMore() {
        guard let user = peer(), let conversation = currentConversation() else { return }
        let actions: [SkesteSheetAction] = [
            SkesteSheetAction(title: "View profile", symbol: "person.crop.circle") { [weak self] in
                self?.push(UserProfileViewController(userID: user.id, source: .chats))
            },
            SkesteSheetAction(title: "Report conversation", symbol: "flag", destructive: false) { [weak self] in
                self?.push(ReportViewController(target: .conversation(conversationID: conversation.id, otherUserID: user.id), source: .chats))
            },
            SkesteSheetAction(title: "Block this rider", symbol: "hand.raised", destructive: true) { [weak self] in
                self?.showConfirm(title: "Block \(user.displayName)?", message: "This rider and their content will leave your mountain. This cannot be undone.", confirmTitle: "Block rider", destructive: true) {
                    AppStore.shared.removeUserAndData(userID: user.id)
                    self?.returnToRootTab(.chats)
                    SkesteToast.show("Rider blocked and removed.", style: .success)
                }
            }
        ]
        present(SkesteActionSheetViewController(heading: "PRIVATE LINE", message: nil, actions: actions), animated: true)
    }
}
