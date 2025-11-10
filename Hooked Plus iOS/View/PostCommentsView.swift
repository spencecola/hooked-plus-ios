//
//  PostCommentsView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/5/25.
//  Fixed: Type-check performance
//

import FirebaseAuth
import SwiftUI

struct PostCommentsView: View {
    @StateObject private var vm: CommentViewModel
    @State private var newComment = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(postId: String) {
        _vm = StateObject(wrappedValue: CommentViewModel(postId: postId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Comment List
            ScrollView {
                LazyVStack(spacing: 12) {
                    if vm.state.comments.isEmpty && !vm.state.isLoading {
                        emptyState
                    } else {
                        ForEach(vm.state.comments) { comment in
                            CommentRowWrapper(
                                comment: comment,
                                viewModel: vm
                            )
                            .padding(.horizontal)
                            .onAppear {
                                Task { await vm.loadMoreIfNeeded(lastCommentId: comment.id) }
                            }
                        }
                    }
                    
                    if vm.state.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            
            // MARK: - New Comment Input
            commentInput
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.loadComments() }
        .refreshable { await vm.loadComments() }
        .overlay {
            if let error = vm.state.errorMessage ?? vm.submitError {
                ErrorBanner(message: error) {
                    vm.clearErrors()
                    Task { await vm.loadComments() }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("No comments yet")
                .foregroundColor(.secondary)
            Text("Be the first to comment!")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .padding()
    }
    
    private var commentInput: some View {
        HStack(alignment: .bottom) {
            TextField("Add a comment...", text: $newComment, axis: .vertical)
                .focused($isTextFieldFocused)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .lineLimit(1...6)
            
            Button {
                Task {
                    let content = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !content.isEmpty else { return }
                    await vm.createComment(content: content)
                    newComment = ""
                    isTextFieldFocused = false
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(vm.isSubmitting ? .gray : .blue)
            }
            .disabled(vm.isSubmitting || newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.trailing, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .top)
    }
}

// MARK: - Wrapper to Reduce ForEach Complexity
private struct CommentRowWrapper: View {
    let comment: Comment
    @ObservedObject var viewModel: CommentViewModel
    @State private var isEditing = false
    @State private var editText = ""
    
    private var isOwnComment: Bool {
        comment.userId == Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        CommentRow(
            comment: comment,
            isOwnComment: isOwnComment,
            isEditing: $isEditing,
            editText: $editText,
            onEdit: { newText in
                await viewModel.editComment(comment, newContent: newText)
            },
            onDelete: {
                await viewModel.deleteComment(comment)
            }
        )
    }
}

// MARK: - Comment Row (Now Simple & Type-Check Friendly)
private struct CommentRow: View {
    let comment: Comment
    let isOwnComment: Bool
    @Binding var isEditing: Bool
    @Binding var editText: String
    let onEdit: (String) async -> Void
    let onDelete: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(comment.userId.prefix(2)).uppercased())
                            .font(.caption).bold()
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.user.firstName)
                        .font(.subheadline).bold()
                    if let createdAt = comment.createdAt {
                        Text(relativeTime(createdAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isOwnComment {
                    Menu {
                        Button("Edit") {
                            isEditing = true
                            editText = comment.content
                        }
                        Button("Delete", role: .destructive) {
                            Task { await onDelete() }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 32, height: 32)
                }
            }
            
            if isEditing {
                HStack {
                    TextField("Edit comment", text: $editText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button("Save") {
                        Task {
                            await onEdit(editText)
                            isEditing = false
                        }
                    }
                    .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button("Cancel") { isEditing = false }
                }
            } else {
                Text(comment.content)
                    .font(.body)
                    .lineLimit(nil)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Error Banner
private struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Button("Retry") { onRetry() }
                .font(.caption).bold()
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.red.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .transition(.move(edge: .top))
    }
}
