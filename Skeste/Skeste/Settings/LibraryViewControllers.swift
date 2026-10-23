import UIKit
import SnapKit

enum ConnectionMode {
    case followers
    case following

    var title: String {
        switch self {
        case .followers: return "FOLLOWERS."
        case .following: return "FOLLOWING."
        }
    }

    var kicker: String {
        switch self {
        case .followers: return "THE PEOPLE WHO FOUND YOU"
        case .following: return "THE LINES YOU FOLLOW"
        }
    }
}

final class LibraryPostRow: UIControl {
    var onAction: (() -> Void)?
    var onOpen: (() -> Void)?
    private let preview = MediaPreviewView()
    private let kindLabel = UILabel(text: nil, font: SkesteFont.demibold(8), color: Palette.cyan)
    private let titleLabel = UILabel(text: nil, font: SkesteFont.medium(13), color: Palette.text, lines: 2)
    private let metaLabel = UILabel(text: nil, font: SkesteFont.medium(9), color: Palette.muted)
    private let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlass(cornerRadius: 20, borderAlpha: 0.08, fill: Palette.glass)
        preview.layer.cornerRadius = 14
        preview.layer.cornerCurve = .continuous
        preview.clipsToBounds = true
        addSubview(preview)
        preview.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(8)
            make.width.equalTo(76)
        }
        kindLabel.tracked(1.2)
        addSubview(kindLabel)
        addSubview(titleLabel)
        addSubview(metaLabel)
        actionButton.titleLabel?.font = SkesteFont.demibold(8)
        actionButton.layer.cornerRadius = 14
        actionButton.layer.cornerCurve = .continuous
        actionButton.backgroundColor = Palette.glassStrong
        actionButton.addAction(UIAction { [weak self] _ in self?.onAction?() }, for: .touchUpInside)
        addSubview(actionButton)
        kindLabel.snp.makeConstraints { make in
            make.leading.equalTo(preview.snp.trailing).offset(11)
            make.top.equalToSuperview().offset(13)
            make.trailing.lessThanOrEqualTo(actionButton.snp.leading).offset(-6)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(kindLabel)
            make.top.equalTo(kindLabel.snp.bottom).offset(3)
            make.trailing.equalTo(actionButton.snp.leading).offset(-7)
        }
        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(kindLabel)
            make.bottom.equalToSuperview().offset(-13)
        }
        actionButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-9)
            make.centerY.equalToSuperview()
            make.width.equalTo(74)
            make.height.equalTo(29)
        }
        addAction(UIAction { [weak self] _ in self?.onOpen?() }, for: .touchUpInside)
        snp.makeConstraints { $0.height.equalTo(112) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(post: Post, actionTitle: String, actionColor: UIColor, actionSymbol: String) {
        preview.configure(with: post.media.first)
        kindLabel.text = post.kind == .reel ? "LINE DROP" : "FIELD NOTE"
        titleLabel.text = post.caption.isEmpty ? "Untitled line" : post.caption
        let author = SKDataStore.shared.user(withID: post.authorID)?.displayName ?? "You"
        metaLabel.text = "\(author)  ·  \(post.createdAt.skesteRelative)  ·  \(post.likeCount.compactCount) LIKES"
        actionButton.setTitle(" \(actionTitle)", for: .normal)
        actionButton.setImage(UIImage(systemName: actionSymbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)), for: .normal)
        actionButton.tintColor = actionColor
        actionButton.setTitleColor(actionColor, for: .normal)
    }
}

