import UIKit
import SnapKit

enum ReportTarget {
    case post(postID: String)
    case comment(commentID: String, postID: String)
    case user(userID: String)
}

enum ReportReason: Int, CaseIterable {
    case illegal
    case inappropriate
    case block
    case other

    var title: String {
        switch self {
        case .illegal: return "Illegal content"
        case .inappropriate: return "Inappropriate content"
        case .block: return "Block this user"
        case .other: return "Something else"
        }
    }

    var detail: String {
        switch self {
        case .illegal: return "Threats, exploitation, or activity that breaks the law."
        case .inappropriate: return "Hate, harassment, explicit media, or graphic content."
        case .block: return "Remove this person from your feed, coaching sessions, and calls."
        case .other: return "Spam, impersonation, or anything that feels off."
        }
    }

    var symbol: String {
        switch self {
        case .illegal: return "exclamationmark.octagon"
        case .inappropriate: return "eye.slash"
        case .block: return "hand.raised"
        case .other: return "ellipsis.bubble"
        }
    }
}

final class ReportOptionRow: UIControl {
    let reason: ReportReason
    private let selection = UIView()
    private let iconHost = UIView()
    private let iconView = UIImageView()
    private let titleLabel: UILabel
    private let detailLabel: UILabel

    override var isSelected: Bool {
        didSet { updateSelection() }
    }

    init(reason: ReportReason) {
        self.reason = reason
        titleLabel = UILabel(text: reason.title, font: SkesteFont.demibold(14), color: Palette.text)
        detailLabel = UILabel(text: reason.detail, font: SkesteFont.body(11), color: Palette.muted, lines: 2)
        super.init(frame: .zero)
        applyGlass(cornerRadius: 18, borderAlpha: 0.08, fill: Palette.glass)

        selection.layer.cornerRadius = 10
        selection.layer.borderWidth = 1.5
        selection.layer.borderColor = Palette.hairline.cgColor
        addSubview(selection)
        selection.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        iconHost.backgroundColor = Palette.glassStrong
        iconHost.layer.cornerRadius = 15
        addSubview(iconHost)
        iconHost.snp.makeConstraints { make in
            make.leading.equalTo(selection.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(30)
        }
        iconView.image = UIImage(systemName: reason.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold))
        iconView.tintColor = reason == .block ? Palette.danger : Palette.cyan
        iconView.contentMode = .scaleAspectFit
        iconHost.addSubview(iconView)
        iconView.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(16) }

        let labels = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labels.axis = .vertical
        labels.spacing = 1
        labels.isUserInteractionEnabled = false
        addSubview(labels)
        labels.snp.makeConstraints { make in
            make.leading.equalTo(iconHost.snp.trailing).offset(11)
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = reason.title
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(64) }
        updateSelection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateSelection() {
        if isSelected {
            selection.backgroundColor = Palette.lime
            selection.layer.borderColor = Palette.lime.cgColor
            layer.borderColor = Palette.cyan.withAlphaComponent(0.3).cgColor
            titleLabel.textColor = Palette.text
        } else {
            selection.backgroundColor = .clear
            selection.layer.borderColor = Palette.hairline.cgColor
            layer.borderColor = Palette.hairline.cgColor
            titleLabel.textColor = Palette.text
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.14) { self.alpha = self.isHighlighted ? 0.72 : 1 }
        }
    }
}

final class ReportViewController: BaseViewController {
    /// Called after a report is submitted, so a presenter that is not inside the
    /// tab navigation (for example the full-screen call) can close itself.
    var onCompleted: (() -> Void)?
    private let target: ReportTarget
    private let source: RootTab
    private var selectedReason: ReportReason?
    private var optionRows: [ReportOptionRow] = []
    private let notesView = SkesteTextView(title: "Add context", placeholder: "Tell us what happened. Optional.", minHeight: 96)
    private let submitButton = GradientButton(title: "SUBMIT REPORT", icon: "arrow.up.right", colors: [Palette.magenta, Palette.violet], height: 54)

