//
//  ContentView.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import SwiftData
import SwiftUI

// ContentView stays small and acts as the app's first screen entry point.
struct ContentView: View {
    // The body delegates the real map work to a dedicated screen file.
    var body: some View {
        FamilyMapScreen()
    }
}

#Preview {
    // The preview uses an in-memory SwiftData container so preview data never touches app storage.
    ContentView()
        .modelContainer(for: LocationRecord.self, inMemory: true)
}
