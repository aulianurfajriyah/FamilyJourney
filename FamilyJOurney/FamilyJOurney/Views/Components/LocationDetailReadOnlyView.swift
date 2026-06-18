//
//  LocationDetailReadOnlyView.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import SwiftUI

struct LocationDetailReadOnlyView: View {
    let record: LocationRecord
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        List {
            // This section explains who owns the location record.
            Section("Family Member") {
                Text(record.member?.name ?? "Unknown")
                    .font(.body) // Dynamic Type compliance
            }

            // This section shows the place saved in SwiftData.
            Section("Location") {
                Text(record.cityName)
                    .font(.body) // Dynamic Type compliance
                Text("Latitude: \(record.latitude.formatted())")
                    .font(.body) // Dynamic Type compliance
                Text("Longitude: \(record.longitude.formatted())")
                    .font(.body) // Dynamic Type compliance
            }

            // This section shows when the journey snapshot happened.
            Section("Time") {
                Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.body) // Dynamic Type compliance
            }

            // This section shows the optional note for the marker.
            if !record.note.isEmpty {
                Section("Note") {
                    Text(record.note)
                        .font(.body) // Dynamic Type compliance
                }
            }

            // Destructive section to delete this location stop from the database.
            Section {
                Button(role: .destructive, action: onDelete) {
                    HStack {
                        Spacer()
                        Text("Delete Location Stop")
                            .font(.body) // Dynamic Type compliance
                        Spacer()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit", action: onEdit)
                    .font(.body)
            }
        }
    }
}
