import UIKit
import SnapKit

final class CallPulseView: UIView {
    private var rings: [CAShapeLayer] = []
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        gradient.colors = [Palette.cyan.withAlphaComponent(0.35).cgColor, Palette.magenta.withAlphaComponent(0.25).cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
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

final class VideoCallViewController: UIViewController {
    private let peer: User
    private let statusLabel = UILabel(text: "CONNECTING VIDEO…", font: SkesteFont.demibold(9), color: Palette.cyan)
    private let nameLabel: UILabel
    private let subtitleLabel: UILabel
    private let timerLabel = UILabel(text: "00:00", font: SkesteFont.mono(11, weight: .medium), color: Palette.muted)
    private var declineWork: DispatchWorkItem?
    private var dismissWork: DispatchWorkItem?
    private var seconds = 0
    private var timer: Timer?
    private let muteButton = UIButton(type: .system)
    private let speakerButton = UIButton(type: .system)
    private var isMuted = false
    private var isSpeaker = true
    private var isEnding = false

    init(peer: User) {
        self.peer = peer
        nameLabel = UILabel(text: peer.displayName, font: SkesteFont.display(24), color: Palette.text)
        subtitleLabel = UILabel(text: peer.homeResort, font: SkesteFont.medium(12), color: Palette.secondary)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.ink
        UIApplication.shared.isIdleTimerDisabled = true

        let artwork = AlpineArtworkView()
        artwork.configure(seed: peer.avatarAsset + peer.id)
        self.view.addSubview(artwork)
        artwork.snp.makeConstraints { $0.edges.equalToSuperview() }

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

        let topKicker = UILabel(text: "SKESTE  /  PRIVATE VIDEO", font: SkesteFont.demibold(8), color: Palette.secondary)
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

        let pulse = CallPulseView()
        view.addSubview(pulse)
        pulse.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-96)
            make.width.height.equalTo(220)
        }
        let avatar = AvatarView(size: 114, showsRing: true)
        avatar.configure(user: peer)
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
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(0)
        }

        statusLabel.textAlignment = .center
        statusLabel.attributedText = NSAttributedString(string: "CONNECTING VIDEO…", attributes: [
            .font: SkesteFont.demibold(9),
            .foregroundColor: Palette.cyan,
            .kern: 1.8
        ])
        view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(18)
        }

        timerLabel.textAlignment = .center
        view.addSubview(timerLabel)
        timerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(statusLabel.snp.bottom).offset(7)
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

        let privacy = UILabel(text: "NO SELF PREVIEW  ·  YOUR CAMERA STAYS PRIVATE", font: SkesteFont.demibold(7), color: Palette.muted)
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

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            self.seconds += 1
            self.timerLabel.text = String(format: "%02d:%02d", self.seconds / 60, self.seconds % 60)
        }
    }

    private func scheduleDecline() {
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.isEnding else { return }
            self.showDeclined()
        }
        declineWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
    }

    private func showDeclined() {
        isEnding = true
        timer?.invalidate()
        SkesteHaptics.warning()
        statusLabel.text = "CALL DECLINED"
        statusLabel.attributedText = NSAttributedString(string: "CALL DECLINED", attributes: [
            .font: SkesteFont.demibold(9),
            .foregroundColor: Palette.amber,
            .kern: 1.8
        ])
        timerLabel.text = "The line went quiet."
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1, execute: work)
    }

    private func endCall() {
        guard !isEnding else { return }
        isEnding = true
        declineWork?.cancel()
        dismissWork?.cancel()
        timer?.invalidate()
        dismiss(animated: true)
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
}
