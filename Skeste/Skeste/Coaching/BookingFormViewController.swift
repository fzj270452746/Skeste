import UIKit
import SnapKit

final class BookingFormViewController: BaseViewController {
    private let coachUserID: String
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let detailsView = SkesteTextView(
        title: "Your question",
        placeholder: "e.g. I keep losing grip on steep, icy entries. What drills should I do before the next storm?",
        minHeight: 150
    )
    private let datePicker = UIDatePicker()
    private let durationControl = SkSegmentedControl(items: ["30 MIN", "45 MIN", "60 MIN"], selected: 1, compact: true)
    private let submitButton = GradientButton(title: "SEND SESSION REQUEST", icon: "paperplane.fill", height: 54)
    private var footerBottomConstraint: Constraint?
    private var topicButtons: [CoachingTopic: PillButton] = [:]
    private var selectedTopic: CoachingTopic?
    private var isWorking = false

    init(coachUserID: String) {
        self.coachUserID = coachUserID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        guard let coach = SKDataStore.shared.user(withID: coachUserID),
              let profile = SKDataStore.shared.coachProfile(for: coachUserID) else {
            showEmptyState()
            return
        }
        buildHeader()
        buildScroll(coach: coach, profile: profile)
        buildFooter()
        registerKeyboard()
        submitButton.addAction(UIAction { [weak self] _ in self?.submit() }, for: .touchUpInside)
    }

    private func showEmptyState() {
        let label = UILabel(text: "This coach is no longer taking sessions.", font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
        label.textAlignment = .center
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(30)
        }
    }

