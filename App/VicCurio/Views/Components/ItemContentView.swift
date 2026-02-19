//
//  ItemContentView.swift
//  VicCurio
//
//  Shared content view for displaying a museum artifact.
//  Used by both TodayView and ItemDetailView.
//  Supports wide (side-by-side) layout for iPad.
//

import SwiftUI
import MapKit

struct ItemContentView: View {
    let item: CuriosityItem
    var showDate: Bool = false
    var showMap: Bool = true
    var isWideLayout: Bool = false
    var onImageTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isWideLayout {
                wideContent
            } else {
                compactContent
            }

            // Shared bottom section (location, tags, attribution)
            VStack(alignment: .leading, spacing: 12) {
                // Location
                if let location = item.location {
                    locationSection(location)
                }

                // Tags
                if !item.tags.isEmpty {
                    tagsSection
                }

                Divider()

                // Attribution and disclaimer
                VStack(alignment: .leading, spacing: 4) {
                    Text("Image: \(item.attributionText)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("Content sourced from Museums Victoria Collections. Information may contain errors.")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }

    // MARK: - Wide Layout (iPad)

    private var wideContent: some View {
        HStack(alignment: .top, spacing: 24) {
            // Left column: Hero image
            heroImage
                .frame(maxWidth: .infinity)

            // Right column: Text content
            VStack(alignment: .leading, spacing: 12) {
                if item.isMineralMonday {
                    MineralMondayBadge()
                }

                if showDate {
                    Text(item.displayDateFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(item.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let funFact = item.funFact, !funFact.isEmpty {
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing)
        }
    }

    // MARK: - Compact Layout (iPhone)

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            heroImage

            VStack(alignment: .leading, spacing: 12) {
                if item.isMineralMonday {
                    MineralMondayBadge()
                }

                if showDate {
                    Text(item.displayDateFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(item.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)

                if let funFact = item.funFact, !funFact.isEmpty {
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
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Subviews

    private var heroImage: some View {
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            onImageTap?()
        }
        .accessibilityLabel(item.title)
    }

    private func locationSection(_ location: LocationData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(location.displayName, systemImage: "mappin")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Map (only if coordinates available and showMap enabled)
            if showMap, let coordinate = location.coordinate {
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
    }

    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        ItemContentView(item: .preview, showDate: true)
    }
}
