//
//  TodayView.swift
//  VicCurio
//
//  Displays today's museum artifact.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    private var feedService: FeedService { FeedService.shared }

    @State private var todayItem: CuriosityItem?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingWebView = false
    @State private var isFavourite = false
    @State private var lastLoadedItemId: String?

    private var favouritesService: FavouritesService {
        FavouritesService(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    loadingView
                } else if let item = todayItem {
                    itemContent(item)
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    emptyView
                }
            }
            .navigationTitle("VicCurio")
            .refreshable {
                await loadTodaysItem(forceRefresh: true)
            }
            .task {
                await loadTodaysItem()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active && oldPhase == .background {
                    Task {
                        await loadTodaysItem(forceRefresh: true)
                    }
                }
            }
            .sheet(isPresented: $showingWebView) {
                if let item = todayItem {
                    MuseumWebView(url: item.museumUrl)
                }
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading today's curiosity...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private func itemContent(_ item: CuriosityItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Shared content (no map on today view, keeps it focused)
            ItemContentView(
                item: item,
                showDate: false,
                showMap: false,
                onImageTap: { showingWebView = true }
            )

            // Action buttons
            HStack(spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFavourite.toggle()
                    }
                    favouritesService.toggleFavourite(for: item)
                } label: {
                    Label(
                        isFavourite ? "Saved" : "Save",
                        systemImage: isFavourite ? "heart.fill" : "heart"
                    )
                }
                .buttonStyle(.bordered)
                .tint(isFavourite ? .red : .primary)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: isFavourite)

                Button {
                    showingWebView = true
                } label: {
                    Label("Learn More", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task {
                    await loadTodaysItem(forceRefresh: true)
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Curiosity Today", systemImage: "sparkles")
        } description: {
            Text("Check back tomorrow for something amazing!")
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    // MARK: - Methods

    private func loadTodaysItem(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil

        do {
            let item = try await feedService.fetchTodaysItem(modelContext: modelContext)
            todayItem = item
            isFavourite = favouritesService.isFavourite(item)
            favouritesService.markAsViewed(item)
        } catch let error as FeedService.FeedError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}
