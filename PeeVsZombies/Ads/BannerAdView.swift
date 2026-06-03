import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-9404799280370656/6116373863"

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
