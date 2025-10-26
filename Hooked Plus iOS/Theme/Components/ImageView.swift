//
//  ImageView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/25/25.
//

import SwiftUI

/// A reusable component to handle loading, styling, and tapping for a single image.
struct ImageView: View {
    let url: String
    let onTap: () -> Void

    var body: some View {
        GeometryReader { geo in
            CachedAsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                case .failure(_):
                    Color.gray
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        )

                case .empty:
                    // Keeps same layout even before loading
                    Color.gray
                        .overlay(ProgressView())
                }
            }
        }
        // GeometryReader collapses otherwise — give it room
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
        .onTapGesture(perform: onTap)
    }
}
