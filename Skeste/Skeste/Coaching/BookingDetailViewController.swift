import UIKit
import SnapKit

final class BookingDetailViewController: BaseViewController {
    private let bookingID: String
    private let source: RootTab
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var lastSignature = ""
    private var didBuild = false

    init(bookingID: String, source: RootTab) {
        self.bookingID = bookingID
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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(58)
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-(AppLayout.tabBarClearance + 20))
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }
        rebuild()
    }

    override func refreshView() {
        guard didBuild else {
            rebuild()
            return
        }
        if SKDataStore.shared.booking(withID: bookingID) == nil {
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
        rebuild()
    }

    @objc private func coachingChanged() {
        guard isViewLoaded else { return }
        rebuild()
    }

    private func signature() -> String {
        guard let booking = SKDataStore.shared.booking(withID: bookingID) else { return "missing" }
        return "\(booking.status.rawValue)-\(booking.respondedAt?.timeIntervalSince1970 ?? 0)-\(booking.lastCallDuration ?? 0)-\(booking.scheduledAt.timeIntervalSince1970)-\(SKDataStore.shared.currentUser?.id ?? "guest")"
    }

    private func buildHeader() {
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel(text: "PRIVATE SESSION", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.9)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }
    }

    private func rebuild() {
        guard let booking = SKDataStore.shared.booking(withID: bookingID),
              let coach = SKDataStore.shared.user(withID: booking.coachUserID),
              let profile = SKDataStore.shared.coachProfile(for: booking.coachUserID) else { return }
        didBuild = true
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let kicker = UILabel(text: "COACH LINE  /  SESSION", font: SkesteFont.demibold(8), color: Palette.cyan)
        kicker.tracked(2)
        contentStack.addArrangedSubview(kicker)
        contentStack.setCustomSpacing(5, after: kicker)
        let title = UILabel(text: "YOUR\nSESSION.", font: SkesteFont.display(32), color: Palette.text, lines: 2)
        title.richTracking(-0.8)
        contentStack.addArrangedSubview(title)
        contentStack.setCustomSpacing(16, after: title)

        let coachCard = UIView()
        coachCard.applyGlass(cornerRadius: 18, borderAlpha: 0.1, fill: Palette.glass)
        let identity = CoachIdentityView(user: coach, profile: profile)
        coachCard.addSubview(identity)
        identity.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
            make.trailing.lessThanOrEqualToSuperview().offset(-100)
        }
        let status = SkesteTagLabel(text: booking.status.title, tint: statusColor(booking.status), fill: statusColor(booking.status).withAlphaComponent(0.12))
        status.insets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        coachCard.addSubview(status)
        status.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
        contentStack.addArrangedSubview(coachCard)
        contentStack.setCustomSpacing(14, after: coachCard)

        let meta = UIView()
        meta.applyGlass(cornerRadius: 16, borderAlpha: 0.08, fill: Palette.glass)
        let metaStack = UIStackView()
        metaStack.axis = .vertical
        metaStack.spacing = 0
        meta.addSubview(metaStack)
        metaStack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)) }
        metaStack.addArrangedSubview(metaRow(symbol: "calendar", title: "Preferred time", value: booking.scheduledAt.bookingStamp))
        metaStack.addArrangedSubview(metaRow(symbol: "timer", title: "Session length", value: "\(booking.durationMinutes) minutes"))
        metaStack.addArrangedSubview(metaRow(symbol: "tag", title: "Focus", value: booking.topic.title))
        if let duration = booking.lastCallDuration, duration > 0 {
            metaStack.addArrangedSubview(metaRow(symbol: "video.fill", title: "Last call", value: Self.durationLabel(duration), showsDivider: false))
        }
        contentStack.addArrangedSubview(meta)
        contentStack.setCustomSpacing(22, after: meta)

        contentStack.addArrangedSubview(sectionLabel("WHAT YOU ASKED"))
        let detailsCard = UIView()
        detailsCard.applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)
        let topicTag = SkesteTagLabel(text: booking.topic.title, tint: Palette.ice, fill: Palette.glassStrong)
        topicTag.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        detailsCard.addSubview(topicTag)
        topicTag.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
        }
        let details = UILabel(text: booking.details, font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
        details.lineSpacing(3)
        detailsCard.addSubview(details)
        details.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(14)
            make.top.equalTo(topicTag.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-16)
        }
        contentStack.addArrangedSubview(detailsCard)
        contentStack.setCustomSpacing(20, after: detailsCard)

        contentStack.addArrangedSubview(timeline(booking))
        contentStack.setCustomSpacing(22, after: contentStack.arrangedSubviews.last ?? coachCard)

        buildActions(booking: booking, coach: coach)
        lastSignature = signature()
    }

    private func statusColor(_ status: BookingStatus) -> UIColor {
        switch status {
        case .pending: return Palette.amber
        case .accepted: return Palette.lime
        case .declined: return Palette.danger
        case .cancelled: return Palette.muted
        case .completed: return Palette.cyan
        }
    }

    private func sectionLabel(_ text: String) -> UIView {
        let label = UILabel(text: text, font: SkesteFont.demibold(9), color: Palette.muted)
        label.tracked(1.7)
        let wrap = UIView()
        wrap.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(2)
            make.top.bottom.equalToSuperview()
        }
        wrap.snp.makeConstraints { $0.height.equalTo(26) }
        return wrap
    }

    private func metaRow(symbol: String, title: String, value: String, showsDivider: Bool = true) -> UIView {
        let row = UIView()
        let icon = UIImageView(image: UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
        icon.tintColor = Palette.cyan
        icon.contentMode = .scaleAspectFit
        row.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        let titleLabel = UILabel(text: title, font: SkesteFont.medium(12), color: Palette.secondary)
        row.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(11)
            make.bottom.equalToSuperview().offset(-11)
        }
        let valueLabel = UILabel(text: value, font: SkesteFont.medium(12), color: Palette.text)
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

    private func timeline(_ booking: CoachBooking) -> UIView {
        let card = UIView()
        card.applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 15, left: 16, bottom: 15, right: 16)) }
        stack.addArrangedSubview(timelineRow(title: "Request sent", detail: booking.createdAt.bookingStamp, done: true))
        let responded = booking.respondedAt.map { "\(booking.status == .accepted ? "Accepted" : "Answered") · \($0.bookingStamp)" }
        stack.addArrangedSubview(timelineRow(
            title: "Coach response",
            detail: responded ?? "Waiting for the coach",
            done: booking.status != .pending
        ))
        let callDetail: String
        switch booking.status {
        case .accepted: callDetail = "Ready — start the call from this session"
        case .pending: callDetail = "Unlocks after the coach accepts"
        case .completed: callDetail = "Completed"
        case .declined: callDetail = "Not available"
        case .cancelled: callDetail = "Cancelled"
        }
        stack.addArrangedSubview(timelineRow(title: "Video session", detail: callDetail, done: booking.status == .accepted || booking.status == .completed))
        return card
    }

    private func timelineRow(title: String, detail: String, done: Bool) -> UIView {
        let row = UIView()
        let dot = UIView()
        dot.backgroundColor = done ? Palette.lime : Palette.hairline
        dot.layer.cornerRadius = 5
        row.addSubview(dot)
        dot.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(2)
            make.width.height.equalTo(10)
        }
        let titleLabel = UILabel(text: title, font: SkesteFont.demibold(12), color: done ? Palette.text : Palette.muted)
        row.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(dot.snp.trailing).offset(10)
            make.top.equalToSuperview().offset(-2)
        }
        let detailLabel = UILabel(text: detail, font: SkesteFont.medium(10), color: Palette.muted, lines: 0)
        row.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview()
        }
        return row
    }

    private func buildActions(booking: CoachBooking, coach: User) {
        switch booking.status {
        case .accepted:
            let call = GradientButton(title: "START VIDEO CALL", icon: "video.fill", colors: SkesteGradient.lime, height: 54, fontSize: 15)
            call.addAction(UIAction { [weak self] _ in self?.startCall(booking) }, for: .touchUpInside)
            contentStack.addArrangedSubview(call)
            contentStack.setCustomSpacing(9, after: call)
            let note = UILabel(text: "START THE CALL WHEN YOU'RE READY", font: SkesteFont.demibold(8), color: Palette.lime)
            note.tracked(1.1)
            note.textAlignment = .center
            contentStack.addArrangedSubview(note)
            contentStack.setCustomSpacing(18, after: note)
            let cancel = GhostButton(title: "CANCEL SESSION", icon: "xmark", height: 48, tint: Palette.danger, borderColor: Palette.danger.withAlphaComponent(0.3))
            cancel.addAction(UIAction { [weak self] _ in self?.confirmCancel(booking) }, for: .touchUpInside)
            contentStack.addArrangedSubview(cancel)
        case .pending:
            let waiting = UIView()
            waiting.applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = Palette.amber
            spinner.startAnimating()
            waiting.addSubview(spinner)
            spinner.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(16)
                make.centerY.equalToSuperview()
            }
            let label = UILabel(text: "Waiting for \(coach.displayName) to accept. Most coaches reply quickly.", font: SkesteFont.body(12), color: Palette.secondary, lines: 0)
            label.lineSpacing(2)
            waiting.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalTo(spinner.snp.trailing).offset(12)
                make.trailing.equalToSuperview().offset(-16)
                make.top.equalToSuperview().offset(15)
                make.bottom.equalToSuperview().offset(-15)
            }
            contentStack.addArrangedSubview(waiting)
            contentStack.setCustomSpacing(12, after: waiting)
            let cancel = GhostButton(title: "CANCEL REQUEST", icon: "xmark", height: 48, tint: Palette.danger, borderColor: Palette.danger.withAlphaComponent(0.3))
            cancel.addAction(UIAction { [weak self] _ in self?.confirmCancel(booking) }, for: .touchUpInside)
            contentStack.addArrangedSubview(cancel)
        case .declined:
            let note = UILabel(text: "\(coach.displayName) can't take this session. Try another coach — there are several who teach the same ground.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
            note.lineSpacing(3)
            contentStack.addArrangedSubview(note)
            contentStack.setCustomSpacing(14, after: note)
            let find = GradientButton(title: "FIND ANOTHER COACH", icon: "person.2.fill", height: 52, fontSize: 14)
            find.addAction(UIAction { [weak self] _ in self?.navigationController?.popToRootViewController(animated: true) }, for: .touchUpInside)
            contentStack.addArrangedSubview(find)
        case .cancelled, .completed:
            let again = GradientButton(title: "BOOK ANOTHER SESSION", icon: "calendar.badge.plus", height: 52, fontSize: 14)
            again.addAction(UIAction { [weak self] _ in self?.rebook() }, for: .touchUpInside)
            contentStack.addArrangedSubview(again)
        }

        let report = UIButton(type: .system)
        report.setTitle("REPORT \(coach.handle.uppercased())", for: .normal)
        report.setTitleColor(Palette.muted, for: .normal)
        report.titleLabel?.font = SkesteFont.demibold(8)
        report.addAction(UIAction { [weak self] _ in self?.reportCoach(coach) }, for: .touchUpInside)
        contentStack.addArrangedSubview(report)
    }

    private func startCall(_ booking: CoachBooking) {
        guard booking.status == .accepted,
              let coach = SKDataStore.shared.user(withID: booking.coachUserID) else {
            showToast("This session is not confirmed yet.", style: .info)
            return
        }
        present(CoachingCallViewController(booking: booking, coach: coach), animated: true)
    }

    private func confirmCancel(_ booking: CoachBooking) {
        let coachName = SKDataStore.shared.user(withID: booking.coachUserID)?.displayName ?? "your coach"
        showConfirm(
            title: "Cancel this session?",
            message: "\(coachName) will be notified and the call entry will close.",
            confirmTitle: "Cancel session",
            destructive: true
        ) { [weak self] in
            SKDataStore.shared.cancelBooking(id: booking.id)
            SkesteHaptics.warning()
            self?.navigationController?.popViewController(animated: true)
            SkesteToast.show("Session cancelled.", style: .info)
        }
    }

    private func rebook() {
        guard let booking = SKDataStore.shared.booking(withID: bookingID) else { return }
        push(BookingFormViewController(coachUserID: booking.coachUserID))
    }

    private func reportCoach(_ coach: User) {
        push(ReportViewController(target: .user(userID: coach.id), source: source))
    }

    static func durationLabel(_ duration: TimeInterval) -> String {
        let total = max(0, Int(duration))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
