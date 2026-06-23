//
//  JourneyGroup.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import CoreLocation
import SwiftUI

// JourneyGroup is a view-only shape that makes SwiftData records easy for MapPolyline to consume.
struct JourneyGroup: Identifiable {
  
    var id: String { memberName }
    let memberName: String
    let color: Color
    let coordinates: [CLLocationCoordinate2D]
}
