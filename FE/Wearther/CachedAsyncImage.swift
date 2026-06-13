import SwiftUI

private final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    func get(_ key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL
    let placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        }
        .task(id: url.absoluteString) { await load() }
    }

    @MainActor
    private func load() async {
        let key = url.absoluteString
        if let cached = ImageCache.shared.get(key) {
            image = cached
            return
        }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let uiImage = UIImage(data: data) else { return }
        ImageCache.shared.set(uiImage, for: key)
        image = uiImage
    }
}
