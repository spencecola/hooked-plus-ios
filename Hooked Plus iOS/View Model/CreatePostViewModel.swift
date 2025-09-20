//
//  CreatePostViewModel.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/17/25.
//

import Combine
import _PhotosUI_SwiftUI

struct FeedState {
    var loading: Bool = false
    var postCreated: Bool = false
    var errorMessage: String?
    var feed: FeedResponse = FeedResponse(page: 1, limit: 20, total: 20, data: [])
}

@MainActor
class FeedViewModel: ObservableObject {
    
    private var locationManager: LocationManager
    
    @Published var state: FeedState = FeedState()
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        refreshFeed()
    }
    
    func refreshFeed() {
        Task {
            defer {
                state.loading = false
            }
            
            state.loading = true
            do {
                let feedResponse = try await FeedService.getFeed()
                state.feed = feedResponse
            } catch {
                debugPrint(error.localizedDescription)
                state.errorMessage = "Failed to retrieve feed at this time."
            }
        }
    }
    
    func createPost(description: String, tags: [String] = [], photos: [PhotosPickerItem]) {
        Task {
            
            defer {
                state.loading = false
            }
            
            state.loading = true
            do {
                try await FeedService.uploadPost(
                    description: description,
                    tags: tags,
                    selectedItems: photos,
                    locationManager: locationManager
                )
                
                state.postCreated = true
            } catch {
                debugPrint("failed to create post \(error)")
                state.errorMessage = "Failed to create post at this time. Please try again."
            }
        }
    }
}
