import SwiftUI

@MainActor
final class SetupViewModel: ObservableObject {
    let mode: GameMode

    @Published var playerCount: Int = 4
    @Published var vibe: Vibe = .normal
    @Published var duration: GameDuration = .minutes20
    @Published var hideAlcoholContent: Bool = false

    init(mode: GameMode) {
        self.mode = mode
    }

    func makeConfig() -> GameConfig {
        GameConfig(
            mode: mode,
            playerCount: playerCount,
            vibe: vibe,
            durationMinutes: duration.rawValue,
            hideAlcoholContent: hideAlcoholContent
        )
    }
}

struct SetupView: View {
    @StateObject private var viewModel: SetupViewModel
    @State private var createdConfig: GameConfig?
    @State private var shouldNavigateToGame = false

    init(mode: GameMode) {
        _viewModel = StateObject(wrappedValue: SetupViewModel(mode: mode))
    }

    var body: some View {
        Form {
            Section("Oyuncular") {
                Stepper(value: $viewModel.playerCount, in: 2...12) {
                    HStack {
                        Text("Oyuncu sayısı")
                        Spacer()
                        Text("\(viewModel.playerCount)")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Ayarlar") {
                Picker("Vibe", selection: $viewModel.vibe) {
                    ForEach(Vibe.allCases) { vibe in
                        Text(vibe.title).tag(vibe)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Süre", selection: $viewModel.duration) {
                    ForEach(GameDuration.allCases) { duration in
                        Text(duration.title).tag(duration)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Alkol içeren görevleri gösterme", isOn: $viewModel.hideAlcoholContent)
            }

            Section {
                Button("Başlat") {
                    createdConfig = viewModel.makeConfig()
                    shouldNavigateToGame = true
                }
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
                .listRowBackground(Color.clear)
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(red: 14 / 255, green: 14 / 255, blue: 17 / 255).ignoresSafeArea())
        .navigationTitle(viewModel.mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $shouldNavigateToGame) {
            if let config = createdConfig {
                GameView(config: config)
            }
        }
    }
}

private enum GameDuration: Int, CaseIterable, Identifiable {
    case minutes10 = 10
    case minutes20 = 20
    case minutes40 = 40

    var id: Int { rawValue }

    var title: String {
        "\(rawValue)"
    }
}

private enum Vibe: String, CaseIterable, Identifiable {
    case chill
    case normal
    case wild

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chill: return "Chill"
        case .normal: return "Normal"
        case .wild: return "Wild"
        }
    }
}

private extension GameMode {
    var title: String {
        switch self {
        case .parti: return "Parti"
        case .ilkBulusma: return "İlk Buluşma"
        case .cift: return "Çift"
        }
    }
}

#Preview {
    NavigationStack {
        SetupView(mode: .parti)
    }
}
