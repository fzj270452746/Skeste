import UIKit
import SnapKit

final class SettingsRowView: UIControl {
    private let iconHost = UIView()
    private let iconView = UIImageView()
    private let titleLabel: UILabel
    private let detailLabel: UILabel
    private let chevron = UIImageView()
    private let destructive: Bool

    init(title: String, detail: String? = nil, symbol: String, destructive: Bool = false) {
        titleLabel = UILabel(text: title, font: SkesteFont.medium(14), color: destructive ? Palette.danger : Palette.text)
        detailLabel = UILabel(text: detail, font: SkesteFont.medium(9), color: Palette.muted)
        self.destructive = destructive
        super.init(frame: .zero)

        iconHost.backgroundColor = destructive ? Palette.danger.withAlphaComponent(0.1) : Palette.glass
        iconHost.layer.cornerRadius = 14
        iconHost.layer.cornerCurve = .continuous
        addSubview(iconHost)
        iconHost.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(34)
        }
        iconView.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold))
        iconView.tintColor = destructive ? Palette.danger : Palette.cyan
        iconView.contentMode = .scaleAspectFit
        iconHost.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(18) }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconHost.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        if let detail {
            detailLabel.text = detail
            addSubview(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-34)
                make.centerY.equalToSuperview()
            }
        } else {
            detailLabel.isHidden = true
        }

        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold))
        chevron.tintColor = Palette.muted
        addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }
        snp.makeConstraints { $0.height.equalTo(52) }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.14) {
                self.backgroundColor = self.isHighlighted ? Palette.glassStrong : .clear
            }
        }
    }
}

final class SettingsStatTile: UIControl {
    private let valueLabel = UILabel(text: nil, font: SkesteFont.display(27), color: Palette.text)
    private let titleLabel = UILabel(text: nil, font: SkesteFont.demibold(7), color: Palette.muted)
    private let iconView = UIImageView()

    init(title: String, symbol: String) {
        super.init(frame: .zero)
        applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)
        titleLabel.text = title
        titleLabel.tracked(1.2)
        iconView.image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
        iconView.tintColor = Palette.cyan
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-11)
            make.top.equalToSuperview().offset(11)
            make.width.height.equalTo(14)
        }
        valueLabel.textAlignment = .center
        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(11)
        }
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(valueLabel.snp.bottom).offset(-1)
            make.bottom.equalToSuperview().offset(-10)
        }
        snp.makeConstraints { $0.height.equalTo(76) }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: String) {
        valueLabel.text = value
        accessibilityLabel = "\(value) \(titleLabel.text ?? "")"
    }

    override var isHighlighted: Bool {
        didSet { UIView.animate(withDuration: 0.14) { self.alpha = self.isHighlighted ? 0.7 : 1 } }
    }
}

