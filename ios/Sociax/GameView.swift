import SwiftUI
import UIKit

struct GameView: View {
    let config: GameConfig

    @StateObject private var viewModel: GameViewModel
    @State private var showSummary = false

    init(config: GameConfig) {
        self.config = config
        _viewModel = StateObject(wrappedValue: GameViewModel(config: config))
    }

    var body: some View {
        ZStack {
            GamePalette.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                topBar

                Spacer(minLength: 0)

                cardContent
                    .id(viewModel.cardIdentity)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))

                Spacer(minLength: 0)

                actionRow
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
            .animation(.easeInOut(duration: 0.22), value: viewModel.cardIdentity)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showSummary) {
            SummaryView(
                stats: viewModel.summary,
                onReplay: {
                    viewModel.restart()
                    showSummary = false
                },
                onHome: {
                    popToRoot()
                }
            )
        }
        .onChange(of: viewModel.shouldShowSummary) { _, newValue in
            if newValue { showSummary = true }
        }
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.modeTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 10)

                if viewModel.canRescue {
                    Button("⚡ Kurtar") {
                        viewModel.rescue()
                    }
                    .buttonStyle(ActionPillButtonStyle(background: GamePalette.spice, foreground: .white))
                    .accessibilityHint("Bu turu kurtarmak için")
                }
            }

            HStack(spacing: 10) {
                statPill(title: "Skor", value: "\(viewModel.score)")
                statPill(title: "Seri", value: "\(viewModel.streak)")
                Spacer()
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text(viewModel.cardTypeTitle)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(GamePalette.accent.opacity(0.2), in: Capsule())
                    .foregroundStyle(.white)

                Spacer()

                Text("Seviye \(viewModel.level)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Text(viewModel.question)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(8)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(GamePalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
        )
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button("OYNA") {
                viewModel.play()
            }
            .buttonStyle(ScalePressButtonStyle(background: GamePalette.primary, foreground: .white))

            Button("GEÇ") {
                viewModel.skip()
            }
            .buttonStyle(ScalePressButtonStyle(background: GamePalette.card, foreground: .white))

            Button("ZORLA 🔥") {
                viewModel.spice()
            }
            .buttonStyle(ScalePressButtonStyle(background: GamePalette.spice, foreground: .white))
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(GamePalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func popToRoot() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .deepNavigationController?
            .popToRootViewController(animated: true)
    }
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var score: Int = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var question: String = "Hazır mısın?"
    @Published private(set) var cardTypeTitle: String = "SOHBET"
    @Published private(set) var level: Int = 1
    @Published private(set) var shouldShowSummary = false

    let config: GameConfig
    let modeTitle: String
    let canRescue: Bool

    var cardIdentity: String { "\(cardTypeTitle)-\(level)-\(question)" }

    private(set) var engine: GameEngine
    private var stats = SessionStats()
    private let playHaptic = UIImpactFeedbackGenerator(style: .light)
    private let spiceHaptic = UIImpactFeedbackGenerator(style: .medium)

    init(config: GameConfig) {
        self.config = config
        self.modeTitle = String(describing: config.mode).readableMode
        self.canRescue = modeTitle != "Parti"
        self.engine = GameEngine(config: config)
        playHaptic.prepare()
        spiceHaptic.prepare()
        syncFromEngine()
    }

    func play() {
        playHaptic.impactOccurred(intensity: 0.8)
        engine.play()
        stats.plays += 1
        syncFromEngine()
        playHaptic.prepare()
    }

    func skip() {
        engine.skip()
        stats.skips += 1
        syncFromEngine()
    }

    func spice() {
        spiceHaptic.impactOccurred(intensity: 0.9)
        engine.spice()
        stats.spice += 1
        syncFromEngine()
        spiceHaptic.prepare()
    }

    func rescue() {
        guard canRescue else { return }
        engine.rescue()
        stats.rescue += 1
        syncFromEngine()
    }

    func restart() {
        shouldShowSummary = false
        stats = SessionStats()
        engine = GameEngine(config: config)
        syncFromEngine()
    }

    var summary: SessionStats {
        var value = stats
        value.finalScore = score
        value.longestStreak = max(value.longestStreak, streak)
        return value
    }

    private func syncFromEngine() {
        score = mirrorInt(labels: ["score", "currentScore"]) ?? score
        streak = mirrorInt(labels: ["streak", "currentStreak"]) ?? streak
        stats.longestStreak = max(stats.longestStreak, streak)

        if let extracted = extractCardInfo() {
            question = extracted.question
            cardTypeTitle = extracted.type
            level = extracted.level
        }

        if mirrorBool(labels: ["isFinished", "finished", "hasEnded"]) == true {
            shouldShowSummary = true
        }
    }

    private func extractCardInfo() -> (question: String, type: String, level: Int)? {
        let mirror = Mirror(reflecting: engine)
        for child in mirror.children {
            guard let label = child.label?.lowercased() else { continue }
            if ["current", "currentcontent", "content", "card", "task"].contains(label) {
                let subject = child.value
                let question = readString(on: subject, labels: ["text", "question", "prompt", "content"]) ?? self.question
                let typeRaw = readString(on: subject, labels: ["type", "kind", "category"]) ?? self.cardTypeTitle
                let level = readInt(on: subject, labels: ["level", "difficulty"]) ?? self.level
                return (question, typeRaw.readableCardType, level)
            }
        }
        return nil
    }

    private func mirrorInt(labels: [String]) -> Int? {
        readInt(on: engine, labels: labels)
    }

    private func mirrorBool(labels: [String]) -> Bool? {
        readBool(on: engine, labels: labels)
    }

    private func readInt(on value: Any, labels: [String]) -> Int? {
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            guard let label = child.label?.lowercased(), labels.contains(label) else { continue }
            if let direct = child.value as? Int { return direct }
            if let wrapped = unwrapOptional(child.value) as? Int { return wrapped }
        }
        return nil
    }

    private func readBool(on value: Any, labels: [String]) -> Bool? {
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            guard let label = child.label?.lowercased(), labels.contains(label) else { continue }
            if let direct = child.value as? Bool { return direct }
            if let wrapped = unwrapOptional(child.value) as? Bool { return wrapped }
        }
        return nil
    }

    private func readString(on value: Any, labels: [String]) -> String? {
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            guard let label = child.label?.lowercased(), labels.contains(label) else { continue }
            if let direct = child.value as? String { return direct }
            if let wrapped = unwrapOptional(child.value) as? String { return wrapped }
            return String(describing: child.value)
        }
        return nil
    }

    private func unwrapOptional(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else { return value }
        return mirror.children.first?.value
    }
}

