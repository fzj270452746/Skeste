import UIKit
import SnapKit

final class MediaViewerCell: UICollectionViewCell {
    static let reuseIdentifier = "MediaViewerCell"
    let preview = MediaPreviewView()
    private(set) var index: Int = 0
    private(set) var active = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.setImageContentMode(.scaleAspectFit)
        contentView.addSubview(preview)
        preview.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(media: MediaItem, index: Int, active: Bool) {
        self.index = index
        self.active = active
        preview.configure(with: media, allowsPlayback: active)
        preview.setPlayBadge(hidden: true)
    }

    func setActive(_ active: Bool) {
        guard active != self.active else { return }
        self.active = active
        preview.setPlaybackActive(active)
        preview.setPlayBadge(hidden: true)
    }
}

final class MediaViewerViewController: UIViewController {
    private let items: [MediaItem]
    private var currentIndex: Int
    private let collectionView: UICollectionView
    private let layout = UICollectionViewFlowLayout()
    private let pageLabel = UILabel(text: "01 / 01", font: SkesteFont.mono(10, weight: .bold), color: .white)
    private let pageStack = UIStackView()
    private var bars: [UIView] = []

    init(items: [MediaItem], startIndex: Int) {
        self.items = items
        self.currentIndex = min(max(0, startIndex), max(0, items.count - 1))
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var prefersStatusBarHidden: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MediaViewerCell.self, forCellWithReuseIdentifier: MediaViewerCell.reuseIdentifier)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalToSuperview() }
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: IndexPath(item: currentIndex, section: 0), at: .centeredHorizontally, animated: false)

        let fade = CAGradientLayer()
        fade.colors = [UIColor.black.withAlphaComponent(0.72).cgColor, UIColor.clear.cgColor]
        fade.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 140)
        let gradientView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 140))
        gradientView.isUserInteractionEnabled = false
        gradientView.layer.addSublayer(fade)
        view.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(160)
        }

        let close = SkesteControls.iconButton(symbol: "xmark", diameter: 42)
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
        }

        pageLabel.textAlignment = .right
        view.addSubview(pageLabel)
        pageLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-22)
            make.centerY.equalTo(close)
        }

        pageStack.axis = .horizontal
        pageStack.spacing = 6
        pageStack.alignment = .center
        view.addSubview(pageStack)
        pageStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-18)
            make.height.equalTo(4)
        }
        for _ in items {
            let bar = UIView()
            bar.layer.cornerRadius = 2
            bar.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            pageStack.addArrangedSubview(bar)
            bar.snp.makeConstraints { $0.width.equalTo(6); $0.height.equalTo(4) }
            bars.append(bar)
        }
        updateChrome()
        DispatchQueue.main.async { [weak self] in
            self?.setActiveCell()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layout.itemSize = view.bounds.size
        layout.invalidateLayout()
    }

    private func updateChrome() {
        pageLabel.text = String(format: "%02d / %02d", currentIndex + 1, items.count)
        for (index, bar) in bars.enumerated() {
            bar.backgroundColor = index == currentIndex ? Palette.lime : UIColor.white.withAlphaComponent(0.3)
        }
    }

    private func setActiveCell() {
        for cell in collectionView.visibleCells {
            guard let mediaCell = cell as? MediaViewerCell, let path = collectionView.indexPath(for: mediaCell) else { continue }
            mediaCell.setActive(path.item == currentIndex)
        }
    }
}

extension MediaViewerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaViewerCell.reuseIdentifier, for: indexPath) as? MediaViewerCell else {
            return UICollectionViewCell()
        }
        cell.configure(media: items[indexPath.item], index: indexPath.item, active: indexPath.item == currentIndex)
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let index = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        guard index != currentIndex, index >= 0, index < items.count else { return }
        currentIndex = index
        updateChrome()
        setActiveCell()
    }
}
