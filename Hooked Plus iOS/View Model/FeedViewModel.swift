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
    var postCreated: Bool = false
    var errorMessage: String?
    var feed: FeedResponse = FeedResponse(page: 1, limit: 20, total: 20, data: [])
    var currentLocation: CLLocation?
    var currentWeather: WeatherData?
}

@MainActor
class FeedViewModel: ObservableObject {
    
    private var locationManager: LocationManager
    private var locationCancellable: Cancellable?
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
        locationCancellable = locationManager.$currentLocation.sink { [weak self] location in
            self?.state.currentLocation = location
            self?.getWeather(lat: location?.coordinate.latitude, lng: location?.coordinate.longitude)
        }
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
    
    func getWeather(lat: Double?, lng: Double?) {
        Task { [weak self] in
            guard let lat, let lng, let weatherData = try? await WeatherService.getWeather(lat: lat, lng: lng) else {
                return
            }
            self?.state.currentWeather = weatherData
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
    
    deinit {
        locationCancellable?.cancel()
    }
}
