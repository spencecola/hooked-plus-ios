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
                if viewModel.state.myCatches.catches.isEmpty {
                    Text("You currently have recorded no catches")
                        .hookedText()
                        .listRowBackground(ColorToken.backgroundSecondary.color)
                }
                
                ForEach(viewModel.state.myCatches.catches) { item in
                    MyCatchView(item: item)
                        .listRowBackground(ColorToken.backgroundSecondary.color)
                }
            }
            .listStyle(.plain) // Use plain style for minimal padding and full width
            .frame(maxWidth: .infinity) // Ensure List takes full width
            .refreshable {
                viewModel.refreshMyCatches()
            }
            .background(ColorToken.backgroundSecondary.color)
        }
        .loading(isLoading: viewModel.state.loading)
        .snackBar(isPresented: Binding(get: {
            viewModel.state.errorMessage != nil
        }, set: { _ in
            // no op
        }), type: .error, message: viewModel.state.errorMessage ?? "Something went wrong. Please try again later.")
    }
}

struct MyCatchView: View {
    
    @State private var selectedImage: String? = nil
    
    var item: MyCatchData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.species?.englishName ?? "")
                    .font(.title)
                    .listRowBackground(Color(ColorToken.backgroundSecondary.color))
                
                // Time ago
                if let createdAt = item.createdAt {
                    Text(timeAgo(from: createdAt))
                        .font(.title2)
                        .listRowBackground(Color(ColorToken.backgroundSecondary.color))
                }
                
                // Weather degrees when caught
                if let weather = item.weather {
                    HStack {
                        Image(systemName: "cloud.sun.rain.fill").padding(.trailing, 0)
                        Text("\(weather.formattedTemperature) \(weather.formattedWind)")
                    }
                }
            }
          
            Spacer()
            // grabs a random image of the images provided and displays
            if let image = item.images?.randomElement() {
                ImageView(url: image) {
                    selectedImage = image
                }
                .frame(width: 100, height: 120)
                .padding(8)
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedImage.map { IdentifiableImage(url: $0) } },
            set: { _ in selectedImage = nil }
        )) { identifiableImage in
            FullScreenImageView(imageUrl: identifiableImage.url)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy" // e.g., "April 25, 2025"
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
}
