import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import 'ad_helper.dart';

class RewardedAdManager {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoading = false;
  static bool _isSdkInitialized = false;
  static Timer? _retryTimer;
  static int _retryDelaySeconds = 3;

  /// Inisialisasi Mobile Ads SDK dan langsung mulai memuat iklan pertama ke memori.
  /// Dipanggil di main.dart saat aplikasi dibuka.
  static Future<void> initialize() async {
    if (!_isSdkInitialized) {
      try {
        await MobileAds.instance.initialize();
        _isSdkInitialized = true;
        debugPrint('[RewardedAdManager] Google Mobile Ads SDK berhasil diinisialisasi.');
      } catch (e) {
        debugPrint('[RewardedAdManager] Gagal inisialisasi Mobile Ads SDK: $e');
      }
    }
    loadAd();
  }

  // FUNGSI 1: MEMUAT IKLAN KE MEMORI HP (Di Balik Layar / Background Preload)
  static void loadAd() {
    if (_rewardedAd != null) {
      debugPrint('[RewardedAdManager] RewardedAd sudah siap di memori.');
      return;
    }
    if (_isAdLoading) {
      debugPrint('[RewardedAdManager] RewardedAd sedang dalam proses pemuatan...');
      return;
    }

    _retryTimer?.cancel();
    _isAdLoading = true;
    debugPrint('[RewardedAdManager] Memuat RewardedAd dari AdMob...');

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[RewardedAdManager] RewardedAd BERHASIL dimuat & siap digunakan!');
          _rewardedAd = ad;
          _isAdLoading = false;
          _retryDelaySeconds = 3; // Reset jeda retry
          _retryTimer?.cancel();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[RewardedAdManager] RewardedAd GAGAL dimuat: $error');
          _rewardedAd = null;
          _isAdLoading = false;
          _scheduleRetry();
        },
      ),
    );
  }

  /// Menjadwalkan muat ulang otomatis di latar belakang jika gagal.
  /// Menjamin memori HP tidak kosong jika koneksi sempat drop saat awal aplikasi dibuka.
  static void _scheduleRetry() {
    _retryTimer?.cancel();
    debugPrint('[RewardedAdManager] Menjadwalkan muat ulang otomatis dalam $_retryDelaySeconds detik...');
    _retryTimer = Timer(Duration(seconds: _retryDelaySeconds), () {
      _retryDelaySeconds = (_retryDelaySeconds * 2).clamp(3, 45);
      loadAd();
    });
  }

  /// Apakah iklan sudah siap ditampilkan sekarang juga.
  static bool get isReady => _rewardedAd != null;

  /// Menunggu sampai iklan siap, memuat ulang kalau perlu.
  ///
  /// Bila iklan sudah standby di memori (kondisi umum berkat startup preload),
  /// fungsi ini selesai SEKETIKA (0 ms) tanpa membuat user menunggu.
  /// Bila baru buka aplikasi dan proses background belum selesai, fungsi ini
  /// menunggu hingga iklan masuk memori atau batas [timeout] tercapai.
  static Future<bool> ensureLoaded({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (_rewardedAd != null) return true;

    loadAd();

    final batas = DateTime.now().add(timeout);
    while (_rewardedAd == null && DateTime.now().isBefore(batas)) {
      await Future.delayed(const Duration(milliseconds: 150));

      // Kalau pemuatan sebelumnya gagal cepat, langsung picu lagi tanpa tunggu timer retry
      if (_rewardedAd == null && !_isAdLoading) {
        loadAd();
      }
    }

    return _rewardedAd != null;
  }

  // FUNGSI 2: MENAMPILKAN IKLAN & MEMBERIKAN HADIAH
  //
  // Segera setelah sebuah iklan ditutup / gagal tampil, otomatis langsung memicu
  // pemuatan iklan cadangan berikutnya di latar belakang agar selalu siap.
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
    final adToShow = _rewardedAd!;
    _rewardedAd = null; // Konsumsi instance iklan agar tidak bisa dipanggil ganda

    adToShow.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[RewardedAdManager] RewardedAd ditutup oleh pengguna.');
        ad.dispose();
        // LANGSUNG PRELOAD IKLAN CADANGAN BERIKUTNYA DI BACKGROUND!
        loadAd();

        // Hadiah sudah diberikan lewat onUserEarnedReward. Kalau belum,
        // berarti user menutup iklan lebih awal.
        if (!earned) {
          onDismissed?.call();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[RewardedAdManager] RewardedAd gagal tampil: $error');
        ad.dispose();
        loadAd(); // Muat pengganti
        onUnavailable?.call();
      },
    );

    adToShow.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('[RewardedAdManager] Hadiah rewarded diterima.');
        earned = true;
        onRewardEarned();
      },
    );
  }
}

