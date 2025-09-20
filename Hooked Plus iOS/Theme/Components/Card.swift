//
//  Card.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 9/5/25.
//

import SwiftUI

struct CardView: View {
    let imageUrls: [String]?
    let description: String?
    let posterName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Images in horizontal scroll view
            if let imageUrls = imageUrls, !imageUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(imageUrls, id: \.self) { imageUrl in
                            if let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 200)
                                            .background(Color.gray.opacity(0.2))
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 200)
                                            .clipped()
                                    case .failure:
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 200)
                                            .foregroundColor(.gray)
                                            .background(Color.gray.opacity(0.2))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
            
            // Description and Poster Name
            VStack(alignment: .leading, spacing: 4) {
                if let description = description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .padding(.horizontal, 12)
                }
                
                Text(posterName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// Preview
struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CardView(
                imageUrls: [
                    "https://example.com/image1.jpg",
                    "https://example.com/image2.jpg",
                    "https://example.com/image3.jpg"
                ],
                description: "This is a sample post with multiple images.",
                posterName: "John Doe"
            )
            CardView(
                imageUrls: nil,
                description: "This post has no images.",
                posterName: "Jane Smith"
            )
            CardView(
                imageUrls: ["https://example.com/image1.jpg"],
                description: nil,
                posterName: "Alice Johnson"
            )
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
