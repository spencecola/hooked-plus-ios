//
//  AuthenticatedTabBarView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/6/25.
//

import SwiftUI
import FirebaseCore

struct AuthenticatedTabBarView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

struct HomeView: View {
    var body: some View {
        VStack {
            Text("Welcome to the Home Screen!")
                .font(.title)
            Spacer()
        }
        .padding()
    }
}

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var userData: [String: Any]?
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            if case .authenticated(let user) = authManager.state {
                Text("Profile")
                    .font(.title)
                Text("Email: \(user.email ?? "No email")")
                if let data = userData {
                    Text("Name: \(data["name"] as? String ?? "No name")")
                    Text("Joined: \(data["createdAt"] as? Timestamp ?? Timestamp()).dateValue(), format: .dateTime)")
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                Button("Fetch User Data") {
                    authManager.fetchUserData { result in
                        switch result {
                        case .success(let data):
                            userData = data
                            errorMessage = ""
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .padding()
                Button("Sign Out") {
                    authManager.signOut()
                }
                .padding()
            } else {
                Text("Loading profile...")
            }
        }
        .padding()
    }
}

struct AuthenticatedTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedTabBarView()
            .environmentObject(AuthManager())
    }
}
