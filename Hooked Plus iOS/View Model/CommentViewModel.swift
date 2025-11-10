//
//  CommentViewModel.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/3/25.
//  Updated for CommentService integration
//

import FirebaseAuth
import Combine
import Foundation

@MainActor
final class CommentViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var state = CommentState(
        isLoading: false,
        comments: [],
        errorMessage: nil
    )
    
    @Published var isSubmitting = false
    @Published var submitError: String?
    
    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var currentPage = 1
    private let pageLimit = 20
    private var hasMorePages = true
    
    let postId: String
    
    // MARK: - Init
    init(postId: String) {
        self.postId = postId
    }
    
    // MARK: - Public API
    
    /// Load initial comments
    func loadComments() async {
        guard !state.isLoading else { return }
        
        state = CommentState(
            isLoading: true,
            comments: state.comments, // preserve existing
            errorMessage: nil
        )
        
        do {
            let response = try await CommentService.getComments(
                for: postId,
                page: 1,
                limit: pageLimit
            )
            
            currentPage = 1
            hasMorePages = response.comments.count == pageLimit
            
            state = CommentState(
                isLoading: false,
                comments: response.comments,
                errorMessage: nil
            )
        } catch {
            state = CommentState(
                isLoading: false,
                comments: state.comments,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    /// Load next page (pagination)
    func loadMoreIfNeeded(lastCommentId: String) async {
        guard hasMorePages,
              !state.isLoading,
              let lastComment = state.comments.last,
              lastComment.id == lastCommentId else { return }
        
        state.isLoading = true
        
        do {
            let nextPage = currentPage + 1
            let response = try await CommentService.getComments(
                for: postId,
                page: nextPage,
                limit: pageLimit
            )
            
            currentPage = nextPage
            hasMorePages = response.comments.count == pageLimit
            
            state.comments.append(contentsOf: response.comments)
            state.isLoading = false
            
        } catch {
            state.errorMessage = "Failed to load more comments"
            state.isLoading = false
        }
    }
    
    /// Create a new comment
    func createComment(content: String) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            submitError = "Comment cannot be empty"
            return
        }
        
        isSubmitting = true
        submitError = nil
        
        do {
            try await CommentService.createComment(postId: postId, content: content)
            
            // Success: refresh to get real comment with server timestamp & ID
            await loadComments()
            isSubmitting = false
            
        } catch {
            // Revert optimistic update
            submitError = error.localizedDescription
            isSubmitting = false
        }
    }
    
    /// Edit existing comment
    func editComment(_ comment: Comment, newContent: String) async {
        guard !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            submitError = "Comment cannot be empty"
            return
        }
        
        guard let index = state.comments.firstIndex(where: { $0.id == comment.id }) else { return }
        
        isSubmitting = true
        submitError = nil
        
        // Optimistic update
        let oldComment = state.comments[index]
        state.comments[index].content = newContent
        state.comments[index].updatedAt = Date()
        
        do {
            try await CommentService.editComment(commentId: comment.id, newContent: newContent)
            isSubmitting = false
            // Optionally refresh from server if you want latest timestamp
        } catch {
            // Revert
            state.comments[index] = oldComment
            submitError = "Failed to edit comment"
            isSubmitting = false
        }
    }
    
    /// Delete comment
    func deleteComment(_ comment: Comment) async {
        guard let index = state.comments.firstIndex(where: { $0.id == comment.id }) else { return }
        
        // Optimistic remove
        state.comments.remove(at: index)
        
        do {
            try await CommentService.deleteComment(commentId: comment.id)
            // Success
        } catch {
            // Revert
            state.comments.insert(comment, at: index)
            state.errorMessage = "Failed to delete comment"
        }
    }
    
    /// Retry loading
    func retry() {
        Task {
            await loadComments()
        }
    }
    
    /// Clear errors
    func clearErrors() {
        state.errorMessage = nil
        submitError = nil
    }
}

struct CommentState {
    var isLoading: Bool
    var comments: [Comment]
    var errorMessage: String?
}
