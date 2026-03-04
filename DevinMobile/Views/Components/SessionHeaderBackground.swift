import SwiftUI

/// Deterministic seeded random number generator (linear congruential).
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
        // Warm up
        for _ in 0..<10 { _ = next() }
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

/// MeshGradient-based generative background seeded from a session ID.
/// Each session gets a unique but deterministic color mesh.
struct SessionHeaderBackground: View {
    let sessionId: String
    let statusColor: Color
    let height: CGFloat

    var body: some View {
        let colors = generateMeshColors()

        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0],
            ],
            colors: colors
        )
        .overlay(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .clear, location: 0.55),
                    .init(color: Color(.systemBackground), location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(height: height)
    }

    /// Generate 9 mesh colors from the session ID seed with good variation.
    private func generateMeshColors() -> [Color] {
        var rng = SeededRNG(seed: stableHash(sessionId))

        // Extract base HSB from status color
        let uiColor = UIColor(statusColor)
        var baseH: CGFloat = 0, baseS: CGFloat = 0, baseB: CGFloat = 0, baseA: CGFloat = 0
        uiColor.getHue(&baseH, saturation: &baseS, brightness: &baseB, alpha: &baseA)

        return (0..<9).map { index in
            // Wide hue shifts for variety, anchored around the status color
            let hueShift = CGFloat.random(in: -0.25...0.25, using: &rng)
            let saturation = CGFloat.random(in: 0.3...0.9, using: &rng)
            let brightness = CGFloat.random(in: 0.4...0.95, using: &rng)

            // Corners and edges get darker, center stays brighter
            let centerBias: CGFloat = index == 4 ? 0.15 : 0.0
            let edgeDarken: CGFloat = (index == 0 || index == 2 || index == 6 || index == 8) ? -0.1 : 0.0

            let h = (baseH + hueShift).truncatingRemainder(dividingBy: 1.0)
            let finalH = h < 0 ? h + 1.0 : h

            return Color(
                hue: Double(finalH),
                saturation: Double(min(1.0, saturation)),
                brightness: Double(min(1.0, brightness + centerBias + edgeDarken))
            )
        }
    }

    /// Stable hash that doesn't change between app launches.
    private func stableHash(_ string: String) -> Int {
        var hash: UInt64 = 5381
        for byte in string.utf8 {
            hash = hash &* 33 &+ UInt64(byte)
        }
        return Int(bitPattern: UInt(hash))
    }
}
