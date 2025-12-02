//
//  PostView.swift
//  Hooked Plus iOS
//

import SwiftUI

struct PostView: View {
    let postId: String
    let handleName: String
    let firstName: String
    let lastName: String
    let profileIcon: String?
    let description: String?
    let timestamp: Date
    let images: [String]
    @Binding var likeCount: Int        // ← Make Binding so updates reflect
    @Binding var commentCount: Int     // ← Make Binding
    let onLike: () -> Void
    
    // MARK: - Modal State
    @State private var showingComments = false
    
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
                
                // if handle name exists on post, display under name
                if handleName.isNotEmpty {
                    VStack(alignment: .leading) {
                        Text("\(firstName) \(lastName)")
                            .hookedText(font: .headline)
                        
                        // Handle name
                        Text("@\(handleName)").hookedText(font: .caption2, color: .gray)
                    }
                } else {
                    Text("\(firstName) \(lastName)")
                        .hookedText(font: .headline)
                }
                
                Spacer()
                
                // Time ago
                Text(timeAgo(from: timestamp))
                    .font(.subheadline)
                    .foregroundColor(ColorToken.textSecondary.color)
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
                // Like Button
                Button {
                    Haptic.light()
                    onLike()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                        Text("\(likeCount) \(likeCount == 1 ? "Like" : "Likes")")
                    }
                    .font(.subheadline)
                    .foregroundColor(ColorToken.textSecondary.color)
                }
                
                Spacer()
                
                // Comment Button → Opens Modal
                Button {
                    showingComments = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .foregroundColor(ColorToken.textSecondary.color)
                        Text("\(commentCount) \(commentCount == 1 ? "Comment" : "Comments")")
                    }
                    .font(.subheadline)
                    .foregroundColor(ColorToken.textSecondary.color)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 4)
        
        // MARK: - Full-Screen Comment Modal
        .sheet(isPresented: $showingComments) {
            HalfSheetView {
                CommentsModal(postId: postId, commentCount: $commentCount)
            }
        }
    }
    
    // Convert Date to "time ago" string
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Modal Wrapper with Live Comment Count Update
private struct CommentsModal: View {
    let postId: String
    @Binding var commentCount: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            PostCommentsView(postId: postId)
//                .navigationTitle("Comments")
//                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .commentCountDidChange)) { notification in
                    if let count = notification.object as? Int {
                        commentCount = count
                    }
                }
        }
    }
}

// MARK: - Helper: Broadcast Comment Count Updates
extension Notification.Name {
    static let commentCountDidChange = Notification.Name("commentCountDidChange")
}

// MARK: - Update CommentViewModel to Broadcast Count
// ADD THIS TO YOUR CommentViewModel.swift (just once!)
extension CommentViewModel {
    private func broadcastCommentCount() {
        NotificationCenter.default.post(
            name: .commentCountDidChange,
            object: state.comments.count
        )
    }
}
