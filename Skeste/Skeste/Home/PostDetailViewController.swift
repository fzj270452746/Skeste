import UIKit
import SnapKit

final class PostMediaCell: UICollectionViewCell {
    static let reuseIdentifier = "PostMediaCell"
    let preview = MediaPreviewView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(preview)
        preview.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PostMediaCarousel: UIView {
    private let collectionView: UICollectionView
    private let layout = UICollectionViewFlowLayout()
    private let pageLabel = UILabel(text: "01 / 01", font: SkesteFont.mono(9, weight: .bold), color: .white)
    private let pageStack = UIStackView()
    private var bars: [UIView] = []
    private var media: [MediaItem] = []
    private var currentIndex = 0
    var onOpen: ((Int) -> Void)?

    override init(frame: CGRect) {
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "090D1D")
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        clipsToBounds = true

        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(PostMediaCell.self, forCellWithReuseIdentifier: PostMediaCell.reuseIdentifier)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)

        pageLabel.backgroundColor = UIColor(hex: "060607").withAlphaComponent(0.55)
        pageLabel.layer.cornerRadius = 12
        pageLabel.layer.masksToBounds = true
        pageLabel.textAlignment = .center
        addSubview(pageLabel)
        pageLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(12)
            make.width.equalTo(54)
            make.height.equalTo(24)
        }

        pageStack.axis = .horizontal
        pageStack.spacing = 5
        pageStack.alignment = .center
        addSubview(pageStack)
        pageStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(4)
        }
        snp.makeConstraints { $0.height.equalTo(440) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if layout.itemSize != bounds.size {
            layout.itemSize = bounds.size
            layout.invalidateLayout()
        }
    }

    func configure(media: [MediaItem]) {
        self.media = media
        currentIndex = 0
        bars.forEach { $0.removeFromSuperview() }
        bars.removeAll()
        pageStack.arrangedSubviews.forEach {
            pageStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for _ in media {
            let bar = UIView()
            bar.backgroundColor = Palette.hairline
            bar.layer.cornerRadius = 2
            pageStack.addArrangedSubview(bar)
            bar.snp.makeConstraints { $0.width.equalTo(10); $0.height.equalTo(4) }
            bars.append(bar)
        }
        if media.count <= 1 {
            pageStack.isHidden = true
            pageLabel.isHidden = media.count == 0
        }
        updatePage()
        collectionView.reloadData()
    }

    @objc private func handleTap() {
        guard !media.isEmpty else { return }
        onOpen?(currentIndex)
    }

    private func updatePage() {
        pageLabel.text = String(format: "%02d / %02d", currentIndex + 1, max(1, media.count))
        for (index, bar) in bars.enumerated() {
            bar.backgroundColor = index == currentIndex ? Palette.lime : Palette.hairline
        }
    }
}

extension PostMediaCarousel: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        media.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PostMediaCell.reuseIdentifier, for: indexPath) as? PostMediaCell else {
            return UICollectionViewCell()
        }
        cell.preview.configure(with: media[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onOpen?(indexPath.item)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0, !media.isEmpty else { return }
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        if index != currentIndex {
            currentIndex = max(0, min(media.count - 1, index))
            updatePage()
        }
    }
}

final class CommentRowView: UIView {
    let comment: Comment
    var onMore: (() -> Void)?
    var onAvatar: (() -> Void)?

    init(comment: Comment) {
        self.comment = comment
        super.init(frame: .zero)
        let author = SKDataStore.shared.user(withID: comment.authorID)
        let avatarButton = UIControl()
        let avatar = AvatarView(size: 32, showsRing: false)
        avatar.configure(user: author)
        avatarButton.addSubview(avatar)
        avatar.snp.makeConstraints { $0.edges.equalToSuperview() }
        avatarButton.addAction(UIAction { [weak self] _ in self?.onAvatar?() }, for: .touchUpInside)
        addSubview(avatarButton)
        avatarButton.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.height.equalTo(32)
        }

