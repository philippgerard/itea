import SwiftUI

struct PullRequestListView: View {
    let owner: String
    let repo: String
    let pullRequestService: PullRequestService
    let repositoryService: RepositoryService

    @State private var pullRequests: [PullRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedState: PRState = .open
    @State private var showCreatePR = false
    @State private var currentPage = 1
    @State private var hasMorePages = true

    enum PRState: String, CaseIterable {
        case open, closed, all

        var displayName: String {
            rawValue.capitalized
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter picker always visible
            Picker("State", selection: $selectedState) {
                ForEach(PRState.allCases, id: \.self) { state in
                    Text(state.displayName).tag(state)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if isLoading && pullRequests.isEmpty {
                Spacer()
                ProgressView("Loading pull requests...")
                Spacer()
            } else if let errorMessage, pullRequests.isEmpty {
                ContentUnavailableView {
                    SwiftUI.Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Retry") {
                        Task { await loadPullRequests() }
                    }
                }
                .frame(maxHeight: .infinity)
            } else if pullRequests.isEmpty {
                ContentUnavailableView(
                    "No Pull Requests",
                    systemImage: "arrow.triangle.pull",
                    description: Text("No \(selectedState.rawValue) pull requests")
                )
                .frame(maxHeight: .infinity)
            } else {
                prList
            }
        }
        .frame(maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreatePR = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreatePR) {
            CreatePullRequestView(
                owner: owner,
                repo: repo,
                pullRequestService: pullRequestService,
                repositoryService: repositoryService
            ) {
                Task { await loadPullRequests() }
            }
            #if targetEnvironment(macCatalyst)
            .presentationSizing(.fitted)
            #endif
        }
        .refreshable {
            await loadPullRequests()
        }
        .onChange(of: selectedState) { _, _ in
            Task { await loadPullRequests() }
        }
        .task {
            await loadPullRequests()
        }
    }

    private var prList: some View {
        List {
            ForEach(pullRequests) { pr in
                NavigationLink(value: pr) {
                    PullRequestRowView(pullRequest: pr)
                }
                .onAppear {
                    Task { await loadMoreIfNeeded(currentItem: pr) }
                }
            }

            if isLoading && !pullRequests.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: PullRequest.self) { pr in
            PullRequestDetailView(
                pullRequest: pr,
                owner: owner,
                repo: repo,
                pullRequestService: pullRequestService
            )
        }
    }

    private func loadPullRequests() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            pullRequests = try await pullRequestService.getPullRequests(
                owner: owner,
                repo: repo,
                state: selectedState.rawValue,
                page: currentPage
            )
            hasMorePages = !pullRequests.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func loadMoreIfNeeded(currentItem: PullRequest) async {
        guard hasMorePages,
              !isLoading,
              pullRequests.last?.id == currentItem.id else { return }

        currentPage += 1
        isLoading = true

        do {
            let morePRs = try await pullRequestService.getPullRequests(
                owner: owner,
                repo: repo,
                state: selectedState.rawValue,
                page: currentPage
            )
            hasMorePages = !morePRs.isEmpty
            pullRequests.append(contentsOf: morePRs)
        } catch {
            currentPage -= 1
        }

        isLoading = false
    }
}
