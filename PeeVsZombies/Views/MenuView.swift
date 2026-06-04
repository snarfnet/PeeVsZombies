import SwiftUI

struct MenuView: View {
    let bestScore: Int
    let onStart: () -> Void

    @State private var handOffset: CGFloat = 58
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Image("TitleKeyArt")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    .black.opacity(0.2),
                    .black.opacity(0.65),
                    .black.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 34)

                VStack(spacing: 2) {
                    Text("PEE VS ZOMBIES")
                        .font(.system(size: 42, weight: .black))
                        .foregroundColor(.yellow)
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                        .shadow(color: .yellow.opacity(0.85), radius: glowPulse ? 18 : 8)

                    Text("LAST CLIFF")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .tracking(2)
                        .shadow(color: .red.opacity(0.85), radius: glowPulse ? 12 : 4)
                }
                .padding(.horizontal, 22)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        glowPulse = true
                    }
                }

                Spacer()

                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(red: 0.09, green: 0.08, blue: 0.06))
                        .frame(height: 64)
                        .offset(y: 44)

                    ZombieHandView()
                        .offset(y: handOffset)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                                handOffset = -8
                            }
                        }
                }
                .frame(height: 82)
                .clipped()

                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Text("BEST")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.yellow.opacity(0.75))
                        Text("\(bestScore)")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(.yellow)
                    }

                    Button(action: onStart) {
                        Text("START")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.88, blue: 0.2),
                                        Color(red: 0.22, green: 0.86, blue: 0.22)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.green.opacity(0.55), radius: 12)
                    }

                    VStack(spacing: 4) {
                        Text("Hold to fire. Drag up and down to aim.")
                        Text("Clear 10 stages. Beat each boss to move on.")
                        Text("Stage 10 has the final boss.")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 18)

                BannerAdView()
                    .frame(height: 50)
            }
        }
    }
}

struct ZombieHandView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.16, green: 0.42, blue: 0.16))
                .frame(width: 28, height: 70)
                .offset(y: -20)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.2, green: 0.5, blue: 0.18))
                .frame(width: 34, height: 30)
                .offset(y: -58)

            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.18, green: 0.46, blue: 0.16))
                    .frame(width: 8, height: 20)
                    .offset(x: CGFloat(i) * 9 - 13.5, y: -76)
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.18, green: 0.46, blue: 0.16))
                .frame(width: 8, height: 16)
                .rotationEffect(.degrees(-30))
                .offset(x: 22, y: -58)
        }
    }
}
