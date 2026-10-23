import UIKit
import SnapKit
import PhotosUI
import UniformTypeIdentifiers

final class PublishMediaTile: UIView {
    private let preview = MediaPreviewView()
    private let removeButton = UIButton(type: .system)
    var onRemove: (() -> Void)?
    let media: MediaItem

    init(media: MediaItem) {
        self.media = media
        super.init(frame: .zero)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = Palette.hairline.cgColor
        clipsToBounds = true
        addSubview(preview)
        preview.snp.makeConstraints { $0.edges.equalToSuperview() }
        preview.configure(with: media)

        removeButton.backgroundColor = UIColor(hex: "060607").withAlphaComponent(0.72)
        removeButton.layer.cornerRadius = 13
        removeButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)), for: .normal)
        removeButton.tintColor = .white
        removeButton.addAction(UIAction { [weak self] _ in self?.onRemove?() }, for: .touchUpInside)
        addSubview(removeButton)
        removeButton.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview().offset(7)
            make.width.height.equalTo(26)
        }

        if media.kind == .video {
            let badge = SkesteTagLabel(text: "VIDEO", tint: .white, fill: UIColor(hex: "060607").withAlphaComponent(0.65))
            badge.insets = UIEdgeInsets(top: 5, left: 7, bottom: 5, right: 7)
            addSubview(badge)
            badge.snp.makeConstraints { make in
                make.leading.bottom.equalToSuperview().offset(8)
            }
        }
        snp.makeConstraints { make in
            make.width.equalTo(118)
            make.height.equalTo(152)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CreatorConsentView: UIView {
    var onOpenEULA: (() -> Void)?
    private let checkbox = UIButton(type: .system)
    private(set) var isAccepted = false
    private let card = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.applyGlass(cornerRadius: 20, borderAlpha: 0.14, fill: Palette.glass)
        addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview() }

        checkbox.layer.cornerRadius = 12
        checkbox.layer.borderWidth = 1.5
        checkbox.layer.borderColor = Palette.lime.withAlphaComponent(0.6).cgColor
        checkbox.backgroundColor = Palette.lime.withAlphaComponent(0.08)
        checkbox.setImage(UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)), for: .normal)
        checkbox.tintColor = .clear
        checkbox.addAction(UIAction { [weak self] _ in self?.toggle() }, for: .touchUpInside)
        checkbox.isAccessibilityElement = true
        checkbox.accessibilityLabel = "Accept Creator EULA"
        checkbox.accessibilityTraits = .button
        checkbox.accessibilityValue = "Not accepted"
        card.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(24)
        }

        let title = UILabel(text: "CREATOR EULA", font: SkesteFont.demibold(10), color: Palette.lime)
        title.tracked(1.8)
        card.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalTo(checkbox.snp.trailing).offset(11)
            make.top.equalTo(checkbox).offset(1)
            make.trailing.equalToSuperview().offset(-14)
        }

        let body = UILabel(text: "I own this media and have permission from everyone in it. I accept the Creator EULA for this drop.", font: SkesteFont.body(12), color: Palette.secondary, lines: 0)
        body.lineSpacing(2)
        card.addSubview(body)
        body.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.trailing.equalToSuperview().offset(-14)
            make.top.equalTo(title.snp.bottom).offset(3)
        }

        let link = UIButton(type: .system)
        link.setTitle("READ THE CREATOR EULA  →", for: .normal)
        link.setTitleColor(Palette.cyan, for: .normal)
        link.titleLabel?.font = SkesteFont.demibold(8)
        link.contentHorizontalAlignment = .left
        link.addAction(UIAction { [weak self] _ in self?.onOpenEULA?() }, for: .touchUpInside)
        card.addSubview(link)
        link.snp.makeConstraints { make in
            make.leading.equalTo(title)
            make.top.equalTo(body.snp.bottom).offset(7)
            make.bottom.equalToSuperview().offset(-14)
        }

        snp.makeConstraints { $0.height.greaterThanOrEqualTo(110) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func toggle() {
        isAccepted.toggle()
        SkesteHaptics.light()
        checkbox.tintColor = isAccepted ? UIColor(hex: "0A0A0B") : .clear
        checkbox.backgroundColor = isAccepted ? Palette.lime : Palette.lime.withAlphaComponent(0.08)
        checkbox.layer.borderColor = Palette.lime.cgColor
        checkbox.accessibilityValue = isAccepted ? "Accepted" : "Not accepted"
        card.layer.borderColor = isAccepted ? Palette.lime.withAlphaComponent(0.42).cgColor : UIColor.white.withAlphaComponent(0.14).cgColor
        card.applyGlow(color: Palette.lime, radius: isAccepted ? 10 : 0, opacity: isAccepted ? 0.10 : 0)
    }
}

