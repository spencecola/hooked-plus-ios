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
            LazyView { NavigationStack {
                FeedView(viewModel: FeedViewModel(locationManager: LocationManager()))
                    .customNavBar(title: "Feed")
            } }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            LazyView { NavigationStack {
                MyCatchesView(viewModel: MyCatchesViewModel())
                    .customNavBar(title: "Fishing Log")
            } }
            .tabItem {
                Label("Fish Log", systemImage: "fish")
            }
            
            LazyView { NavigationStack {
                ProfileView(viewModel: HookedAssembly.resolver.resolve(ProfileViewModel.self)!)
                    .customNavBar(title: "Profile")
            } }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
        .background(ColorToken.backgroundSecondary.color)
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
