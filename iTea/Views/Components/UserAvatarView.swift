import SwiftUI

struct UserAvatarView: View {
    let user: User
    var size: CGFloat = 32

    var body: some View {
        AsyncImage(url: user.avatarURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                placeholderView
            case .empty:
                placeholderView
            @unknown default:
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
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
