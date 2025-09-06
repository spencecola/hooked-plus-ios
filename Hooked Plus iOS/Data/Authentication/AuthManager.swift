//
//  AuthenticationManager.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import FirebaseAuth

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
