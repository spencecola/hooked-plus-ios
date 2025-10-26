//
//  FindFriendsViewModel.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/24/25.
//

import Combine

struct FriendsState {
    var loading: Bool = false
    var errorMessage: String?
    var friends: [UserData] = []
}

class FindFriendsViewModel: ObservableObject {
    @Published var state: FriendsState = FriendsState()
    private var currentPage: Int = 1
    private let limit: Int = 50
    private var isFetching: Bool = false
    private var totalResults: Int = 0
    
    func fetchNextPage(query: String) {
        // Prevent concurrent fetches or fetching beyond the last page
        guard !isFetching && (totalResults == 0 || currentPage <= (totalResults + limit - 1) / limit) else {
            isFetching = false
            return
        }
        isFetching = true
        
        Task { @MainActor in
            // Update state to indicate loading
            state.loading = true
            state.errorMessage = nil
            
            do {
                // Fetch species data for the current page
                let response = try await FriendsService.getSuggestedFriends(query: query, page: currentPage, limit: limit)
                
                // Update total results
                totalResults = response.total
                
                // Append new species to existing ones
                state.friends.append(contentsOf: response.users)
                
                // Increment page for next fetch
                currentPage += 1
            } catch {
                // Handle errors and update state
                state.errorMessage = error.localizedDescription
            }
            
            // Reset loading state
            state.loading = false
            isFetching = false
        }
    }
    
    func resetAndFetch(query: String) {
        // Reset state for a new search
        currentPage = 1
        totalResults = 0
        state.friends = []
        state.errorMessage = nil
        fetchNextPage(query: query)
    }
}
