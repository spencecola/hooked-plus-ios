import SwiftUI

struct Friend: Identifiable {
    let id = UUID()
    let name: String
    let username: String
}

struct FindFriendsView: View {
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    // Sample data - replace with your actual data source
    private let friends = [
        Friend(name: "John Doe", username: "@johndoe"),
        Friend(name: "Jane Smith", username: "@janesmith"),
        Friend(name: "Alex Johnson", username: "@alexj"),
        Friend(name: "Sarah Williams", username: "@sarahw"),
        Friend(name: "Mike Brown", username: "@mikeb")
    ]
    
    // Computed property to filter friends based on search text
    private var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        } else {
            return friends.filter { friend in
                friend.name.lowercased().contains(searchText.lowercased()) ||
                friend.username.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Friends List
                List {
                    ForEach(filteredFriends) { friend in
                        FriendRow(friend: friend)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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
    let friend: Friend
    
    var body: some View {
        HStack {
            // Profile picture placeholder
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(friend.name)
                    .font(.headline)
                Text(friend.username)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Add friend button
            Button("Add") {
                
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.vertical, 4)
        }
    }
}

struct FindFriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FindFriendsView()
    }
}
