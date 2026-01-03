import SwiftUI

/// An async image view that includes authentication headers for loading images from private Gitea instances
struct AuthenticatedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let token: String?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var hasFailed = false

    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url else {
            hasFailed = true
            isLoading = false
            return
        }

        isLoading = true
        hasFailed = false

        var request = URLRequest(url: url)
        if let token {
            request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                hasFailed = true
                isLoading = false
                return
            }

            if let image = UIImage(data: data) {
                loadedImage = image
            } else {
                hasFailed = true
            }
        } catch {
            hasFailed = true
        }

        isLoading = false
    }
}

/// Convenience initializer for simple image loading
extension AuthenticatedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?, token: String?) {
        self.url = url
        self.token = token
        self.content = { $0 }
        self.placeholder = { Color.clear }
    }
}
