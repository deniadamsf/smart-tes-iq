import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import 'ad_helper.dart';

class RewardedAdManager {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoading = false;

  // FUNGSI 1: MEMUAT IKLAN KE MEMORI HP (Di Balik Layar)
  static void loadAd() {
    if (_rewardedAd != null || _isAdLoading) return;
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          print('RewardedAd gagal dimuat: $error');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  // FUNGSI 2: MENAMPILKAN IKLAN & MEMBERIKAN HADIAH
  static void showAd(BuildContext context, VoidCallback onRewardEarned) {
    if (_rewardedAd == null) {
      // Jika internet lemot dan iklan belum selesai dimuat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ads.not_ready'.tr()), // DIUBAH: Menggunakan kunci terjemahan
          backgroundColor: Colors.orange,
        ),
      );
      loadAd(); // Paksa muat ulang
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        // Saat user menutup iklan (X), buang iklan lama dan muat yang baru
        ad.dispose();
        _rewardedAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // JIKA USER BERHASIL MENONTON SAMPAI HABIS, JALANKAN FUNGSI HADIAH!
        onRewardEarned();
      },
    );
  }
}