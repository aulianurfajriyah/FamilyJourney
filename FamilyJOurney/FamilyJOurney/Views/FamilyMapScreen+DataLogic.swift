//
//  FamilyMapScreen+DataLogic.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import CoreLocation
import MapKit
import SwiftUI

// MARK: - Data & Clustering Logic
extension FamilyMapScreen {

    // MARK: Presentation Detent Bridge

    var nativeDetentBinding: Binding<PresentationDetent> {
        Binding<PresentationDetent>(
            get: {
                switch sheetPosition {
                case .collapsed: return .height(80)
                case .medium:    return .medium
                case .large:     return .large
                }
            },
            set: { newValue in
                if newValue == .medium {
                    sheetPosition = .medium
                } else if newValue == .large {
                    sheetPosition = .large
                } else {
                    sheetPosition = .collapsed
                }
            }
        )
    }

    // MARK: Filtered Record Sets

    var filteredRecords: [LocationRecord] {
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

    /// The single most-recent location record for each non-hidden member.
    var latestMemberRecords: [LocationRecord] {
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

    /// Latest check-in for each member up to the current simulated date during time-lapse mode.
    var activeTimelapseMarkers: [LocationRecord] {
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

    /// The record currently selected via MapKit's selection binding.
    var selectedRecord: LocationRecord? {
        locationRecords.first { $0.id == selectedRecordID }
    }

    /// The records fed into the clustering algorithm, depending on the active view mode.
    var recordsToCluster: [LocationRecord] {
        if isTimelapseActive {
            return activeTimelapseMarkers
        } else if isTrackRecordActive {
            return filteredRecords
        } else {
            return latestMemberRecords
        }
    }

    var clusters: [LocationCluster] {
        clusterLocations(recordsToCluster)
    }

    // MARK: Journey Groups

    /// Converts raw SwiftData records into MapKit-friendly polyline inputs.
    var journeyGroups: [JourneyGroup] {
        let groupedRecords = Dictionary(grouping: filteredRecords) { record in
            record.member
        }

        let visibleMembers = groupedRecords.keys.compactMap { $0 }

        return visibleMembers.sorted(by: { $0.name < $1.name }).compactMap { member in
            guard let records = groupedRecords[member] else { return nil }

            let sortedRecords = records.sorted { $0.timestamp < $1.timestamp }

            return JourneyGroup(
                memberName: member.name,
                color: member.color,
                coordinates: sortedRecords.map(\.coordinate)
            )
        }
    }

    // MARK: Camera

    /// Moves the map camera to a region that encompasses all visible saved records.
    func fitCameraToSavedLocations() {
        let visibleRecords = locationRecords.filter { record in
            if let member = record.member {
                return !hiddenMemberIDs.contains(member.id)
            }
            return true
        }
        let region = MKCoordinateRegion.region(fitting: visibleRecords, defaultRegion: Self.defaultRegion)
        cameraPosition = .region(region)
    }

    /// Default region centred on Indonesia, shown before any SwiftData records exist.
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -2.5489, longitude: 118.0149),
        span: MKCoordinateSpan(latitudeDelta: 25, longitudeDelta: 35)
    )

    // MARK: Clustering

    /// Groups nearby records into clusters within the given radius.
    func clusterLocations(_ records: [LocationRecord], radiusMeters: Double = 50.0) -> [LocationCluster] {
        var clusters: [LocationCluster] = []

        for record in records {
            let recordLoc = CLLocation(latitude: record.latitude, longitude: record.longitude)

            if let index = clusters.firstIndex(where: { cluster in
                let clusterLoc = CLLocation(
                    latitude: cluster.coordinate.latitude,
                    longitude: cluster.coordinate.longitude
                )
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

    func generateStableClusterId(for records: [LocationRecord]) -> String {
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
