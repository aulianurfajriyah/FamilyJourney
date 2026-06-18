//
//  MapOverlayContents.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import MapKit
import SwiftUI

// Location clustering structure
struct LocationCluster: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let records: [LocationRecord]
}

// This builder turns grouped SwiftData records into route overlays on the map.
struct JourneyPolylinesContent: MapContent {
    let isTrackRecordActive: Bool
    let journeyGroups: [JourneyGroup]
    
    var body: some MapContent {
        if isTrackRecordActive {
            ForEach(journeyGroups) { group in
                MapPolyline(coordinates: group.coordinates)
                    .stroke(group.color, lineWidth: 4)
            }
        }
    }
}

// This builder turns each SwiftData LocationRecord into one/grouped map annotations.
struct LocationMarkersContent: MapContent {
    let clusters: [LocationCluster]
    
    var body: some MapContent {
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
                        MemberAvatarView(member: member, size: 38, borderWidth: 3)
                            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                    } else {
                        MemberAvatarStackView(members: uniqueMembers, avatarSize: 32)
                    }
                }
            }
            .tag(latestRecord.id)
        }
    }
}