    private func buildHeader() {
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel(text: "NEW SESSION  /  COACH LINE", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.8)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }
    }

    private func buildScroll(coach: User, profile: CoachProfile) {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(58)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-78)
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }

        let kicker = UILabel(text: "BOOK A PRIVATE SESSION", font: SkesteFont.demibold(8), color: Palette.magenta)
        kicker.tracked(2)
        contentStack.addArrangedSubview(kicker)
        contentStack.setCustomSpacing(5, after: kicker)
        let title = UILabel(text: "TELL YOUR\nCOACH.", font: SkesteFont.display(32), color: Palette.text, lines: 2)
        title.richTracking(-0.8)
        contentStack.addArrangedSubview(title)
        contentStack.setCustomSpacing(14, after: title)

        let coachCard = UIView()
        coachCard.applyGlass(cornerRadius: 18, borderAlpha: 0.1, fill: Palette.glass)
        let identity = CoachIdentityView(user: coach, profile: profile)
        coachCard.addSubview(identity)
        identity.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)) }
        contentStack.addArrangedSubview(coachCard)
        contentStack.setCustomSpacing(22, after: coachCard)

        contentStack.addArrangedSubview(sectionLabel("WHAT DO YOU WANT TO WORK ON?"))
        contentStack.addArrangedSubview(topicGrid())
        contentStack.setCustomSpacing(16, after: contentStack.arrangedSubviews.last ?? coachCard)

        contentStack.addArrangedSubview(detailsView)
        let hint = UILabel(text: "A clear goal helps the coach prepare. You can add more detail later.", font: SkesteFont.medium(10), color: Palette.muted, lines: 0)
        hint.lineSpacing(2)
        contentStack.addArrangedSubview(hint)
        contentStack.setCustomSpacing(22, after: hint)

        durationControl.onChange = { _ in SkesteHaptics.light() }
        contentStack.addArrangedSubview(sectionLabel("PREFERRED TIME"))
        let timeCard = UIView()
        timeCard.applyGlass(cornerRadius: 16, borderAlpha: 0.09, fill: Palette.glass)
        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)))
        calendarIcon.tintColor = Palette.cyan
        calendarIcon.contentMode = .scaleAspectFit
        timeCard.addSubview(calendarIcon)
        calendarIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(18)
            make.width.height.equalTo(20)
        }
        let timeTitle = UILabel(text: "When works for you?", font: SkesteFont.medium(13), color: Palette.text)
        timeCard.addSubview(timeTitle)
        datePicker.datePickerMode = .dateAndTime
        datePicker.preferredDatePickerStyle = .compact
        datePicker.minuteInterval = 15
        datePicker.minimumDate = Date().addingTimeInterval(3600)
        datePicker.overrideUserInterfaceStyle = .dark
        datePicker.locale = Locale(identifier: "en_US")
        datePicker.tintColor = Palette.cyan
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        datePicker.date = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        timeCard.addSubview(datePicker)
        timeTitle.snp.makeConstraints { make in
            make.leading.equalTo(calendarIcon.snp.trailing).offset(10)
            make.centerY.equalTo(calendarIcon)
            make.trailing.equalToSuperview().offset(-14)
        }
        datePicker.snp.makeConstraints { make in
            make.leading.equalTo(timeTitle)
            make.trailing.equalToSuperview().offset(-10)
            make.top.equalTo(timeTitle.snp.bottom).offset(8)
            make.height.equalTo(40)
        }
        let timeNote = UILabel(text: "The coach confirms the exact slot when they accept.", font: SkesteFont.medium(10), color: Palette.muted, lines: 0)
        timeNote.lineSpacing(2)
        timeCard.addSubview(timeNote)
        timeNote.snp.makeConstraints { make in
            make.leading.equalTo(timeTitle)
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalTo(datePicker.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-14)
        }
        contentStack.addArrangedSubview(timeCard)
        contentStack.setCustomSpacing(22, after: timeCard)

        contentStack.addArrangedSubview(sectionLabel("SESSION LENGTH"))
        contentStack.addArrangedSubview(durationControl)
        contentStack.setCustomSpacing(22, after: durationControl)

        let privacy = UIView()
        privacy.applyGlass(cornerRadius: 16, borderAlpha: 0.08, fill: Palette.glass)
        let privacyIcon = UIImageView(image: UIImage(systemName: "lock.shield.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
        privacyIcon.tintColor = Palette.lime
        privacy.addSubview(privacyIcon)
        privacyIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(15)
            make.width.height.equalTo(18)
        }
        let privacyText = UILabel(text: "Private 1:1 video session. Not recorded. Only you and your coach can join, and only after they accept.", font: SkesteFont.body(11), color: Palette.secondary, lines: 0)
        privacyText.lineSpacing(2)
        privacy.addSubview(privacyText)
        privacyText.snp.makeConstraints { make in
            make.leading.equalTo(privacyIcon.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-14)
        }
        contentStack.addArrangedSubview(privacy)
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
        wrap.snp.makeConstraints { $0.height.equalTo(28) }
        return wrap
    }

    private func topicGrid() -> UIView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 8
        var row: UIStackView?
        for (index, topic) in CoachingTopic.allCases.enumerated() {
            if index % 2 == 0 {
                let newRow = UIStackView()
                newRow.axis = .horizontal
                newRow.spacing = 8
                newRow.distribution = .fillEqually
                grid.addArrangedSubview(newRow)
                row = newRow
            }
            let button = PillButton(title: topic.title, icon: topic.symbol)
            button.addAction(UIAction { [weak self] _ in self?.select(topic) }, for: .touchUpInside)
            button.accessibilityLabel = topic.title
            topicButtons[topic] = button
            row?.addArrangedSubview(button)
        }
        if CoachingTopic.allCases.count % 2 == 1 {
            row?.addArrangedSubview(UIView())
        }
        return grid
    }

    private func select(_ topic: CoachingTopic) {
        selectedTopic = topic
        for (key, button) in topicButtons {
            button.isSelected = key == topic
        }
        SkesteHaptics.light()
    }

    private func buildFooter() {
        let footer = UIView()
        view.addSubview(footer)
        footer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(96)
        }
        let fade = CAGradientLayer.skeste(colors: [UIColor.clear, Palette.canvas], start: CGPoint(x: 0.5, y: 0), end: CGPoint(x: 0.5, y: 1))
        let fadeView = UIView()
        fadeView.layer.addSublayer(fade)
        fadeView.isUserInteractionEnabled = false
        footer.addSubview(fadeView)
        fadeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        DispatchQueue.main.async { fade.frame = fadeView.bounds }
        footer.addSubview(submitButton)
        submitButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            footerBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8).constraint
        }
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
        footerBottomConstraint?.update(offset: offset - 8)
        scrollView.contentInset.bottom = overlap
        UIView.animate(withDuration: 0.24) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardHidden(_ note: Notification) {
        footerBottomConstraint?.update(offset: -8)
        scrollView.contentInset.bottom = 0
        UIView.animate(withDuration: 0.24) { self.view.layoutIfNeeded() }
    }

    private func submit() {
        guard !isWorking else { return }
        guard let coach = SKDataStore.shared.user(withID: coachUserID) else { return }
        guard let topic = selectedTopic else {
            showToast("Choose what you want to work on.", style: .error)
            SkesteHaptics.warning()
            return
        }
        let details = detailsView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard details.count >= 10 else {
            showToast("Add a little more detail so your coach can prepare.", style: .error)
            SkesteHaptics.warning()
            return
        }
        guard datePicker.date > Date() else {
            showToast("Pick a time in the future.", style: .error)
            return
        }
        requireLogin { [weak self] in
            guard let self else { return }
            self.isWorking = true
            self.submitButton.isEnabled = false
            self.submitButton.title = "SENDING REQUEST…"
            let minutes = [30, 45, 60][min(self.durationControl.selectedIndex, 2)]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self else { return }
                guard SKDataStore.shared.requestBooking(
                    coachUserID: self.coachUserID,
                    topic: topic,
                    details: details,
                    scheduledAt: self.datePicker.date,
                    durationMinutes: minutes
                ) != nil else {
                    self.isWorking = false
                    self.submitButton.isEnabled = true
                    self.submitButton.title = "SEND SESSION REQUEST"
                    self.showToast("That request could not be sent. Try again.", style: .error)
                    return
                }
                SkesteHaptics.success()
                self.navigationController?.popToRootViewController(animated: true)
                SkesteToast.show("Request sent to \(coach.displayName). You can start the call once the coach accepts.", style: .success)
            }
        }
    }
}
