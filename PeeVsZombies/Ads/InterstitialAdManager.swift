import Foundation
import GoogleMobileAds

@MainActor
class InterstitialAdManager: NSObject, ObservableObject {
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910"
    private var interstitial: InterstitialAd?

    override init() {
        super.init()
        Task { await loadAd() }
    }

    private func loadAd() async {
        do {
            interstitial = try await InterstitialAd.load(
                with: adUnitID,
                request: GADRequest()
            )
        } catch {
            interstitial = nil
        }
    }

    func showIfReady() {
        guard let ad = interstitial else {
            Task { await loadAd() }
            return
        }
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let root = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return }

        ad.present(from: root)
        interstitial = nil
        Task { await loadAd() }
    }
}
