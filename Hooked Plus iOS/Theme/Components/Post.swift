import SwiftUI

struct PostView: View {
    let firstName: String
    let lastName: String
    let profileIcon: String?
    let description: String?
    let timestamp: Date
    let images: [String]
    let likeCount: Int
    let commentCount: Int
    
    init(firstName: String, lastName: String, profileIcon: String? = nil, description: String? = nil, timestamp: Date, images: [String], likeCount: Int = 0, commentCount: Int = 0) {
        self.firstName = firstName
        self.lastName = lastName
        self.profileIcon = profileIcon
        self.description = description
        self.timestamp = timestamp
        self.images = images
        self.likeCount = likeCount
        self.commentCount = commentCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Profile icon, name, and time ago
            HStack(spacing: 8) {
                // Profile icon
                Group {
                    if let profileIcon = profileIcon, let url = URL(string: profileIcon) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.gray)
                    }
                }
                
                // Name
                Text("\(firstName) \(lastName)")
                    .font(.headline)
                
                Spacer()
                
                // Time ago
                Text(timeAgo(from: timestamp))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            // Image card
            ImageCardView(images: images)
                .padding(.horizontal)
            
            
            // Description (shown only if present)
            if let description = description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
            }
            
            // Likes and Comments
            HStack {
                Image(systemName: "heart")
                    .foregroundColor(.gray)
                Text("\(likeCount) Likes")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Image(systemName: "bubble.left")
                    .foregroundColor(.gray)
                Text("\(commentCount) Comments")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 4)
    }
    
    // Convert Date to "time ago" string
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated // e.g., "2h ago"
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
