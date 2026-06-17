import SwiftUI

struct IssueListView: View {
    let owner: String
    let repo: String
    let issueService: IssueService
    let attachmentService: AttachmentService
    var canModifyOthers: Bool = false

    @State private var issues: [Issue] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedState: ItemState = .open
    @State private var showCreateIssue = false
    @State private var currentPage = 1
    @State private var hasMorePages = true

    var body: some View {
        VStack(spacing: 0) {
            // Filter picker with glass background
            Picker("State", selection: $selectedState) {
                ForEach(ItemState.allCases, id: \.self) { state in
                    Text(state.displayName).tag(state)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(.ultraThinMaterial)

            if isLoading && issues.isEmpty {
                Spacer()
                ProgressView("Loading issues...")
                Spacer()
            } else if let errorMessage, issues.isEmpty {
                ContentUnavailableView {
                    SwiftUI.Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Retry") {
                        Task { await loadIssues() }
                    }
                }
                .frame(maxHeight: .infinity)
            } else if issues.isEmpty {
                ContentUnavailableView(
                    "No Issues",
                    systemImage: "checkmark.circle",
                    description: Text("No \(selectedState.rawValue) issues")
                )
                .frame(maxHeight: .infinity)
            } else {
                issueList
            }
        }
        .frame(maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateIssue = true
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.medium)
                }
                .accessibilityLabel("New Issue")
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showCreateIssue) {
            CreateIssueView(
                owner: owner,
                repo: repo,
                issueService: issueService,
                attachmentService: attachmentService
            ) {
                Task { await loadIssues() }
            }
            #if targetEnvironment(macCatalyst)
            .presentationSizing(.fitted)
            #endif
        }
        .refreshable {
            await loadIssues()
        }
        .onChange(of: selectedState) { _, _ in
            Task { await loadIssues() }
        }
        .task {
            await loadIssues()
        }
    }

    private var issueList: some View {
        List {
            ForEach(issues) { issue in
                NavigationLink(value: issue) {
                    IssueRowView(issue: issue)
                }
                .onAppear {
                    Task { await loadMoreIfNeeded(currentItem: issue) }
                }
            }

            if isLoading && !issues.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Issue.self) { issue in
            IssueDetailView(
                issue: issue,
                owner: owner,
                repo: repo,
                issueService: issueService,
                attachmentService: attachmentService,
                canModifyOthers: canModifyOthers
            )
        }
    }

    private func loadIssues() async {
        isLoading = true
        errorMessage = nil
        currentPage = 1

        do {
            issues = try await issueService.getIssues(
                owner: owner,
                repo: repo,
                state: selectedState,
                page: currentPage
            )
            hasMorePages = !issues.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func loadMoreIfNeeded(currentItem: Issue) async {
        guard hasMorePages,
              !isLoading,
              issues.last?.id == currentItem.id else { return }

        currentPage += 1
        isLoading = true

        do {
            let moreIssues = try await issueService.getIssues(
                owner: owner,
                repo: repo,
                state: selectedState,
                page: currentPage
            )
            hasMorePages = !moreIssues.isEmpty
            issues.append(contentsOf: moreIssues)
        } catch {
            currentPage -= 1
        }

        isLoading = false
    }
}
