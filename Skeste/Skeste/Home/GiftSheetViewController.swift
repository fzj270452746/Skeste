import UIKit
import SnapKit

final class GiftCardView: UIControl {
    private let artHost = UIView()
    private let artGradient = CAGradientLayer()
    private let imageView = UIImageView()
    private let symbolView = UIImageView()
    private let nameLabel = UILabel(text: nil, font: SkesteFont.demibold(13), color: Palette.text)
    private let taglineLabel = UILabel(text: nil, font: SkesteFont.body(10), color: Palette.muted, lines: 2)
    private let priceLabel = UILabel(text: nil, font: SkesteFont.demibold(12), color: Palette.text)
    private let spinner = UIActivityIndicatorView(style: .medium)
    let gift: Gift

    init(gift: Gift) {
        self.gift = gift
        super.init(frame: .zero)
        applyGlass(cornerRadius: 20, borderAlpha: 0.14, fill: Palette.glass)

        artHost.layer.cornerRadius = 16
        artHost.layer.cornerCurve = .continuous
        artHost.clipsToBounds = true
        addSubview(artHost)
        artHost.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview().inset(8)
            make.height.equalTo(96)
        }
        artGradient.colors = gift.colors.map { UIColor(hex: $0).cgColor }
        artGradient.startPoint = CGPoint(x: 0, y: 0)
        artGradient.endPoint = CGPoint(x: 1, y: 1)
        artHost.layer.insertSublayer(artGradient, at: 0)

        // 礼物图是 1:1 的透明底徽章素材，宽扁的取景框用 aspectFill 会裁掉上下边缘，这里改为完整显示
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        artHost.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        symbolView.image = UIImage(systemName: gift.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .medium))
        symbolView.tintColor = .white
        symbolView.contentMode = .scaleAspectFit
        artHost.addSubview(symbolView)
        symbolView.snp.makeConstraints { $0.center.equalToSuperview(); $0.width.height.equalTo(38) }

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalTo(artHost.snp.bottom).offset(9)
        }
        taglineLabel.numberOfLines = 1
        addSubview(taglineLabel)
        taglineLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-10)
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
        }
        addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(taglineLabel.snp.bottom).offset(6)
            make.bottom.equalToSuperview().offset(-11)
        }

        spinner.color = Palette.cyan
        spinner.hidesWhenStopped = true
        addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(priceLabel)
        }

        snp.makeConstraints { make in
            make.height.equalTo(170)
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        artGradient.frame = artHost.bounds
    }

    func configure() {
        nameLabel.text = gift.name
        taglineLabel.text = gift.tagline
        priceLabel.text = StoreKitService.shared.priceLabel(for: gift)
        if let image = AssetResolver.image(named: gift.imageName) {
            imageView.image = image
            imageView.isHidden = false
            symbolView.isHidden = true
        } else {
            imageView.isHidden = true
            symbolView.isHidden = false
        }
    }

    func setBusy(_ busy: Bool) {
        isUserInteractionEnabled = !busy
        alpha = busy ? 0.7 : 1
        if busy { spinner.startAnimating() } else { spinner.stopAnimating() }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
    }
}

final class GiftSheetViewController: UIViewController {
    var onGiftSent: (() -> Void)?
    private let postID: String
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var cards: [GiftCardView] = []
    private var isPurchasing = false
    private let subtitleLabel = UILabel(text: "Gifts fund the next line. Choose a drop for this rider.", font: SkesteFont.body(13), color: Palette.secondary, lines: 0)

    init(postID: String) {
        self.postID = postID
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 30
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas
        view.overrideUserInterfaceStyle = .dark

        let gradient = CAGradientLayer()
        gradient.colors = [Palette.deep.cgColor, Palette.canvas.cgColor]
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 500)
        view.layer.insertSublayer(gradient, at: 0)

        let grabber = SheetGrabber()
        view.addSubview(grabber)
        grabber.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
        }

        let close = SkesteControls.iconButton(symbol: "xmark", diameter: 34)
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalToSuperview().offset(18)
        }

        let kicker = UILabel(text: "SEND THE STOKE", font: SkesteFont.demibold(9), color: Palette.lime)
        kicker.tracked(2.2)
        view.addSubview(kicker)
        kicker.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalToSuperview().offset(32)
        }

        let title = UILabel(text: "DROP A GIFT", font: SkesteFont.display(26), color: Palette.text)
        title.richTracking(-0.5)
        view.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.top.equalTo(kicker.snp.bottom).offset(2)
        }

        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(22)
            make.trailing.equalToSuperview().offset(-22)
            make.top.equalTo(title.snp.bottom).offset(2)
        }

        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
        }

        contentStack.axis = .vertical
        contentStack.spacing = 10
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 30, right: 20))
            make.width.equalTo(scrollView.snp.width).offset(-40)
        }

        var rowStack: UIStackView?
        for (index, gift) in Gift.catalog.enumerated() {
            if index % 2 == 0 {
                let row = UIStackView()
                row.axis = .horizontal
                row.spacing = 10
                row.distribution = .fillEqually
                contentStack.addArrangedSubview(row)
                rowStack = row
            }
            let card = GiftCardView(gift: gift)
            card.addAction(UIAction { [weak self, weak card] _ in
                guard let self, let card else { return }
                self.purchase(gift, card: card)
            }, for: .touchUpInside)
            rowStack?.addArrangedSubview(card)
            cards.append(card)
        }

        let note = UILabel(text: "Purchases are processed securely by the App Store. Gifts are consumable and delivered instantly.", font: SkesteFont.body(10), color: Palette.muted, lines: 0)
        note.textAlignment = .center
        contentStack.addArrangedSubview(note)

        Task { [weak self] in
            await StoreKitService.shared.loadProducts()
            await MainActor.run {
                self?.cards.forEach { $0.configure() }
            }
        }
    }

    private func purchase(_ gift: Gift, card: GiftCardView) {
        guard !isPurchasing else { return }
        isPurchasing = true
        card.setBusy(true)
        SkesteHaptics.light()
        Task { [weak self] in
            let result = await StoreKitService.shared.purchase(gift)
            await MainActor.run {
                guard let self else { return }
                self.isPurchasing = false
                card.setBusy(false)
                switch result {
                case .success:
                    AppStore.shared.addGift(postID: self.postID, giftID: gift.id)
                    SkesteHaptics.success()
                    GiftBurstView.show(gift: gift)
                    self.onGiftSent?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        self.dismiss(animated: true) {
                            SkesteToast.show("\(gift.name) delivered.", style: .success)
                        }
                    }
                case .cancelled:
                    break
                case .pending:
                    SkesteToast.show("Your gift is pending approval.", style: .info)
                case .unavailable:
                    SkesteToast.show("Gifts are unavailable right now. Please try again later.", style: .error)
                case .failed(let message):
                    SkesteToast.show(message, style: .error)
                }
            }
        }
    }
}
