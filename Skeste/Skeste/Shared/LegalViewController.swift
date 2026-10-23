import UIKit
import SnapKit

enum LegalDocument {
    case terms
    case privacy
    case eula
    case creatorEULA

    var title: String {
        switch self {
        case .terms: return "Terms of Service"
        case .privacy: return "Privacy Policy"
        case .eula: return "End User License Agreement"
        case .creatorEULA: return "Creator EULA"
        }
    }

    var kicker: String {
        switch self {
        case .terms: return "The ground rules"
        case .privacy: return "Your data, your line"
        case .eula: return "The software agreement"
        case .creatorEULA: return "Before you drop it"
        }
    }

    var intro: String {
        switch self {
        case .terms:
            return "Welcome to Skeste. These terms explain what you can expect from the mountain and what we expect from every rider who joins."
        case .privacy:
            return "Skeste is built to keep the focus on the mountain. This policy explains what stays on your device and what is used to run the experience."
        case .eula:
            return "This agreement covers your use of the Skeste application. By using the app, you accept these terms."
        case .creatorEULA:
            return "Skeste is a place for original mountain stories. This agreement applies to every video, photo, and note you publish."
        }
    }

    var accent: UIColor {
        switch self {
        case .terms: return Palette.cyan
        case .privacy: return Palette.lime
        case .eula: return Palette.magenta
        case .creatorEULA: return Palette.amber
        }
    }

    /// Public web pages for the legal documents that are published externally.
    static let termsURL = URL(string: "https://www.privacypolicies.com/live/6c0d3fae-5802-4b06-9336-f20af23eea73")!
    static let privacyURL = URL(string: "https://www.privacypolicies.com/live/aedcbbf7-dbb7-4ed3-ad96-d1f09f963f0b")!
    static let eulaURL = URL(string: "https://www.privacypolicies.com/live/5d47dc71-af03-46cd-b92f-03e7680e4a4b")!

    var webURL: URL? {
        switch self {
        case .terms: return Self.termsURL
        case .privacy: return Self.privacyURL
        case .eula: return Self.eulaURL
        case .creatorEULA: return nil
        }
    }

    var sections: [(String, String)] {
        switch self {
        case .terms:
            return [
                ("1. Who can ride", "You must be at least 13 years old and legally able to accept these terms. If you are under the age of majority where you live, a parent or guardian must approve your use of Skeste."),
                ("2. Your account", "Keep your login details private. You are responsible for activity that happens through your account. Choose a username that does not impersonate another person or brand."),
                ("3. Respect the mountain", "Skeste is a social space for snow sports. Harassment, hate speech, threats, non-consensual imagery, illegal content, and spam are not welcome. Coaching sessions are limited to a coach you booked and who accepted your request. You must never record or share a private session without the other person's consent."),
                ("4. Your content", "You keep ownership of the media and text you publish. You grant Skeste a non-exclusive license to display and promote that content inside the app. You must own the rights to every clip, photo, and sound you share."),
                ("5. Gifts", "Gifts are optional consumable purchases made through the App Store. A completed purchase supports the creator whose post you selected. All purchases are final except where required by applicable law."),
                ("6. Safety", "Mountain activities involve serious risk. Content in Skeste is not instruction or safety advice. Always ride within your ability, check the forecast, carry rescue equipment, and make decisions with trained partners."),
                ("7. Moderation", "We may remove content or suspend accounts that break these terms. You can report posts, comments, coaching sessions, calls, and people from inside the app. Reports are reviewed promptly."),
                ("8. Changes", "We may update these terms as the app evolves. The latest version will always be available here. Continued use after an update means you accept the revised terms.")
            ]
        case .privacy:
            return [
                ("1. What we use", "Your profile details, posts, follows, coaching bookings, call metadata, and purchase results are stored to provide the app experience. Media you select is copied into the app's local storage so it can be shown in your feed."),
                ("2. Location", "The Run Tracker uses your location only while you start a tracked run. Location is used to calculate distance, speed, and vertical descent. You can stop tracking at any time and can change location access in iOS Settings. Snow Desk sends the fixed coordinates of the resort you select to Apple WeatherKit to retrieve a forecast; it does not use your device location for weather."),
                ("3. Coaching sessions", "When you request a session you share the topic, your description, and your preferred time with that coach. We store the booking status and call metadata such as who started the call, when it happened, and how long it lasted. Skeste does not record the audio or video of a session. Private sessions can only start after the coach accepts the request."),
                ("4. Purchases", "Gift purchases are processed by Apple. Skeste receives confirmation that a purchase completed but does not receive your full payment details."),
                ("5. Sign in with Apple", "If you choose Sign in with Apple, Apple returns a stable account identifier. We use it to keep you signed in. Your name is only shared by Apple the first time you authorize the app."),
                ("6. Your choices", "You can edit your profile, remove posts, delete comments, cancel coaching sessions, delete your account, and clear local app data from iOS Settings. Account deletion removes your profile, coaching history, and related in-app content from this device."),
                ("7. Children", "Skeste is not directed to children under 13. If we learn that a child under 13 created an account, the account may be removed."),
                ("8. Contact", "Privacy questions can be sent to the support address listed on the App Store product page. We will respond within a reasonable period.")
            ]
        case .eula:
            return [
                ("1. License", "Skeste grants you a personal, non-transferable, non-exclusive license to use this application on Apple devices you own or control, subject to the App Store Usage Rules."),
                ("2. Restrictions", "You may not copy, modify, distribute, reverse engineer, or resell the application except where such restrictions are prohibited by law."),
                ("3. Ownership", "The application, brand, visual system, and original software remain the property of Skeste and its licensors. Your own content remains yours."),
                ("4. Purchases", "Consumable gifts are processed through Apple In-App Purchase. Pricing is displayed in your local currency by the App Store. Restore and refund requests are handled by Apple."),
                ("5. Availability", "We work to keep the app available and reliable, but we cannot promise uninterrupted operation. Features may change as the product develops."),
                ("6. Termination", "This license ends if you materially breach these terms or delete the application. Sections about ownership, disclaimers, and limitations survive termination."),
                ("7. Disclaimer", "The application is provided on an as-is and as-available basis. Snow sports are inherently dangerous. Weather data is provided by Apple Weather and is an informational forecast; it may be delayed, incomplete, or inaccurate. Avalanche danger levels shown in the app are reference values, not live bulletin data. Coaching sessions are advice from independent coaches and are not a guarantee of safety or a substitute for professional instruction on snow. The app does not guarantee snow conditions, weather, route safety, coaching outcomes, or rescue outcomes. Always check official forecasts and your local avalanche bulletin.")
            ]
        case .creatorEULA:
            return [
                ("1. Original work only", "You must own or have all necessary permissions for every video, image, music track, and voice recording you publish. Do not upload footage that belongs to someone else without written permission."),
                ("2. People and places", "You are responsible for the consent of people who appear recognizably in your media. Do not publish private locations, unsafe access points, or content that encourages trespassing."),
                ("3. Safety and honesty", "Do not edit a clip to hide a serious hazard or misrepresent conditions. Share the whole story. Skeste celebrates progression, not reckless risk."),
                ("4. Rights you grant", "By publishing, you grant Skeste a worldwide, non-exclusive, royalty-free license to host, display, and feature your content inside the app and its official promotional channels."),
                ("5. Moderation", "We may remove content that violates this agreement or community standards. Repeat violations can result in loss of publishing access or account termination."),
                ("6. Gifts", "Gifts are a voluntary way to support creators. They do not purchase ownership of content, guaranteed promotion, or a financial return."),
                ("7. Your responsibility", "You remain responsible for your content and for complying with local laws, resort rules, and the rights of others. You agree to resolve any claims arising from your content.")
            ]
        }
    }
}

