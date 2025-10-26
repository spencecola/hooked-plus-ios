//
//  CachedAsyncImage.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 10/25/25.
//

import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    @Environment(\.imageCache) private var cache
    @State private var phase: AsyncImagePhase = .empty
    let url: URL?
    let content: (AsyncImagePhase) -> Content
    
    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .task(id: url) {
                await load()
            }
    }
    
    private func load() async {
        guard let url = url else {
            phase = .failure(URLError(.badURL))
            return
        }
        
        if let image = cache[url] {
            phase = .success(Image(uiImage: image))
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Decode off main thread
            if let uiImage = await decodeImage(from: data) {
                cache[url] = uiImage
                phase = .success(Image(uiImage: uiImage))
            } else {
                phase = .failure(URLError(.cannotDecodeRawData))
            }
        } catch {
            phase = .failure(error)
        }
    }
    
    private func decodeImage(from data: Data) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let image = UIImage(data: data)
                continuation.resume(returning: image)
            }
        }
    }
}

protocol ImageCache {
    subscript(_ url: URL) -> UIImage? { get set }
}

final class TemporaryImageCache: ImageCache {
    private let cache = NSCache<NSURL, UIImage>()
    
    subscript(_ url: URL) -> UIImage? {
        get { cache.object(forKey: url as NSURL) }
        set {
            if let image = newValue {
                cache.setObject(image, forKey: url as NSURL)
            } else {
                cache.removeObject(forKey: url as NSURL)
            }
        }
    }
}

struct ImageCacheKey: EnvironmentKey {
    static let defaultValue: TemporaryImageCache = TemporaryImageCache()
}

extension EnvironmentValues {
    var imageCache: TemporaryImageCache {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}


