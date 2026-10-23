import UIKit
import SnapKit

final class CoachingViewController: BaseViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    override func setupView() {
        NotificationCenter.default.addObserver(self, selector: #selector(coachingChanged), name: .skesteCoachingChanged, object: nil)
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
        guard isViewLoaded else { return }
        rebuild()
    }

    @objc private func coachingChanged() {
        guard isViewLoaded else { return }
        rebuild()
    }

    private func rebuild() {
        let previousOffset = scrollView.contentOffset
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        buildHeader()
        buildSessions()
        buildHowItWorks()
        buildCoaches()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.scrollView.setContentOffset(previousOffset, animated: false)
        }
    }

    private func buildHeader() {
        let header = UIView()
        let top = UIStackView()
        top.axis = .horizontal
        top.alignment = .center
        top.spacing = 8
        let kicker = UILabel(text: "COACH LINE  /  PRIVATE VIDEO", font: SkesteFont.demibold(8), color: Palette.cyan)
        kicker.tracked(1.8)
        top.addArrangedSubview(kicker)
        top.addArrangedSubview(UIView())
        let live = SkesteTagLabel(text: "1:1", tint: Palette.lime, fill: Palette.lime.withAlphaComponent(0.12))
        live.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        top.addArrangedSubview(live)
        header.addSubview(top)
        top.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }

        let title = UILabel(text: "LEARN\nYOUR LINE.", font: SkesteFont.display(36), color: Palette.text, lines: 2)
        title.richTracking(-0.9)
        header.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(top.snp.bottom).offset(8)
        }

        let dot = UIView()
        dot.backgroundColor = Palette.magenta
        dot.layer.cornerRadius = 6
        header.addSubview(dot)
        dot.snp.makeConstraints { make in
            make.leading.equalTo(title.snp.trailing).offset(8)
            make.top.equalTo(title.snp.top).offset(7)
            make.width.height.equalTo(12)
        }

        let subtitle = UILabel(text: "Pick a certified coach, tell them exactly what you want to work on, then meet on video once the coach accepts.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        subtitle.lineSpacing(3)
        header.addSubview(subtitle)
        subtitle.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview().offset(-34)
            make.top.equalTo(title.snp.bottom).offset(6)
            make.bottom.equalToSuperview()
        }
        contentStack.addArrangedSubview(header)
        contentStack.setCustomSpacing(22, after: header)

        if SKDataStore.shared.isLoggedIn {
            let open = SKDataStore.shared.myBookings.filter { $0.isOpen }
            let accepted = open.filter { $0.status == .accepted }.count
            let meta = UILabel(
                text: accepted > 0
                    ? "\(accepted) SESSION\(accepted == 1 ? "" : "S") READY  ·  \(open.count - accepted) WAITING"
                    : (open.isEmpty ? "NO ACTIVE SESSIONS" : "\(open.count) WAITING FOR A COACH"),
                font: SkesteFont.mono(8, weight: .bold),
                color: accepted > 0 ? Palette.lime : Palette.muted
            )
            meta.tracked(1.5)
            contentStack.addArrangedSubview(meta)
            contentStack.setCustomSpacing(18, after: meta)
        }
    }

    private func buildSessions() {
        let heading = SectionHeadingView(kicker: "Your bookings", title: "SESSIONS", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(12, after: heading)

        guard SKDataStore.shared.isLoggedIn else {
            buildLockedPanel()
            return
        }

        let bookings = SKDataStore.shared.myBookings
        guard !bookings.isEmpty else {
            let wrap = UIView()
            wrap.applyGlass(cornerRadius: 22, borderAlpha: 0.08, fill: Palette.glass)
            let label = UILabel(text: "No sessions yet. Choose a coach below and tell them what you want to fix, learn, or plan.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
            label.textAlignment = .center
            label.lineSpacing(3)
            wrap.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(22) }
            contentStack.addArrangedSubview(wrap)
            contentStack.setCustomSpacing(20, after: wrap)
            return
        }

        let sorted = bookings.sorted { lhs, rhs in
            if lhs.status != rhs.status {
                return statusRank(lhs.status) < statusRank(rhs.status)
            }
            return lhs.createdAt > rhs.createdAt
        }
        for booking in sorted {
            guard let coach = SKDataStore.shared.user(withID: booking.coachUserID) else { continue }
            let row = BookingRowView()
            row.configure(booking: booking, coach: coach)
            row.onCall = { [weak self] in self?.openCall(booking) }
            row.addAction(UIAction { [weak self] _ in self?.openDetail(booking) }, for: .touchUpInside)
            contentStack.addArrangedSubview(row)
            contentStack.setCustomSpacing(9, after: row)
        }
        contentStack.setCustomSpacing(22, after: contentStack.arrangedSubviews.last ?? heading)
    }

    private func statusRank(_ status: BookingStatus) -> Int {
        switch status {
        case .accepted: return 0
        case .pending: return 1
        case .declined: return 2
        case .completed: return 3
        case .cancelled: return 4
        }
    }

    private func buildLockedPanel() {
        let wrap = UIView()
        let lock = UIImageView(image: UIImage(systemName: "video.badge.checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .light)))
        lock.tintColor = Palette.cyan
        wrap.addSubview(lock)
        lock.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(32)
        }
        let kicker = UILabel(text: "MEMBERS ONLY", font: SkesteFont.demibold(9), color: Palette.magenta)
        kicker.tracked(2)
        kicker.textAlignment = .center
        wrap.addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.top.equalTo(lock.snp.bottom).offset(14)
            make.centerX.equalToSuperview()
        }
        let title = UILabel(text: "SIGN IN TO\nBOOK A COACH.", font: SkesteFont.display(24), color: Palette.text, lines: 2)
        title.textAlignment = .center
        wrap.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalTo(kicker.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview()
        }
        let message = UILabel(text: "Browse the coaches below. When you sign in you can describe the technique you want to work on and send a private session request.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        message.textAlignment = .center
        message.lineSpacing(3)
        wrap.addSubview(message)
        message.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        let button = GradientButton(title: "ENTER THE COACH LINE", icon: "arrow.right", height: 54)
        button.addAction(UIAction { [weak self] _ in
            self?.requireLogin { [weak self] in self?.rebuild() }
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
        wrap.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 30, left: 22, bottom: 22, right: 22)) }
        contentStack.addArrangedSubview(panel)
        contentStack.setCustomSpacing(24, after: panel)
    }

    private func buildHowItWorks() {
        let heading = SectionHeadingView(kicker: "Three steps", title: "HOW IT WORKS", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(12, after: heading)

        let card = UIView()
        card.applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)) }
        stack.addArrangedSubview(step(index: "01", title: "Pick a coach", detail: "Compare specialties, certifications and rider ratings."))
        stack.addArrangedSubview(step(index: "02", title: "Describe the goal", detail: "Tell them the exact technique, line or question you want to work on."))
        stack.addArrangedSubview(step(index: "03", title: "Meet on video", detail: "When the coach accepts, both of you can start the private session."))
        contentStack.addArrangedSubview(card)
        contentStack.setCustomSpacing(24, after: card)
    }

    private func step(index: String, title: String, detail: String) -> UIView {
        let row = UIView()
        let badge = UIView()
        badge.backgroundColor = Palette.glassStrong
        badge.layer.cornerRadius = 13
        badge.layer.borderWidth = 1
        badge.layer.borderColor = Palette.hairline.cgColor
        row.addSubview(badge)
        badge.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.width.height.equalTo(26)
        }
        let number = UILabel(text: index, font: SkesteFont.mono(9, weight: .bold), color: Palette.cyan)
        number.textAlignment = .center
        badge.addSubview(number)
        number.snp.makeConstraints { $0.center.equalToSuperview() }

        let titleLabel = UILabel(text: title, font: SkesteFont.demibold(13), color: Palette.text)
        row.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(badge.snp.trailing).offset(11)
            make.top.equalToSuperview().offset(-1)
            make.trailing.equalToSuperview()
        }
        let detailLabel = UILabel(text: detail, font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
        detailLabel.lineSpacing(2)
        row.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview()
        }
        return row
    }

    private func buildCoaches() {
        let heading = SectionHeadingView(kicker: "Certified riders", title: "COACHES", actionTitle: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(12, after: heading)

        let profiles = SKDataStore.shared.coaches
        guard !profiles.isEmpty else {
            let empty = UILabel(text: "Coaches are off the mountain right now. Check back soon.", font: SkesteFont.body(13), color: Palette.muted, lines: 0)
            empty.textAlignment = .center
            contentStack.addArrangedSubview(empty)
            return
        }
        for profile in profiles {
            guard let user = SKDataStore.shared.user(withID: profile.userID) else { continue }
            let card = CoachCardView()
            card.configure(profile: profile, user: user)
            card.addAction(UIAction { [weak self] _ in
                self?.push(CoachProfileViewController(userID: user.id, source: .coaching))
            }, for: .touchUpInside)
            contentStack.addArrangedSubview(card)
            contentStack.setCustomSpacing(10, after: card)
        }
    }

    private func openDetail(_ booking: CoachBooking) {
        push(BookingDetailViewController(bookingID: booking.id, source: .coaching))
    }

    private func openCall(_ booking: CoachBooking) {
        guard booking.status == .accepted,
              let coach = SKDataStore.shared.user(withID: booking.coachUserID) else {
            showToast("This session is not confirmed yet.", style: .info)
            return
        }
        let call = CoachingCallViewController(booking: booking, coach: coach)
        present(call, animated: true)
    }
}
