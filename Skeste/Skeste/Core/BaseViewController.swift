import UIKit
import SnapKit
import SafariServices

enum AppLayout {
    static let screenPadding: CGFloat = 20
    static let tabBarClearance: CGFloat = 106
}

class BaseViewController: UIViewController {
    let backdrop = AuroraBackgroundView()
    private var keyboardTap: UITapGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.canvas
        backdrop.backgroundColor = Palette.canvas
        view.addSubview(backdrop)
        backdrop.snp.makeConstraints { $0.edges.equalToSuperview() }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        keyboardTap = tap

        NotificationCenter.default.addObserver(self, selector: #selector(authNotification), name: .skesteAuthChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contentNotification), name: .skesteContentChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(snowNotification(_:)), name: .skesteSnowChanged, object: nil)
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        backdrop.startAnimating()
        refreshView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        backdrop.stopAnimating()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        false
    }

    func setupView() {}
    func refreshView() {}
    func authDidChange() {}
    func contentDidChange() {}
    func snowDidChange(resortName: String?) {}

    @objc private func authNotification() {
        authDidChange()
    }

    @objc private func contentNotification() {
        contentDidChange()
    }

    @objc private func snowNotification(_ notification: Notification) {
        snowDidChange(resortName: notification.object as? String)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func requireLogin(completion: @escaping () -> Void) {
        if SKDataStore.shared.isLoggedIn {
            completion()
            return
        }
        let auth = AuthViewController()
        auth.onAuthenticated = completion
        auth.modalPresentationStyle = .fullScreen
        present(auth, animated: true)
    }

    func showToast(_ message: String, style: SkesteToastStyle = .info) {
        SkesteToast.show(message, style: style)
    }

    func showConfirm(title: String, message: String, confirmTitle: String, destructive: Bool = false, onConfirm: @escaping () -> Void) {
        let alert = SkesteAlertViewController(title: title, message: message, confirmTitle: confirmTitle, destructive: destructive, onConfirm: onConfirm)
        present(alert, animated: true)
    }

    func presentWebLink(_ url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.preferredBarTintColor = Palette.canvas
        safari.preferredControlTintColor = Palette.cyan
        safari.modalPresentationStyle = .pageSheet
        present(safari, animated: true)
    }

    func presentLegal(_ document: LegalDocument) {
        if let url = document.webURL {
            presentWebLink(url)
            return
        }
        let legal = LegalViewController(document: document)
        let nav = SkesteNavigationController(rootViewController: legal)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 30
        }
        present(nav, animated: true)
    }

    func push(_ viewController: UIViewController) {
        navigationController?.pushViewController(viewController, animated: true)
    }

    func returnToRootTab(_ tab: RootTab) {
        navigationController?.popToRootViewController(animated: false)
        (tabBarController as? MainTabBarController)?.selectRootTab(tab)
    }

    func topPresenter() -> UIViewController {
        var presenter: UIViewController = self
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        return presenter
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
