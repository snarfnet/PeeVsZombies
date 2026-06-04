import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var isPlaying = false
    @State private var showGameOver = false
    @State private var showGameClear = false

    var body: some View {
        ZStack {
            if isPlaying {
                GameView(
                    gameState: gameState,
                    onGameOver: {
                        showGameOver = true
                    },
                    onGameClear: {
                        showGameClear = true
                    }
                )
                .ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    BannerAdView()
                        .frame(height: 50)
                }

                if showGameOver {
                    ResultOverlay(
                        title: "GAME OVER",
                        subtitle: "The horde reached the cliff.",
                        color: .red,
                        score: gameState.score,
                        bestScore: gameState.bestScore,
                        primaryTitle: "Play Again",
                        onPrimary: restart,
                        onMenu: returnToMenu
                    )
                    .transition(.opacity)
                }

                if showGameClear {
                    ResultOverlay(
                        title: "ALL STAGES CLEAR",
                        subtitle: "The Final Corpse is down.",
                        color: .yellow,
                        score: gameState.score,
                        bestScore: gameState.bestScore,
                        primaryTitle: "Run Again",
                        onPrimary: restart,
                        onMenu: returnToMenu
                    )
                    .transition(.opacity)
                }
            } else {
                MenuView(bestScore: gameState.bestScore) {
                    restart()
                    isPlaying = true
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPlaying)
        .animation(.easeInOut(duration: 0.3), value: showGameOver)
        .animation(.easeInOut(duration: 0.3), value: showGameClear)
        .preferredColorScheme(.dark)
    }

    private func restart() {
        showGameOver = false
        showGameClear = false
        gameState.reset()
    }

    private func returnToMenu() {
        showGameOver = false
        showGameClear = false
        isPlaying = false
        gameState.reset()
    }
}

struct ResultOverlay: View {
    let title: String
    let subtitle: String
    let color: Color
    let score: Int
    let bestScore: Int
    let primaryTitle: String
    let onPrimary: () -> Void
    let onMenu: () -> Void

    @StateObject private var adManager = InterstitialAdManager()

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(title)
                    .font(.system(size: 42, weight: .black))
                    .foregroundColor(color)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .shadow(color: color.opacity(0.8), radius: 12)

                Text(subtitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.78))

                VStack(spacing: 6) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(score)")
                        .font(.system(size: 52, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }

                VStack(spacing: 4) {
                    Text("Best")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(bestScore)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }

                Button(action: onPrimary) {
                    Text(primaryTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(12)
                }

                Button(action: onMenu) {
                    Text("Menu")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(color.opacity(0.6), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            adManager.showIfReady()
        }
    }
}
