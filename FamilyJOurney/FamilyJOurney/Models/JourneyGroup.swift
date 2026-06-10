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
    // The member name is stable enough for this MVP's ForEach identity.
    var id: String { memberName }

    // The family member whose records form this route.
    let memberName: String

    // The route color matches this member's marker color.
    let color: Color

    // MapPolyline needs coordinates, so records are converted before rendering.
    let coordinates: [CLLocationCoordinate2D]
}