    init(target: ReportTarget, source: RootTab) {
        self.target = target
        self.source = source
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupView() {
        let close = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        close.addAction(UIAction { [weak self] _ in self?.closeReport() }, for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }

        let headerLabel = UILabel(text: "REPORT  /  SAFETY", font: SkesteFont.demibold(9), color: Palette.secondary)
        headerLabel.tracked(1.8)
        view.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(close)
        }

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(close.snp.bottom).offset(14)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-84)
        }

        let content = UIView()
        scrollView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView.snp.width)
        }

        let line = UIView()
        line.backgroundColor = Palette.magenta
        line.layer.cornerRadius = 2
        content.addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalToSuperview().offset(10)
            make.width.equalTo(42)
            make.height.equalTo(4)
        }

        let kicker = UILabel(text: "KEEP THE RIDGE SAFE", font: SkesteFont.demibold(9), color: Palette.magenta)
        kicker.tracked(2.2)
        content.addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(line.snp.bottom).offset(16)
        }

        let title = UILabel(text: "REPORT\nTHIS.", font: SkesteFont.display(32), color: Palette.text, lines: 2)
        title.richTracking(-0.8)
        content.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(kicker.snp.bottom).offset(0)
        }

        let targetLabel = UILabel(text: targetSummary(), font: SkesteFont.body(13), color: Palette.secondary, lines: 0)
        targetLabel.lineSpacing(3)
        content.addSubview(targetLabel)
        targetLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.top.equalTo(title.snp.bottom).offset(12)
        }

        let sectionLabel = UILabel(text: "WHAT'S HAPPENING?", font: SkesteFont.demibold(9), color: Palette.muted)
        sectionLabel.tracked(1.6)
        content.addSubview(sectionLabel)
        sectionLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(targetLabel.snp.bottom).offset(24)
        }

        let optionsStack = UIStackView()
        optionsStack.axis = .vertical
        optionsStack.spacing = 9
        content.addSubview(optionsStack)
        optionsStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.top.equalTo(sectionLabel.snp.bottom).offset(9)
        }

        for reason in ReportReason.allCases {
            let row = ReportOptionRow(reason: reason)
            row.addAction(UIAction { [weak self] _ in
                self?.select(reason)
            }, for: .touchUpInside)
            optionRows.append(row)
            optionsStack.addArrangedSubview(row)
        }

        content.addSubview(notesView)
        notesView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.top.equalTo(optionsStack.snp.bottom).offset(20)
            make.bottom.equalToSuperview().offset(-20)
        }

        let footer = UIView()
        view.addSubview(footer)
        footer.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
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
        DispatchQueue.main.async {
            fade.frame = fadeView.bounds
        }
        footer.addSubview(submitButton)
        submitButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
        submitButton.addAction(UIAction { [weak self] _ in
            self?.submit()
        }, for: .touchUpInside)
    }

    private func closeReport() {
        guard let nav = navigationController else { return }
        if nav.viewControllers.first === self, nav.presentingViewController != nil {
            nav.dismiss(animated: true)
        } else {
            nav.popViewController(animated: true)
        }
    }

    private func targetSummary() -> String {
        switch target {
        case .post(let postID):
            if let post = SKDataStore.shared.post(withID: postID) {
                let author = SKDataStore.shared.user(withID: post.authorID)?.displayName ?? "a rider"
                let caption = post.caption.count > 120 ? String(post.caption.prefix(120)) + "…" : post.caption
                return "You're reporting a post by \(author): “\(caption)”"
            }
            return "You're reporting a post."
        case .comment(let commentID, _):
            if let comment = SKDataStore.shared.comment(withID: commentID) {
                let text = comment.text.count > 120 ? String(comment.text.prefix(120)) + "…" : comment.text
                return "You're reporting a comment: “\(text)”"
            }
            return "You're reporting a comment."
        case .user(let userID):
            let name = SKDataStore.shared.user(withID: userID)?.displayName ?? "this rider"
            return "You're reporting \(name). Their posts and coaching sessions can be removed from your mountain."
        }
    }

    private func select(_ reason: ReportReason) {
        selectedReason = reason
        for row in optionRows {
            row.isSelected = row.reason == reason
        }
        SkesteHaptics.light()
    }

    private func submit() {
        guard let reason = selectedReason else {
            showToast("Choose what you're reporting.", style: .error)
            return
        }
        view.endEditing(true)
        switch target {
        case .comment(let commentID, _):
            let comment = SKDataStore.shared.comment(withID: commentID)
            SKDataStore.shared.deleteComment(id: commentID)
            if reason == .block, let authorID = comment?.authorID {
                SKDataStore.shared.removeUserAndData(userID: authorID)
                showToast("Comment removed and user blocked.", style: .success)
                returnToRootTab(.home)
                onCompleted?()
                return
            }
            showToast("Report received. The comment has been removed.", style: .success)
            navigationController?.popViewController(animated: true)
            onCompleted?()
        case .post(let postID):
            if reason == .block, let post = SKDataStore.shared.post(withID: postID) {
                SKDataStore.shared.removeUserAndData(userID: post.authorID)
                showToast("Post removed and user blocked.", style: .success)
            } else {
                SKDataStore.shared.deletePost(id: postID)
                showToast("Report received. The post has been removed.", style: .success)
            }
            returnToRootTab(.home)
            onCompleted?()
        case .user(let userID):
            SKDataStore.shared.removeUserAndData(userID: userID)
            showToast("Report received. This user's content has been removed.", style: .success)
            returnToRootTab(source)
            onCompleted?()
        }
    }
}
