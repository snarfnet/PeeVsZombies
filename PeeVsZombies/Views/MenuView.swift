import SwiftUI

struct MenuView: View {
    let bestScore: Int
    let onStart: () -> Void

    @State private var handOffset: CGFloat = 60
    @State private var titleDrip: CGFloat = 0
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Stars
            ForEach(0..<40, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.3...0.9)))
                    .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat(i * 47 % 400) + 20,
                        y: CGFloat(i * 83 % 300) + 20
                    )
            }

            // Moon
            Circle()
                .fill(Color(red: 1.0, green: 0.97, blue: 0.8))
                .frame(width: 60, height: 60)
                .offset(x: -120, y: -160)
                .overlay(
                    Circle()
                        .fill(Color.black)
                        .frame(width: 54, height: 54)
                        .offset(x: -112, y: -157)
                )

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 4) {
                    Text("ションベン")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.9), radius: glowPulse ? 18 : 8)

                    Text("vs")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)

                    Text("ゾンビ")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(Color(red: 0.2, green: 0.9, blue: 0.2))
                        .shadow(color: Color(red: 0.2, green: 0.9, blue: 0.2).opacity(0.8), radius: glowPulse ? 16 : 6)

                    Text("Pee vs Zombies")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 4)
                }
                .padding(.bottom, 32)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        glowPulse = true
                    }
                }

                // Zombie hand rising from ground
                ZStack(alignment: .bottom) {
                    // Ground strip
                    Rectangle()
                        .fill(Color(red: 0.2, green: 0.5, blue: 0.15))
                        .frame(height: 14)

                    // Dirt
                    Rectangle()
                        .fill(Color(red: 0.3, green: 0.2, blue: 0.1))
                        .frame(height: 60)
                        .offset(y: 60)

                    // Zombie hand
                    ZombieHandView()
                        .offset(y: handOffset)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                                handOffset = -10
                            }
                        }
                }
                .frame(height: 100)
                .clipped()

                Spacer().frame(height: 32)

                // Best score
                HStack(spacing: 8) {
                    Text("BEST")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.yellow.opacity(0.8))
                    Text("\(bestScore)")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.08))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
                .padding(.bottom, 24)

                // Start button
                Button(action: onStart) {
                    HStack(spacing: 10) {
                        Text("")
                        Text("ゲーム開始 / Start Game")
                            .font(.system(size: 20, weight: .black))
                        Text("")
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.9, blue: 0.3),
                                Color(red: 0.1, green: 0.65, blue: 0.1)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.green.opacity(0.5), radius: 10)
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 20)

                // How to play hint
                VStack(spacing: 4) {
                    Text("遊び方 / How to play")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("タッチ&ドラッグで角度調整してゾンビに放水！")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                    Text("Touch & drag to aim, hold to pee on zombies!")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

                Spacer()

                BannerAdView()
                    .frame(height: 50)
            }
        }
    }
}

struct ZombieHandView: View {
    var body: some View {
        ZStack {
            // Arm
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.2, green: 0.65, blue: 0.2))
                .frame(width: 28, height: 70)
                .offset(y: -20)

            // Palm
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.25, green: 0.72, blue: 0.25))
                .frame(width: 34, height: 30)
                .offset(y: -58)

            // Fingers
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.22, green: 0.68, blue: 0.22))
                    .frame(width: 8, height: 20)
                    .offset(x: CGFloat(i) * 9 - 13.5, y: -76)
            }

            // Thumb
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.22, green: 0.68, blue: 0.22))
                .frame(width: 8, height: 16)
                .rotationEffect(.degrees(-30))
                .offset(x: 22, y: -58)
        }
    }
}
