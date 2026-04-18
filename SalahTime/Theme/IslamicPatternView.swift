import SwiftUI

// MARK: - Islamic Geometric Pattern

/// Procedurally generated Islamic geometric pattern overlay
/// Uses interlocking 8-pointed stars in a repeating grid
struct IslamicPatternView: View {
    var opacity: Double = 0.04
    var lineColor: Color = SalahColors.tealAccent

    var body: some View {
        Canvas { context, size in
            let cellSize: CGFloat = 40
            let cols = Int(size.width / cellSize) + 2
            let rows = Int(size.height / cellSize) + 2

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * cellSize
                    let y = CGFloat(row) * cellSize
                    let center = CGPoint(x: x, y: y)

                    // Draw 8-pointed star
                    drawEightPointedStar(
                        context: context,
                        center: center,
                        radius: cellSize * 0.35,
                        color: lineColor.opacity(opacity)
                    )

                    // Draw connecting diamond between stars
                    if col < cols - 1 && row < rows - 1 {
                        let midPoint = CGPoint(
                            x: x + cellSize * 0.5,
                            y: y + cellSize * 0.5
                        )
                        drawDiamond(
                            context: context,
                            center: midPoint,
                            size: cellSize * 0.2,
                            color: lineColor.opacity(opacity * 0.6)
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawEightPointedStar(
        context: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color
    ) {
        var path = Path()
        let innerRadius = radius * 0.4
        let points = 8

        for i in 0..<(points * 2) {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let r = i % 2 == 0 ? radius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * r,
                y: center.y + CGFloat(sin(angle)) * r
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        context.stroke(
            path,
            with: .color(color),
            lineWidth: 0.5
        )
    }

    private func drawDiamond(
        context: GraphicsContext,
        center: CGPoint,
        size: CGFloat,
        color: Color
    ) {
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - size))
        path.addLine(to: CGPoint(x: center.x + size, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + size))
        path.addLine(to: CGPoint(x: center.x - size, y: center.y))
        path.closeSubpath()

        context.stroke(
            path,
            with: .color(color),
            lineWidth: 0.5
        )
    }
}

// MARK: - Decorative Crescent

/// A subtle crescent moon decorative element
struct CrescentView: View {
    var size: CGFloat = 30
    var color: Color = SalahColors.goldAccent.opacity(0.15)

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
            Circle()
                .fill(SalahColors.deepEmerald)
                .frame(width: size * 0.75, height: size * 0.75)
                .offset(x: size * 0.15, y: -size * 0.05)
        }
    }
}

#Preview {
    ZStack {
        SalahColors.deepEmerald
        IslamicPatternView()
    }
    .frame(width: 320, height: 480)
}
