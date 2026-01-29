//
//  ItemDetailView.swift
//  VicCurio
//
//  Full detail view for a museum artifact.
//  Used as a sheet from TodayView and as detail column in History/Favourites.
//

import SwiftUI
import SwiftData

/// Sheet presentation wrapper - includes NavigationStack and Done button
struct ItemDetailView: View {
    let item: CuriosityItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ItemDetailContent(item: item)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

/// Reusable detail content - used in both sheet and split view contexts
struct ItemDetailContent: View {
    let item: CuriosityItem

    @Environment(\.modelContext) private var modelContext
    @State private var showingWebView = false
    @State private var isFavourite = false

    private var favouritesService: FavouritesService {
        FavouritesService(modelContext: modelContext)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Shared content (with date and map for detail view)
                ItemContentView(
                    item: item,
                    showDate: true,
                    showMap: true,
                    onImageTap: { showingWebView = true }
                )

                // Action button
                Button {
                    showingWebView = true
                } label: {
                    Label("View on Museums Victoria", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFavourite.toggle()
                    }
                    favouritesService.toggleFavourite(for: item)
                } label: {
                    Image(systemName: isFavourite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavourite ? .red : .primary)
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: isFavourite)
                .accessibilityLabel(isFavourite ? "Remove from favourites" : "Add to favourites")
            }
        }
        .sheet(isPresented: $showingWebView) {
            MuseumWebView(url: item.museumUrl)
        }
        .onAppear {
            isFavourite = favouritesService.isFavourite(item)
        }
        .onChange(of: item.id) {
            // Update favourite state when item changes (split view selection)
            isFavourite = favouritesService.isFavourite(item)
        }
    }
}

#Preview("Sheet") {
    ItemDetailView(item: .preview)
        .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}

#Preview("Content Only") {
    NavigationStack {
        ItemDetailContent(item: .preview)
    }
    .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}
