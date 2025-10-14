import SwiftUI

// MARK: - Main View

struct ImageCardView: View {
    // A fixed height for the complex layout, making it behave like a card.
    // Adjust this value to change the overall height of the image gallery.
    private let containerHeight: CGFloat = 300
    private let spacing: CGFloat = 6
    
    let images: [String]
    @State private var selectedImage: String? = nil
    
    var body: some View {
        Group {
            if images.isEmpty {
                // Empty state
                Color.gray
                    .frame(height: containerHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(Text("No Images Available").foregroundColor(.white))
            } else {
                // Dynamic layout based on image count
                layoutForImageCount()
                    .frame(height: containerHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(8)
        .fullScreenCover(item: Binding(
            get: { selectedImage.map { IdentifiableImage(url: $0) } },
            set: { _ in selectedImage = nil }
        )) { identifiableImage in
            FullScreenImageView(imageUrl: identifiableImage.url)
        }
    }
    
    // MARK: - Dynamic Layout Logic
    
    @ViewBuilder
    private func layoutForImageCount() -> some View {
        let count = images.count
        
        switch count {
        case 1:
            // Rule 1: Full height and width
            ImageView(url: images[0], onTap: { selectedImage = images[0] })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case 2:
            // Rule 2: Split width and fill height
            HStack(spacing: spacing) {
                ImageView(url: images[0], onTap: { selectedImage = images[0] })
                ImageView(url: images[1], onTap: { selectedImage = images[1] })
            }
            
        case 3:
            // Rule 3: Image 1 is 1/2 width, full height. Images 2 & 3 are 1/2 width, split height.
            HStack(spacing: spacing) {
                // Image 1 (50% width, 100% height)
                ImageView(url: images[0], onTap: { selectedImage = images[0] })
                
                // Images 2 & 3 (50% width, split 50% height each)
                VStack(spacing: spacing) {
                    ImageView(url: images[1], onTap: { selectedImage = images[1] })
                    ImageView(url: images[2], onTap: { selectedImage = images[2] })
                }
            }
            
        case 4:
            // Rule 4: 2x2 grid (1/2 width, 1/2 height each)
            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    ImageView(url: images[0], onTap: { selectedImage = images[0] })
                    ImageView(url: images[1], onTap: { selectedImage = images[1] })
                }
                HStack(spacing: spacing) {
                    ImageView(url: images[2], onTap: { selectedImage = images[2] })
                    ImageView(url: images[3], onTap: { selectedImage = images[3] })
                }
            }
            
        case 5:
            // Rule 5: Left: 2 images, 1/2 width, 1/2 height each. Right: 3 images, 1/2 width, 1/3 height each.
            HStack(spacing: spacing) {
                // Images 1 & 2 (50% width, split 50% height each)
                VStack(spacing: spacing) {
                    ImageView(url: images[0], onTap: { selectedImage = images[0] })
                    ImageView(url: images[1], onTap: { selectedImage = images[1] })
                }
                
                // Images 3, 4, & 5 (50% width, split 1/3 height each)
                VStack(spacing: spacing) {
                    ImageView(url: images[2], onTap: { selectedImage = images[2] })
                    ImageView(url: images[3], onTap: { selectedImage = images[3] })
                    ImageView(url: images[4], onTap: { selectedImage = images[4] })
                }
            }
            
        default:
            // Handle 6+ images by displaying the first 5 in the Rule 5 layout
            // and adding a "+N" overlay to the last image.
            let firstFive = Array(images.prefix(5))
            let moreCount = count - 5
            
            HStack(spacing: spacing) {
                // Images 1 & 2 (50% width, split 50% height each)
                VStack(spacing: spacing) {
                    ImageView(url: firstFive[0], onTap: { selectedImage = firstFive[0] })
                    ImageView(url: firstFive[1], onTap: { selectedImage = firstFive[1] })
                }
                
                // Images 3, 4, & 5+ (50% width, split 1/3 height each)
                VStack(spacing: spacing) {
                    ImageView(url: firstFive[2], onTap: { selectedImage = firstFive[2] })
                    ImageView(url: firstFive[3], onTap: { selectedImage = firstFive[3] })
                    
                    // Image 5 with "+N" overlay
                    ImageView(url: firstFive[4], onTap: { selectedImage = firstFive[4] })
                        .overlay(
                            RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.4))
                                .overlay(
                                    Text("+\(moreCount)")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                        )
                }
            }
        }
    }
}

// MARK: - Reusable Image View Component

/// A reusable component to handle loading, styling, and tapping for a single image.
private struct ImageView: View {
    let url: String
    let onTap: () -> Void

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
            } else if phase.error != nil {
                Color.gray.overlay(
                    Image(systemName: "photo.fill")
                        .font(.title)
                        .foregroundColor(.white)
                )
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12)) // Ensure the entire area is tappable
        .shadow(radius: 2)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Full Screen View and Helpers (Kept from original code)

// Helper struct to make image URLs identifiable for fullScreenCover
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let url: String
}

// Full-screen image view
struct FullScreenImageView: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                } else if phase.error != nil {
                    Color.gray.overlay(
                        Text("Error Loading Image")
                            .foregroundColor(.white)
                    )
                    .ignoresSafeArea()
                } else {
                    ProgressView()
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Preview

struct ImageCardView_Previews: PreviewProvider {
    // Using placeholder URLs for mock content in the preview
    static let mockImages: [String] = [
        "https://placehold.co/600x600/FF5733/ffffff?text=1",
        "https://placehold.co/600x600/33FF57/ffffff?text=2",
        "https://placehold.co/600x600/3357FF/ffffff?text=3",
        "https://placehold.co/600x600/F333FF/ffffff?text=4",
        "https://placehold.co/600x600/33FFFF/ffffff?text=5",
        "https://placehold.co/600x600/FFFF33/ffffff?text=6",
        "https://placehold.co/600x600/F0F0F0/000000?text=7"
    ]
    
    static var previews: some View {
        VStack(spacing: 30) {
            Text("1 Image (Full)")
            ImageCardView(images: Array(mockImages.prefix(1)))

            Text("2 Images (H-Split)")
            ImageCardView(images: Array(mockImages.prefix(2)))

            Text("3 Images (Lg Left, 2 Sm Right)")
            ImageCardView(images: Array(mockImages.prefix(3)))

            Text("4 Images (2x2 Grid)")
            ImageCardView(images: Array(mockImages.prefix(4)))

            Text("5 Images (2 Left, 3 Right)")
            ImageCardView(images: Array(mockImages.prefix(5)))
            
            Text("7 Images (5 Layout +2 Overlay)")
            ImageCardView(images: Array(mockImages.prefix(7)))

            Text("0 Images (Empty State)")
            ImageCardView(images: [])
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
