//
//  SheetView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/28/25.
//

import SwiftUI

struct SheetView<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    
    let content: Content
    var title: String?
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ───── Optional Header ─────
                if let title = title {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .background(ColorToken.backgroundSecondary.color)
                }
                
                // ───── Flexible Content Area ─────
                // 1. Try to layout the content without scrolling.
                // 2. If it overflows, wrap it in a ScrollView.
                content
                    .padding()
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: ContentHeightKey.self,
                                    value: proxy.size.height
                                )
                        }
                    )
                    .onPreferenceChange(ContentHeightKey.self) { height in
                        // Store the measured height so we can decide whether to scroll
                        measuredContentHeight = height
                    }
                    // Wrap in ScrollView **only** when needed
                    .modifier(ScrollableWhenNeeded(measuredHeight: measuredContentHeight))
            }
            // ───── Toolbar (close button) ─────
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(ColorToken.buttonSecondary.color)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                    .accessibilityLabel("Close")
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        // Reset the measured height when the sheet appears/disappears
        .onAppear { measuredContentHeight = 0 }
    }
    
    // MARK: – Helper state
    @State private var measuredContentHeight: CGFloat = 0
}

// MARK: – Preference key to capture the content height
private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: – ViewModifier that adds a ScrollView only when needed
private struct ScrollableWhenNeeded: ViewModifier {
    @Environment(\.layoutDirection) var layoutDirection
    let measuredHeight: CGFloat
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let available = geometry.size.height
            if measuredHeight > available {
                // Content is taller → scroll
                ScrollView {
                    content
                }
            } else {
                // Content fits → just fill
                content
            }
        }
    }
}
