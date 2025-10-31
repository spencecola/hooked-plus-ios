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
                LazyVStack(spacing: 16) {
                    if viewModel.state.feed.data.isEmpty && !viewModel.state.loading {
                        Text("There is currently no content to show. Try finding and adding friends to generate a feed.")
                            .hookedText(font: .title2)
                    }
                    
                    ForEach(viewModel.state.feed.data, id: \.id) { item in
                        PostView(firstName: item.firstName ?? "", lastName: item.lastName ?? "", profileIcon: item.profileIcon, description: item.content?.description, timestamp: item.timestamp ?? Date(), images: item.images ?? [], likeCount: item.likeCount ?? 0) {
                            // like post
                            viewModel.likePost(postId: item.id)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity) // Ensure List takes full width
            .refreshable {
                viewModel.refreshFeed()
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
                            .background(ColorToken.buttonSecondary.color)
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
        .snackBar(isPresented: Binding(get: {
            viewModel.state.errorMessage != nil
        }, set: { _ in
            // no op
        }), type: .error, message: viewModel.state.errorMessage ?? "Something went wrong. Please try again later.")
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
