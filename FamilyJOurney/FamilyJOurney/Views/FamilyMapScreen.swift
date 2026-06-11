//
//  FamilyMapScreen.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

// FamilyMapScreen owns the SwiftData query, MapKit camera state, and marker selection state.
struct FamilyMapScreen: View {
    // @Query asks SwiftData for all LocationRecord objects and refreshes this view whenever they change.
    @Query(sort: \LocationRecord.timestamp) private var locationRecords: [LocationRecord]

    // Querying members forces the map screen to refresh when any member's color, emoji, or name is updated.
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]

    // The model context is the write gateway for inserting sample records during this learning MVP.
    @Environment(\.modelContext) private var modelContext

    // This state stores the current MapKit camera position and is bound directly to the Map view.
    @State private var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)

    // This state stores the selected marker ID and is bound directly to MapKit's selection system.
    @State private var selectedRecordID: UUID?

    // This state controls whether the marker detail sheet is visible after a marker tap.
    @State private var isShowingLocationDetails = false

    // This state controls whether the manual location entry sheet is visible.
    @State private var isShowingAddLocationSheet = false

    // This state controls whether the journey legend sheet is visible.
    @State private var isShowingLegendSheet = false

    // Stores the IDs of family members whose journeys are currently hidden.
    @State private var hiddenMemberIDs: Set<UUID> = []

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
            .sheet(isPresented: $isShowingAddLocationSheet) {
                AddLocationSheet()
            }
            .sheet(isPresented: $isShowingLegendSheet) {
                FamilyLegendSheet(hiddenMemberIDs: $hiddenMemberIDs)
                    .presentationDetents([.medium, .large])
            }
            .onChange(of: hiddenMemberIDs) { _, _ in
                fitCameraToSavedLocations()
            }
            .overlay(alignment: .bottom) {
                if locationRecords.isEmpty {
                    EmptyMapHint {
                        isShowingAddLocationSheet = true
                    }
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

    // This builder turns each SwiftData LocationRecord into one/grouped map annotations.
    @MapContentBuilder
    private var locationMarkers: some MapContent {
        let visibleRecords = locationRecords.filter { record in
            if let member = record.member {
                return !hiddenMemberIDs.contains(member.id)
            }
            return true
        }

        let clusters = clusterLocations(visibleRecords)

        ForEach(clusters) { cluster in
            let uniqueMembers = Array(Set(cluster.records.compactMap { $0.member }))
                .sorted(by: { $0.name < $1.name })
            
            let latestRecord = cluster.records.max(by: { $0.timestamp < $1.timestamp }) ?? cluster.records[0]
            
            let annotationTitle = cluster.records.count == 1 
                ? latestRecord.cityName 
                : "\(cluster.records.count) stops (\(latestRecord.cityName))"

            Annotation(annotationTitle, coordinate: cluster.coordinate) {
                VStack(spacing: 4) {
                    if uniqueMembers.count == 1, let member = uniqueMembers.first {
                        if let avatarData = member.avatarImageData, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 38, height: 38)
                                .clipShape(Circle())
                                .background(Circle().fill(Color(uiColor: .systemBackground)))
                                .overlay(
                                    Circle()
                                        .stroke(member.color, lineWidth: 3)
                                )
                                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                        } else {
                            Text(member.emoji)
                                .font(.system(size: 26))
                                .padding(6)
                                .background(Circle().fill(Color(uiColor: .systemBackground)))
                                .overlay(
                                    Circle()
                                        .stroke(member.color, lineWidth: 3)
                                )
                                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                        }
                    } else {
                        let limit = 3
                        let displayedMembers = Array(uniqueMembers.prefix(limit))
                        let remainingCount = uniqueMembers.count - displayedMembers.count
                        
                        HStack(spacing: -10) {
                            ForEach(displayedMembers) { member in
                                if let avatarData = member.avatarImageData, let uiImage = UIImage(data: avatarData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                        .background(Circle().fill(Color(uiColor: .systemBackground)))
                                        .overlay(
                                            Circle()
                                                .stroke(member.color, lineWidth: 2)
                                        )
                                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                                } else {
                                    Text(member.emoji)
                                        .font(.system(size: 20))
                                        .padding(4)
                                        .background(Circle().fill(Color(uiColor: .systemBackground)))
                                        .overlay(
                                            Circle()
                                                .stroke(member.color, lineWidth: 2)
                                        )
                                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                                }
                            }
                            
                            if remainingCount > 0 {
                                Text("+\(remainingCount)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.gray))
                                    .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(4)
                        .background(Capsule().fill(Color(uiColor: .systemBackground)))
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .tag(latestRecord.id)
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

        ToolbarItemGroup(placement: .topBarTrailing) {
          
            Button {
                isShowingAddLocationSheet = true
            } label: {
                Label("Add Location", systemImage: "plus")
            }
            Button {
                isShowingLegendSheet = true
            } label: {
                Label("Legend", systemImage: "line.3.horizontal.decrease.circle")
            }
        }

        
    }

    // Journey groups convert raw SwiftData records into MapKit-friendly polyline inputs.
    private var journeyGroups: [JourneyGroup] {
        let groupedRecords = Dictionary(grouping: locationRecords) { record in
            record.member
        }

        // Filter out members that are currently hidden by the user.
        let visibleMembers = groupedRecords.keys.compactMap { $0 }
            .filter { !hiddenMemberIDs.contains($0.id) }

        return visibleMembers.sorted(by: { $0.name < $1.name }).compactMap { member in
            guard let records = groupedRecords[member] else {
                return nil
            }

            let sortedRecords = records.sorted { first, second in
                first.timestamp < second.timestamp
            }

            return JourneyGroup(
                memberName: member.name,
                color: member.color,
                coordinates: sortedRecords.map(\.coordinate)
            )
        }
    }

    // This helper moves the map camera to a region that includes all saved records.
    private func fitCameraToSavedLocations() {
        let visibleRecords = locationRecords.filter { record in
            if let member = record.member {
                return !hiddenMemberIDs.contains(member.id)
            }
            return true
        }
        let region = MKCoordinateRegion.region(fitting: visibleRecords, defaultRegion: Self.defaultRegion)
        cameraPosition = .region(region)
    }



    // The default region centers on Indonesia before any saved SwiftData records exist.
    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -2.5489, longitude: 118.0149),
        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 35)
    )

    // Location clustering structure
    private struct LocationCluster: Identifiable {
        let id: UUID
        let coordinate: CLLocationCoordinate2D
        let records: [LocationRecord]
    }

    // Cluster location records within a specific radius in meters
    private func clusterLocations(_ records: [LocationRecord], radiusMeters: Double = 50.0) -> [LocationCluster] {
        var clusters: [LocationCluster] = []
        
        for record in records {
            let recordLoc = CLLocation(latitude: record.latitude, longitude: record.longitude)
            
            if let index = clusters.firstIndex(where: { cluster in
                let clusterLoc = CLLocation(latitude: cluster.coordinate.latitude, longitude: cluster.coordinate.longitude)
                return recordLoc.distance(from: clusterLoc) < radiusMeters
            }) {
                let existingCluster = clusters[index]
                var updatedRecords = existingCluster.records
                updatedRecords.append(record)
                clusters[index] = LocationCluster(
                    id: existingCluster.id,
                    coordinate: existingCluster.coordinate,
                    records: updatedRecords
                )
            } else {
                clusters.append(LocationCluster(
                    id: UUID(),
                    coordinate: record.coordinate,
                    records: [record]
                ))
            }
        }
        
        return clusters
    }
}

#Preview {
    // The preview uses an in-memory SwiftData container so sample preview data never touches app storage.
    FamilyMapScreen()
        .modelContainer(for: [LocationRecord.self, FamilyMember.self], inMemory: true)
}
