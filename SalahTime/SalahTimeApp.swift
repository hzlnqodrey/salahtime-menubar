//
//  SalahTimeApp.swift
//  SalahTime
//
//  Created by Hazlan Muhammad Qodri on 19/04/26.
//

import SwiftUI
import ServiceManagement

// MARK: - App Entry Point

@main
struct SalahTimeApp: App {
    // MARK: - State
    
    @State private var prayerManager = PrayerTimeManager()
    @State private var locationManager = LocationManager()
    @State private var notificationManager = NotificationManager()
    @State private var settings = AppSettings.shared
    
    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(prayerManager)
                .environment(locationManager)
                .environment(notificationManager)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }
    
    // MARK: - Menubar Label
    
    @ViewBuilder
    private var menuBarLabel: some View {
        switch settings.menuBarDisplayMode {
        case .iconOnly:
            Label("Salah Time", systemImage: "moon.stars.fill")
                .labelStyle(.iconOnly)
            
        case .iconAndPrayer:
            if let next = prayerManager.nextPrayer {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                    Text("\(next.prayer.englishName) \(prayerManager.countdownString)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
            }
            else {
                Label("Salah Time", systemImage: "moon.stars.fill")
                    .labelStyle(.iconOnly)
            }
        default:
            Label("Salah Time", systemImage: "moon.stars.fill")
                .labelStyle(.iconOnly)
        }
    }
    
    // MARK: - Init
    
    init() {
        // Register for launch at login if enabled
        if AppSettings.shared.launchAtLogin {
            try? SMAppService.mainApp.register()
        }
    }
}
