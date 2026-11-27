import SwiftUI

struct OnboardingView: View {
    let onContinue: @MainActor () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                HStack(spacing: 11) {
                    PulsoMark(size: 46)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Pulso")
                            .font(.title2.weight(.semibold))
                        Text("Una app independiente para SUBE")
                            .font(.caption)
                            .foregroundStyle(PulsoTheme.secondary)
                    }
                }
                .padding(.top, 20)

                NFCPlacementIllustration()
                    .frame(height: 260)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Tu tarjeta,\nmás cerca.")
                        .font(.largeTitle.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Elegí Consultar saldo, Historial o Acreditar carga y acercá la SUBE a tu iPhone.")
                        .font(.body)
                        .foregroundStyle(PulsoTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 18) {
                    InfoNotice(
                        title: "Primero, conocer tu tarjeta",
                        message: "Si iOS admite la tarjeta, podés detectar su chip. El saldo, los viajes y la acreditación todavía requieren acceso a las funciones protegidas de SUBE.",
                        systemImage: "wave.3.right",
                        tint: PulsoTheme.accent
                    )
                    Divider()
                    InfoNotice(
                        title: "Sin cuenta. Sin cambiar tu tarjeta.",
                        message: "Las lecturas quedan en tu iPhone. Podés borrarlas o compartir un diagnóstico cuando quieras.",
                        systemImage: "lock.shield",
                        tint: PulsoTheme.accent
                    )
                }
                .pulsoSurface()

                Button(action: onContinue) {
                    HStack {
                        Text("Empezar")
                        Spacer(minLength: 12)
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 6)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .tint(PulsoTheme.accent)
                .accessibilityIdentifier("onboarding.continue")

                Text("Pulso no es la aplicación oficial de SUBE ni está afiliado a Nación Servicios.")
                    .font(.caption)
                    .foregroundStyle(PulsoTheme.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
        }
        .foregroundStyle(PulsoTheme.ink)
        .background(PulsoTheme.background)
    }
}

/// Lightweight reference-inspired artwork. It never represents a successful
/// balance/top-up operation: the centre symbol is an NFC wave, not a checkmark.
/// All geometry is native and static, including with Reduce Motion enabled.
struct NFCPlacementIllustration: View {
    var compact = false

    var body: some View {
        ZStack {
            Circle()
                .fill(PulsoTheme.illustrationHalo)
                .frame(width: 228, height: 228)
                .offset(y: 6)

            RoundedRectangle(cornerRadius: 13)
                .fill(PulsoTheme.headerBlue)
                .frame(width: 144, height: 91)
                .overlay(alignment: .topLeading) {
                    Text("SUBE")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 15)
                        .padding(.leading, 14)
                }
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(14)
                }
                .rotationEffect(.degrees(-14))
                .offset(x: -65, y: 22)

            RoundedRectangle(cornerRadius: 25)
                .fill(PulsoTheme.illustrationFrame)
                .frame(width: 141, height: 237)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(PulsoTheme.illustrationScreen)
                        .frame(width: 125, height: 221)
                        .overlay(alignment: .topTrailing) {
                            ScreenHighlight()
                                .fill(.white.opacity(0.14))
                                .frame(width: 125, height: 221)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(PulsoTheme.illustrationFrame)
                        .frame(width: 51, height: 7)
                        .padding(.top, 7)
                }
                .overlay {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 29, weight: .medium))
                        .foregroundStyle(PulsoTheme.orange)
                        .frame(width: 65, height: 65)
                        .background(PulsoTheme.surface, in: Circle())
                        .overlay {
                            Circle().stroke(PulsoTheme.orange.opacity(0.45), lineWidth: 2)
                        }
                }
                .offset(x: 30)

            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(PulsoTheme.accent)
                .offset(x: 30, y: -135)
        }
        .padding(.top, 17)
        .frame(width: 290, height: 260)
        .scaleEffect(compact ? 0.77 : 1)
        .frame(height: compact ? 200 : 260)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

private struct ScreenHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX * 0.75, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.72))
        path.closeSubpath()
        return path
    }
}
