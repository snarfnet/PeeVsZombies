import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-3940256099942544/2435281174"

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = window()?.rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    private func window() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })
            .flatMap { $0.windows.first(where: \.isKeyWindow) }
    }
}
