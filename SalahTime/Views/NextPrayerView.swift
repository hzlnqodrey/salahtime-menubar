import SwiftUI

// MARK: - Next Prayer View

/// Prominent card showing the next prayer with animated countdown and progress ring
struct NextPrayerView: View {
    let prayer: PrayerTime?
    let countdownString: String
    let progress: Double

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 10) {
            if let prayer = prayer {
                // Prayer name
                HStack(spacing: 8) {
                    Image(systemName: prayer.prayer.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(SalahColors.goldAccent)
                        .symbolEffect(.pulse, options: .repeating, value: isAnimating)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(prayer.prayer.englishName)
                            .font(SalahTypography.headline)
                            .foregroundStyle(SalahColors.pureWhite)
                        Text(prayer.prayer.arabicName)
                            .font(SalahTypography.arabic)
                            .foregroundStyle(SalahColors.softGray)
                    }

                    Spacer()

                    Text(prayer.formattedTime)
                        .font(SalahTypography.bodyMedium)
                        .foregroundStyle(SalahColors.tealAccent)
                }

                // Countdown with progress ring
                HStack(spacing: 16) {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(SalahColors.emeraldGlow, lineWidth: 3)
                            .frame(width: 52, height: 52)

                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(
                                SalahColors.goldGradient,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 52, height: 52)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: progress)

                        Image(systemName: prayer.prayer.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(SalahColors.goldAccent)
                    }

                    // Countdown timer
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time Remaining")
                            .font(SalahTypography.caption)
                            .foregroundStyle(SalahColors.softGray)

                        Text(countdownString)
                            .font(SalahTypography.countdown)
                            .foregroundStyle(SalahColors.pureWhite)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.linear(duration: 0.3), value: countdownString)
                    }

                    Spacer()
                }
            } else {
                // No next prayer (all passed — edge case near midnight)
                VStack(spacing: 6) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(SalahColors.goldAccent)
                    Text("All prayers completed")
                        .font(SalahTypography.bodyMedium)
                        .foregroundStyle(SalahColors.softGray)
                    Text("Alhamdulillah ❤️")
                        .font(SalahTypography.caption)
                        .foregroundStyle(SalahColors.warmGold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(SalahLayout.cardPadding)
        .goldCard()
        .onAppear { isAnimating = true }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        SalahColors.deepEmerald
        NextPrayerView(
            prayer: PrayerTime(prayer: .asr, time: Date().addingTimeInterval(3661), isNext: true),
            countdownString: "01:01:01",
            progress: 0.65
        )
        .padding()
    }
    .frame(width: 320, height: 200)
}
