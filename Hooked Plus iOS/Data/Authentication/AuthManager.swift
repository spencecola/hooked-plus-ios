//
//  AuthenticationManager.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import FirebaseCore
import FirebaseAuth
import GoogleSignIn

enum AuthState {
    case uninitialized
    case authenticated(user: User)
    case unauthenticated
}

class AuthManager: ObservableObject {
    @Published var state: AuthState = .uninitialized
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.state = if let user { .authenticated(user: user) } else { .unauthenticated }
        }
    }
    
    func signInWithGoogle() async throws {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw URLError(.badServerResponse)
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            // Get the top view controller for presenting Google Sign-In
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
                throw URLError(.cannotFindHost)
            }

            // Perform Google Sign-In
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user
            guard let idToken = user.idToken?.tokenString else {
                throw URLError(.userAuthenticationRequired)
            }

            // Authenticate with Firebase
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
        
            do {
                let result = try await Auth.auth().signIn(with: credential)
                do {
                    try await createUserDocument(user: result.user, firstName: "Test", lastName: "Test")
                } catch {
                    // if we fail to create a user document, delete the new user auth account
                    try await Auth.auth().currentUser?.delete()
                    throw error
                }
            } catch {
                debugPrint("Failed to sign in with google \(error)")
                throw error
            }

            // Optionally, call your backend to create/update user data
            // Example: await UserService.createUser(email: user.profile?.email ?? "", firstName: user.profile?.givenName ?? "", lastName: user.profile?.familyName ?? "", interests: [])
        }

    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            do {
                try await createUserDocument(user: result.user, firstName: firstName, lastName: lastName)
            } catch {
                // if we fail to create a user document, delete the new user auth account
                try await Auth.auth().currentUser?.delete()
                throw error
            }
        } catch {
            debugPrint("Failed to signup \(error)")
            throw error
        }
    }

    func signIn(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            debugPrint("Failed to sign in \(error)")
            throw error
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}

extension AuthManager {
    func isLoading() -> Bool {
        switch state {
            case .uninitialized: true
            default: false
        }
    }
}
