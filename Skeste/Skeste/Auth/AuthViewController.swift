import UIKit
import SnapKit
import AuthenticationServices

final class AuthViewController: BaseViewController {
    var onAuthenticated: (() -> Void)?

    private enum Mode {
        case login
        case signup
    }

    private var mode: Mode = .login
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let modeControl = SkSegmentedControl(items: ["LOG IN", "SIGN UP"], selected: 0)
    private let usernameField = SkesteTextField(title: "Username", placeholder: "your ride name", icon: "person")
    private let passwordField = SkesteTextField(title: "Password", placeholder: "6+ characters", icon: "lock", secure: true)
    private let confirmField = SkesteTextField(title: "Confirm password", placeholder: "one more time", icon: "checkmark.shield", secure: true)
    private let submitButton = GradientButton(title: "ENTER THE MOUNTAIN", icon: "arrow.up.right", height: 54)
    private let footerTextView = UITextView()
    private let appleService = AppleSignInService()
    private var confirmTopConstraint: Constraint?
    private var isRunning = false

    override func setupView() {
        buildHeader()
        buildScroll()
        buildFooter()
        configureApple()
        modeControl.onChange = { [weak self] index in
            self?.setMode(index == 0 ? .login : .signup)
        }
        submitButton.addAction(UIAction { [weak self] _ in
            self?.submit()
        }, for: .touchUpInside)
    }

    private func buildHeader() {
        let close = SkesteControls.iconButton(symbol: "xmark", diameter: 40)
        close.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }

