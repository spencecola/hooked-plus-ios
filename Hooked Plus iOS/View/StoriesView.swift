//
//  StoriesView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/8/25.
//

import SwiftUI
import AVKit

// MARK: - StoriesView
struct StoriesView: View {
    let stories: [StoryData]
    
    // MARK: - Selected story state (local to the component)
    @State private var selectedStory: StoryData?
    
    private let ringColor = Color.pink   // Instagram-like ring
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(stories) { story in
                    storyItem(story)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 100)
        .background(ColorToken.backgroundPrimary.color)   // same bg as FeedView
        
        // ---- Full-screen video player (modal) ----
        .fullScreenCover(item: $selectedStory) { story in
            StoryVideoPlayer(story: story, onDismiss: {
                selectedStory = nil
            })
        }
    }
    
    // MARK: - Single story bubble
    private func storyItem(_ story: StoryData) -> some View {
        VStack(spacing: 4) {
            // Circle thumbnail with coloured ring
            if let videoUrl = URL(string: story.videoUrl) {
                AsyncImage(url: videoUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.gray   // placeholder
                    }
                }
                
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(ringColor, lineWidth: 3)
                        .padding(-2)          // shrink the ring a little so it sits *outside* the image
                )
                .onTapGesture { selectedStory = story }
            }
            
            // User name (truncated to one line)
            Text(story.userFirstName)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}

// MARK: - Full-screen video player
private struct StoryVideoPlayer: View {
    let story: StoryData
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let videoUrl = URL(string: story.videoUrl) {
                VideoPlayer(player: AVPlayer(url: videoUrl))
                    .onAppear {
                        // This line is enough — AVPlayer auto-buffers
                        AVPlayer(url: videoUrl).play()
                    }
            }

            closeButton
        }
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.8))
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .padding()
            }
            Spacer()
        }
    }
}
