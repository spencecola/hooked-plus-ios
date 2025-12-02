//
//  HalfSheetView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/28/25.
//

import SwiftUI

/// A reusable SwiftUI view that applies the 'half-sheet' presentation style.
struct HalfSheetView<Content: View>: View {
    @ViewBuilder let content: Content
    
    // The default presentation detents: half screen and full screen.
    // If you only want a strict half sheet, you can remove .large.
    private let detents: Set<PresentationDetent> = [.medium, .large]
    
    // Optional: A detent to snap to when the sheet is first presented.
    @State private var selectedDetent: PresentationDetent = .medium

    var body: some View {
        VStack {
            // Your content goes here
            content
        }
        // --- Sheet Modifiers ---
        // 1. Specifies the heights the sheet can snap to.
        .presentationDetents(detents, selection: $selectedDetent)
        
        // 2. Makes the drag handle visible (default is .automatic).
        // It appears automatically when there is more than one detent.
        .presentationDragIndicator(.visible)
        
        // Optional: Allows the background to be interactive when the sheet is at the medium detent.
//        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }
}
