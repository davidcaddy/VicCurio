//
//  ItemDetailView.swift
//  VicCurio
//
//  Full detail view for a museum artifact (shown from History).
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    let item: CuriosityItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingWebView = false
    @State private var isFavourite = false

    private var favouritesService: FavouritesService {
        FavouritesService(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

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
        }
    }
}

#Preview {
    ItemDetailView(item: .preview)
        .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}
