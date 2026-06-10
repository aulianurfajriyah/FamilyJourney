//
//  LocationDetailSheet.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import SwiftUI

// LocationDetailSheet presents details for the marker selected through MapKit's selection binding.
struct LocationDetailSheet: View {
    // The record is optional because a selection can disappear after SwiftData updates or deletes data.
    let record: LocationRecord?

    // The body shows either selected record details or a fallback message.
    var body: some View {
        NavigationStack {
            Group {
                if let record {
                    List {
                        // This section explains who owns the location record.
                        Section("Family Member") {
                            Text(record.familyMemberName)
                        }

                        // This section shows the place saved in SwiftData.
                        Section("Location") {
                            Text(record.cityName)
                            Text("Latitude: \(record.latitude.formatted())")
                            Text("Longitude: \(record.longitude.formatted())")
                        }

                        // This section shows when the journey snapshot happened.
                        Section("Time") {
                            Text(record.timestamp.formatted(date: .abbreviated, time: .shortened))
                        }

                        // This section shows the optional note for the marker.
                        if !record.note.isEmpty {
                            Section("Note") {
                                Text(record.note)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("No Location Selected", systemImage: "mappin.slash")
                }
            }
            .navigationTitle("Location Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
