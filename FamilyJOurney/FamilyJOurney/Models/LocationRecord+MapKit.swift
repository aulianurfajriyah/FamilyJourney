//
//  LocationRecord+MapKit.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import CoreLocation

// This extension keeps MapKit conversion close to the SwiftData model that owns the values.
extension LocationRecord {
    // MapKit works with CLLocationCoordinate2D, while SwiftData stores latitude and longitude separately.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
