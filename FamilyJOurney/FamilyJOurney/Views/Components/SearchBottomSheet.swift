//
//  SearchBottomSheet.swift
//  FamilyJOurney
//
//  Created by Antigravity on 18/06/26.
//

import MapKit
import SwiftUI

struct SearchBottomSheet: View {
    @Binding var searchText: String
    @Binding var sheetPosition: SearchSheetPosition
    @Binding var isShowingManagePresets: Bool
    @FocusState.Binding var isSearchFieldFocused: Bool
    
    @ObservedObject var searchCompleter: MapSearchCompleter
    
    let savedLocations: [SavedLocation]
    let searchResults: [SearchResultItem]
    let members: [FamilyMember]
    
    let onSelectResult: (SearchResultItem) -> Void
    let onSelectCompletion: (MKLocalSearchCompletion) -> Void
    
    private var homePreset: SavedLocation? {
        savedLocations.first { $0.name.localizedCaseInsensitiveContains("home") }
    }
    
    private var workPreset: SavedLocation? {
        savedLocations.first { $0.name.localizedCaseInsensitiveContains("work") }
    }
    

    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    
                    
                    TextField("Search stops or preset locations...", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFieldFocused)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                               
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // if sheetPosition != .collapsed {
                    //     Button("Cancel") {
                    //         searchText = ""
                    //         isSearchFieldFocused = false
                    //         withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    //             sheetPosition = .collapsed
                    //         }
                    //     }
                    //     .foregroundColor(.accentColor)
                    //     .font(.body)
                    // } else {
                    //     Image(systemName: "person.crop.circle.fill")
                    //         .font(.title2)
                    //         .foregroundColor(.secondary)
                    // }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground)).opacity(0.4)
                .cornerRadius(30)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
            
            // Expanded content (VStack / ScrollView)
            if sheetPosition != .collapsed {
                if searchText.isEmpty {
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Places Section
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Places")
                                        .font(.headline)
                                        .fontWeight(.bold)
//                                    Image(systemName: "chevron.right")
//                                        .font(.subheadline)
//                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                HStack(spacing: 10) {
                                    PlaceItemView(
                                        name: "Home",
                                        icon: "house.fill",
                                        isAdded: homePreset != nil,
                                        action: {
                                            if let home = homePreset {
                                                onSelectResult(SearchResultItem(
                                                    id: home.id.uuidString,
                                                    title: home.name,
                                                    subtitle: "Preset Location",
                                                    systemImage: "house.fill",
                                                    coordinate: CLLocationCoordinate2D(latitude: home.latitude, longitude: home.longitude)
                                                ))
                                            } else {
                                                isShowingManagePresets = true
                                            }
                                        }
                                    )
                                    
                                    PlaceItemView(
                                        name: "Work",
                                        icon: "briefcase.fill",
                                        isAdded: workPreset != nil,
                                        action: {
                                            if let work = workPreset {
                                                onSelectResult(SearchResultItem(
                                                    id: work.id.uuidString,
                                                    title: work.name,
                                                    subtitle: "Preset Location",
                                                    systemImage: "briefcase.fill",
                                                    coordinate: CLLocationCoordinate2D(latitude: work.latitude, longitude: work.longitude)
                                                ))
                                            } else {
                                                isShowingManagePresets = true
                                            }
                                        }
                                    )
                                    
                                    PlaceItemView(
                                        name: "Add",
                                        icon: "plus",
                                        isAdded: false,
                                        action: {
                                            isShowingManagePresets = true
                                        }
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            // Members Section
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Members")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Spacer()
                                        .padding(.bottom, 20)
                                }
                                .padding(.horizontal, 20)
                                
                                if members.isEmpty {
                                    Text("No family members found.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 20)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(members) { member in
                                                MemberSearchItemView(member: member) {
                                                    if let latestStop = member.locations?.max(by: { $0.timestamp < $1.timestamp }) {
                                                        onSelectResult(SearchResultItem(
                                                            id: latestStop.id.uuidString,
                                                            title: latestStop.cityName,
                                                            subtitle: "Stop by \(member.name)",
                                                            systemImage: "mappin.circle.fill",
                                                            coordinate: CLLocationCoordinate2D(latitude: latestStop.latitude, longitude: latestStop.longitude)
                                                        ))
                                                    } else {
                                                        // Callback to fit all locations
                                                        onSelectResult(SearchResultItem(
                                                            id: "",
                                                            title: "",
                                                            subtitle: "fit_all",
                                                            systemImage: "",
                                                            coordinate: CLLocationCoordinate2D()
                                                        ))
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 8)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    // Search Results List (when typing keyword)
                    if searchCompleter.completions.isEmpty && searchResults.isEmpty {
                        VStack {
                            Spacer()
                            Image(systemName: "mappin.slash")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                                .padding(.bottom, 4)
                            Text("No locations found for \"\(searchText)\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                if !searchCompleter.completions.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Map Suggestions")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 4)
                                        
                                        ForEach(searchCompleter.completions, id: \.self) { completion in
                                            Button {
                                                isSearchFieldFocused = false
                                                onSelectCompletion(completion)
                                            } label: {
                                                HStack(spacing: 12) {
                                                    Image(systemName: "mappin.and.ellipse")
                                                        .font(.title3)
                                                        .foregroundColor(.accentColor)
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(completion.title)
                                                            .font(.body)
                                                            .foregroundColor(.primary)
                                                        Text(completion.subtitle)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Divider()
                                                .padding(.leading, 44)
                                        }
                                    }
                                }
                                
                                if !searchResults.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Local Stops & Presets")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 16)
                                            .padding(.top, 4)
                                        
                                        ForEach(searchResults) { item in
                                            Button {
                                                isSearchFieldFocused = false
                                                onSelectResult(item)
                                            } label: {
                                                HStack(spacing: 12) {
                                                    Image(systemName: item.systemImage)
                                                        .font(.title3)
                                                        .foregroundColor(.accentColor)
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(item.title)
                                                            .font(.body)
                                                            .foregroundColor(.primary)
                                                        Text(item.subtitle)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    Spacer()
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 16)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Divider()
                                                .padding(.leading, 44)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
}
