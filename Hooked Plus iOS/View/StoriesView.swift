//
//  StoriesView.swift
//  Hooked Plus iOS
//
//  Updated by Grok – 2025-11-10
//

import SwiftUI
import AVKit
import Combine

// MARK: - StoriesView
struct StoriesView: View {
    /// The new grouped data structure
    let friendStories: [FriendStoriesData]
    
    @Environment(\.addStoryAction) var addStoryAction: () -> Void
    
    // MARK: - Presentation state
    @State private var presentedViewer: StoriesViewerModel?
    
    private let ringColor = Color.pink // Instagram-like ring
    
    // Define the common size for the circles
    private let circleSize: CGFloat = 70.0
    private let verticalSpacing: CGFloat = 4.0
    private let horizontalPadding: CGFloat = 12.0
    private let rowHeight: CGFloat = 100.0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                
                // --- NEW: Add Story Button at the beginning of the list ---
                addStoryButton
                
                ForEach(friendStories) { friend in
                    friendBubble(friend)
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
        .frame(height: rowHeight)
        .background(ColorToken.backgroundSecondary.color)
        
        // ---- Full-screen story viewer (modal) ----
        .fullScreenCover(item: $presentedViewer) { model in
            StoriesViewer(model: model, onDismiss: { presentedViewer = nil })
        }
    }
    
    // MARK: - Add Story Button
    private var addStoryButton: some View {
        VStack(spacing: verticalSpacing) {
            // Circle with a plus icon
            Circle()
                .fill(Color.gray.opacity(0.2)) // Light gray background
                .frame(width: circleSize, height: circleSize)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(ringColor) // Use the ring color for the plus sign
                )
                // The button should look like a story, but without the ring
                .onTapGesture {
                    addStoryAction() // Propagate the tap action
                }
            
            // Label
            Text("Your Story")
                .hookedText(font: .fixedCaption)
                .lineLimit(1)
                .frame(width: circleSize)
        }
    }
    
    // MARK: - Single friend bubble
    private func friendBubble(_ friend: FriendStoriesData) -> some View {
        VStack(spacing: verticalSpacing) {
            // Use the *first* story as thumbnail (fallback to placeholder)
            let profileIcon = friend.profileIcon ?? "https://i.pravatar.cc/150?img=5"
            if let iconUrl = URL(string: profileIcon) {
                AsyncImage(url: iconUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.gray
                    }
                }
                .frame(width: circleSize, height: circleSize) // Use defined size
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(ringColor, lineWidth: 3)
                        .padding(-2)
                )
                .onTapGesture {
                    presentedViewer = StoriesViewerModel(
                        allFriends: friendStories,
                        startFriendId: friend.friendId
                    )
                }
            }
            
            // Friend name
            Text("\(friend.firstName) \(friend.lastName)")
                .hookedText(font: .fixedCaption)
                .lineLimit(1)
                .frame(width: circleSize) // Use defined size
        }
    }
}

// The rest of the file (StoriesViewerModel, StoriesViewer, StoryVideoPlayer, StoryProgressBar, Collection Extension) remains the same.

// MARK: - Viewer Model (ObservableObject)
final class StoriesViewerModel: ObservableObject, Identifiable {
    let id = UUID()
    let allFriends: [FriendStoriesData]
    
    @Published var currentFriendId: String
    @Published var storyIndex: Int = 0
    
    init(allFriends: [FriendStoriesData], startFriendId: String) {
        self.allFriends = allFriends
        self.currentFriendId = startFriendId
    }
    
    // MARK: Computed helpers
    var currentFriendIndex: Int {
        allFriends.firstIndex { $0.friendId == currentFriendId } ?? 0
    }
    
    var currentFriend: FriendStoriesData {
        allFriends[currentFriendIndex]
    }
}

// MARK: - StoriesViewer
private struct StoriesViewer: View {
    @ObservedObject var model: StoriesViewerModel
    let onDismiss: () -> Void
    