        let brand = UILabel(text: "SKESTE  /  ACCESS", font: SkesteFont.demibold(9), color: Palette.secondary)
        brand.tracked(2)
        view.addSubview(brand)
        brand.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(close)
        }

        let mark = SkesteMarkView()
        view.addSubview(mark)
        mark.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.centerY.equalTo(close)
            make.width.height.equalTo(38)
        }
    }

    private func buildScroll() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-56)
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        let kickerMark = UIView()
        kickerMark.backgroundColor = Palette.magenta
        kickerMark.layer.cornerRadius = 1
        contentView.addSubview(kickerMark)
        kickerMark.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(26)
            make.top.equalToSuperview().offset(12)
            make.width.equalTo(2)
            make.height.equalTo(10)
        }

        let kicker = UILabel(text: "THE ALPINE SOCIAL — EST. 2026", font: SkesteFont.demibold(9), color: Palette.secondary)
        kicker.tracked(1.8)
        contentView.addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.leading.equalTo(kickerMark.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-26)
            make.centerY.equalTo(kickerMark)
        }

        let titleTop = UILabel(text: "FIND YOUR", font: SkesteFont.display(34), color: Palette.text)
        titleTop.richTracking(0.3)
        contentView.addSubview(titleTop)
        titleTop.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.top.equalTo(kickerMark.snp.bottom).offset(12)
        }

        let titleBottom = UILabel(text: "LINE.", font: SkesteFont.display(54), color: Palette.magenta)
        titleBottom.richTracking(0.3)
        contentView.addSubview(titleBottom)
        titleBottom.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.top.equalTo(titleTop.snp.bottom).offset(-4)
        }

        let subtitle = UILabel(text: "A mountain social for riders chasing first light, deep snow, and good company.", font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
        subtitle.lineSpacing(3)
        contentView.addSubview(subtitle)
        subtitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-54)
            make.top.equalTo(titleBottom.snp.bottom).offset(10)
        }

        let riderStack = UIStackView()
        riderStack.axis = .horizontal
        riderStack.spacing = -8
        let riderIDs = ["u_luna", "u_kai", "u_sofia", "u_ava"]
        for id in riderIDs {
            let avatar = AvatarView(size: 28, showsRing: true)
            avatar.configure(user: AppStore.shared.user(withID: id))
            riderStack.addArrangedSubview(avatar)
        }
        contentView.addSubview(riderStack)
        riderStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(26)
            make.top.equalTo(subtitle.snp.bottom).offset(15)
            make.height.equalTo(28)
        }
        let riderLabel = UILabel(text: "RIDERS ON THE RIDGE TONIGHT", font: SkesteFont.demibold(8), color: Palette.muted)
        riderLabel.tracked(1.5)
        contentView.addSubview(riderLabel)
        riderLabel.snp.makeConstraints { make in
            make.leading.equalTo(riderStack.snp.trailing).offset(12)
            make.centerY.equalTo(riderStack)
        }

        let formCard = UIView()
        formCard.applyGlass(cornerRadius: 14, borderAlpha: 0.12, fill: Palette.glass)
        contentView.addSubview(formCard)
        formCard.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
            make.top.equalTo(riderStack.snp.bottom).offset(18)
            make.bottom.equalToSuperview().offset(-24)
        }

        let lineView = UIView()
        lineView.backgroundColor = Palette.magenta
        lineView.layer.cornerRadius = 1
        formCard.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(16)
            make.width.equalTo(44)
            make.height.equalTo(2)
        }

        let welcome = UILabel(text: mode == .login ? "Welcome back to the ridge." : "Claim your line.", font: SkesteFont.demibold(14), color: Palette.text)
        formCard.addSubview(welcome)
        welcome.tag = 901
        welcome.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(lineView.snp.bottom).offset(12)
        }

        formCard.addSubview(modeControl)
        modeControl.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(welcome.snp.bottom).offset(14)
        }

        let fields = UIStackView(arrangedSubviews: [usernameField, passwordField, confirmField])
        fields.axis = .vertical
        fields.spacing = 14
        formCard.addSubview(fields)
        fields.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(modeControl.snp.bottom).offset(18)
        }
        confirmField.isHidden = true

        formCard.addSubview(submitButton)
        submitButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(fields.snp.bottom).offset(20)
        }

        let dividerRow = UIStackView()
        dividerRow.axis = .horizontal
        dividerRow.spacing = 12
        dividerRow.alignment = .center
        let leftLine = UIView()
        leftLine.backgroundColor = Palette.hairline
        leftLine.snp.makeConstraints { $0.height.equalTo(1) }
        let orLabel = UILabel(text: "OR", font: SkesteFont.demibold(9), color: Palette.muted)
        orLabel.tracked(1.4)
        let rightLine = UIView()
        rightLine.backgroundColor = Palette.hairline
        rightLine.snp.makeConstraints { $0.height.equalTo(1) }
        dividerRow.addArrangedSubview(leftLine)
        dividerRow.addArrangedSubview(orLabel)
        dividerRow.addArrangedSubview(rightLine)
        formCard.addSubview(dividerRow)
        dividerRow.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.top.equalTo(submitButton.snp.bottom).offset(16)
        }
        leftLine.snp.makeConstraints { $0.width.equalTo(rightLine) }

        let appleContainer = UIView()
        appleContainer.backgroundColor = .white
        appleContainer.layer.cornerRadius = 10
        appleContainer.layer.cornerCurve = .continuous
        formCard.addSubview(appleContainer)
        appleContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(dividerRow.snp.bottom).offset(16)
            make.height.equalTo(52)
        }
        let appleButton = ASAuthorizationAppleIDButton(type: .continue, style: .white)
        appleButton.cornerRadius = 10
        appleButton.addTarget(self, action: #selector(appleTapped), for: .touchUpInside)
        appleContainer.addSubview(appleButton)
        appleButton.snp.makeConstraints { $0.edges.equalToSuperview() }

        let note = UILabel(text: "Your pass stays on this device. Log out anytime from Base Camp.", font: SkesteFont.body(10), color: Palette.muted, lines: 0)
        note.textAlignment = .center
        formCard.addSubview(note)
        note.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(26)
            make.trailing.equalToSuperview().offset(-26)
            make.top.equalTo(appleContainer.snp.bottom).offset(14)
            make.bottom.equalToSuperview().offset(-18)
        }

        appleService.onSuccess = { [weak self] identifier, name in
            self?.completeAppleLogin(identifier: identifier, name: name)
        }
        appleService.onFailure = { [weak self] message in
            if let message { self?.showToast(message, style: .error) }
        }
    }

    private func buildFooter() {
        let fade = GradientFadeView()
        view.addSubview(fade)
        fade.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(96)
        }

        footerTextView.backgroundColor = .clear
        footerTextView.isEditable = false
        footerTextView.isScrollEnabled = false
        footerTextView.textContainerInset = .zero
        footerTextView.textContainer.lineFragmentPadding = 0
        footerTextView.delegate = self
        footerTextView.linkTextAttributes = [
            .foregroundColor: Palette.cyan,
            .underlineStyle: 0
        ]
        footerTextView.adjustsFontForContentSizeCategory = false
        view.addSubview(footerTextView)
        footerTextView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.trailing.equalToSuperview().offset(-30)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-6)
        }

        let text = "By continuing you agree with Terms of Service & Privacy Policy and EULA"
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: SkesteFont.body(10),
            .foregroundColor: Palette.muted
        ])
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 2
        attributed.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: attributed.length))
        addLink(attributed, text: "Terms of Service", url: LegalDocument.termsURL)
        addLink(attributed, text: "Privacy Policy", url: LegalDocument.privacyURL)
        addLink(attributed, text: "EULA", url: LegalDocument.eulaURL)
        footerTextView.attributedText = attributed
        footerTextView.tintColor = Palette.cyan
    }

    private func addLink(_ string: NSMutableAttributedString, text: String, url: URL) {
        let range = (string.string as NSString).range(of: text)
        guard range.location != NSNotFound else { return }
        string.addAttributes([
            .link: url,
            .foregroundColor: Palette.cyan,
            .font: SkesteFont.demibold(10)
        ], range: range)
    }

    private func configureApple() {
        usernameField.textField.textContentType = .username
        usernameField.textField.returnKeyType = .next
        passwordField.textField.textContentType = .password
        passwordField.textField.returnKeyType = .done
        confirmField.textField.textContentType = .newPassword
        confirmField.textField.returnKeyType = .done
        passwordField.textField.addTarget(self, action: #selector(submitFromKeyboard), for: .editingDidEndOnExit)
        confirmField.textField.addTarget(self, action: #selector(submitFromKeyboard), for: .editingDidEndOnExit)
    }

    @objc private func submitFromKeyboard() {
        submit()
    }

    private func setMode(_ newMode: Mode) {
        guard mode != newMode else { return }
        mode = newMode
        if let welcome = view.viewWithTag(901) as? UILabel {
            welcome.text = newMode == .login ? "Welcome back to the ridge." : "Claim your line."
        }
        confirmField.isHidden = newMode == .login
        submitButton.title = newMode == .login ? "ENTER THE MOUNTAIN" : "CREATE MY PASS"
        passwordField.textField.textContentType = newMode == .login ? .password : .newPassword
        usernameField.textField.returnKeyType = newMode == .login ? .next : .next
        view.endEditing(true)
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    private func submit() {
        guard !isRunning else { return }
        view.endEditing(true)
        let username = usernameField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.text
        if username.isEmpty {
            showToast("Enter your ride name to continue.", style: .error)
            return
        }
        if password.isEmpty {
            showToast("Enter your password to continue.", style: .error)
            return
        }
        if mode == .signup {
            guard password == confirmField.text else {
                showToast("Your passwords do not match.", style: .error)
                return
            }
            guard password.count >= 6 else {
                showToast("Use at least 6 characters for your password.", style: .error)
                return
            }
        }

        isRunning = true
        let loader = SkesteLoadingView.present()
        let modeAtSubmit = mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else {
                loader.dismiss()
                return
            }
            let outcome = modeAtSubmit == .login
                ? AppStore.shared.login(username: username, password: password)
                : AppStore.shared.register(username: username, password: password)
            loader.dismiss { [weak self] in
                self?.isRunning = false
                self?.handle(outcome)
            }
        }
    }

    private func handle(_ outcome: AuthOutcome) {
        switch outcome {
        case .success(let user):
            completeAuthentication(user: user)
        case .failure(let message):
            showToast(message, style: .error)
        }
    }

    private func completeAuthentication(user: User) {
        let callback = onAuthenticated
        let name = user.displayName.components(separatedBy: " ").first ?? user.displayName
        dismiss(animated: true) {
            callback?()
            SkesteToast.show("Welcome to the ridge, \(name).", style: .success)
        }
    }

    @objc private func appleTapped() {
        guard !isRunning else { return }
        view.endEditing(true)
        appleService.start()
    }

    private func completeAppleLogin(identifier: String, name: String?) {
        isRunning = true
        let loader = SkesteLoadingView.present()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            let outcome = AppStore.shared.loginWithApple(appleID: identifier, name: name)
            loader.dismiss { [weak self] in
                self?.isRunning = false
                self?.handle(outcome)
            }
        }
    }

    override func refreshView() {}
}

extension AuthViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard interaction == .invokeDefaultAction else { return false }
        presentWebLink(URL)
        return false
    }

    @available(iOS 17.0, *)
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        guard case .link(let url) = textItem.content else { return defaultAction }
        return UIAction { [weak self] _ in self?.presentWebLink(url) }
    }
}

private final class GradientFadeView: UIView {
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradient.colors = [UIColor.clear.cgColor, Palette.canvas.withAlphaComponent(0.82).cgColor, Palette.canvas.withAlphaComponent(0.97).cgColor]
        gradient.locations = [0, 0.62, 1]
        layer.addSublayer(gradient)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}
