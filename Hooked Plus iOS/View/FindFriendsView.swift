import SwiftUI
import Combine

struct FindFriendsView: View {
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FindFriendsViewModel()
    @State private var searchCancellable: AnyCancellable?
    @State var friendRequested: Bool = false
    

    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                contentView
            }
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if viewModel.state.friends.isEmpty {
                    viewModel.resetAndFetch(query: "")
                }
            }
            .snackBar(isPresented: $friendRequested, type: .success, message: "A friend request has been sent")
            .snackBar(isPresented: Binding(get: {
                viewModel.state.errorMessage != nil
            }, set: { _ in
                // no op
            }), type: .error, message: viewModel.state.errorMessage ?? "Something went wrong. Please try again later")
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        SearchBar(text: $searchText)
            .padding(.horizontal)
            .onChange(of: searchText) { newValue in
                debounceSearch(newValue)
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.state.loading && viewModel.state.friends.isEmpty {
            ProgressView("Loading Friends…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            friendsList
        }
    }

    private var friendsList: some View {
        List {
            ForEach(viewModel.state.friends) { friend in
                FriendRow(friend: friend, friendRequested: $friendRequested)
                    .onAppear {
                        if friend == viewModel.state.friends.last {
                            viewModel.fetchNextPage(query: searchText)
                        }
                    }
            }

            if viewModel.state.loading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Debounced Search

    private func debounceSearch(_ query: String) {
        searchCancellable?.cancel()
        searchCancellable = Just(query)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { text in
                viewModel.resetAndFetch(query: text)
            }
    }
}

// Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Search by name or username", text: $text)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 8)
    }
}

// Friend Row Component
struct FriendRow: View {
    let friend: UserData
    @Binding var friendRequested: Bool
    
    var body: some View {
        HStack {
            // Profile picture placeholder
            ProfileIconView(profileIconUrl: friend.profileIcon, size: 40)
            
            VStack(alignment: .leading) {
                Text("\(friend.firstName) \(friend.lastName)")
                    .font(.headline)
                Text(friend.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Add friend button
            Button("Add") {
                friendRequested = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.vertical, 4)
        }
    }
}
