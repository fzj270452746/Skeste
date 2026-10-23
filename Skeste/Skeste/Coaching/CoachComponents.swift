import UIKit
import SnapKit

/// A coach in the list: who they are, what they teach, and how riders rate them.
final class CoachCardView: UIControl {
    private let avatar = AvatarView(size: 54, showsRing: true)
    private let nameLabel = UILabel(text: nil, font: SkesteFont.demibold(15), color: Palette.text)
    private let verifiedView = UIImageView()
    private let handleLabel = UILabel(text: nil, font: SkesteFont.medium(9), color: Palette.muted)
    private let headlineLabel = UILabel(text: nil, font: SkesteFont.body(12), color: Palette.secondary, lines: 2)
    private let specialtyLabel = UILabel(text: nil, font: SkesteFont.demibold(9), color: Palette.cyan)
    private let metaLabel = UILabel(text: nil, font: SkesteFont.medium(9), color: Palette.muted)
    private let chevron = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlass(cornerRadius: 18, borderAlpha: 0.09, fill: Palette.glass)
        addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(15)
        }
        nameLabel.textAlignment = .left
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(11)
            make.top.equalToSuperview().offset(15)
            make.trailing.lessThanOrEqualToSuperview().offset(-34)
        }
        verifiedView.image = UIImage(systemName: "checkmark.seal.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
        verifiedView.tintColor = Palette.cyan
        verifiedView.contentMode = .scaleAspectFit
        addSubview(verifiedView)
        verifiedView.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(4)
            make.centerY.equalTo(nameLabel)
            make.width.height.equalTo(13)
        }
        addSubview(handleLabel)
        handleLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(0)
        }
        headlineLabel.lineSpacing(2)
        addSubview(headlineLabel)
        headlineLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalTo(handleLabel.snp.bottom).offset(6)
        }
        specialtyLabel.tracked(0.8)
        addSubview(specialtyLabel)
        specialtyLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-34)
            make.top.equalTo(headlineLabel.snp.bottom).offset(7)
        }
        addSubview(metaLabel)
        metaLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-34)
            make.top.equalTo(specialtyLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-14)
        }
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold))
        chevron.tintColor = Palette.muted
        addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(150) }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.14) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
            }
        }
    }

    func configure(profile: CoachProfile, user: User) {
        avatar.configure(user: user)
        nameLabel.text = user.displayName
        verifiedView.isHidden = !user.isVerified
        handleLabel.text = "\(user.handle)  ·  \(profile.availability)"
        headlineLabel.text = profile.headline
        specialtyLabel.text = profile.specialties.prefix(3).joined(separator: "  ·  ").uppercased()
        metaLabel.text = "★ \(String(format: "%.1f", profile.rating))   ·   \(profile.sessionCount) SESSIONS   ·   \(profile.languages.joined(separator: " / "))"
        accessibilityLabel = "\(user.displayName). \(profile.headline). \(profile.specialties.joined(separator: ", "))."
    }
}

/// Compact coach identity used by the booking form, the session detail and the call.
final class CoachIdentityView: UIView {
    let avatar = AvatarView(size: 46, showsRing: true)
    private let nameLabel = UILabel(text: nil, font: SkesteFont.demibold(15), color: Palette.text)
    private let headlineLabel = UILabel(text: nil, font: SkesteFont.body(11), color: Palette.secondary, lines: 2)
    private let badge = SkesteTagLabel(text: "COACH", tint: Palette.lime, fill: Palette.lime.withAlphaComponent(0.12))

    init(user: User, profile: CoachProfile) {
        super.init(frame: .zero)
        avatar.configure(user: user)
        nameLabel.text = user.displayName
        headlineLabel.text = profile.headline
        headlineLabel.lineSpacing(2)
        badge.insets = UIEdgeInsets(top: 3, left: 7, bottom: 3, right: 7)
        addSubview(avatar)
        addSubview(nameLabel)
        addSubview(headlineLabel)
        addSubview(badge)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(2)
            make.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(12)
            make.top.equalToSuperview()
        }
        badge.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(7)
            make.centerY.equalTo(nameLabel)
        }
        headlineLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-2)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview()
        }
        isAccessibilityElement = true
        accessibilityLabel = "\(user.displayName), coach. \(profile.headline)"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A booked session in the coaching screen.
final class BookingRowView: UIControl {
    var onCall: (() -> Void)?
    private let avatar = AvatarView(size: 48, showsRing: true)
    private let nameLabel = UILabel(text: nil, font: SkesteFont.demibold(14), color: Palette.text)
    private let topicLabel = UILabel(text: nil, font: SkesteFont.demibold(9), color: Palette.cyan)
    private let timeLabel = UILabel(text: nil, font: SkesteFont.medium(10), color: Palette.muted)
    private let statusPill = SkesteTagLabel(text: "PENDING", tint: Palette.amber, fill: Palette.amber.withAlphaComponent(0.12))
    private let callButton = UIButton(type: .system)
    private let chevron = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlass(cornerRadius: 18, borderAlpha: 0.09, fill: Palette.glass)
        addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.centerY.equalToSuperview().offset(-2)
        }
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(11)
            make.top.equalToSuperview().offset(15)
            make.trailing.lessThanOrEqualToSuperview().offset(-118)
        }
        topicLabel.tracked(0.8)
        addSubview(topicLabel)
        topicLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
        }
        timeLabel.textColor = Palette.muted
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(topicLabel.snp.bottom).offset(5)
            make.bottom.equalToSuperview().offset(-15)
        }
        statusPill.insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        addSubview(statusPill)
        statusPill.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(14)
        }
        callButton.setTitle("VIDEO CALL", for: .normal)
        callButton.setTitleColor(Palette.ink, for: .normal)
        callButton.titleLabel?.font = SkesteFont.demibold(9)
        callButton.backgroundColor = Palette.lime
        callButton.layer.cornerRadius = 12
        callButton.addAction(UIAction { [weak self] _ in self?.onCall?() }, for: .touchUpInside)
        addSubview(callButton)
        callButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-13)
            make.width.equalTo(92)
            make.height.equalTo(26)
        }
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold))
        chevron.tintColor = Palette.muted
        addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }
        snp.makeConstraints { $0.height.equalTo(104) }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.14) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
            }
        }
    }

    func configure(booking: CoachBooking, coach: User) {
        avatar.configure(user: coach)
        nameLabel.text = coach.displayName
        topicLabel.text = "\(booking.topic.title.uppercased())  ·  \(booking.durationMinutes) MIN"
        timeLabel.text = booking.scheduledAt.bookingStamp
        statusPill.text = booking.status.title
        switch booking.status {
        case .pending:
            statusPill.textColor = Palette.amber
            statusPill.backgroundColor = Palette.amber.withAlphaComponent(0.12)
        case .accepted:
            statusPill.textColor = Palette.lime
            statusPill.backgroundColor = Palette.lime.withAlphaComponent(0.12)
        case .declined:
            statusPill.textColor = Palette.danger
            statusPill.backgroundColor = Palette.danger.withAlphaComponent(0.12)
        case .cancelled:
            statusPill.textColor = Palette.muted
            statusPill.backgroundColor = Palette.glassStrong
        case .completed:
            statusPill.textColor = Palette.cyan
            statusPill.backgroundColor = Palette.cyan.withAlphaComponent(0.12)
        }
        let canCall = booking.status == .accepted
        callButton.isHidden = !canCall
        chevron.isHidden = canCall
        accessibilityLabel = "\(coach.displayName). \(booking.topic.title). \(booking.status.title). \(booking.scheduledAt.bookingStamp)."
    }

}
