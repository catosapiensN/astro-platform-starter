import SwiftUI

struct HomeView: View {
    private let backgroundColor = Color(red: 14 / 255, green: 14 / 255, blue: 17 / 255)
    @State private var showSettings = false

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 24) {
                topBar

                VStack(spacing: 14) {
                    modeCard(title: "Parti", mode: .parti)
                    modeCard(title: "İlk Buluşma", mode: .ilkBulusma)
                    modeCard(title: "Çift", mode: .cift)
                }
                .padding(.top, 16)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsSheetView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var topBar: some View {
        HStack {
            Spacer(minLength: 44)

            Text("sociax")
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.white.opacity(0.9))
            .buttonStyle(.plain)
            .accessibilityLabel("Ayarlar")
        }
    }

    @ViewBuilder
    private func modeCard(title: String, mode: GameMode) -> some View {
        NavigationLink {
            SetupView(mode: mode)
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(minHeight: 84)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsSheetView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Hakkında") {
                        Text("Sociax")
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Gizlilik") {
                        Text("Yakında")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "mailto:feedback@example.com")!) {
                        HStack {
                            Text("Geri Bildirim")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
