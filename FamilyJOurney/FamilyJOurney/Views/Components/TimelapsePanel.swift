//
//  TimelapsePanel.swift
//  FamilyJOurney
//
//  Created by Antigravity on 17/06/26.
//

import Combine
import SwiftUI

struct TimelapsePanel: View {
    @Binding var isTimelapseActive: Bool
    @Binding var timelapseStartDate: Date
    @Binding var timelapseEndDate: Date
    @Binding var timelapseCurrentDate: Date

    let locationRecords: [LocationRecord]

    @State private var isPlaybackActive = false
    @State private var playbackSpeed: Double = 1.0

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 14) {
            // Header Row
            HStack {
                Label("Timelapse Simulation", systemImage: "clock.arrow.2.circlepath")
                    .font(.headline)
                    .foregroundStyle(.tint)
                Spacer()
                Button {
                    isTimelapseActive = false
                    isPlaybackActive = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .background(Color.primary.opacity(0.1))
            
            // Date Selection Ranges - Stacked Vertically to prevent clipping/collision
            VStack(spacing: 10) {
                DatePicker("Start Time", selection: $timelapseStartDate, in: ...timelapseEndDate, displayedComponents: [.date, .hourAndMinute])
                    .font(.subheadline)
                    .onChange(of: timelapseStartDate) { _, _ in
                        if timelapseCurrentDate < timelapseStartDate {
                            timelapseCurrentDate = timelapseStartDate
                        }
                    }
                
                DatePicker("End Time", selection: $timelapseEndDate, in: timelapseStartDate..., displayedComponents: [.date, .hourAndMinute])
                    .font(.subheadline)
                    .onChange(of: timelapseEndDate) { _, _ in
                        if timelapseCurrentDate > timelapseEndDate {
                            timelapseCurrentDate = timelapseEndDate
                        }
                    }
            }
            
            // Simulation Current Time Stamp Display
            Text(timelapseCurrentDate.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.vertical, 2)
            
            // Scrubbing Progress Slider
            let duration = max(1.0, timelapseEndDate.timeIntervalSince(timelapseStartDate))
            let sliderBinding = Binding<Double>(
                get: { timelapseCurrentDate.timeIntervalSince(timelapseStartDate) },
                set: { newValue in
                    timelapseCurrentDate = timelapseStartDate.addingTimeInterval(newValue)
                }
            )
            Slider(value: sliderBinding, in: 0...duration)
                .tint(.accentColor)
            
            // Playback controls
            HStack {
                Button {
                    if timelapseCurrentDate >= timelapseEndDate {
                        timelapseCurrentDate = timelapseStartDate
                    }
                    isPlaybackActive.toggle()
                } label: {
                    Image(systemName: isPlaybackActive ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.accentColor))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Picker("Speed", selection: $playbackSpeed) {
                    Text("1x").tag(1.0)
                    Text("2x").tag(2.0)
                    Text("5x").tag(5.0)
                    Text("10x").tag(10.0)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
        .onReceive(timer) { _ in
            guard isPlaybackActive else { return }
            advanceTimelapse()
        }
        .onAppear {
            initializeDates()
        }
    }

    private func initializeDates() {
        if let oldest = locationRecords.min(by: { $0.timestamp < $1.timestamp }),
           let newest = locationRecords.max(by: { $0.timestamp < $1.timestamp }) {
            timelapseStartDate = oldest.timestamp
            timelapseEndDate = newest.timestamp
        } else {
            timelapseStartDate = Date().addingTimeInterval(-86400 * 7)
            timelapseEndDate = Date()
        }
        timelapseCurrentDate = timelapseStartDate
    }

    private func advanceTimelapse() {
        let totalDuration = timelapseEndDate.timeIntervalSince(timelapseStartDate)
        // Advance step size is proportional to speed and duration, taking ~20 seconds at 1x speed.
        let step = max(60.0, (totalDuration / 200.0) * playbackSpeed)
        let nextDate = timelapseCurrentDate.addingTimeInterval(step)
        
        withAnimation(.easeInOut(duration: 0.25)) {
            if nextDate >= timelapseEndDate {
                timelapseCurrentDate = timelapseEndDate
                isPlaybackActive = false
            } else {
                timelapseCurrentDate = nextDate
            }
        }
    }
}
