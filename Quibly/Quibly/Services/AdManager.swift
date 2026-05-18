import GoogleMobileAds
import SwiftUI
import Combine

@MainActor
final class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    // MARK: - Ad Unit IDs (replace test IDs with production IDs before shipping)

    enum AdUnitID {
        static let rewardedCoins = "ca-app-pub-3940256099942544/1712485313"
        static let banner        = "ca-app-pub-3940256099942544/2934735716"
        static let interstitial  = "ca-app-pub-3940256099942544/4411468910"
    }

    // MARK: - State

    @Published var isRewardedAdReady = false
    @Published var isLoadingAd = false
    @Published var isBannerVisible = false

    let rewardedCoinGrant = 50

    private var rewardedAd: RewardedAd?
    private var onDismissCallback: (() -> Void)?

    private override init() {
        super.init()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        Task { await loadRewardedAd() }
    }

    // MARK: - Rewarded Ads

    func loadRewardedAd() async {
        guard !isLoadingAd else { return }
        isLoadingAd = true
        isRewardedAdReady = false
        do {
            rewardedAd = try await RewardedAd.load(
                with: AdUnitID.rewardedCoins, request: Request())
            rewardedAd?.fullScreenContentDelegate = self
            isRewardedAdReady = true
        } catch {
            print("[AdManager] Rewarded ad failed to load: \(error.localizedDescription)")
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await loadRewardedAd()
            }
        }
        isLoadingAd = false
    }

    func showRewardedAd(onReward: @escaping (Int) -> Void, onDismiss: (() -> Void)? = nil) {
        guard isRewardedAdReady, let ad = rewardedAd else {
            Task { await loadRewardedAd() }
            return
        }
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else { return }

        onDismissCallback = onDismiss
        isRewardedAdReady = false

        ad.present(from: rootVC) { [weak self] in
            guard let self else { return }
            onReward(self.rewardedCoinGrant)
        }
    }

    // MARK: - Banner Ads

    func showBanner() {
        isBannerVisible = true
    }

    func hideBanner() {
        isBannerVisible = false
    }

    // MARK: - Interstitial Ads

    func showInterstitialIfReady() {
        // TODO: load and present GADInterstitialAd at natural break points
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidRecordImpression(_ ad: FullScreenPresentingAd) {}
    nonisolated func adDidRecordClick(_ ad: FullScreenPresentingAd) {}
    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {}
    nonisolated func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {}

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            rewardedAd = nil
            onDismissCallback?()
            onDismissCallback = nil
            await loadRewardedAd()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[AdManager] Ad failed to present: \(error.localizedDescription)")
        Task { @MainActor [weak self] in
            self?.rewardedAd = nil
            await self?.loadRewardedAd()
        }
    }
}
