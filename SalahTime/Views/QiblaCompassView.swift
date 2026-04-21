import SwiftUI

// MARK: - Qibla Compass View

/// Compact compass showing Qibla direction with Kaaba icon
struct QiblaCompassView: View {
    let bearing: Double  // Degrees from North
    let compassDirection: String  // e.g., "NW"

    @State private var animatedBearing: Double = 0

    var body: some View {
        HStack(spacing: 14) {
            // Compass circle
            ZStack {
                // Outer ring
                Circle()
                    .stroke(SalahColors.emeraldGlow, lineWidth: 2)
                    .frame(width: 56, height: 56)

                // Cardinal marks
                cardinalMarks

                // Qibla direction line
                QiblaDirectionLine(bearing: animatedBearing)
                    .frame(width: 56, height: 56)

                // Center dot
                Circle()
                    .fill(SalahColors.tealAccent)
                    .frame(width: 5, height: 5)

                // Kaaba icon at Qibla position
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(SalahColors.goldAccent)
                    .offset(
                        x: 22 * CGFloat(sin(animatedBearing * .pi / 180)),
                        y: -22 * CGFloat(cos(animatedBearing * .pi / 180))
                    )
                    .shadow(color: SalahColors.goldAccent.opacity(0.4), radius: 3)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Qibla Direction")
                    .font(SalahTypography.captionMedium)
                    .foregroundStyle(SalahColors.softGray)

                HStack(spacing: 4) {
                    Text(String(format: "%.1f°", bearing))
                        .font(SalahTypography.headline)
                        .foregroundStyle(SalahColors.pureWhite)

                    Text(compassDirection)
                        .font(SalahTypography.bodyMedium)
                        .foregroundStyle(SalahColors.tealAccent)
                }

                HStack(spacing: 3) {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 10))
                    Text("Makkah")
                        .font(SalahTypography.caption)
                }
                .foregroundStyle(SalahColors.warmGold)
            }

            Spacer()
        }
        .padding(SalahLayout.cardPadding)
        .glassCard()
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedBearing = bearing
            }
        }
        .onChange(of: bearing) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedBearing = newValue
            }
        }
    }

    // MARK: - Cardinal Marks

    private var cardinalMarks: some View {
        ZStack {
            ForEach(["N", "E", "S", "W"], id: \.self) { direction in
                Text(direction)
                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                    .foregroundStyle(direction == "N" ? SalahColors.tealAccent : SalahColors.dimGray)
                    .offset(
                        x: 32 * CGFloat(sin(cardinalAngle(direction) * .pi / 180)),
                        y: -32 * CGFloat(cos(cardinalAngle(direction) * .pi / 180))
                    )
            }
        }
    }

    private func cardinalAngle(_ direction: String) -> Double {
        switch direction {
        case "N": 0
        case "E": 90
        case "S": 180
        case "W": 270
        default: 0
        }
    }
}

// MARK: - Qibla Direction Line

/// Draws a line from center toward the Qibla bearing
struct QiblaDirectionLine: Shape {
    var bearing: Double

    var animatableData: Double {
        get { bearing }
        set { bearing = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 4
        let angle = bearing * .pi / 180

        let end = CGPoint(
            x: center.x + radius * CGFloat(sin(angle)),
            y: center.y - radius * CGFloat(cos(angle))
        )

        path.move(to: center)
        path.addLine(to: end)
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        SalahColors.deepEmerald
        QiblaCompassView(
            bearing: 295.5,
            compassDirection: "NW"
        )
        .padding()
    }
    .frame(width: 320, height: 120)
}
