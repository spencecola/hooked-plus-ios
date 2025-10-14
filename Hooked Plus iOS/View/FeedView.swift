import SwiftUI

struct FeedView: View {
    @State var createPost = false
    @StateObject private var viewModel: FeedViewModel
    
    init(viewModel: FeedViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.state.feed.data) { item in
                    PostView(firstName: item.firstName ?? "", lastName: item.lastName ?? "", profileIcon: item.profileIcon, description: item.content?.description, timestamp: item.timestamp ?? Date(), images: item.images ?? [])
                        .listRowBackground(Color(ColorToken.backgroundPrimary.color))
                        .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)) // Add 8pt spacing above and below each row
                }
            }
            .listStyle(.plain) // Use plain style for minimal padding and full width
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
