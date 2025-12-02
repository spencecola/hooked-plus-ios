//
// FeedViewModel.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/17/25.
//

import Combine
import _PhotosUI_SwiftUI

struct FeedState {
    var loading: Bool = false
    var postCreated: Bool = false {
        didSet {
            if postCreated {
                errorMessage = nil
            }
        }
    }
    
    var errorMessage: String?
    
    var feed: FeedResponse = FeedResponse(page: 1, limit: 20, total: 20, data: []) {
        didSet {
            errorMessage = nil
        }
    }
    
    var stories: [FriendStoriesData] = []
    var currentLocation: CLLocation?
    var locationAuthorization: CLAuthorizationStatus?
    var currentWeather: WeatherData?
}

@MainActor
class FeedViewModel: ObservableObject {
    
    private var locationManager: LocationManager
    private var locationCancellables = Set<AnyCancellable>()
    @Published var state: FeedState = FeedState()
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        refreshFeed()
        subscribeToLocationChanges()
    }
    
    func subscribeToLocationChanges() {
        // request location permission
        locationManager.requestLocationPermission()
        // listen for location updates
        locationCancellables.insert(locationManager.$currentLocation.sink { [weak self] location in
            self?.state.currentLocation = location
            self?.getWeather(lat: location?.coordinate.latitude, lng: location?.coordinate.longitude)
        })
        // listen for location status updates
        locationCancellables.insert(locationManager.$authorizationStatus.sink { [weak self] authStatus in
            self?.state.locationAuthorization = authStatus
        })
    }
    
    func onRequestLocationPermission() {
        DispatchQueue.main.async { [weak self] in
            self?.locationManager.requestLocationPermission()
        }
    }
    
    func refreshFeed() {
        Task {
            defer {
                state.loading = false
            }
            
            state.loading = true
            do {
                // fetch feed
                let feedResponse = try await FeedService.getFeed()
                state.feed = feedResponse
                
                // fetch stories
                let storiesResponse = try? await StoryService.fetchFriendStories()
                state.stories = storiesResponse ?? []
            } catch {
                debugPrint(error.localizedDescription)
                state.errorMessage = "Failed to retrieve feed at this time."
            }
        }
    }
    
    func getWeather(lat: Double?, lng: Double?) {
        Task { [weak self] in
            guard let lat, let lng, let weatherData = try? await WeatherService.getWeather(lat: lat, lng: lng) else {
                return
            }
            self?.state.currentWeather = weatherData
        }
    }
    
    func createPost(isCatch: Bool, description: String, tags: [String] = [], photos: [PhotosPickerItem], species: SpeciesData? = nil, depth: String? = nil, weight: String? = nil, isLunker: Bool = false) async  -> Bool {
        
        // validate data used in create post
        if isCatch, weight?.isNotEmpty != true {
            state.errorMessage = "Woops! Please enter a catch weight and try again."
            return false
        }
        
        if isCatch, species == nil {
            state.errorMessage = "Woops! Please select a species for your catch and try again."
            return false
        }
        
        if isCatch, isLunker, photos.count < 3 {
            state.errorMessage = "Woops! Please make sure to add the required images needed for our team to review your catch."
            return false
        }
        
        defer {
            state.loading = false
        }
        
        state.loading = true
        do {
            try await FeedService.uploadPost(
                isCatch: isCatch,
                description: description,
                weight: weight,
                depth: depth,
                isLunker: isLunker,
                species: species,
                tags: tags,
                selectedItems: photos,
                locationManager: locationManager
            )
            
            state.postCreated = true
        } catch {
            debugPrint("failed to create post \(error)")
            state.errorMessage = "Failed to create post at this time. Please try again."
            return false
        }
        return true
    }
    
    func likePost(postId: String) {
        Task {
            do {
                state.loading = true
                try await FeedService.likePost(postId: postId)
                state.loading = false
                refreshFeed()
            } catch {
                state.loading = false
                state.errorMessage = "Failed to like this post"
            }
        }
    }
    
    deinit {
        locationCancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
}
