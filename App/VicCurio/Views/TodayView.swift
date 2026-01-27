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
    private var feedService: FeedService { FeedService.shared }

    @State private var todayItem: CuriosityItem?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingDetail = false

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
            .sheet(isPresented: $showingDetail) {
                if let item = todayItem {
                    ItemDetailView(item: item)
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
        VStack(alignment: .leading, spacing: 16) {
            // Hero image
            AsyncImage(url: item.imageUrl) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(item.aspectRatio ?? 1.0, contentMode: .fit)
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(item.aspectRatio ?? 1.0, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture {
                showingDetail = true
            }

            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Mineral Monday badge
                if item.isMineralMonday {
                    MineralMondayBadge()
                }

                // Title
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)

                // Summary
                Text(item.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)

                // Fun fact
                if let funFact = item.funFact {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(funFact)
                            .font(.callout)
                            .italic()
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Location
                if let location = item.location, location.showOnMap {
                    Label(location.displayName, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button {
                        favouritesService.toggleFavourite(for: item)
                    } label: {
                        Label(
                            favouritesService.isFavourite(item) ? "Saved" : "Save",
                            systemImage: favouritesService.isFavourite(item) ? "heart.fill" : "heart"
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(favouritesService.isFavourite(item) ? .red : .primary)

                    Button {
                        showingDetail = true
                    } label: {
                        Label("Learn More", systemImage: "info.circle")
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }

                // Attribution
                Text(item.attributionText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
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
