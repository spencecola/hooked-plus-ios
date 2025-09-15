//
//  FeedView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/13/25.
//

import SwiftUI

// Placeholder views for each segment
struct FeedView: View {
    @State var createPost = false
    var body: some View {
        ZStack {
            VStack {
                Text("Feed Content")
                    .font(.title2)
                Text("This is where the social feed will appear.")
                    .foregroundColor(.secondary)
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
        }.sheet(isPresented: $createPost) {
            CreatePostView()
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
