import UIKit
import SnapKit

final class CoachProfileViewController: BaseViewController {
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
        guard didBuild else {
            rebuild()
            return
        }
        if SKDataStore.shared.user(withID: userID) == nil || SKDataStore.shared.coachProfile(for: userID) == nil {
            navigationController?.popViewController(animated: true)
            return
        }
        if signature() != lastSignature {
            rebuild()
        }
    }

    override func authDidChange() {
        rebuild()
    }

    override func contentDidChange() {
        guard isViewLoaded, view.window != nil, presentedViewController == nil else { return }
        if SKDataStore.shared.user(withID: userID) == nil {
            navigationController?.popViewController(animated: true)
        } else {
            rebuild()
        }
    }

    @objc private func coachingChanged() {
        guard isViewLoaded else { return }
        rebuild()
    }

    private func signature() -> String {
        guard let user = SKDataStore.shared.user(withID: userID) else { return "missing" }
        let profile = SKDataStore.shared.coachProfile(for: userID)
        let booking = SKDataStore.shared.openBooking(with: userID)?.status.rawValue ?? "none"
        return "\(user.displayName)-\(user.bio)-\(user.isVerified)-\(user.avatarFileName ?? user.avatarAsset)-\(profile?.rating ?? 0)-\(booking)-\(SKDataStore.shared.isFollowing(userID: userID))-\(SKDataStore.shared.currentUser?.id ?? "guest")"
    }

    private func buildHeader() {
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { [weak self] _ in self?.closeProfile() }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel(text: "COACH PROFILE", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.9)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }
        let flag = SkesteControls.iconButton(symbol: "flag", diameter: 40)
        flag.addAction(UIAction { [weak self] _ in self?.reportCoach() }, for: .touchUpInside)
        view.addSubview(flag)
        flag.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.centerY.equalTo(back)
        }
    }

    private func closeProfile() {
        guard let nav = navigationController else { return }
        if nav.viewControllers.first === self, nav.presentingViewController != nil {
            nav.dismiss(animated: true)
        } else {
            nav.popViewController(animated: true)
        }
    }

    private func rebuild() {
        guard let user = SKDataStore.shared.user(withID: userID),
              let profile = SKDataStore.shared.coachProfile(for: userID) else { return }
        didBuild = true
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

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
        let coachBadge = SkesteTagLabel(text: "CERTIFIED COACH", tint: Palette.lime, fill: Palette.lime.withAlphaComponent(0.12))
        coachBadge.insets = UIEdgeInsets(top: 4, left: 9, bottom: 4, right: 9)
        hero.addSubview(coachBadge)
        coachBadge.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(6)
        }

        let name = UILabel(text: user.displayName, font: SkesteFont.display(28), color: Palette.text, lines: 0)
        name.textAlignment = .center
        name.richTracking(-0.4)
        hero.addSubview(name)
        name.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(avatar.snp.bottom).offset(15)
        }

        let handle = UILabel(text: "\(user.handle)  ·  \(user.homeResort)", font: SkesteFont.demibold(11), color: Palette.cyan)
        handle.textAlignment = .center
        hero.addSubview(handle)
        handle.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(name.snp.bottom).offset(1)
        }

        let headline = UILabel(text: profile.headline, font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        headline.textAlignment = .center
        headline.lineSpacing(3)
        hero.addSubview(headline)
        headline.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.top.equalTo(handle.snp.bottom).offset(8)
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
        let values = [
            ("RATING", String(format: "%.1f", profile.rating)),
            ("SESSIONS", "\(profile.sessionCount)"),
            ("YEARS", "\(profile.yearsExperience)")
        ]
        for (index, value) in values.enumerated() {
            let column = UIStackView()
            column.axis = .vertical
            column.alignment = .center
            column.spacing = 1
            column.addArrangedSubview(UILabel(text: value.1, font: SkesteFont.display(25), color: Palette.text))
            let label = UILabel(text: value.0, font: SkesteFont.demibold(7), color: Palette.muted)
            label.tracked(1.3)
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
        }
        contentStack.addArrangedSubview(stats)
        contentStack.setCustomSpacing(14, after: stats)

        if !user.bio.isEmpty {
            let bioWrap = UIView()
            let bar = AccentLineView()
            bar.setColors([Palette.cyan, Palette.magenta])
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
            contentStack.setCustomSpacing(20, after: bioWrap)
        }

        if !profile.specialties.isEmpty {
            contentStack.addArrangedSubview(sectionLabel("WHAT I COACH"))
            contentStack.addArrangedSubview(tagGrid(profile.specialties))
            contentStack.setCustomSpacing(20, after: contentStack.arrangedSubviews.last ?? hero)
        }

        contentStack.addArrangedSubview(sectionLabel("CERTIFICATIONS & LOGISTICS"))
        let details = UIView()
        details.applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)
        let detailStack = UIStackView()
        detailStack.axis = .vertical
        detailStack.spacing = 0
        details.addSubview(detailStack)
        detailStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)) }
        for certification in profile.certifications {
            detailStack.addArrangedSubview(infoRow(symbol: "checkmark.seal.fill", title: certification, value: "Certified"))
        }
        detailStack.addArrangedSubview(infoRow(symbol: "globe", title: "Languages", value: profile.languages.joined(separator: " / ")))
        detailStack.addArrangedSubview(infoRow(symbol: "calendar", title: "Availability", value: profile.availability))
        detailStack.addArrangedSubview(infoRow(symbol: "clock", title: "Response", value: profile.responseTime, showsDivider: false))
        contentStack.addArrangedSubview(details)
        contentStack.setCustomSpacing(22, after: details)

        buildActions(user: user)
        lastSignature = signature()
    }

    private func sectionLabel(_ text: String) -> UIView {
        let label = UILabel(text: text, font: SkesteFont.demibold(9), color: Palette.muted)
        label.tracked(1.8)
        let wrap = UIView()
        wrap.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(2)
            make.top.bottom.equalToSuperview()
        }
        wrap.snp.makeConstraints { $0.height.equalTo(26) }
        return wrap
    }

    private func tagGrid(_ tags: [String]) -> UIView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 8
        var row: UIStackView?
        for (index, tag) in tags.enumerated() {
            if index % 2 == 0 {
                let newRow = UIStackView()
                newRow.axis = .horizontal
                newRow.spacing = 8
                newRow.distribution = .fillEqually
                grid.addArrangedSubview(newRow)
                row = newRow
            }
            let label = SkesteTagLabel(text: tag, tint: Palette.ice, fill: Palette.glass)
            label.insets = UIEdgeInsets(top: 9, left: 10, bottom: 9, right: 10)
            row?.addArrangedSubview(label)
        }
        if tags.count % 2 == 1 {
            row?.addArrangedSubview(UIView())
        }
        return grid
    }

    private func infoRow(symbol: String, title: String, value: String, showsDivider: Bool = true) -> UIView {
        let row = UIView()
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
        icon.tintColor = Palette.cyan
        icon.contentMode = .scaleAspectFit
        row.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        let titleLabel = UILabel(text: title, font: SkesteFont.medium(13), color: Palette.text)
        row.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(11)
            make.bottom.equalToSuperview().offset(-11)
        }
        let valueLabel = UILabel(text: value, font: SkesteFont.medium(11), color: Palette.muted)
        valueLabel.textAlignment = .right
        row.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
        }
        if showsDivider {
            let divider = UIView()
            divider.backgroundColor = Palette.hairline
            row.addSubview(divider)
            divider.snp.makeConstraints { make in
                make.leading.equalTo(titleLabel)
                make.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
        }
        return row
    }

    private func buildActions(user: User) {
        if user.id == SKDataStore.shared.currentUser?.id {
            return
        }
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 9
        let booking = SKDataStore.shared.openBooking(with: userID)

        if let booking, booking.status == .accepted {
            let call = GradientButton(title: "START VIDEO CALL", icon: "video.fill", colors: SkesteGradient.lime, height: 54, fontSize: 15)
            call.addAction(UIAction { [weak self] _ in self?.startCall(booking) }, for: .touchUpInside)
            stack.addArrangedSubview(call)
            let view = GhostButton(title: "VIEW SESSION", icon: "calendar", height: 48)
            view.addAction(UIAction { [weak self] _ in self?.openDetail(booking) }, for: .touchUpInside)
            stack.addArrangedSubview(view)
            let note = UILabel(text: "CONFIRMED  ·  START THE CALL WHEN YOU'RE READY", font: SkesteFont.demibold(8), color: Palette.lime)
            note.tracked(1.2)
            note.textAlignment = .center
            stack.addArrangedSubview(note)
        } else if let booking, booking.status == .pending {
            let pending = GhostButton(title: "SESSION PENDING", icon: "clock", height: 50, tint: Palette.amber, borderColor: Palette.amber.withAlphaComponent(0.3))
            pending.addAction(UIAction { [weak self] _ in self?.openDetail(booking) }, for: .touchUpInside)
            stack.addArrangedSubview(pending)
            let note = UILabel(text: "YOU'LL BE ABLE TO CALL ONCE \(user.displayName.uppercased()) ACCEPTS", font: SkesteFont.demibold(8), color: Palette.muted)
            note.tracked(1.1)
            note.textAlignment = .center
            note.numberOfLines = 0
            stack.addArrangedSubview(note)
        } else {
            let book = GradientButton(title: "REQUEST A VIDEO SESSION", icon: "calendar.badge.plus", height: 54, fontSize: 15)
            book.addAction(UIAction { [weak self] _ in self?.bookSession() }, for: .touchUpInside)
            stack.addArrangedSubview(book)
            let note = UILabel(text: "TELL THE COACH WHAT YOU WANT TO WORK ON", font: SkesteFont.demibold(8), color: Palette.muted)
            note.tracked(1.1)
            note.textAlignment = .center
            stack.addArrangedSubview(note)
        }
        contentStack.addArrangedSubview(stack)
        contentStack.setCustomSpacing(18, after: stack)

        let report = UIButton(type: .system)
        report.setTitle("REPORT \(user.handle.uppercased())", for: .normal)
        report.setTitleColor(Palette.muted, for: .normal)
        report.titleLabel?.font = SkesteFont.demibold(8)
        report.addAction(UIAction { [weak self] _ in self?.reportCoach() }, for: .touchUpInside)
        contentStack.addArrangedSubview(report)
    }

    private func bookSession() {
        requireLogin { [weak self] in
            guard let self, SKDataStore.shared.coachProfile(for: self.userID) != nil else { return }
            self.push(BookingFormViewController(coachUserID: self.userID))
        }
    }

    private func startCall(_ booking: CoachBooking) {
        guard booking.status == .accepted,
              let coach = SKDataStore.shared.user(withID: booking.coachUserID) else {
            showToast("This session is not confirmed yet.", style: .info)
            return
        }
        present(CoachingCallViewController(booking: booking, coach: coach), animated: true)
    }

    private func openDetail(_ booking: CoachBooking) {
        push(BookingDetailViewController(bookingID: booking.id, source: source))
    }

    private func reportCoach() {
        guard userID != SKDataStore.shared.currentUser?.id else { return }
        requireLogin { [weak self] in
            guard let self else { return }
            self.push(ReportViewController(target: .user(userID: self.userID), source: self.source))
        }
    }
}
