//
//  FamilyMapScreen.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import Combine
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
    
    // Time-lapse simulation state
    @State private var isTimelapseActive = false
    @State private var timelapseStartDate = Date()
    @State private var timelapseEndDate = Date()
    @State private var timelapseCurrentDate = Date()

    // Track record mode state (displays travel history via polylines & historical markers)
    @State private var isTrackRecordActive = false

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
                JourneyPolylinesContent(isTrackRecordActive: isTrackRecordActive, journeyGroups: journeyGroups)
                LocationMarkersContent(clusters: clusters)
            }
            .mapControls {
                MapCompass()
                MapScaleView()
              //  MapUserLocationButton()
            }
            .navigationTitle("Family Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                FamilyMapToolbar(
                    hasLocationRecords: !locationRecords.isEmpty,
                    isTrackRecordActive: $isTrackRecordActive,
                    isTimelapseActive: $isTimelapseActive,
                    isShowingAddLocationSheet: $isShowingAddLocationSheet,
                    isShowingLegendSheet: $isShowingLegendSheet,
                    onFit: { fitCameraToSavedLocations() }
                )
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
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingAddLocationSheet) {
                AddLocationSheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingLegendSheet) {
                FamilyLegendSheet(hiddenMemberIDs: $hiddenMemberIDs)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
                } else if isTimelapseActive {
                    TimelapsePanel(
                        isTimelapseActive: $isTimelapseActive,
                        timelapseStartDate: $timelapseStartDate,
                        timelapseEndDate: $timelapseEndDate,
                        timelapseCurrentDate: $timelapseCurrentDate,
                        locationRecords: locationRecords
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }
        }
    }

    // Filtered records reflecting the active legend selections and the time-lapse slider limit if active.
    private var filteredRecords: [LocationRecord] {
        let baseRecords = locationRecords.filter { record in
            if let member = record.member {
                return !hiddenMemberIDs.contains(member.id)
            }
            return true
        }
        
        if isTimelapseActive {
            return baseRecords.filter { record in
                record.timestamp >= timelapseStartDate && record.timestamp <= timelapseCurrentDate
            }
        }
        
        return baseRecords
    }

    // Latest location record for each non-hidden member.
    private var latestMemberRecords: [LocationRecord] {
        let baseRecords = locationRecords.filter { record in
            if let member = record.member {
                return !hiddenMemberIDs.contains(member.id)
            }
            return true
        }
        
        let grouped = Dictionary(grouping: baseRecords) { $0.member?.id }
        return grouped.values.compactMap { records in
            records.max(by: { $0.timestamp < $1.timestamp })
        }
    }

    // Latest check-in for each member up to the current simulated date during time-lapse mode.
    private var activeTimelapseMarkers: [LocationRecord] {
        let activeRecords = locationRecords.filter { record in
            if let member = record.member {
                return !hiddenMemberIDs.contains(member.id) &&
                       record.timestamp >= timelapseStartDate &&
                       record.timestamp <= timelapseCurrentDate
            }
            return false
        }
        
        let grouped = Dictionary(grouping: activeRecords) { $0.member?.id }
        return grouped.values.compactMap { records in
            records.max(by: { $0.timestamp < $1.timestamp })
        }
    }

    // The selected record is derived from MapKit's selected UUID and the latest SwiftData query result.
    private var selectedRecord: LocationRecord? {
        locationRecords.first { $0.id == selectedRecordID }
    }

    // The records to show on the map depending on active modes (timelapse, track record, or default latest).
    private var recordsToCluster: [LocationRecord] {
        if isTimelapseActive {
            return activeTimelapseMarkers
        } else if isTrackRecordActive {
            return filteredRecords
        } else {
            return latestMemberRecords
        }
    }

    private var clusters: [LocationCluster] {
        clusterLocations(recordsToCluster)
    }



    // Journey groups convert raw SwiftData records into MapKit-friendly polyline inputs.
    private var journeyGroups: [JourneyGroup] {
        let groupedRecords = Dictionary(grouping: filteredRecords) { record in
            record.member
        }

        let visibleMembers = groupedRecords.keys.compactMap { $0 }

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
                
                let stableId = generateStableClusterId(for: updatedRecords)
                clusters[index] = LocationCluster(
                    id: stableId,
                    coordinate: existingCluster.coordinate,
                    records: updatedRecords
                )
            } else {
                let stableId = generateStableClusterId(for: [record])
                clusters.append(LocationCluster(
                    id: stableId,
                    coordinate: record.coordinate,
                    records: [record]
                ))
            }
        }
        
        return clusters
    }

    private func generateStableClusterId(for records: [LocationRecord]) -> String {
        if isTimelapseActive {
            // Use member IDs so identity is tied to the moving member
            let memberIds = records.compactMap { $0.member?.id.uuidString }
            return memberIds.sorted().joined(separator: "-")
        } else {
            // Use record IDs
            let recordIds = records.map { $0.id.uuidString }
            return recordIds.sorted().joined(separator: "-")
        }
    }


}

#Preview {
    // The preview uses an in-memory SwiftData container so sample preview data never touches app storage.
    FamilyMapScreen()
        .modelContainer(for: [LocationRecord.self, FamilyMember.self], inMemory: true)
}
