//
//  FeedView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/13/25.
//

import SwiftUI

struct FeedView: View {
    @State var createPost = false
    @StateObject private var viewModel: FeedViewModel
    
    init(viewModel: FeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.state.feed.data) { item in
                        CardView(
                            imageUrls: item.images,
                            description: item.content?.description,
                            posterName: ""
                        )
                    }
                }
                .padding(.vertical)
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        createPost = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $createPost) {
            CreatePostView(viewModel: viewModel)
        }
        .loading(isLoading: viewModel.state.loading)
        .onAppear {
            viewModel.refreshFeed()
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(viewModel: FeedViewModel(locationManager: LocationManager()))
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color(.systemGroupedBackground))
    }
}
