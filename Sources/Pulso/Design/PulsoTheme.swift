import SwiftUI
import UIKit

/// Blue/neutral reference palette, rendered with native shapes and system text.
/// There are no repeating decorative animations or offscreen blur layers.
enum PulsoTheme {
    static let background = adaptive(light: 0xF7F8FA, dark: 0x111A22)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x1A2732)
    static let surfaceSecondary = adaptive(light: 0xEAF3F8, dark: 0x233743)
    static let ink = adaptive(light: 0x263944, dark: 0xEFF7FA)
    static let secondary = adaptive(light: 0x586873, dark: 0xB4C6D1)
    static let accent = adaptive(light: 0x007EAE, dark: 0x83D6F2)
    static let onAccent = adaptive(light: 0xFFFFFF, dark: 0x07314A)
    static let headerBlue = Color(red: 0, green: 126.0 / 255, blue: 174.0 / 255)
    static let orange = adaptive(light: 0xED8C15, dark: 0xFFB349)
    static let selectedText = adaptive(light: 0x9D4D00, dark: 0xFFCB86)
    static let selectionFill = adaptive(light: 0xFFF7EA, dark: 0x382A1B)
    static let idleRing = adaptive(light: 0xA7B4BB, dark: 0x748A98)
    static let illustrationScreen = adaptive(light: 0xD1E3F4, dark: 0x29465E)
    static let illustrationFrame = adaptive(light: 0x405C91, dark: 0x87A5CC)
    static let illustrationHalo = adaptive(light: 0xEBF3FA, dark: 0x182A37)
    static let line = adaptive(light: 0xDEE6EC, dark: 0x344550)
    static let caution = adaptive(light: 0x91601C, dark: 0xF1CA88)

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xff) / 255,
                green: CGFloat((hex >> 8) & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255,
                alpha: 1
            )
        })
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "Sistema"
        case .light: "Claro"
        case .dark: "Oscuro"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct SurfaceModifier: ViewModifier {
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PulsoTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(PulsoTheme.line.opacity(0.65), lineWidth: 1)
                    .accessibilityHidden(true)
            }
    }
}

extension View {
    func pulsoSurface(padding: CGFloat = 20) -> some View {
        modifier(SurfaceModifier(padding: padding))
    }
}

struct Eyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1.5)
            .foregroundStyle(PulsoTheme.secondary)
    }
}

struct StatusPill: View {
    let text: String
    var systemImage: String = "circle.fill"
    var tint: Color = PulsoTheme.accent

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(0.09), in: Capsule())
            .accessibilityElement(children: .combine)
    }
}

struct InfoNotice: View {
    let title: String
    let message: String
    var systemImage = "info.circle"
    var tint: Color = PulsoTheme.secondary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PulsoTheme.ink)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(PulsoTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct PrimaryScanButton: View {
    var title = "Iniciar lectura"
    var isDisabled = false
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "wave.3.right")
                .font(.headline)
                .foregroundStyle(PulsoTheme.onAccent)
                .frame(maxWidth: .infinity, minHeight: 34)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .tint(PulsoTheme.accent)
        .disabled(isDisabled)
        .accessibilityHint("Inicia directamente una lectura NFC de los datos públicos de tu tarjeta")
    }
}

struct PulsoMark: View {
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: "wave.3.right")
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(PulsoTheme.headerBlue, in: RoundedRectangle(cornerRadius: size * 0.26))
            .accessibilityHidden(true)
    }
}
