import SwiftUI

// MARK: - Header View

/// Displays Hijri date, Gregorian date, and current location
struct HeaderView: View {
    let hijriDate: String
    let hijriDateArabic: String
    let gregorianDate: String
    let cityName: String
    let specialDay: String?

    var body: some View {
        VStack(spacing: 6) {
            // Hijri date (prominent, gold accent)
            Text(hijriDateArabic)
                .font(SalahTypography.arabicLarge)
                .foregroundStyle(SalahColors.goldAccent)
                .lineLimit(1)

            Text(hijriDate)
                .font(SalahTypography.captionMedium)
                .foregroundStyle(SalahColors.warmGold)

            // Special day badge
            if let special = specialDay {
                Text(special)
                    .font(SalahTypography.caption)
                    .foregroundStyle(SalahColors.amberGlow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(SalahColors.goldAccent.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .strokeBorder(SalahColors.goldAccent.opacity(0.3), lineWidth: 0.5)
                            )
                    )
            }

            // Gregorian date
            Text(gregorianDate)
                .font(SalahTypography.caption)
                .foregroundStyle(SalahColors.softGray)

            // Location
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 9))
                Text(cityName)
                    .font(SalahTypography.caption)
            }
            .foregroundStyle(SalahColors.tealAccent.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SalahLayout.cardPadding)
        .padding(.horizontal, SalahLayout.cardPadding)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        SalahColors.deepEmerald
        HeaderView(
            hijriDate: "25 Ramadan 1447",
            hijriDateArabic: "٢٥ رمضان ١٤٤٧ هـ",
            gregorianDate: "Friday, 18 April 2026",
            cityName: "Jakarta, ID",
            specialDay: "🌙 Ramadan"
        )
    }
    .frame(width: 320, height: 160)
}