        let name = UILabel(text: author?.displayName ?? "Rider", font: SkesteFont.demibold(12), color: Palette.text)
        addSubview(name)
        name.snp.makeConstraints { make in
            make.leading.equalTo(avatarButton.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(1)
        }

        let time = UILabel(text: comment.createdAt.skesteRelative, font: SkesteFont.medium(9), color: Palette.muted)
        addSubview(time)
        time.snp.makeConstraints { make in
            make.leading.equalTo(name.snp.trailing).offset(7)
            make.centerY.equalTo(name)
        }

        let more = UIButton(type: .system)
        more.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)), for: .normal)
        more.tintColor = Palette.muted
        more.addAction(UIAction { [weak self] _ in self?.onMore?() }, for: .touchUpInside)
        addSubview(more)
        more.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(-4)
            make.width.height.equalTo(30)
        }

        let body = UILabel(text: comment.text, font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
        body.lineSpacing(3)
        addSubview(body)
        body.snp.makeConstraints { make in
            make.leading.equalTo(avatarButton.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-8)
            make.top.equalTo(name.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PostDetailViewController: BaseViewController {
    private let postID: String
    private let focusComments: Bool
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let commentsStack = UIStackView()
    private let inputBar = UIView()
    private let commentField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let inputAvatar = AvatarView(size: 32, showsRing: false)
    private let likeButton = PostActionButton(symbol: "heart", tint: Palette.secondary, activeTint: Palette.magenta)
    private let commentButton = PostActionButton(symbol: "bubble.left", tint: Palette.secondary, activeTint: Palette.cyan)
    private let giftButton = PostActionButton(symbol: "gift", tint: Palette.secondary, activeTint: Palette.amber)
    private let giftCTA = GradientButton(title: "SEND STOKE", icon: "gift.fill", colors: [Palette.amber, Palette.magenta], height: 40, fontSize: 12)
    private let commentsCountLabel = UILabel(text: "COMMENTS", font: SkesteFont.demibold(9), color: Palette.cyan)
    private var inputBottomConstraint: Constraint?
    private var didFocusComments = false
    private var commentsAnchor: UIView?
    private var lastSignature = ""
    private var media: [MediaItem] = []

    init(postID: String, focusComments: Bool = false) {
        self.postID = postID
        self.focusComments = focusComments
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        buildHeader()
        buildScroll()
        buildInput()
        configureActions()
        rebuildContent(preserveOffset: false)
        registerKeyboard()
    }

    override func refreshView() {
        guard SKDataStore.shared.post(withID: postID) != nil else {
            navigationController?.popViewController(animated: true)
            return
        }
        let signature = contentSignature()
        if signature != lastSignature {
            rebuildContent(preserveOffset: true)
        }
        updateInputIdentity()
    }

    override func authDidChange() {
        updateInputIdentity()
        rebuildContent(preserveOffset: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if focusComments, !didFocusComments, let anchor = commentsAnchor {
            didFocusComments = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self else { return }
                let rect = anchor.convert(anchor.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -30), animated: true)
            }
        }
    }

    private func buildHeader() {
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }

        let label = UILabel(text: "THE FULL STORY", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.8)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }

        let more = SkesteControls.iconButton(symbol: "ellipsis", diameter: 40)
        more.addAction(UIAction { [weak self] _ in self?.showPostMenu() }, for: .touchUpInside)
        view.addSubview(more)
        more.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.centerY.equalTo(back)
        }
    }

    private func buildScroll() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(62)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-110)
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }
    }

    private func configureActions() {
        likeButton.addAction(UIAction { [weak self] _ in self?.toggleLike() }, for: .touchUpInside)
        commentButton.addAction(UIAction { [weak self] _ in self?.focusOnComments() }, for: .touchUpInside)
        giftButton.addAction(UIAction { [weak self] _ in self?.showGiftLog() }, for: .touchUpInside)
        giftCTA.addAction(UIAction { [weak self] _ in self?.openGifts() }, for: .touchUpInside)
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

        inputBar.addSubview(inputAvatar)
        inputAvatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview()
        }

        commentField.attributedPlaceholder = NSAttributedString(string: "Add to the story…", attributes: [.foregroundColor: Palette.muted, .font: SkesteFont.body(13)])
        commentField.font = SkesteFont.body(14)
        commentField.textColor = Palette.text
        commentField.tintColor = Palette.cyan
        commentField.backgroundColor = Palette.glassStrong
        commentField.layer.cornerRadius = 10
        commentField.layer.cornerCurve = .continuous
        commentField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        commentField.leftViewMode = .always
        commentField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
        commentField.rightViewMode = .always
        commentField.delegate = self
        commentField.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        sendButton.backgroundColor = Palette.hairline
        sendButton.layer.cornerRadius = 10
        sendButton.setImage(UIImage(systemName: "arrow.up", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)), for: .normal)
        sendButton.tintColor = Palette.muted
        sendButton.addAction(UIAction { [weak self] _ in self?.sendComment() }, for: .touchUpInside)
        inputBar.addSubview(commentField)
        inputBar.addSubview(sendButton)
        commentField.snp.makeConstraints { make in
            make.leading.equalTo(inputAvatar.snp.trailing).offset(9)
            make.centerY.equalToSuperview()
            make.height.equalTo(42)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
        }
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-11)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(38)
        }
        updateInputIdentity()
    }

    private func updateInputIdentity() {
        let user = SKDataStore.shared.currentUser
        inputAvatar.configure(user: user)
        inputAvatar.alpha = user == nil ? 0.35 : 1
        if user == nil {
            commentField.attributedPlaceholder = NSAttributedString(string: "Sign in to join the conversation", attributes: [.foregroundColor: Palette.muted, .font: SkesteFont.body(13)])
        } else {
            commentField.attributedPlaceholder = NSAttributedString(string: "Add to the story…", attributes: [.foregroundColor: Palette.muted, .font: SkesteFont.body(13)])
        }
    }

    @objc private func fieldChanged() {
        let hasText = !(commentField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        scrollView.contentInset.bottom = overlap + 68
        UIView.animate(withDuration: 0.24) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardHidden(_ note: Notification) {
        inputBottomConstraint?.update(offset: -6)
        scrollView.contentInset.bottom = 0
        UIView.animate(withDuration: 0.24) { self.view.layoutIfNeeded() }
    }

    private func contentSignature() -> String {
        guard let post = SKDataStore.shared.post(withID: postID) else { return "missing" }
        let commentSignature = SKDataStore.shared.comments(for: postID).map { "\($0.id)-\($0.text.count)" }.joined(separator: ",")
        return "\(post.likeCount)-\(post.giftCount)-\(commentSignature)-\(SKDataStore.shared.currentUser?.id ?? "guest")"
    }

    private func rebuildContent(preserveOffset: Bool) {
        guard let post = SKDataStore.shared.post(withID: postID),
              let author = SKDataStore.shared.user(withID: post.authorID) else { return }
        let previous = scrollView.contentOffset
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        media = post.media
        commentsAnchor = nil

        let authorRow = UIControl()
        let avatar = AvatarView(size: 44, showsRing: true)
        avatar.configure(user: author)
        authorRow.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        let name = UILabel(text: author.displayName, font: SkesteFont.demibold(15), color: Palette.text)
        let handle = UILabel(text: "\(author.handle)  ·  \(post.createdAt.skesteRelative)  ·  \(post.location)", font: SkesteFont.medium(10), color: Palette.muted)
        let authorText = UIStackView(arrangedSubviews: [name, handle])
        authorText.axis = .vertical
        authorText.spacing = 1
        authorText.isUserInteractionEnabled = false
        authorRow.addSubview(authorText)
        authorText.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(11)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-35)
        }
        let arrow = UIImageView(image: UIImage(systemName: "arrow.up.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)))
        arrow.tintColor = Palette.secondary
        authorRow.addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        authorRow.addAction(UIAction { [weak self] _ in self?.openAuthor(author) }, for: .touchUpInside)
        authorRow.snp.makeConstraints { $0.height.equalTo(50) }
        contentStack.addArrangedSubview(authorRow)
        contentStack.setCustomSpacing(18, after: authorRow)

        let kind = UILabel(text: post.kind == .reel ? "LINE DROP  /  \(post.tags.first?.uppercased() ?? "FREERIDE")" : "FIELD NOTE  /  \(post.tags.first?.uppercased() ?? "THE CIRCLE")", font: SkesteFont.demibold(9), color: post.kind == .reel ? Palette.magenta : Palette.cyan)
        kind.tracked(1.8)
        contentStack.addArrangedSubview(kind)
        contentStack.setCustomSpacing(7, after: kind)

        if !post.caption.isEmpty {
            let caption = UILabel(text: post.caption, font: SkesteFont.medium(19), color: Palette.text, lines: 0)
            caption.lineSpacing(5)
            contentStack.addArrangedSubview(caption)
            contentStack.setCustomSpacing(17, after: caption)
        }

        if !post.media.isEmpty {
            let carousel = PostMediaCarousel()
            carousel.configure(media: post.media)
            carousel.onOpen = { [weak self] index in
                guard let self else { return }
                let viewer = MediaViewerViewController(items: post.media, startIndex: index)
                self.present(viewer, animated: true)
            }
            contentStack.addArrangedSubview(carousel)
            contentStack.setCustomSpacing(14, after: carousel)
        }

        let tags = UILabel(text: post.tags.map { "#\($0)" }.joined(separator: "   "), font: SkesteFont.demibold(11), color: Palette.cyan, lines: 0)
        contentStack.addArrangedSubview(tags)
        contentStack.setCustomSpacing(13, after: tags)

        let metaRow = UIStackView()
        metaRow.axis = .horizontal
        metaRow.spacing = 10
        // The dot below is pinned to 3pt; with the default .fill alignment that fixed
        // height becomes the row's height and the 8pt meta labels get squashed flat.
        metaRow.alignment = .center
        let views = UILabel(text: "\(post.viewCount.compactCount) VIEWS", font: SkesteFont.demibold(8), color: Palette.muted)
        views.tracked(1.2)
        let dot = UIView()
        dot.backgroundColor = Palette.muted
        dot.layer.cornerRadius = 1.5
        dot.snp.makeConstraints { $0.width.height.equalTo(3) }
        let date = UILabel(text: post.createdAt.skesteRelative.uppercased(), font: SkesteFont.demibold(8), color: Palette.muted)
        date.tracked(1.2)
        metaRow.addArrangedSubview(views)
        metaRow.addArrangedSubview(dot)
        metaRow.addArrangedSubview(date)
        metaRow.addArrangedSubview(UIView())
        contentStack.addArrangedSubview(metaRow)
        contentStack.setCustomSpacing(14, after: metaRow)

        let actionBar = UIView()
        actionBar.applyGlass(cornerRadius: 22, borderAlpha: 0.09, fill: Palette.glass)
        let actions = UIStackView()
        actions.axis = .horizontal
        actions.alignment = .center
        actions.spacing = 10
        likeButton.configure(count: post.likeCount, active: SKDataStore.shared.isLiked(postID: post.id), symbol: SKDataStore.shared.isLiked(postID: post.id) ? "heart.fill" : "heart")
        commentButton.configure(count: SKDataStore.shared.commentCount(for: post.id), active: false, symbol: "bubble.left")
        giftButton.configure(count: post.giftCount, active: false, symbol: "gift")
        actions.addArrangedSubview(likeButton)
        actions.addArrangedSubview(commentButton)
        actions.addArrangedSubview(giftButton)
        actions.addArrangedSubview(UIView())
        actions.addArrangedSubview(giftCTA)
        actionBar.addSubview(actions)
        actions.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(13)
            make.top.bottom.equalToSuperview().inset(9)
        }
        giftCTA.snp.makeConstraints { make in
            make.width.equalTo(138)
            make.height.equalTo(38)
        }
        contentStack.addArrangedSubview(actionBar)
        contentStack.setCustomSpacing(26, after: actionBar)

        let separator = UIView()
        separator.backgroundColor = Palette.hairline
        separator.snp.makeConstraints { $0.height.equalTo(1) }
        contentStack.addArrangedSubview(separator)
        contentStack.setCustomSpacing(22, after: separator)

        let commentsHeader = UIView()
        let title = UILabel(text: "COMMENTS", font: SkesteFont.display(22), color: Palette.text)
        commentsHeader.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        let count = UILabel(text: String(SKDataStore.shared.commentCount(for: post.id)).uppercased(), font: SkesteFont.mono(10, weight: .bold), color: Palette.cyan)
        commentsHeader.addSubview(count)
        count.snp.makeConstraints { make in
            make.leading.equalTo(title.snp.trailing).offset(8)
            make.top.equalToSuperview().offset(3)
        }
        contentStack.addArrangedSubview(commentsHeader)
        contentStack.setCustomSpacing(16, after: commentsHeader)
        commentsAnchor = commentsHeader

        commentsStack.axis = .vertical
        commentsStack.spacing = 17
        contentStack.addArrangedSubview(commentsStack)
        rebuildComments(postID: post.id)

        lastSignature = contentSignature()
        if preserveOffset {
            DispatchQueue.main.async { self.scrollView.setContentOffset(previous, animated: false) }
        }
    }

    private func rebuildComments(postID: String) {
        commentsStack.arrangedSubviews.forEach {
            commentsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let comments = SKDataStore.shared.comments(for: postID)
        if comments.isEmpty {
            let empty = UILabel(text: "No comments yet. Start the conversation.", font: SkesteFont.body(13), color: Palette.muted, lines: 0)
            empty.textAlignment = .center
            let wrap = UIView()
            wrap.backgroundColor = Palette.glassStrong
            wrap.layer.cornerRadius = 10
            wrap.addSubview(empty)
            empty.snp.makeConstraints { $0.edges.equalToSuperview().inset(18) }
            commentsStack.addArrangedSubview(wrap)
            return
        }
        for comment in comments {
            let row = CommentRowView(comment: comment)
            row.onMore = { [weak self] in self?.commentMenu(comment) }
            row.onAvatar = { [weak self] in
                guard let author = SKDataStore.shared.user(withID: comment.authorID) else { return }
                self?.openAuthor(author)
            }
            commentsStack.addArrangedSubview(row)
        }
    }

    private func toggleLike() {
        requireLogin { [weak self] in
            guard let self else { return }
            guard let liked = SKDataStore.shared.toggleLike(postID: self.postID), let post = SKDataStore.shared.post(withID: self.postID) else { return }
            self.likeButton.configure(count: post.likeCount, active: liked, symbol: liked ? "heart.fill" : "heart")
            SkesteHaptics.light()
            self.lastSignature = self.contentSignature()
        }
    }

    private func openGifts() {
        requireLogin { [weak self] in
            guard let self else { return }
            let sheet = GiftSheetViewController(postID: self.postID)
            sheet.onGiftSent = { [weak self] in
                self?.rebuildContent(preserveOffset: true)
            }
            if let sheetController = sheet.sheetPresentationController {
                sheetController.detents = [.medium(), .large()]
                sheetController.preferredCornerRadius = 30
            }
            self.present(sheet, animated: true)
        }
    }

    /// Tapping the gift count opens the log of gifts this line has received;
    /// sending a new gift stays on the SEND STOKE button.
    private func showGiftLog() {
        let sheet = GiftListViewController(postID: postID)
        sheet.onSend = { [weak self] in self?.openGifts() }
        if let sheetController = sheet.sheetPresentationController {
            sheetController.detents = [.medium(), .large()]
            sheetController.preferredCornerRadius = 30
        }
        present(sheet, animated: true)
    }

    private func sendComment() {
        guard let text = commentField.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        requireLogin { [weak self] in
            guard let self else { return }
            guard SKDataStore.shared.addComment(postID: self.postID, text: text) != nil else {
                self.showToast("That post is no longer available.", style: .error)
                return
            }
            self.commentField.text = ""
            self.fieldChanged()
            self.commentField.resignFirstResponder()
            self.rebuildContent(preserveOffset: true)
            self.lastSignature = self.contentSignature()
            self.showToast("Your note is on the ridge.", style: .success)
        }
    }

    private func focusOnComments() {
        guard let anchor = commentsAnchor else { return }
        let rect = anchor.convert(anchor.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -20), animated: true)
    }

    private func commentMenu(_ comment: Comment) {
        var actions: [SkesteSheetAction] = [
            SkesteSheetAction(title: "Report this comment", symbol: "flag") { [weak self] in
                self?.push(ReportViewController(target: .comment(commentID: comment.id, postID: comment.postID), source: .home))
            }
        ]
        if comment.authorID == SKDataStore.shared.currentUser?.id {
            actions.insert(SkesteSheetAction(title: "Delete comment", symbol: "trash", destructive: true) { [weak self] in
                self?.showConfirm(title: "Delete this comment?", message: "This note will be removed from the story.", confirmTitle: "Delete", destructive: true) {
                    SKDataStore.shared.deleteComment(id: comment.id)
                    self?.rebuildContent(preserveOffset: true)
                    self?.lastSignature = self?.contentSignature() ?? ""
                    self?.showToast("Comment deleted.", style: .success)
                }
            }, at: 0)
        }
        present(SkesteActionSheetViewController(heading: "COMMENT OPTIONS", message: nil, actions: actions), animated: true)
    }

    private func openAuthor(_ author: User) {
        if author.id == SKDataStore.shared.currentUser?.id {
            (tabBarController as? MainTabBarController)?.selectRootTab(.settings)
            return
        }
        push(UserProfileViewController(userID: author.id, source: .home))
    }

    private func showPostMenu() {
        guard let post = SKDataStore.shared.post(withID: postID) else { return }
        var actions: [SkesteSheetAction] = [
            SkesteSheetAction(title: "Report this post", symbol: "flag") { [weak self] in
                self?.push(ReportViewController(target: .post(postID: post.id), source: .home))
            }
        ]
        if post.authorID == SKDataStore.shared.currentUser?.id {
            actions.insert(SkesteSheetAction(title: "Delete this post", symbol: "trash", destructive: true) { [weak self] in
                self?.showConfirm(title: "Delete this line?", message: "This post and all of its comments will be removed.", confirmTitle: "Delete post", destructive: true) {
                    SKDataStore.shared.deletePost(id: post.id)
                    self?.returnToRootTab(.home)
                    SkesteToast.show("Your post has been removed.", style: .success)
                }
            }, at: 0)
        }
        present(SkesteActionSheetViewController(heading: "POST OPTIONS", message: post.caption, actions: actions), animated: true)
    }
}

extension PostDetailViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !SKDataStore.shared.isLoggedIn {
            requireLogin { [weak self] in
                self?.updateInputIdentity()
                self?.rebuildContent(preserveOffset: true)
                self?.commentField.becomeFirstResponder()
            }
            return false
        }
        return true
    }
}

extension PostDetailViewController: UIScrollViewDelegate {}
