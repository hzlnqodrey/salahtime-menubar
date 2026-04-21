import SwiftUI

// MARK: - Popover View

/// Main container view for the menubar popover
/// Displays prayer times, countdown, Qibla, and inline settings
struct PopoverView: View {
    @Environment(PrayerTimeManager.self) private var prayerManager
    @Environment(LocationManager.self) private var locationManager
    @Environment(NotificationManager.self) private var notificationManager
    @State private var settings = AppSettings.shared

    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Background: Native Apple glassmorphism with emerald tint
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Subtle emerald tint overlay
            SalahColors.deepEmerald.opacity(0.75)
                .ignoresSafeArea()

            // Islamic pattern overlay
            IslamicPatternView()
                .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                if showSettings {
                    // Settings view with slide transition
                    VStack(spacing: 0) {
                        // Back button
                        HStack {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showSettings = false
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Back")
                                        .font(SalahTypography.bodyMedium)
                                }
                                .foregroundStyle(SalahColors.tealAccent)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }
                        .padding(.horizontal, SalahLayout.cardPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                        SettingsView(settings: settings)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
                } else {
                    // Main content
                    mainContent
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .leading)
                        ))
                }
            }
        }
        .frame(width: SalahLayout.popoverWidth)
        .frame(maxHeight: SalahLayout.popoverMaxHeight)
        .onAppear {
            setupApp()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: SalahLayout.sectionSpacing) {
                // Settings gear button (top right)
                HStack {
                    // Decorative crescent
                    CrescentView(size: 18, color: SalahColors.goldAccent.opacity(0.3))

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showSettings = true
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SalahColors.softGray)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                .padding(.horizontal, SalahLayout.cardPadding)
                .padding(.top, 8)

                // Header (Hijri + Gregorian dates + location)
                HeaderView(
                    hijriDate: HijriDateCalculator.todayHijri(),
                    hijriDateArabic: HijriDateCalculator.todayHijriArabic(),
                    gregorianDate: HijriDateCalculator.todayGregorian(),
                    cityName: locationManager.effectiveCityName,
                    specialDay: HijriDateCalculator.specialDay()
                )

                // Next Prayer Highlight
                NextPrayerView(
                    prayer: prayerManager.nextPrayer,
                    countdownString: prayerManager.countdownString,
                    progress: prayerManager.progress
                )
                .padding(.horizontal, SalahLayout.cardPadding)

                // All Prayer Times
                PrayerTimesListView(prayerTimes: prayerManager.allPrayerTimes)
                    .padding(.horizontal, SalahLayout.cardPadding)

                // Qibla Compass
                QiblaCompassView(
                    bearing: QiblaCalculator.bearing(
                        latitude: locationManager.effectiveLatitude,
                        longitude: locationManager.effectiveLongitude
                    ),
                    compassDirection: QiblaCalculator.compassDirection(
                        bearing: QiblaCalculator.bearing(
                            latitude: locationManager.effectiveLatitude,
                            longitude: locationManager.effectiveLongitude
                        )
                    )
                )
                .padding(.horizontal, SalahLayout.cardPadding)

                // Error message if any
                if let error = prayerManager.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                        Text(error)
                            .font(SalahTypography.caption)
                    }
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, SalahLayout.cardPadding)
                }

                // Bottom bismillah
                Text("بسم الله الرحمن الرحيم")
                    .font(.system(size: 11))
                    .foregroundStyle(SalahColors.warmGold.opacity(0.25))
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Setup

    private func setupApp() {
        // Request permissions
        locationManager.requestLocation()
        notificationManager.requestPermission()

        // Calculate prayer times when location is available
        if locationManager.hasValidLocation {
            calculateAndSchedule()
        }

        // Observe location changes
        observeLocationChanges()

        // Observe midnight recalculation
        NotificationCenter.default.addObserver(
            forName: .midnightRecalculation,
            object: nil,
            queue: .main
        ) { _ in
            calculateAndSchedule()
        }

        // Observe settings changes that require recalculation
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            calculateAndSchedule()
        }
    }

    private func observeLocationChanges() {
        // Poll for location availability (simple approach for initial setup)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if locationManager.hasValidLocation {
                calculateAndSchedule()
                timer.invalidate()
            }
        }
    }

    private func calculateAndSchedule() {
        prayerManager.calculatePrayerTimes(
            latitude: locationManager.effectiveLatitude,
            longitude: locationManager.effectiveLongitude
        )
        notificationManager.scheduleNotifications(for: prayerManager.allPrayerTimes)
    }
}

// MARK: - Preview

#Preview {
    PopoverView()
        .environment(PrayerTimeManager())
        .environment(LocationManager())
        .environment(NotificationManager())
}
