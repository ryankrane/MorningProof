import Foundation
import AuthenticationServices
import SwiftUI
import GoogleSignIn

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    nonisolated(unsafe) static let shared = AuthenticationManager()

    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let storageKey = "morning_proof_auth_user"
    private let googleClientID = "591131827329-487r1epolmgvbq8vdf3cje54qlpmi0a3.apps.googleusercontent.com"

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

    func signInWithGoogle(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil

        // Configure Google Sign-In with client ID
        let config = GIDConfiguration(clientID: googleClientID)
        GIDSignIn.sharedInstance.configuration = config

        // Get the root view controller for presenting the sign-in flow
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            isLoading = false
            errorMessage = "Unable to get root view controller"
            completion(false)
            return
        }

        // Present Google Sign-In
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let error = error {
                    self.isLoading = false
                    // Check if user cancelled (GIDSignInError code 1 = canceled)
                    let nsError = error as NSError
                    if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    completion(false)
                    return
                }

                guard let user = result?.user,
                      let profile = user.profile else {
                    self.isLoading = false
                    self.errorMessage = "Unable to get user profile"
                    completion(false)
                    return
                }

                // Create AuthUser from Google profile
                let authUser = AuthUser(
                    id: user.userID ?? UUID().uuidString,
                    email: profile.email,
                    fullName: profile.name,
                    provider: .google
                )

                self.saveUser(authUser)
                self.isAuthenticated = true
                self.currentUser = authUser
                self.isLoading = false
                completion(true)
            }
        }
    }

    /// Handle Google Sign-In URL callback
    func handleGoogleURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Sign Out

    func signOut() {
        // Sign out of Google if using Google provider
        if currentUser?.provider == .google {
            GIDSignIn.sharedInstance.signOut()
        }
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