struct SessionStats {
    var finalScore: Int = 0
    var longestStreak: Int = 0
    var plays: Int = 0
    var skips: Int = 0
    var spice: Int = 0
    var rescue: Int = 0
}

enum GamePalette {
    static let background = Color(red: 14 / 255, green: 14 / 255, blue: 17 / 255)
    static let card = Color(red: 23 / 255, green: 23 / 255, blue: 28 / 255)
    static let primary = Color(red: 76 / 255, green: 141 / 255, blue: 1)
    static let accent = Color(red: 76 / 255, green: 141 / 255, blue: 1)
    static let spice = Color(red: 1, green: 138 / 255, blue: 61 / 255)
}

private struct ScalePressButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
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

private struct ActionPillButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(background, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

private extension String {
    var readableMode: String {
        let lower = lowercased()
        if lower.contains("part") { return "Parti" }
        if lower.contains("ilk") || lower.contains("date") { return "İlk Buluşma" }
        if lower.contains("cift") || lower.contains("couple") { return "Çift" }
        return self
    }

    var readableCardType: String {
        let lower = lowercased()
        if lower.contains("truth") || lower.contains("ger") { return "GERÇEK" }
        if lower.contains("talk") || lower.contains("chat") || lower.contains("soh") { return "SOHBET" }
        if lower.contains("dare") || lower.contains("mey") { return "MEYDAN OKU" }
        if lower.contains("flirt") || lower.contains("fl") { return "FLÖRT" }
        if lower.contains("biz") { return "BİZ" }
        return uppercased()
    }
}

private extension UIViewController {
    var deepNavigationController: UINavigationController? {
        if let nav = self as? UINavigationController { return nav }
        for child in children {
            if let nav = child.deepNavigationController { return nav }
        }
        if let presented = presentedViewController {
            return presented.deepNavigationController
        }
        return nil
    }
}
