import UIKit
import SnapKit

final class CallPulseView: UIView {
    private var rings: [CAShapeLayer] = []
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        gradient.colors = [Palette.cyan.withAlphaComponent(0.35).cgColor, Palette.magenta.withAlphaComponent(0.25).cgColor]
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)

        for index in 0..<3 {
            let ring = CAShapeLayer()
            ring.fillColor = UIColor.clear.cgColor
            ring.strokeColor = (index == 1 ? Palette.magenta : Palette.cyan).withAlphaComponent(0.34 - CGFloat(index) * 0.08).cgColor
            ring.lineWidth = 1
            layer.addSublayer(ring)
            rings.append(ring)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        gradient.cornerRadius = bounds.width / 2
        for (index, ring) in rings.enumerated() {
            let inset = CGFloat(6 + index * 16)
            ring.path = UIBezierPath(ovalIn: bounds.insetBy(dx: inset, dy: inset)).cgPath
            ring.frame = bounds
        }
    }

    func startPulsing() {
        for (index, ring) in rings.enumerated() {
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 0.92
            scale.toValue = 1.08
            scale.duration = 1.4 + Double(index) * 0.2
            scale.autoreverses = true
            scale.repeatCount = .infinity
            scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            ring.add(scale, forKey: "call.pulse")
            let opacity = CABasicAnimation(keyPath: "opacity")
            opacity.fromValue = 0.2
            opacity.toValue = 0.8
            opacity.duration = 1.2 + Double(index) * 0.15
            opacity.autoreverses = true
            opacity.repeatCount = .infinity
            ring.add(opacity, forKey: "call.opacity")
        }
    }
}

/// The private coaching session screen. The existing call surface is kept and now
/// receives the booked session, the coach and the topic focus.
final class CoachingCallViewController: UIViewController {
    private let booking: CoachBooking
    private let coach: User
    private let profile: CoachProfile?
    private let statusLabel = UILabel(text: "CONNECTING VIDEO…", font: SkesteFont.demibold(9), color: Palette.cyan)
    private let nameLabel: UILabel
    private let subtitleLabel: UILabel
    private let timerLabel = UILabel(text: "00:00", font: SkesteFont.mono(11, weight: .medium), color: Palette.muted)
    private let muteButton = UIButton(type: .system)
    private let speakerButton = UIButton(type: .system)
    private var seconds = 0
    private var timer: Timer?
    private var isMuted = false
    private var isSpeaker = true
    private var isEnding = false
    private var declineWork: DispatchWorkItem?
    private var dismissWork: DispatchWorkItem?

    init(booking: CoachBooking, coach: User) {
        self.booking = booking
        self.coach = coach
        self.profile = SKDataStore.shared.coachProfile(for: coach.id)
        nameLabel = UILabel(text: coach.displayName, font: SkesteFont.display(24), color: Palette.text)
        subtitleLabel = UILabel(
            text: profile.map { "COACH  ·  \($0.specialties.prefix(2).joined(separator: " / ").uppercased())" } ?? "COACH",
            font: SkesteFont.medium(10),
            color: Palette.cyan
        )
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        declineWork?.cancel()
        dismissWork?.cancel()
        timer?.invalidate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.ink
        UIApplication.shared.isIdleTimerDisabled = true

        let artwork = AlpineArtworkView()
        artwork.configure(seed: coach.avatarAsset + coach.id)
        view.addSubview(artwork)
        artwork.snp.makeConstraints { $0.edges.equalToSuperview() }
        // A slow drift keeps the remote frame feeling live instead of a frozen card.
        artwork.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        UIView.animate(withDuration: 14, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut]) {
            artwork.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        view.addSubview(blur)
        blur.snp.makeConstraints { $0.edges.equalToSuperview() }

        let shade = CAGradientLayer()
        shade.colors = [
            UIColor(hex: "03050F").withAlphaComponent(0.42).cgColor,
            UIColor(hex: "03050F").withAlphaComponent(0.15).cgColor,
            UIColor(hex: "03050F").withAlphaComponent(0.85).cgColor
        ]
        shade.locations = [0, 0.45, 1]
        let shadeView = UIView()
        shadeView.isUserInteractionEnabled = false
        shadeView.layer.addSublayer(shade)
        view.addSubview(shadeView)
        shadeView.snp.makeConstraints { $0.edges.equalToSuperview() }
        DispatchQueue.main.async { shade.frame = shadeView.bounds }

        let topKicker = UILabel(text: "SKESTE  /  PRIVATE COACHING", font: SkesteFont.demibold(8), color: Palette.secondary)
        topKicker.tracked(1.8)
        view.addSubview(topKicker)
        topKicker.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(22)
        }

