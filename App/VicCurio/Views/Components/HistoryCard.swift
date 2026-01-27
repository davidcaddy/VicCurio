//
//  HistoryCard.swift
//  VicCurio
//
//  Card component for displaying items in history view.
//

import SwiftUI

struct HistoryCard: View {
    let item: CuriosityItem

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: item.thumbnailUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(item.title)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Date badge
                HStack(spacing: 4) {
                    Text(item.displayDateFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if item.isMineralMonday {
                        Image(systemName: "diamond.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .accessibilityLabel("Mineral Monday item")
                    }
                }

                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                if let location = item.location, location.showOnMap {
                    Label(location.name, systemImage: "mappin")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        HistoryCard(item: .preview)
        HistoryCard(item: .preview)
    }
    .padding()
}
