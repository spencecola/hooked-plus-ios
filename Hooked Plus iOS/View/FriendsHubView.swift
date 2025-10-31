//
//  FriendHubView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/27/25.
//

import SwiftUI

struct FriendHubView: View {
    // Enum for picker segments
    private enum FriendsTab: String, CaseIterable, Identifiable {
        case pending = "Pending"
        case friends = "Friends"
        
        var id: String { rawValue }
    }
    
    @State private var selectedTab: FriendsTab = .pending
    
    var body: some View {
        VStack {
            Picker("Select View", selection: $selectedTab) {
                ForEach(FriendsTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            switch selectedTab {
            case .pending:
                PendingFriendsView()
            case .friends:
                FriendsView()
            }
            
            Spacer()
        }
        .padding()
        .background(ColorToken.backgroundPrimary.color)
    }
}
