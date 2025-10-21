import Combine

struct SpeciesState {
    var loading: Bool = false
    var errorMessage: String?
    var species: [SpeciesData] = []
}

class SpeciesViewModel: ObservableObject {
    @Published var state: SpeciesState = SpeciesState()
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
                let response = try await SpeciesService.getAllSpecies(query: query, page: currentPage, limit: limit)
                
                // Update total results
                totalResults = response.total
                
                // Append new species to existing ones
                state.species.append(contentsOf: response.results)
                
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
        state.species = []
        state.errorMessage = nil
        fetchNextPage(query: query)
    }
}
