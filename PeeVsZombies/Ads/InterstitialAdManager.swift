import Foundation
import GoogleMobileAds
import UIKit

@MainActor
class InterstitialAdManager: NSObject, ObservableObject {
    private let adUnitID = "ca-app-pub-9404799280370656/6116373863"
    private var interstitial: GADInterstitialAd?

    override init() {
        super.init()
        Task { await loadAd() }
    }

    private func loadAd() async {
        do {
            interstitial = try await GADInterstitialAd.load(
                withAdUnitID: adUnitID,
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

        ad.present(fromRootViewController: root)
        interstitial = nil
        Task { await loadAd() }
    }
}
