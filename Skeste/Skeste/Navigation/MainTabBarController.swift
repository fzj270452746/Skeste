import UIKit
import SnapKit

enum RootTab: Int, CaseIterable {
    case home = 0
    case tools = 1
    case chats = 2
    case settings = 3

    var icon: String {
        switch self {
        case .home: return "mountain.2.fill"
        case .tools: return "slider.horizontal.3"
        case .chats: return "bubble.left.and.bubble.right.fill"
        case .settings: return "person.crop.circle"
        }
    }

    var title: String {
        switch self {
        case .home: return "Mountain"
        case .tools: return "Ridge Lab"
        case .chats: return "Ride Line"
        case .settings: return "Base Camp"
        }
    }
}

final class SkesteNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarHidden(true, animated: false)
        view.backgroundColor = Palette.canvas
        interactivePopGestureRecognizer?.isEnabled = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        topViewController?.preferredStatusBarStyle ?? .lightContent
    }

    override var childForStatusBarStyle: UIViewController? {
        topViewController
    }
}

final class TabIconButton: UIControl {
    private let iconView = UIImageView()
    private let activeBubble = UIView()
    private let activeGradient = CAGradientLayer()
    private let dot = UIView()
    private let isCenter: Bool
    private let symbolName: String

    var isActive: Bool = false {
        didSet { update(animated: true) }
    }

    init(tab: RootTab, isCenter: Bool = false) {
        self.isCenter = isCenter
        self.symbolName = isCenter ? "plus" : tab.icon
        super.init(frame: .zero)

        activeGradient.colors = SkesteGradient.signature.map(\.cgColor)
        activeGradient.startPoint = CGPoint(x: 0, y: 0)
        activeGradient.endPoint = CGPoint(x: 1, y: 1)
        activeBubble.layer.addSublayer(activeGradient)
        activeBubble.isUserInteractionEnabled = false
        addSubview(activeBubble)

        iconView.image = UIImage(systemName: symbolName, withConfiguration: UIImage.SymbolConfiguration(pointSize: isCenter ? 22 : 19, weight: .semibold)) ?? UIImage(systemName: "circle.fill")
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        addSubview(iconView)

        dot.backgroundColor = Palette.magenta
        dot.layer.cornerRadius = 1.5
        dot.isHidden = true
        addSubview(dot)

        activeBubble.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(isCenter ? -2 : 0)
            make.width.equalTo(isCenter ? 52 : 38)
            make.height.equalTo(isCenter ? 52 : 28)
        }
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(isCenter ? -2 : 0)
            make.width.height.equalTo(isCenter ? 24 : 21)
        }
        dot.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(iconView.snp.bottom).offset(9)
            make.width.height.equalTo(3)
        }
        if isCenter {
            transform = CGAffineTransform(translationX: 0, y: -7)
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = isCenter ? "Create" : tab.title

        snp.makeConstraints { $0.height.equalTo(62) }
        update(animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        activeGradient.frame = activeBubble.bounds
        activeGradient.cornerRadius = isCenter ? 12 : 6
        activeBubble.layer.cornerRadius = isCenter ? 12 : 6
    }

    private func update(animated: Bool) {
        let active = isActive || isCenter
        let activeTint = UIColor.white
        let animations = {
            self.activeBubble.alpha = active ? 1 : 0
            self.activeBubble.transform = active ? .identity : CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.iconView.tintColor = active ? activeTint : Palette.muted
        }
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: animations)
        } else {
            animations()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.iconView.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.82, y: 0.82) : .identity
            }
        }
    }
}

final class CustomTabBarView: UIView {
    var onSelect: ((RootTab) -> Void)?
    var onCompose: (() -> Void)?
    private let tabs: [RootTab] = [.home, .tools, .chats, .settings]
    private var buttons: [RootTab: TabIconButton] = [:]
    private let composeButton: TabIconButton
    private let blurContainer = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let borderLayer = CAGradientLayer()
    private let borderMask = CAShapeLayer()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        composeButton = TabIconButton(tab: .home, isCenter: true)
        super.init(frame: frame)
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 22
        layer.shadowOffset = CGSize(width: 0, height: 10)