final class PublishViewController: BaseViewController {
    var onPublished: (() -> Void)?

    private enum PublishMode {
        case video
        case post
    }

    private var mode: PublishMode = .video
    private var media: [MediaItem] = []
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let modeControl = SkSegmentedControl(items: ["LINE DROP", "FIELD NOTE"], selected: 0)
    private let modeHint = UILabel(text: nil, font: SkesteFont.medium(11), color: Palette.muted, lines: 0)
    private let mediaScroll = UIScrollView()
    private let mediaStack = UIStackView()
    private let addTile = UIControl()
    private let captionView = SkesteTextView(title: "The story", placeholder: "What happened out there? Say it like you'd tell a friend.", minHeight: 132)
    private let tagsField = SkesteTextField(title: "Tags", placeholder: "#freeride  #firstlight", icon: "number")
    private let consent = CreatorConsentView()
    private let publishButton = GradientButton(title: "PUBLISH TO THE RIDGE", icon: "arrow.up.right", height: 54)
    private var footerBottomConstraint: Constraint?
    private var isWorking = false
    private let processing = UIActivityIndicatorView(style: .medium)

    override func setupView() {
        buildHeader()
        buildScroll()
        buildFooter()
        updateMode()
        registerKeyboard()
        publishButton.addAction(UIAction { [weak self] _ in self?.attemptPublish() }, for: .touchUpInside)
        consent.onOpenEULA = { [weak self] in self?.presentLegal(.creatorEULA) }
    }

