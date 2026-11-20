import SwiftUI

extension Color {
    init(hex: String) {
        let value = hex.replacingOccurrences(of: "#", with: "")
        let number = UInt64(value, radix: 16) ?? 0
        self.init(.sRGB, red: Double((number >> 16) & 0xFF) / 255, green: Double((number >> 8) & 0xFF) / 255, blue: Double(number & 0xFF) / 255, opacity: 1)
    }
}

enum AppPalette {
    static let ink = Color(hex: "#152038")
    static let muted = Color(hex: "#718096")
    static let canvas = Color(hex: "#F7F9FC")
    static let yellow = Color(hex: "#FFD85C")
    static let coral = Color(hex: "#FF796B")
    static let lavender = Color(hex: "#EDE8FF")
}

struct CategoryArtView: View {
    let category: CategoryDefinition
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color(hex: category.tintHex))
            Image(systemName: category.symbolName)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(Color(hex: category.colorHex))
        }
        .frame(width: size, height: size)
    }
}

struct SectionTitle: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(AppPalette.ink)
            Spacer()
            if let action, let actionTitle { Button(actionTitle, action: action).font(.subheadline.weight(.semibold)).foregroundStyle(AppPalette.coral) }
        }
    }
}

struct SoftCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: AppPalette.ink.opacity(0.07), radius: 16, y: 8)
    }
}
