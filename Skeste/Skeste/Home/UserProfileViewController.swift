import UIKit
import SnapKit

final class ProfileHaloView: UIView {
    private let outer = CAShapeLayer()
    private let inner = CAShapeLayer()
    private let tick = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        outer.fillColor = UIColor.clear.cgColor
        outer.strokeColor = Palette.cyan.withAlphaComponent(0.25).cgColor
        outer.lineWidth = 1
        outer.lineDashPattern = [2, 6]
        inner.fillColor = UIColor.clear.cgColor
        inner.strokeColor = Palette.magenta.withAlphaComponent(0.18).cgColor
        inner.lineWidth = 1
        tick.fillColor = Palette.lime.cgColor
        tick.shadowColor = Palette.lime.cgColor
        tick.shadowOpacity = 0.8
        tick.shadowRadius = 5
        tick.shadowOffset = .zero
        layer.addSublayer(outer)
        layer.addSublayer(inner)
        layer.addSublayer(tick)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        outer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1)).cgPath
        inner.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 15, dy: 15)).cgPath
        tick.path = UIBezierPath(ovalIn: CGRect(x: bounds.width - 24, y: 28, width: 6, height: 6)).cgPath
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 30
        rotation.repeatCount = .infinity
        outer.add(rotation, forKey: "halo.rotate")
    }
}

final class ProfilePostTile: UIControl {
    var onOpen: (() -> Void)?
    private let preview = MediaPreviewView()
    private let artwork = AlpineArtworkView()
    private let kindBadge = SkesteTagLabel(text: "NOTE", tint: .white, fill: UIColor(hex: "060607").withAlphaComponent(0.6))
    private let playIcon = UIImageView()
    private let captionLabel = UILabel(text: nil, font: SkesteFont.demibold(12), color: .white, lines: 5)
    private let timeLabel = UILabel(text: nil, font: SkesteFont.mono(8, weight: .bold), color: UIColor.white.withAlphaComponent(0.7))
    private let shade = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.deep
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.hairline.cgColor
        clipsToBounds = true

        // These cover the whole control; if they stay touch-enabled they swallow the
        // tap before the tile's touchUpInside can fire.
        artwork.isUserInteractionEnabled = false
        artwork.translatesAutoresizingMaskIntoConstraints = false
        addSubview(artwork)
        artwork.snp.makeConstraints { $0.edges.equalToSuperview() }

        preview.isHidden = true
        preview.isUserInteractionEnabled = false
        addSubview(preview)
        preview.snp.makeConstraints { $0.edges.equalToSuperview() }
        shade.colors = [UIColor.clear.cgColor, UIColor(hex: "060607").withAlphaComponent(0.15).cgColor, UIColor(hex: "060607").withAlphaComponent(0.92).cgColor]
        shade.locations = [0, 0.45, 1]
        layer.addSublayer(shade)

        kindBadge.insets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        addSubview(kindBadge)
        kindBadge.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(9)
        }

        playIcon.image = UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))
        playIcon.tintColor = .white
        playIcon.backgroundColor = UIColor(hex: "060607").withAlphaComponent(0.5)
        playIcon.layer.cornerRadius = 14
        playIcon.contentMode = .center
        addSubview(playIcon)
        playIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-9)
            make.top.equalToSuperview().offset(9)
            make.width.height.equalTo(28)
        }

        addSubview(captionLabel)
        captionLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(11)
            make.bottom.equalToSuperview().offset(-26)
        }

        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(11)
            make.bottom.equalToSuperview().offset(-9)
        }

        addAction(UIAction { [weak self] _ in self?.onOpen?() }, for: .touchUpInside)
        isAccessibilityElement = true
        accessibilityTraits = .button
        snp.makeConstraints { make in
            make.height.equalTo(226)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shade.frame = bounds
    }

    func configure(post: Post) {
        timeLabel.text = post.createdAt.skesteRelative.uppercased()
        captionLabel.text = post.caption
        artwork.configure(seed: post.id)
        if let first = post.media.first {
            preview.isHidden = false
            preview.configure(with: first)
            artwork.isHidden = true
            kindBadge.text = first.kind == .video ? "LINE DROP" : "NOTE"
            playIcon.isHidden = first.kind != .video
        } else {
            preview.isHidden = true
            artwork.isHidden = false
            kindBadge.text = "FIELD NOTE"
            playIcon.isHidden = true
        }
        accessibilityLabel = post.caption.isEmpty ? "Open \(kindBadge.text?.lowercased() ?? "note")" : post.caption
    }
}

final class UserProfileViewController: BaseViewController {
    private let userID: String
    private let source: RootTab
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var lastSignature = ""
    private var didBuild = false

