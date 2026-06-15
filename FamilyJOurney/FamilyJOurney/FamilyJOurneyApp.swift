//
//  FamilyJOurneyApp.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import SwiftData
import SwiftUI

// FamilyJOurneyApp is the app entry point that installs the SwiftData container.
@main
struct FamilyJOurneyApp: App {
    // The scene creates the first SwiftUI window for the learning app.
    var body: some Scene {
        WindowGroup {
            // ContentView can read and write LocationRecord data through the model container below.
            ContentView()
        }
        // The model container stores location and family member objects and makes @Query work throughout the view tree.
        .modelContainer(for: [LocationRecord.self, FamilyMember.self, SavedLocation.self])
    }
}
