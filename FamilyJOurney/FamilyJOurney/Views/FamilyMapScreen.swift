//
//  FamilyMapScreen.swift
//  FamilyJOurney
//
//  Created by Aulia Nur Fajriyah on 10/06/26.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

// FamilyMapScreen owns the SwiftData query, MapKit camera state, and marker selection state.
// Business logic is split across:
//   • FamilyMapScreen+DataLogic.swift  – computed properties, clustering, camera helpers
//   • FamilyMapScreen+Search.swift     – search results and flyTo helpers
// UI sub-components live in Views/Components/:
//   • MapUtilityButtons.swift          – top-trailing button cluster
//   • LongPressAlertOverlay.swift      – long-press action card
//   • FamilyMapToolbar.swift           – navigation bar buttons
struct FamilyMapScreen: View {

    // MARK: - SwiftData Queries

    /// All location records, sorted oldest-first so polylines draw in chronological order.
    @Query(sort: \LocationRecord.timestamp) var locationRecords: [LocationRecord]

    /// Querying members forces a re-render whenever name/color/emoji changes.
    @Query(sort: \FamilyMember.name) var members: [FamilyMember]

    /// Saved preset locations used for search.
    @Query(sort: \SavedLocation.name) var savedLocations: [SavedLocation]

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Map State

    @State var cameraPosition: MapCameraPosition = .region(Self.defaultRegion)
    @State var selectedRecordID: UUID?
    @Namespace var mapScope

    // MARK: - Mode Toggles

    @State var isTrackRecordActive = false

    // Timelapse
    @State var isTimelapseActive = false
    @State var timelapseStartDate = Date()
    @State var timelapseEndDate = Date()
    @State var timelapseCurrentDate = Date()

    // Hidden members (legend filter)
    @State var hiddenMemberIDs: Set<UUID> = []

    // MARK: - Sheet Context

