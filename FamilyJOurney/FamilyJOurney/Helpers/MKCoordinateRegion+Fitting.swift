//
//  MKCoordinateRegion+Fitting.swift
//  FamilyJOurney
//
//  Created by Antigravity on 10/06/26.
//

import MapKit

extension MKCoordinateRegion {
    // This helper calculates a region that fits all location records.
    static func region(fitting locationRecords: [LocationRecord], defaultRegion: MKCoordinateRegion) -> MKCoordinateRegion {
        guard !locationRecords.isEmpty else {
            return defaultRegion
        }

        let latitudes = locationRecords.map(\.latitude)
        let longitudes = locationRecords.map(\.longitude)
        
        let minimumLatitude = latitudes.min() ?? defaultRegion.center.latitude
        let maximumLatitude = latitudes.max() ?? defaultRegion.center.latitude
        let minimumLongitude = longitudes.min() ?? defaultRegion.center.longitude
        let maximumLongitude = longitudes.max() ?? defaultRegion.center.longitude
        
        let center = CLLocationCoordinate2D(
            latitude: (minimumLatitude + maximumLatitude) / 2,
            longitude: (minimumLongitude + maximumLongitude) / 2
        )
        
        // Pad the region slightly so markers aren't right on the edge.
        let span = MKCoordinateSpan(
            latitudeDelta: max((maximumLatitude - minimumLatitude) * 1.8, 2.5),
            longitudeDelta: max((maximumLongitude - minimumLongitude) * 1.8, 2.5)
        )

        return MKCoordinateRegion(center: center, span: span)
    }
}
