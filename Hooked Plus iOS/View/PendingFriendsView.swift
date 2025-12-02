//
//  PendingFriendsView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/27/25.
//

import SwiftUI
import Combine

struct PendingFriendsView: View {
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PendingFriendsViewModel()
    @State private var searchCancellable: AnyCancellable?
    @State var friendApproved: Bool = false
    

    var body: some View {
        NavigationStack {
            VStack {
                searchBar
                contentView
            }
            .navigationTitle("Pending Friends")
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
            .background(ColorToken.backgroundSecondary.color)
            .snackBar(isPresented: $friendApproved, type: .success, message: "Friend request accepted.")
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
            
            if viewModel.state.friends.isEmpty {
                Text("You have no friends pending at this time")
                    .hookedText()
                    .listRowBackground(ColorToken.backgroundSecondary.color)
            }
            
            ForEach(viewModel.state.friends) { friend in
                FriendRow(friend: friend) { friendId in
                    viewModel.approveFriend(friendId: friendId)
                    friendApproved = true
                }
                .listRowBackground(ColorToken.backgroundSecondary.color)
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
private struct SearchBar: View {
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
private struct FriendRow: View {
    let friend: FriendUserData
    let onFriendAccepted: (String) -> Void
    var body: some View {
        HStack {
            // Profile picture placeholder
            ProfileIconView(profileIconUrl: friend.user.profileIcon, size: 40)
            
            VStack(alignment: .leading) {
                Text("\(friend.user.firstName) \(friend.user.lastName)")
                    .font(.headline)
                Text(friend.user.handleName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Add friend button
            Button("Accept") {
                onFriendAccepted(friend.id)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.vertical, 4)
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}
