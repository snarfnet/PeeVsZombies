import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var isPlaying = false
    @State private var showGameOver = false

    var body: some View {
        ZStack {
            if isPlaying {
                GameView(gameState: gameState) {
                    showGameOver = true
                }
                .ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    BannerAdView()
                        .frame(height: 50)
                }

                if showGameOver {
                    GameOverOverlay(
                        score: gameState.score,
                        bestScore: gameState.bestScore,
                        onRestart: {
                            showGameOver = false
                            gameState.reset()
                        },
                        onMenu: {
                            showGameOver = false
                            isPlaying = false
                            gameState.reset()
                        }
                    )
                    .transition(.opacity)
                }
            } else {
                MenuView(bestScore: gameState.bestScore) {
                    gameState.reset()
                    isPlaying = true
                    showGameOver = false
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPlaying)
        .animation(.easeInOut(duration: 0.3), value: showGameOver)
        .preferredColorScheme(.dark)
    }
}

struct GameOverOverlay: View {
    let score: Int
    let bestScore: Int
    let onRestart: () -> Void
    let onMenu: () -> Void

    @StateObject private var adManager = InterstitialAdManager()

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("GAME OVER")
                    .font(.system(size: 44, weight: .black))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.8), radius: 12)

                Text("ゲームオーバー")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red.opacity(0.8))

                Spacer().frame(height: 8)

                VStack(spacing: 6) {
                    Text("Score / スコア")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(score)")
                        .font(.system(size: 52, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }

                VStack(spacing: 4) {
                    Text("Best / ベスト")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(bestScore)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                }

                Spacer().frame(height: 12)

                Button(action: onRestart) {
                    Text("もう一度 / Play Again")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(12)
                }

                Button(action: onMenu) {
                    Text("メニュー / Menu")
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
                            .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                    )
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            adManager.showIfReady()
        }
    }
}
