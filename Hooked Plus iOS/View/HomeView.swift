//
//  HomeView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/13/25.
//

import SwiftUI

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
                FeedView(viewModel: FeedViewModel(locationManager: LocationManager()))
            case .lakeReport:
                LakeReportView()
            case .live:
                LiveView()
            }
            
            Spacer()
        }
        .padding()
        .background(ColorToken.backgroundSecondary.color)
        
    }
}
