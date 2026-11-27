import SwiftUI

struct OnboardingView: View {
    let onContinue: @MainActor () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(spacing: 10) {
                    PulsoMark()
                    Text("pulso")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                }
                .padding(.top, 18)

                VStack(alignment: .leading, spacing: 14) {
                    Eyebrow(text: "Tu primera lectura")
                    Text("Acercá tu tarjeta.\nDescubrí su señal.")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Un lector NFC para explorar tu SUBE desde el iPhone, a tu ritmo.")
                        .font(.body)
                        .foregroundStyle(PulsoTheme.secondary)
                }

                NFCPlacementIllustration()
                    .frame(height: 225)

                VStack(alignment: .leading, spacing: 24) {
                    OnboardingFeature(
                        symbol: "wave.3.right",
                        title: "Detectá el chip",
                        detail: "Si iOS lo admite, vas a ver su familia y los datos públicos de la tarjeta."
                    )
                    OnboardingFeature(
                        symbol: "lock.shield",
                        title: "La tarjeta queda intacta",
                        detail: "Esta versión no autentica ni modifica la tarjeta. El saldo y los viajes todavía no se leen."
                    )
                    OnboardingFeature(
                        symbol: "iphone",
                        title: "Todo queda en tu iPhone",
                        detail: "Sin cuenta ni servidor. Vos decidís si guardás o compartís las lecturas."
                    )
                }
                .pulsoSurface()

                Button(action: onContinue) {
                    HStack {
                        Text("Empezar")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: 20))
                .tint(PulsoTheme.accent)

                Text("Proyecto independiente. No es la aplicación oficial de SUBE ni está afiliado a Nación Servicios.")
                    .font(.caption)
                    .foregroundStyle(PulsoTheme.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
        }
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
    }
}

private struct OnboardingFeature: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(PulsoTheme.accent)
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(PulsoTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A decorative guide, never a simulated NFC reading or balance.
struct NFCPlacementIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(PulsoTheme.surfaceSecondary)
                .frame(width: 210, height: 210)
            Circle()
                .stroke(PulsoTheme.accent.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [4, 7]))
                .frame(width: 244, height: 244)

            RoundedRectangle(cornerRadius: 25)
                .fill(PulsoTheme.deepGreen)
                .frame(width: 99, height: 184)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(PulsoTheme.mint.opacity(0.45))
                        .frame(width: 34, height: 5)
                        .padding(.top, 12)
                }
                .rotationEffect(.degrees(-12))
                .offset(x: -34, y: 10)

            RoundedRectangle(cornerRadius: 16)
                .fill(PulsoTheme.mint.gradient)
                .frame(width: 142, height: 91)
                .overlay(alignment: .topLeading) {
                    Image(systemName: "wave.3.right")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(PulsoTheme.deepGreen)
                        .padding(15)
                }
                .overlay(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(PulsoTheme.deepGreen.opacity(0.18))
                        .frame(width: 45, height: 5)
                        .padding(15)
                }
                .rotationEffect(.degrees(13))
                .offset(x: 42, y: -39)
                .shadow(color: .black.opacity(0.13), radius: 15, y: 8)

            Image(systemName: "sparkle")
                .foregroundStyle(PulsoTheme.accent)
                .font(.title2)
                .offset(x: 94, y: 69)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}
