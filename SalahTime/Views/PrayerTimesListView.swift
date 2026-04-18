import SwiftUI

// MARK: - Prayer Times List View

/// Displays all 6 prayer times with the next prayer highlighted
struct PrayerTimesListView: View {
    let prayerTimes: [PrayerTime]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(prayerTimes.enumerated()), id: \.element.id) { index, pt in
                PrayerTimeRow(prayerTime: pt)

                // Subtle separator between rows (not after last)
                if index < prayerTimes.count - 1 {
                    Rectangle()
                        .fill(SalahColors.tealAccent.opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.horizontal, 12)
                }
            }
        }
        .padding(.vertical, 4)
        .glassCard()
    }
}

// MARK: - Prayer Time Row

struct PrayerTimeRow: View {
    let prayerTime: PrayerTime

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Prayer icon
            Image(systemName: prayerTime.prayer.icon)
                .font(.system(size: SalahLayout.iconSize))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            // Prayer names
            VStack(alignment: .leading, spacing: 1) {
                Text(prayerTime.prayer.englishName)
                    .font(SalahTypography.bodyMedium)
                    .foregroundStyle(textColor)

                Text(prayerTime.prayer.arabicName)
                    .font(SalahTypography.caption)
                    .foregroundStyle(arabicTextColor)
            }

            Spacer()

            // Time
            Text(prayerTime.formattedTime)
                .font(SalahTypography.countdownSmall)
                .foregroundStyle(timeColor)

            // Next prayer indicator
            if prayerTime.isNext {
                Circle()
                    .fill(SalahColors.goldAccent)
                    .frame(width: 6, height: 6)
                    .shadow(color: SalahColors.goldAccent.opacity(0.5), radius: 4)
            }
        }
        .padding(.horizontal, SalahLayout.cardPadding)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: SalahLayout.cornerRadiusSmall)
                .fill(rowBackground)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    // MARK: - Colors

    private var iconColor: Color {
        if prayerTime.isNext { return SalahColors.goldAccent }
        if prayerTime.isPassed { return SalahColors.dimGray }
        return SalahColors.tealAccent
    }

    private var textColor: Color {
        if prayerTime.isNext { return SalahColors.pureWhite }
        if prayerTime.isPassed { return SalahColors.dimGray }
        return SalahColors.softWhite
    }

    private var arabicTextColor: Color {
        if prayerTime.isNext { return SalahColors.warmGold }
        if prayerTime.isPassed { return SalahColors.passedPrayer }
        return SalahColors.softGray
    }

    private var timeColor: Color {
        if prayerTime.isNext { return SalahColors.goldAccent }
        if prayerTime.isPassed { return SalahColors.dimGray }
        return SalahColors.tealSoft
    }

    private var rowBackground: Color {
        if prayerTime.isNext {
            return SalahColors.goldAccent.opacity(isHovered ? 0.12 : 0.06)
        }
        return isHovered ? SalahColors.tealAccent.opacity(0.06) : Color.clear
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        SalahColors.deepEmerald
        PrayerTimesListView(
            prayerTimes: [
                PrayerTime(prayer: .fajr, time: Date().addingTimeInterval(-3600 * 10), isPassed: true),
                PrayerTime(prayer: .sunrise, time: Date().addingTimeInterval(-3600 * 8), isPassed: true),
                PrayerTime(prayer: .dhuhr, time: Date().addingTimeInterval(-3600 * 4), isPassed: true),
                PrayerTime(prayer: .asr, time: Date().addingTimeInterval(3600), isNext: true),
                PrayerTime(prayer: .maghrib, time: Date().addingTimeInterval(3600 * 4)),
                PrayerTime(prayer: .isha, time: Date().addingTimeInterval(3600 * 6)),
            ]
        )
        .padding()
    }
    .frame(width: 320, height: 400)
}