        let minimize = SkesteControls.iconButton(symbol: "chevron.down", diameter: 38)
        minimize.addAction(UIAction { [weak self] _ in self?.endCall() }, for: .touchUpInside)
        view.addSubview(minimize)
        minimize.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalTo(topKicker)
        }

        let more = SkesteControls.iconButton(symbol: "ellipsis", diameter: 38)
        more.addAction(UIAction { [weak self] _ in self?.showCallMenu() }, for: .touchUpInside)
        view.addSubview(more)
        more.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(topKicker)
        }

        let pulse = CallPulseView()
        view.addSubview(pulse)
        pulse.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-104)
            make.width.height.equalTo(220)
        }
        let avatar = AvatarView(size: 114, showsRing: true)
        avatar.configure(user: coach)
        view.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.center.equalTo(pulse)
        }

        nameLabel.textAlignment = .center
        nameLabel.richTracking(-0.4)
        view.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(pulse.snp.bottom).offset(22)
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }

        subtitleLabel.textAlignment = .center
        subtitleLabel.tracked(1.2)
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
        }

        statusLabel.textAlignment = .center
        setStatus("CONNECTING VIDEO…", color: Palette.cyan)
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
        }

        timerLabel.textAlignment = .center
        view.addSubview(timerLabel)
        timerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(statusLabel.snp.bottom).offset(7)
        }

        let sessionPill = SkesteTagLabel(
            text: "\(booking.topic.title.uppercased())  ·  \(booking.durationMinutes) MIN  ·  \(booking.scheduledAt.bookingStamp.uppercased())",
            tint: Palette.ice,
            fill: Palette.glass
        )
        sessionPill.insets = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
        view.addSubview(sessionPill)
        sessionPill.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(timerLabel.snp.bottom).offset(12)
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }

        let controls = UIStackView()
        controls.axis = .horizontal
        controls.spacing = 22
        controls.alignment = .center
        controls.distribution = .equalCentering
        view.addSubview(controls)
        controls.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-34)
        }

        configureControl(muteButton, symbol: "mic.fill", title: "Mute")
        muteButton.addAction(UIAction { [weak self] _ in self?.toggleMute() }, for: .touchUpInside)
        configureControl(speakerButton, symbol: "speaker.wave.2.fill", title: "Speaker")
        speakerButton.addAction(UIAction { [weak self] _ in self?.toggleSpeaker() }, for: .touchUpInside)

        let endButton = UIButton(type: .system)
        endButton.backgroundColor = Palette.danger
        endButton.layer.cornerRadius = 34
        endButton.setImage(UIImage(systemName: "phone.down.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)), for: .normal)
        endButton.tintColor = .white
        endButton.applyGlow(color: Palette.danger, radius: 20, opacity: 0.35)
        endButton.addAction(UIAction { [weak self] _ in self?.endCall() }, for: .touchUpInside)
        endButton.snp.makeConstraints { $0.width.height.equalTo(68) }

        controls.addArrangedSubview(muteButton)
        controls.addArrangedSubview(endButton)
        controls.addArrangedSubview(speakerButton)
        controls.snp.makeConstraints { make in
            make.height.equalTo(82)
        }

        let privacy = UILabel(text: "PRIVATE SESSION  ·  NOT RECORDED", font: SkesteFont.demibold(7), color: Palette.muted)
        privacy.tracked(1.2)
        privacy.textAlignment = .center
        view.addSubview(privacy)
        privacy.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(controls.snp.top).offset(-20)
        }

        pulse.startPulsing()
        SkesteHaptics.medium()
        startTimer()
        scheduleDecline()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        timer?.invalidate()
    }

    private func configureControl(_ button: UIButton, symbol: String, title: String) {
        button.backgroundColor = Palette.glassStrong
        button.layer.cornerRadius = 28
        button.layer.borderWidth = 1
        button.layer.borderColor = Palette.hairline.cgColor
        button.tintColor = Palette.text
        button.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)), for: .normal)
        button.snp.makeConstraints { $0.width.height.equalTo(56) }
        button.accessibilityLabel = title
    }

    private func scheduleDecline() {
        let work = DispatchWorkItem { [weak self] in
            self?.showDeclined()
        }
        declineWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
    }

    private func showDeclined() {
        guard !isEnding else { return }
        isEnding = true
        timer?.invalidate()
        SkesteHaptics.warning()
        setStatus("CALL DECLINED", color: Palette.amber)
        timerLabel.text = "The coach declined the call."
        timerLabel.font = SkesteFont.medium(11)
        UIView.animate(withDuration: 0.25) {
            self.view.alpha = 0.82
        }
        let work = DispatchWorkItem { [weak self] in
            self?.dismiss(animated: true) {
                SkesteToast.show("Call declined.", style: .info)
            }
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: work)
    }

    private func setStatus(_ text: String, color: UIColor) {
        statusLabel.attributedText = NSAttributedString(string: text, attributes: [
            .font: SkesteFont.demibold(9),
            .foregroundColor: color,
            .kern: 1.8
        ])
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            self.seconds += 1
            self.timerLabel.text = String(format: "%02d:%02d", self.seconds / 60, self.seconds % 60)
        }
    }

    private func toggleMute() {
        isMuted.toggle()
        SkesteHaptics.light()
        let symbol = isMuted ? "mic.slash.fill" : "mic.fill"
        muteButton.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)), for: .normal)
        muteButton.tintColor = isMuted ? Palette.amber : Palette.text
        muteButton.backgroundColor = isMuted ? Palette.amber.withAlphaComponent(0.16) : Palette.glassStrong
    }

    private func toggleSpeaker() {
        isSpeaker.toggle()
        SkesteHaptics.light()
        let symbol = isSpeaker ? "speaker.wave.2.fill" : "speaker.slash.fill"
        speakerButton.setImage(UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)), for: .normal)
        speakerButton.tintColor = isSpeaker ? Palette.text : Palette.amber
    }

    private func showCallMenu() {
        let actions: [SkesteSheetAction] = [
            SkesteSheetAction(title: "View coach profile", symbol: "person.crop.circle") { [weak self] in
                self?.openProfile()
            },
            SkesteSheetAction(title: "Report this coach", symbol: "flag") { [weak self] in
                self?.presentReport()
            },
            SkesteSheetAction(title: "Block this coach", symbol: "hand.raised", destructive: true) { [weak self] in
                self?.confirmBlock()
            }
        ]
        present(SkesteActionSheetViewController(heading: "SESSION OPTIONS", message: nil, actions: actions), animated: true)
    }

    private func openProfile() {
        let profile = CoachProfileViewController(userID: coach.id, source: .coaching)
        let nav = SkesteNavigationController(rootViewController: profile)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    private func presentReport() {
        let report = ReportViewController(target: .user(userID: coach.id), source: .coaching)
        let nav = SkesteNavigationController(rootViewController: report)
        nav.modalPresentationStyle = .pageSheet
        report.onCompleted = { [weak self, weak nav] in
            nav?.dismiss(animated: true) {
                self?.endCall(message: "Report received. The session has ended.")
            }
        }
        present(nav, animated: true)
    }

    private func confirmBlock() {
        let alert = SkesteAlertViewController(
            title: "Block \(coach.displayName)?",
            message: "This coach and their content will leave your mountain. The session ends immediately and cannot be restored.",
            confirmTitle: "Block coach",
            destructive: true
        ) { [weak self] in
            guard let self else { return }
            SKDataStore.shared.removeUserAndData(userID: self.coach.id)
            self.endCall(message: "Coach blocked and removed.")
        }
        present(alert, animated: true)
    }

    private func endCall(message: String? = nil) {
        guard !isEnding else { return }
        isEnding = true
        declineWork?.cancel()
        dismissWork?.cancel()
        timer?.invalidate()
        dismiss(animated: true) {
            if let message {
                SkesteToast.show(message, style: .success)
            } else {
                SkesteToast.show("Session ended.", style: .info)
            }
        }
    }
}
