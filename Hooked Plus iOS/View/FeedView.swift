//
//  FeedView.swift
//  Hooked Plus iOS
//
//  Fully refactored, type-check safe, and modular
//

import SwiftUI

struct FeedView: View {
    @State private var createPost = false
    @StateObject private var viewModel: FeedViewModel
    
    init(viewModel: FeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            feedContent
            floatingActionButton
        }
        .background(ColorToken.backgroundPrimary.color)
        .sheet(isPresented: $createPost) {
            CreatePostView(viewModel: viewModel)
        }
        .loading(isLoading: viewModel.state.loading)
        .onAppear { viewModel.refreshFeed() }
        .snackBar(
            isPresented: Binding(
                get: { viewModel.state.errorMessage != nil },
                set: { _ in }
            ),
            type: .error,
            message: viewModel.state.errorMessage ?? "Something went wrong. Please try again later."
        )
    }
}

// MARK: - Feed Content
private extension FeedView {
    var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                StoriesView(stories: exampleStories)
                                    .padding(.top, 8)
                
                if viewModel.state.feed.data.isEmpty && !viewModel.state.loading {
                    EmptyFeedView()
                } else {
                    ForEach(viewModel.state.feed.data, id: \.id) { item in
                        FeedPostRow(item: item, viewModel: viewModel)
                    }
                }
            }
            .contentMargins(.vertical, 8, for: .scrollContent)
        }
        .frame(maxWidth: .infinity)
        .refreshable { viewModel.refreshFeed() }
    }
}

// MARK: - Empty State
private struct EmptyFeedView: View {
    var body: some View {
        Text("There is currently no content to show. Try finding and adding friends to generate a feed.")
            .hookedText(font: .title2)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding()
    }
}

// MARK: - Floating Action Button
private extension FeedView {
    var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    createPost = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(ColorToken.buttonSecondary.color)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Post Row (Safe & Type-Check Friendly)
private struct FeedPostRow: View {
    let item: FeedItemData // Replace with your actual model name
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        PostView(
            postId: item.id,
            firstName: item.firstName ?? "",
            lastName: item.lastName ?? "",
            profileIcon: item.profileIcon,
            description: item.content?.description,
            timestamp: item.timestamp ?? Date(),
            images: item.images ?? [],
            likeCount: .constant(item.likeCount ?? 0),
            commentCount: .constant(item.commentCount ?? 0),
            onLike: {
                viewModel.likePost(postId: item.id)
            }
        )
    }
}

// MARK: - Preview
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView(viewModel: FeedViewModel(locationManager: LocationManager()))
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color(.systemGroupedBackground))
    }
}

private let exampleStories: [StoryData] = [
    StoryData(
        userId: "user_001",
        userProfileIconUrl: "https://i.pravatar.cc/150?img=1",
        userFirstName: "Alex",
        userLastName: "Johnson",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
        createdAt: Date(),
        expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
    ),
    StoryData(
        userId: "user_002",
        userProfileIconUrl: "https://i.pravatar.cc/150?img=2",
        userFirstName: "Sarah",
        userLastName: "Williams",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
        createdAt: Date(),
        expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
    ),
    StoryData(
        userId: "user_003",
        userProfileIconUrl: "https://i.pravatar.cc/150?img=3",
        userFirstName: "Mike",
        userLastName: "Anderson",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        createdAt: Date(),
        expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
    ),
    StoryData(
        userId: "user_004",
        userProfileIconUrl: "https://i.pravatar.cc/150?img=4",
        userFirstName: "Emma",
        userLastName: "Brown",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
        createdAt: Date(),
        expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
    ),
    StoryData(
        userId: "user_005",
        userProfileIconUrl: "https://i.pravatar.cc/150?img=5",
        userFirstName: "John",
        userLastName: "Taylor",
        videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
        createdAt: Date(),
        expiresAt: Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
    )
]

