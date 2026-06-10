//
//  FamilyMapScreen.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import MapKit
import SwiftData
import SwiftUI

// FamilyMapScreen owns the SwiftData query, MapKit camera state, and marker selection state.
struct FamilyMapScreen: View {
    // @Query asks SwiftData for all LocationRecord objects and refreshes this view whenever they change.
    @Query(sort: \LocationRecord.timestamp) private var locationRecords: [LocationRecord]

    // The model context is the write gateway for inserting sample records during this learning MVP.
    @Environment(\.modelContext) private var modelContext

    // This state stores the current MapKit camera position and is bound directly to the Map view.
    @State private var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)

    // This state stores the selected marker ID and is bound directly to MapKit's selection system.
    @State private var selectedRecordID: UUID?

    // This state controls whether the marker detail sheet is visible after a marker tap.
    @State private var isShowingLocationDetails = false

    // The body renders the map first, because the map is the main learning surface for this screen.
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $selectedRecordID) {
                journeyPolylines
                locationMarkers
            }
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
            }
            .navigationTitle("Family Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                mapToolbar
            }
            .onChange(of: selectedRecordID) { _, newValue in
                isShowingLocationDetails = newValue != nil
            }
            .onChange(of: locationRecords.map(\.id)) { _, _ in
                fitCameraToSavedLocations()
            }
            .sheet(isPresented: $isShowingLocationDetails) {
                LocationDetailSheet(record: selectedRecord)
                    .presentationDetents([.medium])
            }
            .overlay(alignment: .bottom) {
                if locationRecords.isEmpty {
                    EmptyMapHint(addSampleLocations: addSampleLocations)
                        .padding()
                }
            }
        }
    }

    // The selected record is derived from MapKit's selected UUID and the latest SwiftData query result.
    private var selectedRecord: LocationRecord? {
        locationRecords.first { $0.id == selectedRecordID }
    }

    // This builder turns grouped SwiftData records into route overlays on the map.
    @MapContentBuilder
    private var journeyPolylines: some MapContent {
        ForEach(journeyGroups) { group in
            MapPolyline(coordinates: group.coordinates)
                .stroke(group.color, lineWidth: 4)
        }
    }

    // This builder turns each SwiftData LocationRecord into one tappable map marker.
    @MapContentBuilder
    private var locationMarkers: some MapContent {
        ForEach(locationRecords, id: \.id) { record in
            Marker(record.cityName, coordinate: record.coordinate)
                .tint(FamilyMemberColor.color(for: record.familyMemberName))
                .tag(record.id)
        }
    }

    // The toolbar keeps map actions near the map while leaving the main body readable.
    @ToolbarContentBuilder
    private var mapToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Fit") {
                fitCameraToSavedLocations()
            }
            .disabled(locationRecords.isEmpty)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("Sample") {
                addSampleLocations()
            }
        }
    }

    // Journey groups convert raw SwiftData records into MapKit-friendly polyline inputs.
    private var journeyGroups: [JourneyGroup] {
        let groupedRecords = Dictionary(grouping: locationRecords) { record in
            record.familyMemberName
        }

        return groupedRecords.keys.sorted().compactMap { memberName in
            guard let records = groupedRecords[memberName] else {
                return nil
            }

            let sortedRecords = records.sorted { first, second in
                first.timestamp < second.timestamp
            }

            return JourneyGroup(
                memberName: memberName,
                color: FamilyMemberColor.color(for: memberName),
                coordinates: sortedRecords.map(\.coordinate)
            )
        }
    }

    // This helper moves the map camera to a region that includes all saved records.
    private func fitCameraToSavedLocations() {
        let region = MKCoordinateRegion.region(fitting: locationRecords, defaultRegion: Self.defaultRegion)
        cameraPosition = .region(region)
    }

    // This helper inserts sample records through SwiftData so @Query can refresh the map automatically.
    private func addSampleLocations() {
        modelContext.insertSampleLocationRecords()
        fitCameraToSavedLocations()
    }

    // The default region centers on Indonesia before any saved SwiftData records exist.
    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -2.5489, longitude: 118.0149),
        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 35)
    )
}

#Preview {
    // The preview uses an in-memory SwiftData container so sample preview data never touches app storage.
    FamilyMapScreen()
        .modelContainer(for: LocationRecord.self, inMemory: true)
}
