import SwiftUI

struct RepositoryRowView: View {
    let repository: Repository

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(repository.name)
                    .font(.headline)

                if repository.isPrivate {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if repository.fork {
                    Image(systemName: "tuningfork")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let description = repository.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                if let stars = repository.starsCount {
                    SwiftUI.Label("\(stars)", systemImage: "star")
                }
                if let forks = repository.forksCount {
                    SwiftUI.Label("\(forks)", systemImage: "tuningfork")
                }
                if let issues = repository.openIssuesCount {
                    SwiftUI.Label("\(issues)", systemImage: "exclamationmark.circle")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RepositoryRowView(
        repository: Repository(
            id: 1,
            name: "example-repo",
            fullName: "user/example-repo",
            description: "An example repository with a description",
            owner: User(id: 1, login: "user", fullName: nil, email: nil, avatarUrl: nil, isAdmin: false, created: nil),
            private: false,
            fork: false,
            htmlUrl: nil,
            cloneUrl: nil,
            defaultBranch: "main",
            starsCount: 42,
            forksCount: 10,
            openIssuesCount: 5,
            openPrCounter: 2,
            createdAt: nil,
            updatedAt: nil
        )
    )
    .padding()
}
