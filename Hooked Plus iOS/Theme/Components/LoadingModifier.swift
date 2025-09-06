//
//  LoadingModifier.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/6/25.
//

import SwiftUI

struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            if isLoading {
                Color.white.opacity(0.5)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
        }
    }
}

extension View {
    func loading(isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}
