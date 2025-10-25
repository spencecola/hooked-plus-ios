//
//  LazyView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/24/25.
//

import SwiftUI

struct LazyView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var hasAppeared = false
    
    var body: some View {
        if hasAppeared {
            content()
        } else {
            Color.clear // Placeholder to trigger .onAppear without visual impact
                .frame(width: 0, height: 0) // Optional: minimize layout impact
                .onAppear {
                    hasAppeared = true
                }
        }
    }
}
