//
//  SearchResultItem.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import CoreLocation

struct SearchResultItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let coordinate: CLLocationCoordinate2D
}