        blurContainer.layer.cornerRadius = 18
        blurContainer.layer.cornerCurve = .continuous
        blurContainer.clipsToBounds = true
        blurContainer.backgroundColor = UIColor(hex: "120E32").withAlphaComponent(0.74)
        addSubview(blurContainer)
        blurContainer.snp.makeConstraints { $0.edges.equalToSuperview() }

        borderLayer.colors = [
            UIColor.white.withAlphaComponent(0.22).cgColor,
            UIColor(hex: "FF3FD8").withAlphaComponent(0.22).cgColor,
            UIColor.white.withAlphaComponent(0.12).cgColor
        ]
        borderLayer.startPoint = CGPoint(x: 0, y: 0)
        borderLayer.endPoint = CGPoint(x: 1, y: 1)
        borderLayer.mask = borderMask
        layer.addSublayer(borderLayer)

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.trailing.equalToSuperview().offset(-13)
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-5)
        }

        var ordered: [UIView] = []
        for tab in tabs {
            if tab == .chats {
                ordered.append(composeButton)
                composeButton.addAction(UIAction { [weak self] _ in
                    SkesteHaptics.medium()
                    self?.onCompose?()
                }, for: .touchUpInside)
            }
            let button = TabIconButton(tab: tab)
            buttons[tab] = button
            button.addAction(UIAction { [weak self] _ in
                SkesteHaptics.light()
                self?.setSelected(tab)
                self?.onSelect?(tab)
            }, for: .touchUpInside)
            ordered.append(button)
        }
        ordered.forEach { stack.addArrangedSubview($0) }

        snp.makeConstraints { $0.height.equalTo(76) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        borderLayer.frame = bounds
        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 18)
        borderMask.path = path.cgPath
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.white.cgColor
        borderMask.lineWidth = 1
        blurContainer.layer.cornerRadius = 18
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extended = bounds.insetBy(dx: 0, dy: -18)
        return extended.contains(point)
    }

    func setSelected(_ tab: RootTab) {
        for (key, button) in buttons {
            button.isActive = key == tab
        }
    }
}

final class MainTabBarController: UITabBarController, UINavigationControllerDelegate {
    private let customBar = CustomTabBarView()
    private var currentRoot: RootTab = .home
    private var barHidden = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas
        tabBar.isHidden = true

        let home = SkesteNavigationController(rootViewController: HomeViewController())
        let tools = SkesteNavigationController(rootViewController: ToolsViewController())
        let chats = SkesteNavigationController(rootViewController: ChatsViewController())
        let settings = SkesteNavigationController(rootViewController: SettingsViewController())
        let controllers = [home, tools, chats, settings]
        controllers.forEach { $0.delegate = self }
        setViewControllers(controllers, animated: false)
        selectedIndex = RootTab.home.rawValue

        view.addSubview(customBar)
        customBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
        customBar.setSelected(.home)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-startTools") {
            selectedIndex = RootTab.tools.rawValue
            currentRoot = .tools
            customBar.setSelected(.tools)
        }
        #endif
        customBar.onSelect = { [weak self] tab in
            self?.selectRootTab(tab)
        }
        customBar.onCompose = { [weak self] in
            self?.presentComposer()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(authChanged), name: .skesteAuthChanged, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(customBar)
    }

    func selectRootTab(_ tab: RootTab) {
        guard tab.rawValue < (viewControllers?.count ?? 0) else { return }
        selectedIndex = tab.rawValue
        currentRoot = tab
        customBar.setSelected(tab)
        showCustomBar(animated: false)
    }

    private func presentComposer() {
        let controller = PublishViewController()
        controller.onPublished = { [weak self] in
            self?.selectRootTab(.home)
        }
        let nav = SkesteNavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let isRoot = viewController === navigationController.viewControllers.first
        showCustomBar(animated: true, visible: isRoot)
    }

    private func showCustomBar(animated: Bool, visible: Bool = true) {
        if visible == !barHidden { return }
        barHidden = !visible
        customBar.isUserInteractionEnabled = visible
        let animations = {
            self.customBar.alpha = visible ? 1 : 0
            self.customBar.transform = visible ? .identity : CGAffineTransform(translationX: 0, y: 22)
        }
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: animations)
        } else {
            animations()
        }
    }

    @objc private func authChanged() {
        if AppStore.shared.isLoggedIn {
            customBar.setSelected(currentRoot)
        }
    }
}