    struct AddLocationSheetContext: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D?
    }

    struct PresetLocationSheetContext: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D?
    }

    @State private var isShowingLocationDetails = false
    @State private var isShowingLegendSheet = false
    @State private var addLocationContext: AddLocationSheetContext? = nil
    @State private var presetLocationContext: PresetLocationSheetContext? = nil

    // MARK: - Long-Press State

    /// A single optional drives the long-press alert. Using one variable instead of
    /// two (a Bool + an optional coordinate) avoids the flicker race condition.
    @State var longPressAlertCoordinate: CLLocationCoordinate2D? = nil

    // MARK: - Search State

    @State var searchText = ""
    @State var sheetPosition: SearchSheetPosition = .collapsed
    @State private var isShowingManagePresets = false
    @FocusState private var isSearchFieldFocused: Bool
    @StateObject private var searchCompleter = MapSearchCompleter()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mapLayer
                .overlay(alignment: .topTrailing) {
                    MapUtilityButtons(
                        isTrackRecordActive: $isTrackRecordActive,
                        isTimelapseActive: $isTimelapseActive,
                        mapScope: mapScope
                    )
                }
                .overlay(alignment: .bottom) { bottomOverlay }
                .navigationTitle("Family Journey")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    FamilyMapToolbar(
                        hasLocationRecords: !locationRecords.isEmpty,
                        onAddLocation: { addLocationContext = AddLocationSheetContext(coordinate: nil) },
                        isShowingLegendSheet: $isShowingLegendSheet,
                        onFit: { fitCameraToSavedLocations() }
                    )
                }
                .background(sheetBackground)
                .sheet(isPresented: Binding(
                    get: { !locationRecords.isEmpty && !isTimelapseActive },
                    set: { _ in }
                )) { searchSheet }
                .onChange(of: selectedRecordID) { _, newValue in
                    isShowingLocationDetails = newValue != nil
                }
                .onChange(of: locationRecords.map(\.id)) { _, _ in
                    fitCameraToSavedLocations()
                }
                .onChange(of: hiddenMemberIDs) { _, _ in
                    fitCameraToSavedLocations()
                }
                .onChange(of: isSearchFieldFocused) { _, isFocused in
                    if isFocused {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            sheetPosition = .medium
                        }
                    }
                }
                .onChange(of: searchText) { _, newValue in
                    searchCompleter.updateQuery(newValue)
                    if !newValue.isEmpty {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            sheetPosition = .large
                        }
                    }
                }
                .onChange(of: isShowingManagePresets) { _, newValue in
                    if newValue && presetLocationContext == nil {
                        presetLocationContext = PresetLocationSheetContext(coordinate: nil)
                    }
                }
                .onChange(of: presetLocationContext == nil) { _, isNil in
                    if isNil { isShowingManagePresets = false }
                }
        }
    }

    // MARK: - Map Layer

    /// The full-screen map wrapped in a MapReader for long-press coordinate conversion.
    private var mapLayer: some View {
        ZStack {
            MapReader { mapProxy in
                Map(position: $cameraPosition, selection: $selectedRecordID, scope: mapScope) {
                    JourneyPolylinesContent(
                        isTrackRecordActive: isTrackRecordActive,
                        journeyGroups: journeyGroups
                    )
                    LocationMarkersContent(clusters: clusters)
                }
                .mapScope(mapScope)
                .mapControls { MapScaleView() }
                .simultaneousGesture(longPressGesture(proxy: mapProxy))
            }

            // Long-press action card
            if let coordinate = longPressAlertCoordinate {
                LongPressAlertOverlay(
                    coordinate: coordinate,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            longPressAlertCoordinate = nil
                        }
                    },
                    onAddStop: { coord in
                        withAnimation(.easeInOut(duration: 0.15)) { longPressAlertCoordinate = nil }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            addLocationContext = AddLocationSheetContext(coordinate: coord)
                        }
                    },
                    onSavePreset: { coord in
                        withAnimation(.easeInOut(duration: 0.15)) { longPressAlertCoordinate = nil }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            presetLocationContext = PresetLocationSheetContext(coordinate: coord)
                        }
                    }
                )
                .transition(.scale(scale: 0.92).combined(with: .opacity))
                .zIndex(99)
            }
        }
    }

    /// Builds the sequenced long-press + drag gesture used to capture a map coordinate.
    private func longPressGesture(proxy: MapProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onEnded { value in
                // Reset first so any existing alert is dismissed before the new coordinate arrives.
                longPressAlertCoordinate = nil
                if case .second(true, let dragValue) = value, let drag = dragValue {
                    if let coordinate = proxy.convert(drag.location, from: .local) {
                        // Dispatch async so the nil-reset is committed to SwiftUI before
                        // we set the new coordinate, preventing a mid-render flicker.
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                longPressAlertCoordinate = coordinate
                            }
                        }
                    }
                }
            }
    }

    // MARK: - Bottom Overlay

    @ViewBuilder
    private var bottomOverlay: some View {
        if locationRecords.isEmpty {
            EmptyMapHint {
                addLocationContext = AddLocationSheetContext(coordinate: nil)
            }
            .padding()
        } else if isTimelapseActive {
            TimelapsePanel(
                isTimelapseActive: $isTimelapseActive,
                timelapseStartDate: $timelapseStartDate,
                timelapseEndDate: $timelapseEndDate,
                timelapseCurrentDate: $timelapseCurrentDate,
                locationRecords: locationRecords
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Sheet Background

    /// Attaches all sheet presentations to invisible Color.clear views so they don't
    /// interfere with the map's hit-testing.
    private var sheetBackground: some View {
        ZStack {
            Color.clear
                .sheet(isPresented: $isShowingLocationDetails) {
                    LocationDetailSheet(record: selectedRecord)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
            Color.clear
                .sheet(isPresented: $isShowingLegendSheet) {
                    FamilyLegendSheet(hiddenMemberIDs: $hiddenMemberIDs)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            Color.clear
                .sheet(item: $addLocationContext) { context in
                    AddLocationSheet(initialCoordinate: context.coordinate)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
            Color.clear
                .sheet(item: $presetLocationContext) { context in
                    ManageSavedLocationsSheet(initialCoordinate: context.coordinate)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
        }
    }

    // MARK: - Search Sheet

    private var searchSheet: some View {
        SearchBottomSheet(
            searchText: $searchText,
            sheetPosition: $sheetPosition,
            isShowingManagePresets: $isShowingManagePresets,
            isSearchFieldFocused: $isSearchFieldFocused,
            searchCompleter: searchCompleter,
            savedLocations: savedLocations,
            searchResults: searchResults,
            members: members,
            onSelectResult: { item in
                if item.subtitle == "fit_all" {
                    fitCameraToSavedLocations()
                    withAnimation { sheetPosition = .collapsed }
                } else {
                    flyTo(item)
                }
            },
            onSelectCompletion: { completion in
                flyTo(completion)
            }
        )
        .padding(sheetPosition == .collapsed ? 0 : 10)
        .presentationDetents([.height(80), .medium, .large], selection: nativeDetentBinding)
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .interactiveDismissDisabled()
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(50)
        .presentationBackground(.clear)
    }
}

#Preview {
    // The preview uses an in-memory SwiftData container so sample preview data never touches app storage.
    FamilyMapScreen()
        .modelContainer(for: [LocationRecord.self, FamilyMember.self], inMemory: true)
}
