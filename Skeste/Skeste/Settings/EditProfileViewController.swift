import UIKit
import SnapKit
import PhotosUI

final class EditProfileViewController: BaseViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let nameField = SkesteTextField(title: "Display name", placeholder: "Your name on the mountain", icon: "person")
    private let resortField = SkesteTextField(title: "Home resort", placeholder: "Where you ride", icon: "mappin.and.ellipse")
    private let bioView = SkesteTextView(title: "Bio", placeholder: "What are you chasing this season?", minHeight: 110)
    private let avatar = AvatarView(size: 108, showsRing: true)
    private let selectedImageView = UIImageView()
    private let handleLabel = UILabel(text: nil, font: SkesteFont.medium(11), color: Palette.muted)
    private var selectedImage: UIImage?

    override func setupView() {
        guard let user = SKDataStore.shared.currentUser else {
            showToast("Sign in to edit your profile.", style: .error)
            return
        }
        buildHeader()
        buildForm(user: user)
    }

    private func buildHeader() {
        let back = SkesteControls.iconButton(symbol: "chevron.left", diameter: 40)
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }
        let label = UILabel(text: "IDENTITY  /  EDIT PROFILE", font: SkesteFont.demibold(9), color: Palette.secondary)
        label.tracked(1.6)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(back)
        }
    }

    private func buildForm(user: User) {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(60)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-40)
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }

        let title = UILabel(text: "MAKE IT YOURS.", font: SkesteFont.display(30), color: Palette.text)
        title.richTracking(-0.6)
        contentStack.addArrangedSubview(title)
        contentStack.setCustomSpacing(4, after: title)

        handleLabel.text = user.handle
        contentStack.addArrangedSubview(handleLabel)
        contentStack.setCustomSpacing(20, after: handleLabel)

        let avatarButton = UIControl()
        avatar.configure(user: user)
        avatarButton.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        selectedImageView.contentMode = .scaleAspectFill
        selectedImageView.clipsToBounds = true
        selectedImageView.layer.cornerRadius = 51
        selectedImageView.layer.borderWidth = 3
        selectedImageView.layer.borderColor = Palette.magenta.cgColor
        selectedImageView.isHidden = true
        avatarButton.addSubview(selectedImageView)
        selectedImageView.snp.makeConstraints { make in
            make.center.equalTo(avatar)
            make.width.height.equalTo(102)
        }
        let badge = UIView()
        badge.backgroundColor = Palette.lime
        badge.layer.cornerRadius = 18
        badge.layer.borderWidth = 3
        badge.layer.borderColor = Palette.frost.cgColor
        avatarButton.addSubview(badge)
        badge.snp.makeConstraints { make in
            make.trailing.equalTo(avatar).offset(-3)
            make.bottom.equalTo(avatar).offset(-4)
            make.width.height.equalTo(36)
        }
        let camera = UIImageView(image: UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)))
        camera.tintColor = UIColor(hex: "0A0A0B")
        badge.addSubview(camera)
        camera.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(16) }
        avatarButton.addAction(UIAction { [weak self] _ in self?.choosePhoto() }, for: .touchUpInside)
        avatarButton.snp.makeConstraints { $0.height.equalTo(110) }
        contentStack.addArrangedSubview(avatarButton)
        contentStack.setCustomSpacing(8, after: avatarButton)

        let change = UILabel(text: "TAP TO CHANGE YOUR AVATAR", font: SkesteFont.demibold(8), color: Palette.cyan)
        change.tracked(1.4)
        change.textAlignment = .center
        contentStack.addArrangedSubview(change)
        contentStack.setCustomSpacing(24, after: change)

        nameField.textField.text = user.displayName
        nameField.textField.autocapitalizationType = .words
        nameField.textField.returnKeyType = .next
        resortField.textField.text = user.homeResort
        resortField.textField.autocapitalizationType = .words
        resortField.textField.returnKeyType = .next
        bioView.setText(user.bio)
        contentStack.addArrangedSubview(nameField)
        contentStack.setCustomSpacing(14, after: nameField)
        contentStack.addArrangedSubview(resortField)
        contentStack.setCustomSpacing(14, after: resortField)
        contentStack.addArrangedSubview(bioView)
        contentStack.setCustomSpacing(20, after: bioView)

        let charLabel = UILabel(text: "KEEP IT SHORT, KEEP IT TRUE.  ·  MAX 180 CHARACTERS", font: SkesteFont.demibold(7), color: Palette.muted)
        charLabel.tracked(1.0)
        contentStack.addArrangedSubview(charLabel)
        contentStack.setCustomSpacing(24, after: charLabel)

        let save = GradientButton(title: "SAVE MY PROFILE", icon: "checkmark", height: 54)
        save.addAction(UIAction { [weak self] _ in self?.save() }, for: .touchUpInside)
        contentStack.addArrangedSubview(save)

        let note = UILabel(text: "Your profile is visible to riders in your feed, comments, and coaching sessions.", font: SkesteFont.body(10), color: Palette.muted, lines: 0)
        note.textAlignment = .center
        contentStack.addArrangedSubview(note)
    }

    private func choosePhoto() {
        view.endEditing(true)
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func save() {
        view.endEditing(true)
        guard let user = SKDataStore.shared.currentUser else { return }
        let name = nameField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            showToast("Give your profile a name.", style: .error)
            return
        }
        let bio = String(bioView.text.prefix(180)).trimmingCharacters(in: .whitespacesAndNewlines)
        var fileName: String?
        if let selectedImage {
            fileName = MediaFiles.saveImage(selectedImage)
        }
        SKDataStore.shared.updateProfile(displayName: name, bio: bio, avatarFileName: fileName, avatarAsset: fileName == nil ? nil : nil)
        let resort = resortField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !resort.isEmpty, resort != user.homeResort {
            SKDataStore.shared.updateHomeResort(resort)
        }
        navigationController?.popViewController(animated: true)
        SkesteToast.show("Profile updated.", style: .success)
    }
}

extension EditProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let image = object as? UIImage, error == nil else { return }
            DispatchQueue.main.async {
                self?.selectedImage = image
                self?.selectedImageView.image = image
                self?.selectedImageView.isHidden = false
                SkesteHaptics.light()
            }
        }
    }
}