    private func buildHeader() {
        let close = SkesteControls.iconButton(symbol: "xmark", diameter: 40)
        close.addAction(UIAction { [weak self] _ in
            self?.navigationController?.dismiss(animated: true)
        }, for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel(text: "CREATE  /  THE DROP", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.8)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(close)
        }
        let dot = UIView()
        dot.backgroundColor = Palette.lime
        dot.layer.cornerRadius = 3
        view.addSubview(dot)
        dot.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-22)
            make.centerY.equalTo(close)
            make.width.height.equalTo(6)
        }
    }

    private func buildScroll() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(58)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-116)
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }

        let kicker = UILabel(text: "PICK YOUR FORMAT", font: SkesteFont.demibold(9), color: Palette.cyan)
        kicker.tracked(2)
        contentStack.addArrangedSubview(kicker)
        contentStack.setCustomSpacing(6, after: kicker)

        let title = UILabel(text: "DROP\nIT.", font: SkesteFont.display(36), color: Palette.text, lines: 2)
        title.richTracking(-0.8)
        contentStack.addArrangedSubview(title)
        contentStack.setCustomSpacing(16, after: title)

        contentStack.addArrangedSubview(modeControl)
        contentStack.setCustomSpacing(7, after: modeControl)

        modeHint.numberOfLines = 0
        contentStack.addArrangedSubview(modeHint)
        contentStack.setCustomSpacing(18, after: modeHint)

        let mediaPanel = UIView()
        mediaPanel.applyGlass(cornerRadius: 14, borderAlpha: 0.09, fill: Palette.glass)
        contentStack.addArrangedSubview(mediaPanel)
        contentStack.setCustomSpacing(16, after: mediaPanel)

        let mediaHeader = UILabel(text: "MEDIA", font: SkesteFont.demibold(9), color: Palette.muted)
        mediaHeader.tracked(1.6)
        mediaPanel.addSubview(mediaHeader)
        mediaHeader.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(14)
        }

        processing.color = Palette.cyan
        processing.hidesWhenStopped = true
        mediaPanel.addSubview(processing)
        processing.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalTo(mediaHeader)
        }

        mediaScroll.showsHorizontalScrollIndicator = false
        mediaScroll.contentInsetAdjustmentBehavior = .never
        mediaPanel.addSubview(mediaScroll)
        mediaScroll.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(mediaHeader.snp.bottom).offset(10)
            make.height.equalTo(170)
        }
        mediaStack.axis = .horizontal
        mediaStack.spacing = 9
        mediaStack.alignment = .center
        mediaScroll.addSubview(mediaStack)
        mediaStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 8, right: 14))
            make.height.equalTo(152)
        }

        addTile.backgroundColor = Palette.glassStrong
        addTile.layer.cornerRadius = 16
        addTile.layer.cornerCurve = .continuous
        addTile.layer.borderWidth = 1
        addTile.layer.borderColor = Palette.cyan.withAlphaComponent(0.28).cgColor
        let plus = UIImageView(image: UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .semibold)))
        plus.tintColor = Palette.cyan
        plus.isUserInteractionEnabled = false
        addTile.addSubview(plus)
        plus.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.centerY.equalToSuperview().offset(-12) }
        let addLabel = UILabel(text: "ADD MEDIA", font: SkesteFont.demibold(8), color: Palette.cyan)
        addLabel.tracked(1.2)
        addLabel.isUserInteractionEnabled = false
        addTile.addSubview(addLabel)
        addLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(plus.snp.bottom).offset(6)
        }
        addTile.isAccessibilityElement = true
        addTile.accessibilityTraits = .button
        addTile.accessibilityLabel = "Add media"
        addTile.addAction(UIAction { [weak self] _ in self?.chooseMedia() }, for: .touchUpInside)
        addTile.snp.makeConstraints { make in
            make.width.equalTo(118)
            make.height.equalTo(152)
        }
        refreshMedia()

        let storyKicker = UILabel(text: "WORDS", font: SkesteFont.demibold(9), color: Palette.cyan)
        storyKicker.tracked(2)
        contentStack.addArrangedSubview(storyKicker)
        contentStack.setCustomSpacing(6, after: storyKicker)
        contentStack.addArrangedSubview(captionView)
        contentStack.setCustomSpacing(14, after: captionView)

        contentStack.addArrangedSubview(tagsField)
        contentStack.setCustomSpacing(20, after: tagsField)

        contentStack.addArrangedSubview(consent)
        contentStack.setCustomSpacing(18, after: consent)

        let note = UILabel(text: "Posts appear at the top of the feed. Be real, credit the crew, and respect the mountain.", font: SkesteFont.body(10), color: Palette.muted, lines: 0)
        note.textAlignment = .center
        contentStack.addArrangedSubview(note)
    }

    private func buildFooter() {
        let footer = UIView()
        view.addSubview(footer)
        footer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(94)
            footerBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).constraint
        }
        let fade = CAGradientLayer.skeste(colors: [UIColor.clear, Palette.canvas.withAlphaComponent(0.86), Palette.canvas.withAlphaComponent(0.97)], start: CGPoint(x: 0.5, y: 0), end: CGPoint(x: 0.5, y: 1))
        let fadeView = UIView()
        fadeView.isUserInteractionEnabled = false
        fadeView.layer.addSublayer(fade)
        footer.addSubview(fadeView)
        fadeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view)
        }
        DispatchQueue.main.async { fade.frame = fadeView.bounds }
        footer.addSubview(publishButton)
        publishButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-8)
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
        footerBottomConstraint?.update(offset: 0)
        scrollView.contentInset.bottom = 0
        UIView.animate(withDuration: 0.24) { self.view.layoutIfNeeded() }
    }

    private func updateMode() {
        modeHint.text = mode == .video
            ? "One portrait video, 9:16. Build the moment with a title and tags."
            : "Up to six photos, or just your words. Keep the story tight."
        addTile.isHidden = mode == .post ? media.count >= 6 : !media.isEmpty
        modeControl.select(mode == .video ? 0 : 1, notify: false)
        modeControl.onChange = { [weak self] index in
            guard let self else { return }
            self.mode = index == 0 ? .video : .post
            self.media.removeAll()
            self.refreshMedia()
            self.updateMode()
            self.view.endEditing(true)
        }
    }

    private func refreshMedia() {
        mediaStack.arrangedSubviews.forEach {
            mediaStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for item in media {
            let tile = PublishMediaTile(media: item)
            tile.onRemove = { [weak self] in
                self?.media.removeAll(where: { $0.id == item.id })
                self?.refreshMedia()
                self?.updateMode()
            }
            mediaStack.addArrangedSubview(tile)
        }
        addTile.isHidden = mode == .post ? media.count >= 6 : !media.isEmpty
        if !addTile.isHidden {
            mediaStack.addArrangedSubview(addTile)
        }
        addTile.isHidden = mode == .post ? media.count >= 6 : !media.isEmpty
    }

    private func chooseMedia() {
        view.endEditing(true)
        guard !isWorking else { return }
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = mode == .video ? 1 : max(1, 6 - media.count)
        configuration.filter = mode == .video ? .videos : .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func attemptPublish() {
        guard !isWorking else { return }
        requireLogin { [weak self] in
            self?.validateAndPublish()
        }
    }

    private func validateAndPublish() {
        guard consent.isAccepted else {
            showToast("Accept the Creator EULA before publishing.", style: .error)
            SkesteHaptics.warning()
            let rect = consent.convert(consent.bounds, to: scrollView)
            scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -90), animated: true)
            return
        }
        let caption = captionView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if mode == .video {
            guard let video = media.first, video.kind == .video else {
                showToast("Add the video for your line drop.", style: .error)
                return
            }
            if caption.isEmpty {
                showToast("Give your line a title or a few words.", style: .error)
                return
            }
        } else if caption.isEmpty && media.isEmpty {
            showToast("Write a note or add a photo first.", style: .error)
            return
        }

        isWorking = true
        publishButton.isEnabled = false
        publishButton.title = "SENDING IT…"
        let tags = parseTags(tagsField.text)
        let kind: PostKind = mode == .video ? .reel : .note
        let mediaToPublish = media
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self else { return }
            guard let post = SKDataStore.shared.addPost(kind: kind, caption: caption, tags: tags, media: mediaToPublish) else {
                self.isWorking = false
                self.publishButton.isEnabled = true
                self.publishButton.title = "PUBLISH TO THE RIDGE"
                self.showToast("That drop could not be published.", style: .error)
                return
            }
            SkesteHaptics.success()
            self.navigationController?.dismiss(animated: true) {
                self.onPublished?()
                SkesteToast.show(post.kind == .reel ? "Your line is live on the ridge." : "Your field note is live.", style: .success)
            }
        }
    }

    private func parseTags(_ text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ", #")
        return text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(5)
            .map { $0 }
    }
}

