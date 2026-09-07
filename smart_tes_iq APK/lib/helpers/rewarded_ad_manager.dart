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
  //
  // Dipakai sebagai GERBANG di Tantangan Harian, jadi pemanggil harus tahu
  // ketiga kemungkinan akhirnya — bukan cuma yang berhasil:
  //
  //   onRewardEarned : iklan ditonton sampai selesai.
  //   onUnavailable  : iklan tidak tersedia (offline / belum termuat / gagal
  //                    tampil). Pemanggil WAJIB tetap meloloskan user.
  //                    Kehilangan satu impresi jauh lebih murah daripada
  //                    mengunci user dari fitur dan dapat ulasan bintang satu.
  //   onDismissed    : iklan ditutup sebelum selesai. Pemanggil perlu ini
  //                    untuk mengaktifkan lagi tombolnya.
  //
  // onUnavailable dan onDismissed opsional supaya pemanggil lama
  // (showAd(context, cb)) tetap jalan tanpa diubah.
  static void showAd(
    BuildContext context,
    VoidCallback onRewardEarned, {
    VoidCallback? onUnavailable,
    VoidCallback? onDismissed,
  }) {
    if (_rewardedAd == null) {
      loadAd(); // muat untuk kesempatan berikutnya

      if (onUnavailable != null) {
        onUnavailable();
      } else {
        // Perilaku lama dipertahankan untuk pemanggil yang belum diperbarui.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ads.not_ready'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    bool earned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadAd();
        // Hadiah sudah diberikan lewat onUserEarnedReward. Kalau belum,
        // berarti user menutup iklan lebih awal.
        if (!earned) onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadAd();
        // Gagal tampil bukan salah user — perlakukan seperti tidak tersedia.
        onUnavailable?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        earned = true;
        onRewardEarned();
      },
    );
  }
}
