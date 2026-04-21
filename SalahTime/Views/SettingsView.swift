//
//  SettingsView.swift
//  SalahTime
//
//  Created by Hazlan Muhammad Qodri on 21/04/26.
//

import SwiftUI
import AppKit
import ServiceManagement
import UniformTypeIdentifiers

// MARK: - Settings View

/// Inline settings panel that slides in from the right within the popover
struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(NotificationManager.self) private var notificationManager

    @State private var latitudeText: String = ""
    @State private var longitudeText: String = ""
    @State private var cityText: String = ""

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 8) {
                // Header
                settingsHeader

                // Display Section
                displaySection

                // Prayer Calculation Section
                calculationSection

                // Location Section
                locationSection

                // Notifications Section
                notificationSection

                // Adhan Audio Section
                adhanSection

                // General Section
                generalSection

                // App Info
                appInfoSection
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        HStack {
            Text("Settings")
                .font(SalahTypography.title)
                .foregroundStyle(SalahColors.pureWhite)
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Display

    private var displaySection: some View {
        SettingsSection(title: "Display", icon: "display") {
            Picker("Menubar Style", selection: $settings.menuBarDisplayMode) {
                ForEach(MenuBarDisplayMode.allCases, id: \.rawValue) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .colorMultiply(SalahColors.tealAccent)
        }
    }

    // MARK: - Calculation Method

    private var calculationSection: some View {
        SettingsSection(title: "Calculation Method", icon: "function") {
            Picker("Method", selection: $settings.calculationMethod) {
                ForEach(CalculationMethodSetting.allCases, id: \.rawValue) { method in
                    Text(method.displayName).tag(method)
                }
            }
            .labelsHidden()
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        SettingsSection(title: "Location", icon: "location") {
            Toggle("Auto-detect location", isOn: $settings.useAutoLocation)
                .toggleStyle(.switch)
                .tint(SalahColors.tealAccent)

            if !settings.useAutoLocation {
                VStack(spacing: 8) {
                    TextField("City name", text: $cityText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            settings.manualCityName = cityText
                        }

                    HStack(spacing: 8) {
                        TextField("Latitude", text: $latitudeText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if let lat = Double(latitudeText) {
                                    settings.manualLatitude = lat
                                }
                            }

                        TextField("Longitude", text: $longitudeText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if let lng = Double(longitudeText) {
                                    settings.manualLongitude = lng
                                }
                            }
                    }
                }
                .font(SalahTypography.caption)
            }
        }
        .onAppear {
            latitudeText = settings.manualLatitude != 0 ? String(settings.manualLatitude) : ""
            longitudeText = settings.manualLongitude != 0 ? String(settings.manualLongitude) : ""
            cityText = settings.manualCityName
        }
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        SettingsSection(title: "Notifications", icon: "bell") {
            if !notificationManager.isPermissionGranted {
                Button("Enable Notifications") {
                    notificationManager.requestPermission()
                }
                .buttonStyle(.borderedProminent)
                .tint(SalahColors.tealAccent)
            }

            // Pre-reminder
            HStack {
                Text("Remind before")
                    .font(SalahTypography.body)
                    .foregroundStyle(SalahColors.softWhite)

                Spacer()

                Picker("", selection: $settings.preReminderMinutes) {
                    Text("Off").tag(0)
                    Text("5 min").tag(5)
                    Text("10 min").tag(10)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                }
                .frame(width: 100)
            }

            // Per-prayer toggles
            VStack(spacing: 4) {
                ForEach(Prayer.allCases) { prayer in
                    PrayerNotificationToggle(
                        prayer: prayer,
                        settings: settings
                    )
                }
            }
        }
    }

    // MARK: - Adhan

    private var adhanSection: some View {
        SettingsSection(title: "Adhan Audio", icon: "speaker.wave.3") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(settings.customAdhanURL != nil ? "Custom Adhan" : "Default Adhan")
                        .font(SalahTypography.bodyMedium)
                        .foregroundStyle(SalahColors.softWhite)

                    if let url = settings.customAdhanURL {
                        Text(url.lastPathComponent)
                            .font(SalahTypography.caption)
                            .foregroundStyle(SalahColors.softGray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if settings.customAdhanURL != nil {
                    Button("Reset") {
                        settings.customAdhanBookmarkData = nil
                    }
                    .font(SalahTypography.caption)
                    .foregroundStyle(SalahColors.softGray)
                }

                Button("Choose File") {
                    importCustomAdhan()
                }
                .buttonStyle(.bordered)
                .font(SalahTypography.caption)
            }
        }
    }

    // MARK: - General

    private var generalSection: some View {
        SettingsSection(title: "General", icon: "gearshape") {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .toggleStyle(.switch)
                .tint(SalahColors.tealAccent)
        }
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        VStack(spacing: 4) {
            Text("Salah Time")
                .font(SalahTypography.captionMedium)
                .foregroundStyle(SalahColors.softGray)

            Text("v1.0.0")
                .font(SalahTypography.caption)
                .foregroundStyle(SalahColors.dimGray)

            Text("بسم الله الرحمن الرحيم")
                .font(SalahTypography.arabic)
                .foregroundStyle(SalahColors.warmGold.opacity(0.5))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Custom Adhan Import

    private func importCustomAdhan() {
        let panel = NSOpenPanel()
        panel.title = "Choose Adhan Audio File"
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            // Create security-scoped bookmark for persistent access
            if let bookmarkData = try? url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                settings.customAdhanBookmarkData = bookmarkData
            }
        }
    }
}

// MARK: - Settings Section

/// Reusable settings section with title and icon
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(SalahColors.tealAccent)
                Text(title)
                    .font(SalahTypography.captionMedium)
                    .foregroundStyle(SalahColors.tealAccent)
            }

            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(10)
            .glassCard(cornerRadius: SalahLayout.cornerRadiusSmall)
        }
    }
}

// MARK: - Per-Prayer Notification Toggle

struct PrayerNotificationToggle: View {
    let prayer: Prayer
    @Bindable var settings: AppSettings

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: prayer.icon)
                .font(.system(size: 12))
                .foregroundStyle(SalahColors.softGray)
                .frame(width: 18)

            Text(prayer.englishName)
                .font(SalahTypography.body)
                .foregroundStyle(SalahColors.softWhite)

            Spacer()

            // Notification toggle
            Toggle("", isOn: Binding(
                get: { settings.isNotificationEnabled(for: prayer) },
                set: { settings.setNotification(for: prayer, enabled: $0) }
            ))
            .toggleStyle(.switch)
            .tint(SalahColors.tealAccent)
            .scaleEffect(0.7)
            .labelsHidden()

            // Adhan toggle (only if notification enabled)
            if settings.isNotificationEnabled(for: prayer) && prayer.isActualPrayer {
                Toggle("", isOn: Binding(
                    get: { settings.isAdhanEnabled(for: prayer) },
                    set: { settings.setAdhan(for: prayer, enabled: $0) }
                ))
                .toggleStyle(.switch)
                .tint(SalahColors.goldAccent)
                .scaleEffect(0.7)
                .labelsHidden()

                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(
                        settings.isAdhanEnabled(for: prayer)
                            ? SalahColors.goldAccent
                            : SalahColors.dimGray
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        SalahColors.deepEmerald
        SettingsView(settings: AppSettings.shared)
            .environment(NotificationManager())
    }
    .frame(width: 320, height: 520)
}