    private let progressDuration: Double = 30   // seconds per story
    @State private var currentProgress: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let currentStory = model.currentFriend.stories[safe: model.storyIndex],
               let _ = URL(string: currentStory.videoUrl) {
                StoryVideoPlayer(
                    story: currentStory,
                    progressDuration: progressDuration,
                    onComplete: advanceStory
                ).id(currentStory.id)
                
                // MARK: UI overlay
                VStack {
                    HStack {
                        Spacer()
                        closeButton
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Progress bars for all stories of the current friend
                    VStack(alignment: .leading, spacing: 8) {
                        profileInfoRow(data: model.currentFriend)
                        HStack(spacing: 4) {
                            ForEach(0..<model.currentFriend.stories.count, id: \.self) { idx in
                                StoryProgressBar(
                                    isActive: idx == model.storyIndex,
                                    progress: idx < model.storyIndex ? 1.0 : (idx == model.storyIndex ? currentProgress : 0.0),
                                    duration: progressDuration
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("\(model.storyIndex + 1) / \(model.currentFriend.stories.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 30)
                }
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 { previousStory() }
                    if value.translation.width < -100 { advanceStory() }
                }
        )
    }
    
    @ViewBuilder
    private func profileInfoRow(data: FriendStoriesData) -> some View {
        HStack {
            ProfileIconView(profileIconUrl: data.profileIcon, size: 36)
            Text("\(data.firstName) \(data.lastName)").foregroundColor(.white)
        }
    }
    
    // MARK: – Navigation
    private func advanceStory() {
        guard model.storyIndex < model.currentFriend.stories.count - 1 else {
            // Move to next friend
            let nextIdx = model.currentFriendIndex + 1
            guard nextIdx < model.allFriends.count else {
                onDismiss()
                return
            }
            model.currentFriendId = model.allFriends[nextIdx].friendId
            model.storyIndex = 0
            currentProgress = 0
            return
        }
        model.storyIndex += 1
        currentProgress = 0
    }
    
    private func previousStory() {
        guard model.storyIndex > 0 else {
            // Move to previous friend, last story
            let prevIdx = model.currentFriendIndex - 1
            guard prevIdx >= 0 else { return }
            let prevFriend = model.allFriends[prevIdx]
            model.currentFriendId = prevFriend.friendId
            model.storyIndex = prevFriend.stories.count - 1
            currentProgress = 0
            return
        }
        model.storyIndex -= 1
        currentProgress = 0
    }
    
    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundColor(.white.opacity(0.8))
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
    }
}

// MARK: - StoryVideoPlayer (with loading indicator)
private struct StoryVideoPlayer: View {
    let story: StoryData
    let progressDuration: Double
    let onComplete: () -> Void
    
    // MARK: State
    @State private var player: AVPlayer
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var isBuffering = true
    
    init(story: StoryData, progressDuration: Double, onComplete: @escaping () -> Void) {
        self.story = story
        self.progressDuration = progressDuration
        self.onComplete = onComplete
        if let url = URL(string: story.videoUrl) {
            _player = State(initialValue: AVPlayer(url: url))
        } else {
            _player = State(initialValue: AVPlayer())
        }
    }
    
    var body: some View {
        ZStack {
            // The actual video
            VideoPlayer(player: player)
                .onAppear {
                    // Observe the player-item status
                    observePlayerStatus()
                    player.play()
                    isPlaying = true
                    startTimer()
                }
                .onDisappear {
                    player.pause()
                    isPlaying = false
                }
        }
        .loading(isLoading: isBuffering)
        .onChange(of: progress) { newValue in
            if newValue >= 1.0 && isPlaying {
                onComplete()
            }
        }
    }
    
    // MARK: – Observe AVPlayerItem status
    private func observePlayerStatus() {
        guard let item = player.currentItem else { return }
        
        // KVO – watch the .status property
        item.publisher(for: \.status)
            .sink { status in
                withAnimation {
                    switch status {
                    case .readyToPlay:
                        isBuffering = false          // video is ready → hide spinner
                    case .failed:
                        isBuffering = false
                        print("AVPlayerItem failed: \(item.error?.localizedDescription ?? "unknown")")
                    default:
                        isBuffering = true
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: – Timer for progress bar
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard let duration = player.currentItem?.duration.seconds,
                  duration > 0,
                  isPlaying else {
                timer.invalidate()
                return
            }
            let elapsed = player.currentTime().seconds
            progress = elapsed / duration
        }
    }
    
    // MARK: – KVO storage
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Progress bar for a single story
private struct StoryProgressBar: View {
    let isActive: Bool
    let progress: Double
    let duration: Double
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background (inactive or empty)
                Capsule()
                    .fill(Color.white.opacity(isActive ? 0.7 : 0.3))
                
                // Filled progress
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * CGFloat(progress))
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .frame(height: 4)
    }
}
// MARK: - Safe array access
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
