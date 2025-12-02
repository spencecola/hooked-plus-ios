//
//  AuthenticationManager.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import GoogleSignIn

enum AuthState {
    case uninitialized
    case authenticated(user: User)
    case unauthenticated
}

protocol AuthManagable {
    var state: AuthState { get }
    var statePublisher: AnyPublisher<AuthState, Never> { get }
    func signInWithGoogle() async throws
    func signUpWithGoogle(handleName: String, firstName: String, lastName: String) async throws
    func signUp(handleName: String, email: String, password: String, firstName: String, lastName: String) async throws
    func signIn(email: String, password: String) async throws
    func signOut()
}

class AuthManager: AuthManagable, ObservableObject {
    @Published var state: AuthState = .uninitialized
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    var statePublisher: AnyPublisher<AuthState, Never> {
         $state.eraseToAnyPublisher()
     }

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.state = if let user {
                .authenticated(user: user)
            } else {
                .unauthenticated
            }
            
            // subscribe on authenticated
            if case .authenticated(_) = self?.state {
                // attempt to subscribe to current user topic
                subscribeToUserIDTopic()
            }
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
                let _ = try await Auth.auth().signIn(with: credential)
            } catch {
                debugPrint("Failed to sign in with google \(error)")
                throw error
            }

            // Optionally, call your backend to create/update user data
            // Example: await UserService.createUser(email: user.profile?.email ?? "", firstName: user.profile?.givenName ?? "", lastName: user.profile?.familyName ?? "", interests: [])
        }

    func signUpWithGoogle(handleName: String, firstName: String, lastName: String) async throws {
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
                    try await createUserDocument(user: result.user, handleName: handleName, firstName: firstName, lastName: lastName)
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

    func signUp(handleName: String, email: String, password: String, firstName: String, lastName: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            do {
                try await createUserDocument(user: result.user, handleName: handleName, firstName: firstName, lastName: lastName)
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
            if let currentId = Auth.auth().currentUser?.uid {
                unsubscribeFromUserIDTopic(previousUserID: currentId)
            }
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

func subscribeToUserIDTopic() {
    // Ensure the Firebase Auth user is available
    guard let userID = Auth.auth().currentUser?.uid else {
        print("Error: User is not signed in or UID is nil.")
        return
    }

    // 1. Construct the unique topic name
    let topicName = "user_\(userID)"
    
    // 2. Subscribe the device to the topic
    Messaging.messaging().subscribe(toTopic: topicName) { error in
        if let error = error {
            print("Error subscribing to topic \(topicName): \(error.localizedDescription)")
        } else {
            print("Successfully subscribed to topic: \(topicName)")
        }
    }
}

func unsubscribeFromUserIDTopic(previousUserID: String) {
    // 1. Construct the previous user's topic name
    let previousTopicName = "user_\(previousUserID)"

    // 2. Unsubscribe the device from that topic
    Messaging.messaging().unsubscribe(fromTopic: previousTopicName) { error in
        if let error = error {
            print("Error unsubscribing from topic \(previousTopicName): \(error.localizedDescription)")
        } else {
            print("Successfully unsubscribed from topic: \(previousTopicName)")
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
