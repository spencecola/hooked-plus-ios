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
            LazyView {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            LazyView {
                MyCatchesView(viewModel: MyCatchesViewModel())
            }
            .tabItem {
                Label("Catch Log", systemImage: "fish")
            }
            
            LazyView {
                ProfileView(viewModel: HookedAssembly.resolver.resolve(ProfileViewModel.self)!)
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }.background(ColorToken.backgroundPrimary.color)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

struct AuthenticatedTabBarView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedTabBarView()
            .environmentObject(AuthManager())
    }
}