extension PublishViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }
        isWorking = true
        processing.startAnimating()
        if mode == .video {
            guard let provider = results.first?.itemProvider, provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
                finishProcessing()
                return
            }
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                guard let url, error == nil, let stored = MediaFiles.storeVideo(from: url) else {
                    DispatchQueue.main.async { self?.finishProcessing() }
                    return
                }
                DispatchQueue.main.async {
                    self?.media = [MediaItem(kind: .video, assetName: "", fileName: stored)]
                    self?.finishProcessing()
                    self?.refreshMedia()
                    self?.updateMode()
                }
            }
        } else {
            let group = DispatchGroup()
            var loaded: [MediaItem] = []
            let lock = NSLock()
            for result in results {
                let provider = result.itemProvider
                guard provider.canLoadObject(ofClass: UIImage.self) else { continue }
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }
                    guard let image = object as? UIImage, error == nil, let fileName = MediaFiles.saveImage(image) else { return }
                    let item = MediaItem(kind: .image, assetName: "", fileName: fileName)
                    lock.lock()
                    loaded.append(item)
                    lock.unlock()
                }
            }
            group.notify(queue: .main) { [weak self] in
                guard let self else { return }
                self.media.append(contentsOf: loaded.prefix(max(0, 6 - self.media.count)))
                self.finishProcessing()
                self.refreshMedia()
                self.updateMode()
            }
        }
    }

    private func finishProcessing() {
        isWorking = false
        processing.stopAnimating()
    }
}
