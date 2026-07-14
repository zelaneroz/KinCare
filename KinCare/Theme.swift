import SwiftUI

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s.removeAll { $0 == "#" }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

enum KC {
    // Surfaces
    static let page = Color(hex: "FBFAF7")
    static let band = Color(hex: "F4F1EA")
    static let card = Color.white
    static let border = Color(hex: "E3DDD2")
    static let borderStrong = Color(hex: "CBC4BA")

    // Text
    static let text = Color(hex: "292724")
    static let muted = Color(hex: "5F5952")
    static let soft = Color(hex: "8B857C")

    // Sage — tasks, completion
    static let sage = Color(hex: "D8E4D3")
    static let sageText = Color(hex: "33502B")
    static let sageBtn = Color(hex: "C9DDC2")

    // Sky blue — appointments, medical
    static let blue = Color(hex: "DCE9F7")
    static let blueText = Color(hex: "205A8C")

    // Lavender — wellness, capacity
    static let lav = Color(hex: "E5DFF0")
    static let lavText = Color(hex: "4E3B7A")
    static let lavBtn = Color(hex: "7C689E")

    // Coral — attention only
    static let coral = Color(hex: "FBEFE9")
    static let coralBorder = Color(hex: "E0A985")
    static let coralText = Color(hex: "A5522A")

    // Radii
    static let radiusCard: CGFloat = 16
    static let radiusItem: CGFloat = 14
    static let radiusControl: CGFloat = 12
}

extension Font {
    static let kcPageTitle = Font.system(size: 28, weight: .medium)
    static let kcHeaderTitle = Font.system(size: 18, weight: .medium)
    static let kcCardTitle = Font.system(size: 16, weight: .medium)
    static let kcBigCardTitle = Font.system(size: 18, weight: .medium)
    static let kcBody = Font.system(size: 14, weight: .regular)
    static let kcSubtitle = Font.system(size: 15, weight: .regular)
    static let kcButton = Font.system(size: 16, weight: .medium)
    static let kcSectionLabel = Font.system(size: 13, weight: .medium)
    static let kcMetadata = Font.system(size: 13, weight: .regular)
    static let kcFootnote = Font.system(size: 12, weight: .regular)
}
