import Foundation
import AuthenticationServices
import UIKit

final class AppleSignInService: NSObject {
    var onSuccess: ((_ userIdentifier: String, _ name: String?) -> Void)?
    var onFailure: ((_ message: String?) -> Void)?
    private var isRunning = false
    private var controller: ASAuthorizationController?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.controller = controller
        controller.performRequests()
    }

    private static func message(for error: Error) -> String {
        guard let authError = error as? ASAuthorizationError else {
            return "Apple sign-in could not be completed. Please try again."
        }
        switch authError.code {
        case .canceled:
            return ""
        case .failed, .invalidResponse:
            return "Apple sign-in could not be completed. Please try again."
        case .notHandled, .unknown:
            return "Apple sign-in is unavailable right now. Use your username instead."
        default:
            return "Apple sign-in could not be completed. Please try again."
        }
    }
}

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        isRunning = false
        self.controller = nil
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            onFailure?("Apple sign-in could not be completed. Please try again.")
            return
        }
        let name: String?
        if let components = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            let formatted = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
            name = formatted.isEmpty ? nil : formatted
        } else {
            name = nil
        }
        onSuccess?(credential.user, name)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isRunning = false
        self.controller = nil
        let message = Self.message(for: error)
        onFailure?(message.isEmpty ? nil : message)
    }
}

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first(where: { $0.isKeyWindow }) ?? windows.first ?? ASPresentationAnchor()
    }
}
