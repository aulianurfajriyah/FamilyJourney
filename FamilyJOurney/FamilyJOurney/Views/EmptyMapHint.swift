//
//  EmptyMapHint.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import SwiftUI

// EmptyMapHint gives a clear empty state before the user has entered real locations.
struct EmptyMapHint: View {
    // The parent passes in the insert action so this child does not need direct SwiftData access.
    let addSampleLocations: () -> Void

    // The body renders a compact callout over the map.
    var body: some View {
        VStack(spacing: 12) {
            Text("No saved locations yet")
                .font(.headline)

            Text("Add sample records to see SwiftData markers and journey polylines on the map.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Add Sample Locations", action: addSampleLocations)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
