//
//  ItemDetailView.swift
//  VicCurio
//
//  Full detail view for a museum artifact.
//

import SwiftUI
import SwiftData
import MapKit

struct ItemDetailView: View {
    let item: CuriosityItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingWebView = false

    private var favouritesService: FavouritesService {
        FavouritesService(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero image
                    AsyncImage(url: item.imageUrl) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(item.aspectRatio ?? 1.0, contentMode: .fit)
                                .overlay { ProgressView() }
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel(item.title)

                    // Content
                    VStack(alignment: .leading, spacing: 12) {
                        // Mineral Monday badge
                        if item.isMineralMonday {
                            MineralMondayBadge()
                        }

                        // Date
                        Text(item.displayDateFormatted)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Title
                        Text(item.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        // Summary
                        Text(item.summary)
                            .font(.body)

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

                        // Map
                        if let location = item.location, location.showOnMap, let coordinate = location.coordinate {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(location.displayName, systemImage: "mappin")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Map(initialPosition: .region(MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                                ))) {
                                    Marker(item.title, coordinate: coordinate)
                                }
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        Divider()

                        // Attribution
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Image: \(item.attributionText)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Button {
                                showingWebView = true
                            } label: {
                                Label("View on Museums Victoria", systemImage: "arrow.up.right.square")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
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
                        favouritesService.toggleFavourite(for: item)
                    } label: {
                        Image(systemName: favouritesService.isFavourite(item) ? "heart.fill" : "heart")
                            .foregroundStyle(favouritesService.isFavourite(item) ? .red : .primary)
                    }
                    .accessibilityLabel(favouritesService.isFavourite(item) ? "Remove from favourites" : "Add to favourites")
                }
            }
            .sheet(isPresented: $showingWebView) {
                MuseumWebView(url: item.museumUrl)
            }
        }
    }
}

#Preview {
    ItemDetailView(item: .preview)
        .modelContainer(for: [PersistedItem.self, CachedFeed.self], inMemory: true)
}
