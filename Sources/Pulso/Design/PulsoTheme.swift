import SwiftUI
import UIKit

/// A restrained palette that follows the system appearance and increased contrast.
enum PulsoTheme {
    static let background = adaptive(light: 0xF4F8F4, dark: 0x0A1716)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x142421)
    static let surfaceSecondary = adaptive(light: 0xE8F0EB, dark: 0x1C322C)
    static let ink = adaptive(light: 0x153B33, dark: 0xECF6EE)
    static let secondary = adaptive(light: 0x526A62, dark: 0xB1C7BB)
    static let accent = adaptive(light: 0x116B53, dark: 0x9AE8BC)
    static let mint = Color(red: 168.0 / 255, green: 240.0 / 255, blue: 206.0 / 255)
    static let deepGreen = Color(red: 16.0 / 255, green: 43.0 / 255, blue: 40.0 / 255)
    static let line = adaptive(light: 0xDCE7DF, dark: 0x2B4339)
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
            .background(PulsoTheme.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
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
    var title = "Escanear tarjeta"
    var isDisabled = false
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "wave.3.right")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 34)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.roundedRectangle(radius: 20))
        .tint(PulsoTheme.accent)
        .disabled(isDisabled)
        .accessibilityHint("Abre las instrucciones para leer una tarjeta con el NFC del iPhone")
    }
}

struct PulsoMark: View {
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: "wave.3.right")
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(PulsoTheme.deepGreen)
            .frame(width: size, height: size)
            .background(PulsoTheme.mint, in: RoundedRectangle(cornerRadius: size * 0.31))
            .accessibilityHidden(true)
    }
}
