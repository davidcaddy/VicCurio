//
//  MineralMondayBadge.swift
//  VicCurio
//
//  Badge component for Mineral Monday items.
//

import SwiftUI

struct MineralMondayBadge: View {
    var compact: Bool = false

    var body: some View {
        Label("Mineral Monday", systemImage: "diamond.fill")
            .font(compact ? .caption2 : .caption)
            .fontWeight(.bold)
            .foregroundStyle(.green)
            .accessibilityLabel("Mineral Monday item")
    }
}

#Preview {
    VStack(spacing: 20) {
        MineralMondayBadge()
        MineralMondayBadge(compact: true)
    }
    .padding()
}
