//
//  SampleLocationRecords.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import Foundation

// SampleLocationRecords provides starter data while the full data-entry flow is still being built.
enum SampleLocationRecords {
    // This helper creates realistic sample records so the map can show markers and polylines on day three.
    static func makeRecords(relativeTo now: Date = Date()) -> [LocationRecord] {
        let calendar = Calendar.current

        return [
            LocationRecord(
                familyMemberName: "Aulia",
                cityName: "Jakarta",
                latitude: -6.2088,
                longitude: 106.8456,
                timestamp: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
                note: "Started the family journey from Jakarta."
            ),
            LocationRecord(
                familyMemberName: "Aulia",
                cityName: "Bandung",
                latitude: -6.9175,
                longitude: 107.6191,
                timestamp: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                note: "Weekend visit in Bandung."
            ),
            LocationRecord(
                familyMemberName: "Bima",
                cityName: "Surabaya",
                latitude: -7.2575,
                longitude: 112.7521,
                timestamp: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                note: "Current home city."
            ),
            LocationRecord(
                familyMemberName: "Bima",
                cityName: "Yogyakarta",
                latitude: -7.7956,
                longitude: 110.3695,
                timestamp: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                note: "Travel stop for the family timeline."
            )
        ]
    }
}