final class LegalViewController: BaseViewController {
    private let document: LegalDocument

    init(document: LegalDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        let closeButton = SkesteControls.iconButton(symbol: "xmark", diameter: 40)
        closeButton.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }

        let brand = UILabel(text: "SKESTE  /  LEGAL", font: SkesteFont.demibold(9), color: Palette.muted)
        brand.tracked(2)
        view.addSubview(brand)
        brand.snp.makeConstraints { make in
            make.centerY.equalTo(closeButton)
            make.centerX.equalToSuperview()
        }

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(closeButton.snp.bottom).offset(20)
        }

        let content = UIView()
        scrollView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0))
            make.width.equalTo(scrollView)
        }

        let accentLine = UIView()
        accentLine.backgroundColor = document.accent
        accentLine.layer.cornerRadius = 2
        content.addSubview(accentLine)
        accentLine.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalToSuperview().offset(10)
            make.width.equalTo(42)
            make.height.equalTo(4)
        }

        let kicker = UILabel(text: document.kicker.uppercased(), font: SkesteFont.demibold(10), color: document.accent)
        kicker.tracked(2.4)
        content.addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.top.equalTo(accentLine.snp.bottom).offset(16)
        }

        let titleLabel = UILabel(text: document.title, font: SkesteFont.display(30), color: Palette.text, lines: 0)
        titleLabel.richTracking(-0.4)
        content.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.top.equalTo(kicker.snp.bottom).offset(4)
        }

        let dateLabel = UILabel(text: "Effective October 19, 2026", font: SkesteFont.medium(11), color: Palette.muted)
        content.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
        }

        let intro = UILabel(text: document.intro, font: SkesteFont.body(15), color: Palette.secondary, lines: 0)
        intro.lineSpacing(5)
        content.addSubview(intro)
        intro.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.top.equalTo(dateLabel.snp.bottom).offset(18)
        }

        let divider = UIView()
        divider.backgroundColor = Palette.hairline
        content.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.height.equalTo(1)
            make.top.equalTo(intro.snp.bottom).offset(22)
        }

        var previous: UIView = divider
        for (index, section) in document.sections.enumerated() {
            let number = UILabel(text: String(format: "%02d", index + 1), font: SkesteFont.mono(10, weight: .bold), color: document.accent)
            content.addSubview(number)
            number.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(AppLayout.screenPadding)
                make.top.equalTo(previous.snp.bottom).offset(24)
                make.width.equalTo(24)
            }

            let heading = UILabel(text: section.0, font: SkesteFont.demibold(16), color: Palette.text, lines: 0)
            content.addSubview(heading)
            heading.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(AppLayout.screenPadding + 34)
                make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
                make.top.equalTo(previous.snp.bottom).offset(21)
            }

            let body = UILabel(text: section.1, font: SkesteFont.body(14), color: Palette.secondary, lines: 0)
            body.lineSpacing(4)
            content.addSubview(body)
            body.snp.makeConstraints { make in
                make.leading.equalTo(heading)
                make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
                make.top.equalTo(heading.snp.bottom).offset(7)
                if index == document.sections.count - 1 {
                    make.bottom.equalToSuperview().offset(-24)
                }
            }
            previous = body
        }
    }

    override func refreshView() {}
}