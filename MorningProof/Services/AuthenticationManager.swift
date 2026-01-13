import Foundation
import AuthenticationServices
import SwiftUI
import GoogleSignIn

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageKey = "morning_proof_auth_user"

    override init() {
        super.init()
        loadStoredUser()
    }

    // MARK: - User Model

    struct AuthUser: Codable {
        let id: String
        let email: String?
        let fullName: String?
        let provider: AuthProvider

        enum AuthProvider: String, Codable {
            case apple
            case google
            case anonymous
        }
    }

    // MARK: - Sign in with Apple

    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = [
                    appleIDCredential.fullName?.givenName,
                    appleIDCredential.fullName?.familyName
                ].compactMap { $0 }.joined(separator: " ")

                let user = AuthUser(
                    id: userID,
                    email: email,
                    fullName: fullName.isEmpty ? nil : fullName,
                    provider: .apple
                )

                saveUser(user)
                isAuthenticated = true
                currentUser = user
                isLoading = false
                completion(true)
            } else {
                isLoading = false
                errorMessage = "Invalid credentials"
                completion(false)
            }

        case .failure(let error):
            isLoading = false
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                // User canceled, not an error
                errorMessage = nil
            } else {
                errorMessage = error.localizedDescription
            }
            completion(false)
        }
    }

    // MARK: - Sign in with Google

    private let googleClientID = "591131827329-487r1epolmgvbq8vdf3cje54qlpmi0a3.apps.googleusercontent.com"

    func signInWithGoogle(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            isLoading = false
            errorMessage = "Unable to get root view controller"
            completion(false)
            return
        }

        let config = GIDConfiguration(clientID: googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self = self else { return }

            Task { @MainActor in
                self.isLoading = false

                if let error = error {
                    if (error as NSError).code == GIDSignInError.canceled.rawValue {
                        // User canceled, not an error
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    completion(false)
                    return
                }

                guard let googleUser = result?.user else {
                    self.errorMessage = "Failed to get user data"
                    completion(false)
                    return
                }

                let user = AuthUser(
                    id: googleUser.userID ?? UUID().uuidString,
                    email: googleUser.profile?.email,
                    fullName: googleUser.profile?.name,
                    provider: .google
                )

                self.saveUser(user)
                self.isAuthenticated = true
                self.currentUser = user
                completion(true)
            }
        }
    }

    // Handle Google Sign-In URL callback
    func handleGoogleURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Sign Out

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - Anonymous / Skip

    func continueAnonymously() {
        let user = AuthUser(
            id: UUID().uuidString,
            email: nil,
            fullName: nil,
            provider: .anonymous
        )
        saveUser(user)
        isAuthenticated = true
        currentUser = user
    }

    // MARK: - Persistence

    private func saveUser(_ user: AuthUser) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func loadStoredUser() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let user = try? JSONDecoder().decode(AuthUser.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }

    // MARK: - Check Apple ID Credential State

    func checkAppleCredentialState() {
        guard let user = currentUser, user.provider == .apple else { return }

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: user.id) { credentialState, _ in
            Task { @MainActor in
                switch credentialState {
                case .revoked, .notFound:
                    self.signOut()
                case .authorized:
                    break
                default:
                    break
                }
            }
        }
    }
}