    init(userID: String, source: RootTab) {
        self.userID = userID
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        NotificationCenter.default.addObserver(self, selector: #selector(coachingChanged), name: .skesteCoachingChanged, object: nil)
        buildHeader()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(60)
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-AppLayout.tabBarClearance)
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }
        rebuild()
    }

    override func refreshView() {
        if !didBuild {
            rebuild()
            return
        }
        if SKDataStore.shared.user(withID: userID) == nil {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        if lastSignature != signature() {
            rebuild()
        }
    }

    override func authDidChange() {
        rebuild()
    }

    override func contentDidChange() {
        guard isViewLoaded, view.window != nil else { return }
        if presentedViewController == nil {
            if SKDataStore.shared.user(withID: userID) == nil {
                navigationController?.popToRootViewController(animated: true)
            } else {
                rebuild()
            }
        }
    }

    private func signature() -> String {
        guard let user = SKDataStore.shared.user(withID: userID) else { return "missing" }
        let coach = SKDataStore.shared.coachProfile(for: userID) != nil
        let booking = SKDataStore.shared.openBooking(with: userID)?.status.rawValue ?? "none"
        return "\(user.displayName)-\(user.bio)-\(user.avatarFileName ?? user.avatarAsset)-\(SKDataStore.shared.posts(by: userID).count)-\(SKDataStore.shared.isFollowing(userID: userID))-\(coach)-\(booking)-\(SKDataStore.shared.currentUser?.id ?? "guest")"
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

        let label = UILabel(text: "RIDER PROFILE", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.9)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }

        let flag = SkesteControls.iconButton(symbol: "flag", diameter: 40)
        flag.tag = 701
        flag.addAction(UIAction { [weak self] _ in self?.reportUser() }, for: .touchUpInside)
        view.addSubview(flag)
        flag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.centerY.equalTo(back)
        }
    }

    private func rebuild() {
        guard let user = SKDataStore.shared.user(withID: userID) else { return }
        didBuild = true
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let isSelf = user.id == SKDataStore.shared.currentUser?.id
        (view.viewWithTag(701) as? UIButton)?.isHidden = isSelf

        let hero = UIView()
        let halo = ProfileHaloView()
        hero.addSubview(halo)
        halo.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(4)
            make.width.height.equalTo(142)
        }
        let avatar = AvatarView(size: 108, showsRing: true)
        avatar.configure(user: user)
        hero.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(21)
        }

        let index = UILabel(text: "RIDER / \(String(format: "%02d", Int(StableHash.of(user.id) % 99) + 1))", font: SkesteFont.mono(8, weight: .bold), color: Palette.muted)
        index.tracked(1.6)
        hero.addSubview(index)
        index.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-4)
            make.top.equalToSuperview().offset(26)
        }

        let name = UILabel(text: user.displayName, font: SkesteFont.display(28), color: Palette.text, lines: 0)
        name.textAlignment = .center
        name.richTracking(-0.4)
        hero.addSubview(name)
        name.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(avatar.snp.bottom).offset(15)
        }

        let handle = UILabel(text: user.handle, font: SkesteFont.demibold(11), color: Palette.cyan)
        handle.textAlignment = .center
        let traits = UILabel(text: user.traitLine, font: SkesteFont.medium(11), color: Palette.secondary)
        traits.textAlignment = .center
        let resort = UILabel(text: user.homeResort.uppercased(), font: SkesteFont.demibold(8), color: Palette.muted)
        resort.tracked(1.5)
        resort.textAlignment = .center

        let metaStack = UIStackView()
        metaStack.axis = .vertical
        metaStack.alignment = .center
        metaStack.spacing = 3
        metaStack.addArrangedSubview(handle)
        if let coach = SKDataStore.shared.coachProfile(for: user.id) {
            let badge = SkesteTagLabel(text: "COACH  ·  \(coach.specialties.prefix(2).joined(separator: " / ").uppercased())", tint: Palette.lime, fill: Palette.lime.withAlphaComponent(0.12))
            badge.insets = UIEdgeInsets(top: 4, left: 9, bottom: 4, right: 9)
            metaStack.addArrangedSubview(badge)
            metaStack.setCustomSpacing(7, after: badge)
        }
        metaStack.setCustomSpacing(7, after: handle)
        metaStack.addArrangedSubview(traits)
        metaStack.addArrangedSubview(resort)
        hero.addSubview(metaStack)
        metaStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(name.snp.bottom).offset(1)
            make.bottom.equalToSuperview()
        }
        contentStack.addArrangedSubview(hero)
        contentStack.setCustomSpacing(20, after: hero)

        let stats = UIView()
        stats.applyGlass(cornerRadius: 22, borderAlpha: 0.09, fill: Palette.glass)
        let statsRow = UIStackView()
        statsRow.axis = .horizontal
        statsRow.distribution = .fillEqually
        statsRow.alignment = .center
        stats.addSubview(statsRow)
        statsRow.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 4, bottom: 14, right: 4)) }
        let posts = SKDataStore.shared.posts(by: user.id)
        let values = [
            ("FOLLOWERS", SKDataStore.shared.followerCount(for: user).compactCount),
            ("FOLLOWING", SKDataStore.shared.followingCount(for: user).compactCount),
            ("LINES", "\(posts.count)")
        ]
        for (index, value) in values.enumerated() {
            let column = UIStackView()
            column.axis = .vertical
            column.alignment = .center
            column.spacing = 1
            let number = UILabel(text: value.1, font: SkesteFont.display(25), color: Palette.text)
            let label = UILabel(text: value.0, font: SkesteFont.demibold(7), color: Palette.muted)
            label.tracked(1.3)
            column.addArrangedSubview(number)
            column.addArrangedSubview(label)
            statsRow.addArrangedSubview(column)
            column.snp.makeConstraints { $0.height.equalTo(38) }
            if index < values.count - 1 {
                let separator = UIView()
                separator.backgroundColor = Palette.hairline
                column.addSubview(separator)
                separator.snp.makeConstraints { make in
                    make.trailing.equalToSuperview()
                    make.centerY.equalToSuperview()
                    make.width.equalTo(1)
                    make.height.equalTo(28)
                }
            }
            _ = index
        }
        contentStack.addArrangedSubview(stats)
        contentStack.setCustomSpacing(13, after: stats)

        if !user.bio.isEmpty {
            let bioWrap = UIView()
            let bar = AccentLineView()
            bar.setColors([Palette.magenta, Palette.amber])
            bioWrap.addSubview(bar)
            bar.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.top.equalToSuperview().offset(3)
                make.width.equalTo(2)
                make.height.equalTo(44)
            }
            let bio = UILabel(text: user.bio, font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
            bio.lineSpacing(3)
            bioWrap.addSubview(bio)
            bio.snp.makeConstraints { make in
                make.leading.equalTo(bar.snp.trailing).offset(10)
                make.trailing.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            contentStack.addArrangedSubview(bioWrap)
            contentStack.setCustomSpacing(18, after: bioWrap)
        }

        if !isSelf {
            buildActions(user: user)
        } else {
            let edit = GhostButton(title: "EDIT MY PROFILE", icon: "pencil", height: 48)
            edit.addAction(UIAction { [weak self] _ in
                self?.push(EditProfileViewController())
            }, for: .touchUpInside)
            contentStack.addArrangedSubview(edit)
            contentStack.setCustomSpacing(18, after: edit)
        }

        let sectionHeader = UIView()
        let kicker = UILabel(text: "FROM THIS RIDER", font: SkesteFont.demibold(9), color: Palette.secondary)
        kicker.tracked(2)
        sectionHeader.addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
        }
        let title = UILabel(text: "LINES & NOTES", font: SkesteFont.display(22), color: Palette.text)
        sectionHeader.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(kicker.snp.bottom).offset(2)
            make.bottom.equalToSuperview()
        }
        contentStack.addArrangedSubview(sectionHeader)
        contentStack.setCustomSpacing(13, after: sectionHeader)

        if posts.isEmpty {
            let wrap = UIView()
            wrap.backgroundColor = Palette.glass
            wrap.layer.cornerRadius = 14
            wrap.layer.borderWidth = 1
            wrap.layer.borderColor = Palette.hairline.cgColor
            let label = UILabel(text: "No lines or notes from this rider yet.", font: SkesteFont.body(13), color: Palette.muted, lines: 0)
            label.textAlignment = .center
            wrap.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(22) }
            contentStack.addArrangedSubview(wrap)
        } else {
            let grid = UIStackView()
            grid.axis = .vertical
            grid.spacing = 10
            var row: UIStackView?
            for (index, post) in posts.enumerated() {
                if index % 2 == 0 {
                    let newRow = UIStackView()
                    newRow.axis = .horizontal
                    newRow.spacing = 10
                    newRow.distribution = .fillEqually
                    grid.addArrangedSubview(newRow)
                    row = newRow
                }
                let tile = ProfilePostTile()
                tile.configure(post: post)
                tile.onOpen = { [weak self] in
                    self?.push(PostDetailViewController(postID: post.id))
                }
                row?.addArrangedSubview(tile)
            }
            if posts.count % 2 == 1 {
                let spacer = UIView()
                row?.addArrangedSubview(spacer)
            }
            contentStack.addArrangedSubview(grid)
        }

        if !isSelf {
            let report = UIButton(type: .system)
            report.setTitle("REPORT \(user.handle.uppercased())", for: .normal)
            report.setTitleColor(Palette.muted, for: .normal)
            report.titleLabel?.font = SkesteFont.demibold(8)
            report.addAction(UIAction { [weak self] _ in self?.reportUser() }, for: .touchUpInside)
            contentStack.addArrangedSubview(report)
            contentStack.setCustomSpacing(24, after: report)
        }

        lastSignature = signature()
    }

    private func buildActions(user: User) {
        let following = SKDataStore.shared.isFollowing(userID: user.id)
        let coach = SKDataStore.shared.coachProfile(for: user.id)

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 9
        row.distribution = .fillEqually

        if following {
            let follow = GhostButton(title: "FOLLOWING", icon: "checkmark", height: 48, tint: Palette.lime, borderColor: Palette.lime.withAlphaComponent(0.3))
            follow.addAction(UIAction { [weak self] _ in self?.toggleFollow(user) }, for: .touchUpInside)
            row.addArrangedSubview(follow)
        } else if coach != nil {
            let follow = GhostButton(title: "FOLLOW", icon: "plus", height: 48)
            follow.addAction(UIAction { [weak self] _ in self?.toggleFollow(user) }, for: .touchUpInside)
            row.addArrangedSubview(follow)
        } else {
            let follow = GradientButton(title: "FOLLOW", icon: "plus", colors: SkesteGradient.signature, height: 48)
            follow.addAction(UIAction { [weak self] _ in self?.toggleFollow(user) }, for: .touchUpInside)
            row.addArrangedSubview(follow)
        }

        if coach != nil {
            if let booking = SKDataStore.shared.openBooking(with: user.id) {
                if booking.status == .accepted {
                    let call = GhostButton(title: "VIDEO CALL", icon: "video.fill", height: 48, tint: Palette.lime, borderColor: Palette.lime.withAlphaComponent(0.3))
                    call.addAction(UIAction { [weak self] _ in self?.startCall(booking) }, for: .touchUpInside)
                    row.addArrangedSubview(call)
                } else {
                    let pending = GhostButton(title: "SESSION PENDING", icon: "clock", height: 48, tint: Palette.amber, borderColor: Palette.amber.withAlphaComponent(0.3))
                    pending.addAction(UIAction { [weak self] _ in self?.openBookingDetail(booking) }, for: .touchUpInside)
                    row.addArrangedSubview(pending)
                }
            } else {
                let book = GradientButton(title: "BOOK A SESSION", icon: "calendar.badge.plus", colors: SkesteGradient.signature, height: 48, fontSize: 13)
                book.addAction(UIAction { [weak self] _ in self?.bookSession(user) }, for: .touchUpInside)
                row.addArrangedSubview(book)
            }
        }
        contentStack.addArrangedSubview(row)
        contentStack.setCustomSpacing(18, after: row)
    }

    private func toggleFollow(_ user: User) {
        requireLogin { [weak self] in
            guard let self else { return }
            guard let following = SKDataStore.shared.toggleFollow(userID: user.id) else { return }
            SkesteHaptics.light()
            self.rebuild()
            self.showToast(following ? "You're following \(user.displayName)." : "You unfollowed \(user.displayName).", style: .success)
        }
    }

    private func bookSession(_ user: User) {
        requireLogin { [weak self] in
            guard let self else { return }
            guard SKDataStore.shared.coachProfile(for: user.id) != nil else {
                self.showToast("This rider is not taking sessions right now.", style: .error)
                return
            }
            self.push(BookingFormViewController(coachUserID: user.id))
        }
    }

    private func openBookingDetail(_ booking: CoachBooking) {
        push(BookingDetailViewController(bookingID: booking.id, source: source))
    }

    private func startCall(_ booking: CoachBooking) {
        guard booking.status == .accepted,
              let coach = SKDataStore.shared.user(withID: booking.coachUserID) else {
            showToast("This session is not confirmed yet.", style: .info)
            return
        }
        present(CoachingCallViewController(booking: booking, coach: coach), animated: true)
    }

    @objc private func coachingChanged() {
        guard isViewLoaded, view.window != nil, presentedViewController == nil else { return }
        rebuild()
    }

    private func reportUser() {
        guard userID != SKDataStore.shared.currentUser?.id else { return }
        requireLogin { [weak self] in
            guard let self else { return }
            self.push(ReportViewController(target: .user(userID: self.userID), source: self.source))
        }
    }
}
