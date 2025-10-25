//
//  MyCatchesView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/23/25.
//

import SwiftUI

struct MyCatchesView: View {
    @StateObject private var viewModel: MyCatchesViewModel
    
    init(viewModel: MyCatchesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            List {
                ForEach(viewModel.state.myCatches.catches) { item in
                    MyCatchView(item: item)
                }
            }
            .listStyle(.plain) // Use plain style for minimal padding and full width
            .frame(maxWidth: .infinity) // Ensure List takes full width
            .refreshable {
                viewModel.refreshMyCatches()
            }
            
            // Error message if present
            if let errorMessage = viewModel.state.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .loading(isLoading: viewModel.state.loading)
    }
}

struct MyCatchView: View {
    
    var item: MyCatchData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(item.species?.englishName ?? "")
                    .listRowBackground(Color(ColorToken.backgroundPrimary.color))
                    .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)) // Add 8pt spacing above and below each row
                
                Spacer()
                
                // Time ago
                if let createdAt = item.createdAt {
                    Text(timeAgo(from: createdAt))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            // Image card
            ImageCardView(images: item.images ?? [])
                .padding(.horizontal)
        }
    }
    
    // Convert Date to "time ago" string
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated // e.g., "2h ago"
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
