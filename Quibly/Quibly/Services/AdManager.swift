import SwiftUI

// Ad infrastructure ready for Google AdMob (or any provider).
//
// Integration steps:
//  1. Add the GoogleMobileAds Swift Package:
//     https://github.com/googleads/swift-package-manager-google-mobile-ads
//  2. Add your App ID to Info.plist under GADApplicationIdentifier.
//  3. Replace stub implementations below with real GAD calls (marked TODO).
//  4. Enable SKAdNetworkItems in Info.plist per AdMob requirements.
//  5. Request ATT permission (AppTrackingTransparency) on first launch.
@MainActor
final class AdManager: ObservableObject {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs (replace with real IDs before shipping)

    enum AdUnitID {
        /// Test IDs — swap for production IDs from AdMob dashboard.
        static let rewardedCoins = "ca-app-pub-3940256099942544/1712485313" // AdMob test rewarded
        static let banner        = "ca-app-pub-3940256099942544/2934735716" // AdMob test banner
        static let interstitial  = "ca-app-pub-3940256099942544/4411468910" // AdMob test interstitial
    }

    // MARK: - State

    @Published var isRewardedAdReady = false
    @Published var isLoadingAd = false
    @Published var isBannerVisible = false

    /// Coins awarded for watching a full rewarded ad.
    let rewardedCoinGrant = 50

    private init() {
        // TODO: Initialize AdMob SDK once the package is added:
        // GADMobileAds.sharedInstance().start(completionHandler: nil)
        loadRewardedAd()
    }

    // MARK: - Rewarded Ads

    func loadRewardedAd() {
        guard !isLoadingAd else { return }
        isLoadingAd = true

        // TODO: Replace with real AdMob load:
        // GADRewardedAd.load(withAdUnitID: AdUnitID.rewardedCoins, request: GADRequest()) { [weak self] ad, error in
        //     self?.isLoadingAd = false
        //     if let ad { self?.rewardedAd = ad; self?.isRewardedAdReady = true }
        // }

        // Stub: simulate a brief network load then mark ready.
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            isLoadingAd = false
            isRewardedAdReady = true
        }
    }

    /// Present a rewarded ad. Calls `onReward` with coin amount if the user
    /// completes it, or `onDismiss` if they skip. Always reloads a new ad after.
    func showRewardedAd(onReward: @escaping (Int) -> Void, onDismiss: (() -> Void)? = nil) {
        guard isRewardedAdReady else {
            loadRewardedAd()
            return
        }
        isRewardedAdReady = false

        // TODO: Present real AdMob rewarded ad:
        // guard let rootVC = UIApplication.shared.connectedScenes
        //     .compactMap({ $0 as? UIWindowScene })
        //     .first?.windows.first?.rootViewController else { return }
        // rewardedAd?.present(fromRootViewController: rootVC, userDidEarnRewardHandler: {
        //     onReward(self.rewardedCoinGrant)
        // })

        // Stub: immediately grant reward.
        onReward(rewardedCoinGrant)
        loadRewardedAd()
    }

    // MARK: - Banner Ads

    func showBanner() {
        // TODO: Create and attach GADBannerView to the window.
        isBannerVisible = true
    }

    func hideBanner() {
        // TODO: Remove GADBannerView from the window.
        isBannerVisible = false
    }

    // MARK: - Interstitial Ads

    func showInterstitialIfReady() {
        // TODO: Load and present GADInterstitialAd at natural break points
        // (e.g., after every 3 completed games).
    }
}