final class SettingsViewController: BaseViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var lastSignature = ""

    override func setupView() {
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
        if lastSignature != signature() { rebuild() }
    }

    override func authDidChange() {
        rebuild()
    }

    override func contentDidChange() {
        guard isViewLoaded else { return }
        rebuild()
    }

    private func signature() -> String {
        guard let user = SKDataStore.shared.currentUser else { return "guest" }
        return "\(user.displayName)-\(user.bio)-\(user.avatarFileName ?? user.avatarAsset)-\(SKDataStore.shared.currentHomeCounts())"
    }

    private func rebuild() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        if SKDataStore.shared.isLoggedIn {
            buildSignedIn()
        } else {
            buildSignedOut()
        }
        lastSignature = signature()
    }

    private func buildHeader(titleTop: String, titleBottom: String) -> UILabel {
        let wrap = UIView()
        let kicker = UILabel(text: "BASE CAMP  /  \(titleTop)", font: SkesteFont.demibold(8), color: Palette.secondary)
        kicker.tracked(2)
        wrap.addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
        }
        let title = UILabel(text: titleBottom, font: SkesteFont.display(34), color: Palette.text)
        title.richTracking(-1.0)
        wrap.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(kicker.snp.bottom).offset(2)
        }
        let line = AccentLineView()
        line.setColors([Palette.magenta, Palette.magenta])
        wrap.addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(title.snp.bottom).offset(6)
            make.width.equalTo(92)
            make.height.equalTo(3)
            make.bottom.equalToSuperview()
        }
        contentStack.addArrangedSubview(wrap)
        contentStack.setCustomSpacing(20, after: wrap)
        return title
    }

    private func buildSignedIn() {
        guard let user = SKDataStore.shared.currentUser else { return }
        _ = buildHeader(titleTop: "PERSONAL", titleBottom: "YOUR BASE.")

        let profileCard = UIControl()
        profileCard.applyGlass(cornerRadius: 16, borderAlpha: 0.12, fill: Palette.glass)
        let avatar = AvatarView(size: 70, showsRing: true)
        avatar.configure(user: user)
        profileCard.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(17)
        }
        let name = UILabel(text: user.displayName, font: SkesteFont.display(24), color: Palette.text)
        name.richTracking(-0.4)
        profileCard.addSubview(name)
        name.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(14)
            make.top.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        let handle = UILabel(text: "\(user.handle)  ·  \(user.homeResort)", font: SkesteFont.medium(11), color: Palette.secondary)
        profileCard.addSubview(handle)
        handle.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(name.snp.bottom).offset(1)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        let edit = UILabel(text: "VIEW MY RIDGE  →", font: SkesteFont.demibold(8), color: Palette.cyan)
        edit.tracked(1.2)
        profileCard.addSubview(edit)
        edit.snp.makeConstraints { make in
            make.leading.equalTo(name)
            make.top.equalTo(handle.snp.bottom).offset(7)
            make.bottom.equalToSuperview().offset(-18)
        }
        profileCard.addAction(UIAction { [weak self] _ in
            self?.push(UserProfileViewController(userID: user.id, source: .settings))
        }, for: .touchUpInside)
        contentStack.addArrangedSubview(profileCard)
        contentStack.setCustomSpacing(10, after: profileCard)

        let statsRow = UIStackView()
        statsRow.axis = .horizontal
        statsRow.spacing = 8
        statsRow.distribution = .fillEqually
        let followers = SettingsStatTile(title: "FOLLOWERS", symbol: "person.2.fill")
        followers.setValue(SKDataStore.shared.currentFollowers.count.compactCount)
        followers.addAction(UIAction { [weak self] _ in self?.push(ConnectionsViewController(mode: .followers)) }, for: .touchUpInside)
        let following = SettingsStatTile(title: "FOLLOWING", symbol: "arrow.up.right")
        following.setValue(SKDataStore.shared.currentFollowing.count.compactCount)
        following.addAction(UIAction { [weak self] _ in self?.push(ConnectionsViewController(mode: .following)) }, for: .touchUpInside)
        let lines = SettingsStatTile(title: "LINES", symbol: "square.grid.2x2")
        lines.setValue("\(SKDataStore.shared.currentPostCount)")
        lines.addAction(UIAction { [weak self] _ in self?.push(MyWorksViewController()) }, for: .touchUpInside)
        statsRow.addArrangedSubview(followers)
        statsRow.addArrangedSubview(following)
        statsRow.addArrangedSubview(lines)
        contentStack.addArrangedSubview(statsRow)
        contentStack.setCustomSpacing(26, after: statsRow)

        buildSectionLabel("IDENTITY")
        let identity = sectionCard()
        let editRow = SettingsRowView(title: "Edit profile", detail: nil, symbol: "pencil")
        editRow.addAction(UIAction { [weak self] _ in self?.push(EditProfileViewController()) }, for: .touchUpInside)
        let aboutRow = SettingsRowView(title: "About Skeste", detail: "v1.0", symbol: "info.circle")
        aboutRow.addAction(UIAction { [weak self] _ in self?.push(AboutViewController()) }, for: .touchUpInside)
        addRow(editRow, to: identity)
        addRow(aboutRow, to: identity, showsDivider: false)
        contentStack.addArrangedSubview(identity)
        contentStack.setCustomSpacing(22, after: identity)

        buildSectionLabel("YOUR STASH")
        let stash = sectionCard()
        let likes = SettingsRowView(title: "Liked lines", detail: "\(SKDataStore.shared.state.socialGraphs[user.id]?.likedPostIDs.count ?? 0)", symbol: "heart.fill")
        likes.addAction(UIAction { [weak self] _ in self?.push(MyLikesViewController()) }, for: .touchUpInside)
        let follow = SettingsRowView(title: "Following", detail: "\(SKDataStore.shared.currentFollowing.count)", symbol: "person.2")
        follow.addAction(UIAction { [weak self] _ in self?.push(ConnectionsViewController(mode: .following)) }, for: .touchUpInside)
        let works = SettingsRowView(title: "My works", detail: "\(SKDataStore.shared.currentPostCount)", symbol: "rectangle.stack.fill")
        works.addAction(UIAction { [weak self] _ in self?.push(MyWorksViewController()) }, for: .touchUpInside)
        addRow(likes, to: stash)
        addRow(follow, to: stash)
        addRow(works, to: stash, showsDivider: false)
        contentStack.addArrangedSubview(stash)
        contentStack.setCustomSpacing(22, after: stash)

        let logout = GhostButton(title: "LOG OUT", icon: "arrow.right.square", height: 50)
        logout.addAction(UIAction { [weak self] _ in self?.confirmLogout() }, for: .touchUpInside)
        contentStack.addArrangedSubview(logout)
        contentStack.setCustomSpacing(9, after: logout)

        let delete = UIButton(type: .system)
        delete.setTitle("DELETE ACCOUNT", for: .normal)
        delete.setTitleColor(Palette.danger, for: .normal)
        delete.titleLabel?.font = SkesteFont.demibold(9)
        delete.addAction(UIAction { [weak self] _ in self?.confirmDelete() }, for: .touchUpInside)
        contentStack.addArrangedSubview(delete)
        contentStack.setCustomSpacing(16, after: delete)

        let version = UILabel(text: "SKESTE  ·  1.0 (1)  ·  MADE FOR THE MOUNTAIN", font: SkesteFont.demibold(7), color: Palette.muted)
        version.tracked(1.2)
        version.textAlignment = .center
        contentStack.addArrangedSubview(version)
    }

    private func buildSignedOut() {
        _ = buildHeader(titleTop: "WELCOME", titleBottom: "BASE CAMP.")
        let panel = UIView()
        panel.applyGlass(cornerRadius: 18, borderAlpha: 0.10, fill: Palette.glass)
        let lock = UIImageView(image: UIImage(systemName: "person.crop.circle.badge.questionmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .light)))
        lock.tintColor = Palette.cyan
        panel.addSubview(lock)
        lock.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(34)
            make.width.height.equalTo(38)
        }
        let title = UILabel(text: "YOUR PASS IS\nWAITING.", font: SkesteFont.display(24), color: Palette.text, lines: 2)
        title.textAlignment = .center
        panel.addSubview(title)
        title.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(lock.snp.bottom).offset(18)
        }
        let message = UILabel(text: "Sign in to build your profile, keep your favorite lines, and book a private video session with a coach.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        message.textAlignment = .center
        message.lineSpacing(3)
        panel.addSubview(message)
        message.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(26)
            make.top.equalTo(title.snp.bottom).offset(8)
        }
        let signIn = GradientButton(title: "ENTER THE MOUNTAIN", icon: "arrow.right", height: 52)
        signIn.addAction(UIAction { [weak self] _ in
            self?.requireLogin { [weak self] in self?.rebuild() }
        }, for: .touchUpInside)
        panel.addSubview(signIn)
        signIn.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(18)
            make.top.equalTo(message.snp.bottom).offset(24)
            make.bottom.equalToSuperview().offset(-20)
        }
        contentStack.addArrangedSubview(panel)
        contentStack.setCustomSpacing(26, after: panel)

        buildSectionLabel("MORE")
        let more = sectionCard()
        let aboutRow = SettingsRowView(title: "About Skeste", detail: "v1.0", symbol: "info.circle")
        aboutRow.addAction(UIAction { [weak self] _ in self?.push(AboutViewController()) }, for: .touchUpInside)
        addRow(aboutRow, to: more, showsDivider: false)
        contentStack.addArrangedSubview(more)
    }

    private func buildSectionLabel(_ text: String) {
        let label = UILabel(text: text, font: SkesteFont.demibold(8), color: Palette.muted)
        label.tracked(2)
        let wrap = UIView()
        wrap.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.top.bottom.equalToSuperview()
        }
        contentStack.addArrangedSubview(wrap)
        wrap.snp.makeConstraints { $0.height.equalTo(22) }
        contentStack.setCustomSpacing(8, after: wrap)
    }

    private func sectionCard() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.backgroundColor = Palette.glass
        stack.layer.cornerRadius = 14
        stack.layer.cornerCurve = .continuous
        stack.layer.cornerCurve = .continuous
        stack.layer.borderWidth = 1
        stack.layer.borderColor = Palette.hairline.cgColor
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0)
        return stack
    }

    private func addRow(_ row: UIView, to stack: UIStackView, showsDivider: Bool = true) {
        stack.addArrangedSubview(row)
        if showsDivider {
            let divider = UIView()
            divider.backgroundColor = Palette.hairline
            divider.snp.makeConstraints { make in
                make.height.equalTo(1)
            }
            let wrap = UIView()
            wrap.addSubview(divider)
            divider.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(56)
                make.trailing.equalToSuperview().offset(-14)
                make.top.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
            wrap.snp.makeConstraints { $0.height.equalTo(1) }
            stack.addArrangedSubview(wrap)
        }
    }

    private func confirmLogout() {
        showConfirm(title: "Leave base camp?", message: "Your saved session will be cleared on this device. Your posts and coaching sessions stay right where they are.", confirmTitle: "Log out") { [weak self] in
            let loader = SkesteLoadingView.present()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                SKDataStore.shared.logout()
                loader.dismiss {
                    self?.rebuild()
                    SkesteToast.show("Logged out. See you on the next storm.", style: .info)
                }
            }
        }
    }

    private func confirmDelete() {
        showConfirm(title: "Delete your account?", message: "Your profile, posts, comments, and coaching sessions will be removed from this device. This action cannot be undone.", confirmTitle: "Delete account", destructive: true) { [weak self] in
            let loader = SkesteLoadingView.present()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                SKDataStore.shared.deleteAccount()
                loader.dismiss {
                    self?.rebuild()
                    SkesteToast.show("Your account has been deleted.", style: .success)
                }
            }
        }
    }
}

extension SKDataStore {
    func currentHomeCounts() -> String {
        "\(currentFollowers.count)-\(currentFollowing.count)-\(currentPostCount)"
    }
}
