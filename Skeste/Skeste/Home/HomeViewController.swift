import UIKit
import SnapKit

final class SpotlightCarouselView: UIView {
    private let collectionView: UICollectionView
    private let layout = UICollectionViewFlowLayout()
    private let pageStack = UIStackView()
    private var pageBars: [UIView] = []
    private var pageWidths: [Constraint] = []
    private(set) var posts: [Post] = []
    private(set) var activeIndex = 0
    private var didSetInitialActive = false

    var onOpen: ((Post) -> Void)?
    var onAuthor: ((Post) -> Void)?
    var onLike: ((Post) -> Void)?
    var onComment: ((Post) -> Void)?
    var onGift: ((Post) -> Void)?

    override init(frame: CGRect) {
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 26)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        backgroundColor = .clear
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SpotlightCell.self, forCellWithReuseIdentifier: SpotlightCell.reuseIdentifier)
        collectionView.contentInsetAdjustmentBehavior = .never
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(540)
        }

        pageStack.axis = .horizontal
        pageStack.alignment = .center
        pageStack.spacing = 6
        addSubview(pageStack)
        pageStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(collectionView.snp.bottom).offset(12)
            make.height.equalTo(8)
            make.bottom.equalToSuperview()
        }
        snp.makeConstraints { $0.height.equalTo(560) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let itemWidth = max(250, bounds.width - 42)
        if layout.itemSize.width != itemWidth || layout.itemSize.height != 540 {
            layout.itemSize = CGSize(width: itemWidth, height: 540)
            layout.invalidateLayout()
        }
    }

    func configure(posts: [Post], startingAt: Int = 0) {
        self.posts = posts
        activeIndex = min(max(0, startingAt), max(0, posts.count - 1))
        didSetInitialActive = false
        rebuildPages()
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        scroll(to: activeIndex, animated: false)
        DispatchQueue.main.async { [weak self] in
            self?.updateActiveIndex(force: true)
        }
    }

    private func rebuildPages() {
        pageBars.forEach { $0.removeFromSuperview() }
        pageBars.removeAll()
        pageWidths.removeAll()
        pageStack.arrangedSubviews.forEach {
            pageStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard !posts.isEmpty else {
            let bar = UIView()
            bar.backgroundColor = Palette.lime
            bar.layer.cornerRadius = 1.5
            bar.snp.makeConstraints { make in
                make.width.equalTo(18)
                make.height.equalTo(3)
            }
            pageStack.addArrangedSubview(bar)
            return
        }
        for index in 0..<posts.count {
            let bar = UIView()
            bar.layer.cornerRadius = 1.5
            bar.backgroundColor = Palette.hairline
            pageStack.addArrangedSubview(bar)
            bar.snp.makeConstraints { make in
                make.height.equalTo(3)
                pageWidths.append(make.width.equalTo(6).constraint)
            }
            pageBars.append(bar)
        }
        updatePageBars()
    }

    private func updatePageBars() {
        for (index, bar) in pageBars.enumerated() {
            bar.backgroundColor = index == activeIndex ? Palette.lime : Palette.hairline
            if index < pageWidths.count {
                pageWidths[index].update(offset: index == activeIndex ? 22 : 6)
            }
        }
        UIView.animate(withDuration: 0.25) { self.pageStack.layoutIfNeeded() }
    }

    private func scroll(to index: Int, animated: Bool) {
        guard index >= 0, index < posts.count else { return }
        let itemWidth = layout.itemSize.width + layout.minimumLineSpacing
        let x = CGFloat(index) * itemWidth
        collectionView.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
    }

    private func updateActiveIndex(force: Bool = false) {
        guard !posts.isEmpty else { return }
        let step = layout.itemSize.width + layout.minimumLineSpacing
        let index = max(0, min(posts.count - 1, Int(round(collectionView.contentOffset.x / max(step, 1)))))
        if index != activeIndex || force {
            activeIndex = index
            updatePageBars()
            for cell in collectionView.visibleCells {
                guard let spotlight = cell as? SpotlightCell, let indexPath = collectionView.indexPath(for: spotlight) else { continue }
                spotlight.setActive(indexPath.item == index)
            }
        }
    }

    func pausePlayback() {
        for cell in collectionView.visibleCells {
            (cell as? SpotlightCell)?.setActive(false)
        }
    }

    func resumePlayback() {
        updateActiveIndex(force: true)
    }
}

