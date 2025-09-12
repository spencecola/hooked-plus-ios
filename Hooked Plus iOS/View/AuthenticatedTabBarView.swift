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
            // TODO: use swinject
            ProfileView(viewModel: HookedAssembly.resolver.resolve(ProfileViewModel.self)!)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }.background(ColorToken.backgroundPrimary.color)
    }
}

struct HomeView: View {
    // Enum for picker segments
    private enum HomeTab: String, CaseIterable, Identifiable {
        case feed = "Feed"
        case lakeReport = "Lake Report"
        case live = "Live"
        
        var id: String { rawValue }
    }
    
    @State private var selectedTab: HomeTab = .feed
    
    var body: some View {
        VStack {
            Picker("Select View", selection: $selectedTab) {
                ForEach(HomeTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            switch selectedTab {
            case .feed:
                FeedView()
            case .lakeReport:
                LakeReportView()
            case .live:
                LiveView()
            }
            
            Spacer()
        }
        .padding()
        .background(ColorToken.backgroundPrimary.color)
    }
}

// Placeholder views for each segment
struct FeedView: View {
    var body: some View {
        VStack {
            Text("Feed Content")
                .font(.title2)
            Text("This is where the social feed will appear.")
                .foregroundColor(.secondary)
        }
    }
}

struct LakeReportView: View {
    var body: some View {
        VStack {
            Text("Lake Report")
                .font(.title2)
            Text("This is where lake reports will be displayed.")
                .foregroundColor(.secondary)
        }
    }
}

struct LiveView: View {
    var body: some View {
        VStack {
            Text("Live Updates")
                .font(.title2)
            Text("This is where live updates will be shown.")
                .foregroundColor(.secondary)
        }
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
