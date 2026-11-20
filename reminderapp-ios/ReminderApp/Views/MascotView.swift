import SwiftUI

enum MascotExpression: String {
    case happy, encouraging, celebrating, thinking, reminding, sleepy

    var message: String {
        switch self {
        case .happy: "Ready when you are!"
        case .encouraging: "Tiny step, big win."
        case .celebrating: "Look at you go!"
        case .thinking: "Let’s make a plan."
        case .reminding: "A little heads up!"
        case .sleepy: "Rest is productive too."
        }
    }
}

struct MascotView: View {
    let expression: MascotExpression
    var size: CGFloat = 100
    var showsCaption = true
    @State private var isFloating = false

    private let elephant = Color(hex: "#91CFE5")
    private let innerEar = Color(hex: "#F4AFC2")

    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geometry in
                let unit = geometry.size.width
                ZStack {
                    Circle().fill(AppPalette.yellow.opacity(0.30)).frame(width: unit * 0.94)
                    // Broad ears, curved trunk, tusks, and feet make the silhouette recognizable at small sizes.
                    Ellipse().fill(elephant).frame(width: unit * 0.39, height: unit * 0.53).position(x: unit * 0.22, y: unit * 0.48).rotationEffect(.degrees(-13))
                    Ellipse().fill(elephant).frame(width: unit * 0.39, height: unit * 0.53).position(x: unit * 0.78, y: unit * 0.48).rotationEffect(.degrees(13))
                    Ellipse().fill(innerEar).frame(width: unit * 0.23, height: unit * 0.38).position(x: unit * 0.21, y: unit * 0.49).rotationEffect(.degrees(-13))
                    Ellipse().fill(innerEar).frame(width: unit * 0.23, height: unit * 0.38).position(x: unit * 0.79, y: unit * 0.49).rotationEffect(.degrees(13))
                    Ellipse().fill(elephant).frame(width: unit * 0.53, height: unit * 0.39).position(x: unit * 0.50, y: unit * 0.70)
                    HStack(spacing: unit * 0.20) { Ellipse().fill(Color(hex: "#6CB5D1")).frame(width: unit * 0.17, height: unit * 0.19); Ellipse().fill(Color(hex: "#6CB5D1")).frame(width: unit * 0.17, height: unit * 0.19) }.position(x: unit * 0.50, y: unit * 0.85)
                    Ellipse().fill(elephant).frame(width: unit * 0.64, height: unit * 0.65).position(x: unit * 0.50, y: unit * 0.43)
                    HStack(spacing: unit * 0.18) { eye(unit); eye(unit) }.position(x: unit * 0.50, y: unit * 0.38)
                    HStack(spacing: unit * 0.19) {
                        Capsule().fill(.white).frame(width: unit * 0.07, height: unit * 0.16).rotationEffect(.degrees(-22))
                        Capsule().fill(.white).frame(width: unit * 0.07, height: unit * 0.16).rotationEffect(.degrees(22))
                    }.position(x: unit * 0.50, y: unit * 0.66)
                    ElephantTrunk().stroke(Color(hex: "#5DA9C6"), style: StrokeStyle(lineWidth: unit * 0.17, lineCap: .round, lineJoin: .round))
                    ElephantTrunk().stroke(elephant, style: StrokeStyle(lineWidth: unit * 0.13, lineCap: .round, lineJoin: .round))
                    Circle().fill(Color(hex: "#477E9D")).frame(width: unit * 0.025).position(x: unit * 0.76, y: unit * 0.69)
                    if expression == .celebrating { Image(systemName: "sparkles").foregroundStyle(AppPalette.coral).font(.system(size: unit * 0.18, weight: .bold)).position(x: unit * 0.87, y: unit * 0.10) }
                    if expression == .reminding { Image(systemName: "bell.fill").foregroundStyle(AppPalette.coral).font(.system(size: unit * 0.17)).position(x: unit * 0.85, y: unit * 0.15) }
                    if expression == .thinking { Image(systemName: "questionmark").foregroundStyle(AppPalette.coral).font(.system(size: unit * 0.18, weight: .bold)).position(x: unit * 0.86, y: unit * 0.12) }
                    if expression == .sleepy { Text("Zz").font(.system(size: unit * 0.18, weight: .bold, design: .rounded)).foregroundStyle(AppPalette.ink).position(x: unit * 0.84, y: unit * 0.12) }
                }
            }
            .frame(width: size, height: size)
            .offset(y: isFloating ? -2 : 2)
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: isFloating)
            if showsCaption { Text(expression.message).font(.caption.weight(.semibold)).foregroundStyle(AppPalette.ink).lineLimit(1).minimumScaleFactor(0.75) }
        }
        .onAppear { isFloating = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Elephant helper, \(expression.message)")
    }

    private func eye(_ unit: CGFloat) -> some View {
        Group {
            if expression == .sleepy { Capsule().fill(AppPalette.ink).frame(width: unit * 0.10, height: unit * 0.025) }
            else { Circle().fill(AppPalette.ink).frame(width: unit * 0.09, height: unit * 0.09) }
        }
    }
}

private struct ElephantTrunk: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        return Path { path in
            path.move(to: CGPoint(x: w * 0.50, y: h * 0.52))
            path.addCurve(to: CGPoint(x: w * 0.61, y: h * 0.77), control1: CGPoint(x: w * 0.49, y: h * 0.70), control2: CGPoint(x: w * 0.48, y: h * 0.79))
            path.addCurve(to: CGPoint(x: w * 0.76, y: h * 0.68), control1: CGPoint(x: w * 0.73, y: h * 0.76), control2: CGPoint(x: w * 0.76, y: h * 0.76))
        }
    }
}