extension SpotlightCarouselView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        posts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpotlightCell.reuseIdentifier, for: indexPath) as? SpotlightCell else {
            return UICollectionViewCell()
        }
        let post = posts[indexPath.item]
        let active = indexPath.item == activeIndex
        cell.configure(post: post, index: indexPath.item, active: active)
        cell.onOpen = { [weak self] in self?.onOpen?(post) }
        cell.onAuthor = { [weak self] in self?.onAuthor?(post) }
        cell.onLike = { [weak self] in self?.onLike?(post) }
        cell.onComment = { [weak self] in self?.onComment?(post) }
        cell.onGift = { [weak self] in self?.onGift?(post) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? SpotlightCell)?.setActive(false)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateActiveIndex()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard !posts.isEmpty else { return }
        let step = layout.itemSize.width + layout.minimumLineSpacing
        let maxOffset = max(0, scrollView.contentSize.width - scrollView.bounds.width)
        let proposed = targetContentOffset.pointee.x
        let index = max(0, min(posts.count - 1, Int(round(proposed / step))))
        targetContentOffset.pointee.x = min(maxOffset, CGFloat(index) * step)
    }
}

final class HomeViewController: BaseViewController {
    private let scrollView = UIScrollView()
    private let refreshControl = UIRefreshControl()
    private let contentStack = UIStackView()
    private let feedStack = UIStackView()
    private var headerView: HomeHeaderView?
    private var conditionsView: ConditionsStripView?
    private var carousel: SpotlightCarouselView?
    private var footerContainer = UIView()
    private var footerLabel = UILabel(text: nil, font: SkesteFont.medium(11), color: Palette.muted)
    private var footerSpinner = UIActivityIndicatorView(style: .medium)
    private var visibleCount = 5
    private var filteredPosts: [Post] = []
    private var isLoadingMore = false
    private var lastSignature = ""
    private var pendingReload = false
    private let feedCountLabel = UILabel(text: nil, font: SkesteFont.demibold(9), color: Palette.muted)

