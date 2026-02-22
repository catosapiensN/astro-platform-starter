import SwiftUI

struct SummaryView: View {
    let stats: SessionStats
    let onReplay: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            GamePalette.background
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Oyun Özeti")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .padding(.top, 16)

                VStack(spacing: 8) {
                    scoreRow(title: "Final Skor", value: "\(stats.finalScore)")
                    scoreRow(title: "En Uzun Seri", value: "\(stats.longestStreak)")
                    scoreRow(title: "OYNA", value: "\(stats.plays)")
                    scoreRow(title: "GEÇ", value: "\(stats.skips)")
                    scoreRow(title: "ZORLA", value: "\(stats.spice)")
                    scoreRow(title: "KURTAR", value: "\(stats.rescue)")
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(GamePalette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                )

                Spacer()

                VStack(spacing: 10) {
                    Button("Tekrar Oyna") {
                        onReplay()
                    }
                    .buttonStyle(SummaryButtonStyle(background: GamePalette.primary, foreground: .white))

                    Button("Ana Menü") {
                        onHome()
                    }
                    .buttonStyle(SummaryButtonStyle(background: GamePalette.spice, foreground: .white))
                }
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
    }

    private func scoreRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 16)
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 7)
    }
}

private struct SummaryButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}