final class ConnectionRow: UIControl {
    var onAction: (() -> Void)?
    var onOpen: (() -> Void)?
    private let avatar = AvatarView(size: 46, showsRing: true)
    private let name = UILabel(text: nil, font: SkesteFont.demibold(14), color: Palette.text)
    private let handle = UILabel(text: nil, font: SkesteFont.medium(10), color: Palette.muted)
    private let meta = UILabel(text: nil, font: SkesteFont.medium(9), color: Palette.secondary)
    private let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlass(cornerRadius: 20, borderAlpha: 0.08, fill: Palette.glass)
        addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(11)
            make.centerY.equalToSuperview()
        }
        addSubview(name)
        addSubview(handle)
        addSubview(meta)
        actionButton.titleLabel?.font = SkesteFont.demibold(8)
        actionButton.layer.cornerRadius = 14
        actionButton.layer.cornerCurve = .continuous
        actionButton.backgroundColor = Palette.glassStrong
        actionButton.addAction(UIAction { [weak self] _ in self?.onAction?() }, for: .touchUpInside)
        addSubview(actionButton)
        name.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(11)
            make.top.equalToSuperview().offset(12)
            make.trailing.lessThanOrEqualTo(actionButton.snp.leading).offset(-8)
        }
        handle.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(name.snp.bottom).offset(0)
        }
        meta.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(handle.snp.bottom).offset(4)
        }
        actionButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.width.equalTo(84)
            make.height.equalTo(29)
        }
        addAction(UIAction { [weak self] _ in self?.onOpen?() }, for: .touchUpInside)
        snp.makeConstraints { $0.height.equalTo(74) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(user: User, mode: ConnectionMode) {
        avatar.configure(user: user)
        name.text = user.displayName
        handle.text = user.handle
        meta.text = user.homeResort
        let following = SKDataStore.shared.isFollowing(userID: user.id)
        if mode == .following {
            actionButton.setTitle(" UNFOLLOW", for: .normal)
            actionButton.setTitleColor(Palette.secondary, for: .normal)
            actionButton.tintColor = Palette.secondary
            actionButton.setImage(UIImage(systemName: "person.badge.minus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)), for: .normal)
        } else {
            actionButton.setTitle(following ? " FOLLOWING" : " FOLLOW BACK", for: .normal)
            let color = following ? Palette.lime : Palette.cyan
            actionButton.setTitleColor(color, for: .normal)
            actionButton.tintColor = color
            actionButton.setImage(UIImage(systemName: following ? "checkmark" : "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9, weight: .semibold)), for: .normal)
        }
    }
}

class LibraryBaseViewController: BaseViewController {
    let scrollView = UIScrollView()
    let contentStack = UIStackView()
    private let navTitle: String

    init(navTitle: String) {
        self.navTitle = navTitle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel(text: navTitle, font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.8)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(60)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-40)
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
        guard isViewLoaded else { return }
        rebuild()
    }

    func rebuild() {}

    func clearContent() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    func addTitle(_ text: String, kicker: String, countText: String) {
        let kickerLabel = UILabel(text: kicker, font: SkesteFont.demibold(9), color: Palette.secondary)
        kickerLabel.tracked(2)
        contentStack.addArrangedSubview(kickerLabel)
        contentStack.setCustomSpacing(3, after: kickerLabel)
        let row = UIView()
        let title = UILabel(text: text, font: SkesteFont.display(30), color: Palette.text, lines: 2)
        title.richTracking(-0.6)
        row.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        let count = UILabel(text: countText, font: SkesteFont.mono(9, weight: .bold), color: Palette.muted)
        row.addSubview(count)
        count.snp.makeConstraints { make in
            make.leading.equalTo(title.snp.trailing).offset(8)
            make.top.equalToSuperview().offset(5)
        }
        contentStack.addArrangedSubview(row)
        contentStack.setCustomSpacing(18, after: row)
    }

    func addEmpty(_ text: String) {
        let wrap = UIView()
        wrap.applyGlass(cornerRadius: 22, borderAlpha: 0.08, fill: Palette.glass)
        let label = UILabel(text: text, font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        label.textAlignment = .center
        label.lineSpacing(3)
        wrap.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(24) }
        contentStack.addArrangedSubview(wrap)
    }
}

extension LibraryBaseViewController {
    func pushReportIfPossible() {}
}

final class MyLikesViewController: LibraryBaseViewController {
    init() { super.init(navTitle: "LIKED LINES") }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func rebuild() {
        clearContent()
        guard SKDataStore.shared.isLoggedIn else { return }
        let posts = SKDataStore.shared.sortedPosts.filter { SKDataStore.shared.isLiked(postID: $0.id) }
        addTitle("LIKED\nLINES.", kicker: "SAVED TO YOUR STASH", countText: "\(posts.count)")
        guard !posts.isEmpty else {
            addEmpty("Nothing saved yet. Tap the heart on a line that stays with you and it will land here.")
            return
        }
        for post in posts {
            let row = LibraryPostRow()
            row.configure(post: post, actionTitle: "UNLIKE", actionColor: Palette.magenta, actionSymbol: "heart.slash")
            row.onAction = { [weak self] in
                _ = SKDataStore.shared.toggleLike(postID: post.id)
                self?.rebuild()
                SkesteToast.show("Removed from your liked lines.", style: .info)
            }
            row.onOpen = { [weak self] in
                self?.push(PostDetailViewController(postID: post.id))
            }
            contentStack.addArrangedSubview(row)
            contentStack.setCustomSpacing(9, after: row)
        }
    }
}

final class MyWorksViewController: LibraryBaseViewController {
    init() { super.init(navTitle: "MY WORKS") }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func rebuild() {
        clearContent()
        guard let user = SKDataStore.shared.currentUser else { return }
        let posts = SKDataStore.shared.posts(by: user.id)
        addTitle("MY\nWORKS.", kicker: "DROPPED BY YOU", countText: "\(posts.count)")
        guard !posts.isEmpty else {
            addEmpty("Your stash is empty. Head to the plus and drop your first line on the mountain.")
            return
        }
        for post in posts {
            let row = LibraryPostRow()
            row.configure(post: post, actionTitle: "DELETE", actionColor: Palette.danger, actionSymbol: "trash")
            row.onAction = { [weak self] in
                self?.showConfirm(title: "Delete this line?", message: "This post and its comments will be removed for good.", confirmTitle: "Delete post", destructive: true) {
                    SKDataStore.shared.deletePost(id: post.id)
                    self?.rebuild()
                    SkesteToast.show("Your line has been removed.", style: .success)
                }
            }
            row.onOpen = { [weak self] in
                self?.push(PostDetailViewController(postID: post.id))
            }
            contentStack.addArrangedSubview(row)
            contentStack.setCustomSpacing(9, after: row)
        }
    }
}

final class ConnectionsViewController: LibraryBaseViewController {
    private let mode: ConnectionMode

    init(mode: ConnectionMode) {
        self.mode = mode
        super.init(navTitle: mode == .followers ? "FOLLOWERS" : "FOLLOWING")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func rebuild() {
        clearContent()
        guard SKDataStore.shared.isLoggedIn else { return }
        let users = mode == .followers ? SKDataStore.shared.currentFollowers : SKDataStore.shared.currentFollowing
        addTitle(mode.title, kicker: mode.kicker, countText: "\(users.count)")
        guard !users.isEmpty else {
            addEmpty(mode == .followers ? "No followers yet. Keep sharing lines and the right people will find you." : "You're not following anyone yet. Discover riders from the coaching page or under any post.")
            return
        }
        for user in users {
            let row = ConnectionRow()
            row.configure(user: user, mode: mode)
            row.onAction = { [weak self] in
                _ = SKDataStore.shared.toggleFollow(userID: user.id)
                self?.rebuild()
                let stillFollowing = SKDataStore.shared.isFollowing(userID: user.id)
                SkesteToast.show(stillFollowing ? "Following \(user.displayName)." : "You unfollowed \(user.displayName).", style: .info)
            }
            row.onOpen = { [weak self] in
                self?.push(UserProfileViewController(userID: user.id, source: .settings))
            }
            contentStack.addArrangedSubview(row)
            contentStack.setCustomSpacing(9, after: row)
        }
    }
}
