//
//  CommentSection.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/5/25.
//

import SwiftUI

struct CommentSection: View {
    let postId: String
    @State private var showingAllComments = false
    
    var body: some View {
        Section {
            if showingAllComments {
                PostCommentsView(postId: postId)
                    .frame(maxHeight: .infinity)
            } else {
                Button {
                    showingAllComments = true
                } label: {
                    Label("View all comments", systemImage: "message")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
