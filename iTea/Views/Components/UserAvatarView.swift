import SwiftUI

struct UserAvatarView: View {
    let user: User
    var size: CGFloat = 32

    @State private var loadedImage: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(width: size, height: size)
            } else {
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: user.avatarUrl) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = user.avatarURL else { return }
        guard loadedImage == nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                loadedImage = image
            }
        } catch {
            // Failed to load, will show placeholder
        }
    }

    private var placeholderView: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundStyle(.secondary)
    }
}

#Preview {
    UserAvatarView(
        user: User(
            id: 1,
            login: "test",
            fullName: "Test User",
            email: nil,
            avatarUrl: nil,
            isAdmin: false,
            created: nil
        ),
        size: 48
    )
}
