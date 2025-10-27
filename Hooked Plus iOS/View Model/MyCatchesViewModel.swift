//
//  Untitled.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/23/25.
//

import Combine
import _PhotosUI_SwiftUI

struct MyCatchesState {
    var loading: Bool = false
    var errorMessage: String?
    var myCatches: MyCatchesResponse = MyCatchesResponse(page: 1, limit: 20, catches: []) {
        didSet {
            errorMessage = nil
        }
    }
}

@MainActor
class MyCatchesViewModel: ObservableObject {
    
    @Published var state: MyCatchesState = MyCatchesState()
    
    init() {
        refreshMyCatches()
    }
    
    func refreshMyCatches() {
        Task {
            defer {
                state.loading = false
            }
            
            state.loading = true
            do {
                let myCatchesResponse = try await MyCatchesService.getMyCatches()
                state.myCatches = myCatchesResponse
            } catch {
                debugPrint(error.localizedDescription)
                state.errorMessage = "Failed to retrieve your catches at this time."
            }
        }
    }
}