    override func setupView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.keyboardDismissMode = .interactive
        scrollView.delegate = self
        scrollView.refreshControl = refreshControl
        refreshControl.tintColor = Palette.cyan
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(AppLayout.screenPadding)
            make.trailing.equalToSuperview().offset(-AppLayout.screenPadding)
            make.bottom.equalToSuperview().offset(-(AppLayout.tabBarClearance + 18))
            make.width.equalTo(scrollView.snp.width).offset(-AppLayout.screenPadding * 2)
        }

        rebuild(preserveScroll: false)
    }

    override func refreshView() {
        SnowReportStore.shared.refreshIfNeeded(named: homeResortKey())
        let signature = currentSignature()
        if signature != lastSignature {
            rebuild(preserveScroll: true)
        } else {
            updateHeader()
        }
        carousel?.resumePlayback()
    }

    override func snowDidChange(resortName: String?) {
        guard isViewLoaded, view.window != nil else { return }
        guard resortName == nil || resortName == homeResortKey() else { return }
        updateHeader()
    }

    private func homeResortName() -> String {
        SKDataStore.shared.currentUser?.homeResort ?? "Chamonix, FR"
    }

    private func homeResortKey() -> String {
        SnowLibrary.resort(named: homeResortName())?.name ?? SnowLibrary.resorts[0].name
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        carousel?.pausePlayback()
    }

    override func authDidChange() {
        rebuild(preserveScroll: true)
    }

    override func contentDidChange() {
        guard isViewLoaded, view.window != nil else { return }
        if presentedViewController == nil {
            rebuild(preserveScroll: true)
        } else {
            pendingReload = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if pendingReload {
            pendingReload = false
            rebuild(preserveScroll: true)
        }
    }

    private func currentSignature() -> String {
        let posts = SKDataStore.shared.sortedPosts.map { "\($0.id)-\($0.likeCount)-\($0.giftCount)" }.joined(separator: "|")
        let comments = SKDataStore.shared.state.comments.count
        return "\(posts)#\(comments)#\(SKDataStore.shared.currentUser?.id ?? "guest")"
    }

    private func rebuild(preserveScroll: Bool) {
        let previousOffset = preserveScroll ? scrollView.contentOffset : .zero
        let previousSpotlight = carousel?.activeIndex ?? 0
        filteredPosts = noteFeed()
        visibleCount = min(max(visibleCount, 5), max(filteredPosts.count, 5))
        if !preserveScroll { visibleCount = 5 }

        contentStack.arrangedSubviews.forEach { view in
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        buildHeader()
        buildConditions()
        buildSpotlight(startingAt: previousSpotlight)
        buildFeedHeader()
        buildFeed()
        buildFooter()
        lastSignature = currentSignature()
        updateHeader()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if preserveScroll {
                let maxOffset = max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom)
                self.scrollView.setContentOffset(CGPoint(x: 0, y: min(previousOffset.y, maxOffset)), animated: false)
            }
            self.carousel?.resumePlayback()
        }
    }

    private func buildHeader() {
        let spacer = UIView()
        spacer.snp.makeConstraints { $0.height.equalTo(4) }
        contentStack.addArrangedSubview(spacer)
        let header = HomeHeaderView()
        header.onAccountTapped = { [weak self] in
            self?.accountTapped()
        }
        contentStack.addArrangedSubview(header)
        headerView = header
        updateHeader()
    }

    private func updateHeader() {
        headerView?.configure(user: SKDataStore.shared.currentUser)
        conditionsView?.configure(resort: homeResortName())
    }

    private func buildConditions() {
        let wrap = UIView()
        let conditions = ConditionsStripView()
        conditions.onTap = { [weak self] in
            self?.push(SnowDeskViewController())
        }
        wrap.addSubview(conditions)
        conditions.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
        }
        contentStack.addArrangedSubview(wrap)
        conditionsView = conditions
        conditions.configure(resort: SKDataStore.shared.currentUser?.homeResort ?? "Chamonix, FR")
    }

    private func buildSpotlight(startingAt: Int) {
        let heading = SectionHeadingView(kicker: "Tonight's standout lines", title: "THE DROP", actionTitle: "RIDGE RADIO", onAction: nil)
        contentStack.addArrangedSubview(heading)
        contentStack.setCustomSpacing(24, after: heading)

        let carousel = SpotlightCarouselView()
        let reels = SKDataStore.shared.reels
        carousel.configure(posts: reels, startingAt: startingAt)
        carousel.onOpen = { [weak self] post in self?.openPost(post) }
        carousel.onAuthor = { [weak self] post in self?.openAuthor(post) }
        carousel.onLike = { [weak self] post in self?.toggleLike(post) }
        carousel.onComment = { [weak self] post in self?.openComments(post) }
        carousel.onGift = { [weak self] post in self?.openGifts(post) }
        contentStack.addArrangedSubview(carousel)
        self.carousel = carousel
        contentStack.setCustomSpacing(30, after: carousel)
    }

    private func buildFeedHeader() {
        let heading = SectionHeadingView(kicker: "Stories from the ridgeline", title: "FIELD NOTES", actionTitle: nil, onAction: nil)
        contentStack.addArrangedSubview(heading)
        feedCountLabel.attributedText = NSAttributedString(string: "SCROLL FOR MORE  ↓", attributes: [
            .font: SkesteFont.demibold(8),
            .foregroundColor: Palette.muted,
            .kern: 1.8
        ])
        let meta = UIView()
        meta.addSubview(feedCountLabel)
        feedCountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview()
        }
        contentStack.addArrangedSubview(meta)
        contentStack.setCustomSpacing(15, after: meta)
    }

    private func buildFeed() {
        feedStack.axis = .vertical
        feedStack.spacing = 14
        contentStack.addArrangedSubview(feedStack)

        if filteredPosts.isEmpty {
            let empty = UILabel(text: "No field notes yet. Drop the first one.", font: SkesteFont.medium(14), color: Palette.secondary, lines: 0)
            empty.textAlignment = .center
            let wrap = UIView()
            wrap.backgroundColor = Palette.glass
            wrap.layer.cornerRadius = 14
            wrap.layer.borderWidth = 1
            wrap.layer.borderColor = Palette.hairline.cgColor
            wrap.addSubview(empty)
            empty.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(24)
            }
            feedStack.addArrangedSubview(wrap)
            return
        }

        let shown = filteredPosts.prefix(visibleCount)
        for (index, post) in shown.enumerated() {
            let card = PostCardView()
            card.configure(post: post, index: index)
            card.onOpen = { [weak self] in self?.openPost(post) }
            card.onAuthor = { [weak self] in self?.openAuthor(post) }
            card.onLike = { [weak self] in self?.toggleLike(post) }
            card.onComment = { [weak self] in self?.openComments(post) }
            card.onGift = { [weak self] in self?.openGifts(post) }
            card.onMore = { [weak self] in self?.showPostMenu(post) }
            feedStack.addArrangedSubview(card)
        }
    }

    private func buildFooter() {
        footerSpinner.color = Palette.cyan
        footerSpinner.hidesWhenStopped = true
        footerLabel.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [footerSpinner, footerLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 6
        footerContainer = UIView()
        footerContainer.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        contentStack.addArrangedSubview(footerContainer)
        updateFooter()
    }

    private func updateFooter() {
        if filteredPosts.isEmpty {
            footerLabel.text = ""
            footerSpinner.stopAnimating()
            return
        }
        if visibleCount >= filteredPosts.count {
            footerLabel.text = "YOU'VE REACHED THE EDGE OF THE RIDGE"
        } else {
            footerLabel.text = "MORE NOTES BELOW  ·  \(filteredPosts.count - visibleCount) TO GO"
        }
        footerLabel.font = SkesteFont.demibold(8)
        footerLabel.textColor = Palette.muted
        footerLabel.attributedText = NSAttributedString(string: footerLabel.text ?? "", attributes: [
            .font: SkesteFont.demibold(8),
            .foregroundColor: Palette.muted,
            .kern: 1.4
        ])
    }

    /// The home feed below THE DROP is image-only. Video posts live in the
    /// spotlight carousel, so reels never enter this stack.
    private func noteFeed() -> [Post] {
        SKDataStore.shared.sortedPosts.filter { $0.kind == .note }
    }

    private func loadMore() {
        guard !isLoadingMore, visibleCount < filteredPosts.count else { return }
        isLoadingMore = true
        footerSpinner.startAnimating()
        footerLabel.text = "LOADING MORE NOTES…"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            self.visibleCount = min(self.visibleCount + 4, self.filteredPosts.count)
            self.isLoadingMore = false
            self.footerSpinner.stopAnimating()
            self.rebuild(preserveScroll: true)
        }
    }

    @objc private func refreshPulled() {
        Task { [weak self] in
            guard let self else { return }
            _ = await SnowReportStore.shared.refresh(named: self.homeResortKey(), force: true)
            self.refreshControl.endRefreshing()
            self.updateHeader()
        }
    }

    private func accountTapped() {
        if SKDataStore.shared.isLoggedIn {
            (tabBarController as? MainTabBarController)?.selectRootTab(.settings)
        } else {
            requireLogin { [weak self] in
                self?.rebuild(preserveScroll: true)
            }
        }
    }

    private func openPost(_ post: Post) {
        let detail = PostDetailViewController(postID: post.id)
        push(detail)
    }

    private func openComments(_ post: Post) {
        let detail = PostDetailViewController(postID: post.id, focusComments: true)
        push(detail)
    }

    private func openAuthor(_ post: Post) {
        guard let author = SKDataStore.shared.user(withID: post.authorID) else { return }
        if author.id == SKDataStore.shared.currentUser?.id {
            (tabBarController as? MainTabBarController)?.selectRootTab(.settings)
            return
        }
        push(UserProfileViewController(userID: author.id, source: .home))
    }

    private func toggleLike(_ post: Post) {
        requireLogin { [weak self] in
            guard let self else { return }
            if SKDataStore.shared.toggleLike(postID: post.id) == nil {
                self.showToast("That line is no longer available.", style: .error)
                return
            }
            self.rebuild(preserveScroll: true)
        }
    }

    private func openGifts(_ post: Post) {
        requireLogin { [weak self] in
            guard let self else { return }
            let sheet = GiftSheetViewController(postID: post.id)
            sheet.onGiftSent = { [weak self] in
                self?.rebuild(preserveScroll: true)
            }
            if let presentation = sheet.sheetPresentationController {
                presentation.detents = [.medium(), .large()]
                presentation.prefersGrabberVisible = false
                presentation.preferredCornerRadius = 30
            }
            self.present(sheet, animated: true)
        }
    }

    private func showPostMenu(_ post: Post) {
        var actions: [SkesteSheetAction] = [
            SkesteSheetAction(title: "Report this post", symbol: "flag") { [weak self] in
                self?.push(ReportViewController(target: .post(postID: post.id), source: .home))
            }
        ]
        if post.authorID == SKDataStore.shared.currentUser?.id {
            actions.insert(SkesteSheetAction(title: "Delete this post", symbol: "trash", destructive: true) { [weak self] in
                self?.showConfirm(title: "Delete this line?", message: "This post and its comments will leave the mountain for good.", confirmTitle: "Delete post", destructive: true) {
                    SKDataStore.shared.deletePost(id: post.id)
                    self?.rebuild(preserveScroll: true)
                    self?.showToast("Your post has been removed.", style: .success)
                }
            }, at: 0)
        }
        let sheet = SkesteActionSheetViewController(heading: "POST OPTIONS", message: post.caption, actions: actions)
        present(sheet, animated: true)
    }
}

extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.scrollView, !isLoadingMore else { return }
        let threshold = scrollView.contentSize.height - scrollView.bounds.height * 0.7
        if scrollView.contentOffset.y > threshold, visibleCount < filteredPosts.count {
            loadMore()
        }
    }
}
