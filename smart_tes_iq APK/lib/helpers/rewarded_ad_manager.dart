import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import 'ad_helper.dart';

class RewardedAdManager {
  static RewardedAd? _rewardedAd;
  static DateTime? _loadedAt;
  static bool _isAdLoading = false;
  static bool _isSdkInitialized = false;
  static Timer? _retryTimer;
  static int _retryAttempt = 0;
  static Completer<bool>? _loadCompleter;

  /// Batas maksimal retry otomatis di background agar tidak dianggap spam
  /// oleh algoritma Google AdMob saat stok iklan sedang kosong (No Fill).
  static const int _maxBackgroundRetries = 3;
  static const List<int> _backoffSeconds = [15, 30, 60];

  /// Iklan AdMob kedaluwarsa setelah 60 menit di memori.
  /// Kita segarkan jika usianya sudah lebih dari 50 menit.
  static const Duration _adExpiration = Duration(minutes: 50);

  /// Inisialisasi Mobile Ads SDK (termasuk adapter Mediasi) dan muat iklan pertama.
  static Future<void> initialize() async {
    if (!_isSdkInitialized) {
      try {
        final status = await MobileAds.instance.initialize();
        _isSdkInitialized = true;
        debugPrint('[RewardedAdManager] Google Mobile Ads SDK berhasil diinisialisasi.');
        status.adapterStatuses.forEach((adapter, info) {
          debugPrint(
            '[RewardedAdManager] Adapter Mediasi [$adapter]: ${info.state} (${info.description})',
          );
        });
      } catch (e) {
        debugPrint('[RewardedAdManager] Gagal inisialisasi Mobile Ads SDK: $e');
      }
    }
    loadAd(forceResetRetry: true);
  }

  /// Mengecek apakah iklan masih valid dan belum kedaluwarsa (> 50 menit).
  static bool get _isAdFresh {
    if (_rewardedAd == null || _loadedAt == null) return false;
    return DateTime.now().difference(_loadedAt!) < _adExpiration;
  }

  /// Apakah iklan sudah siap ditampilkan sekarang juga.
  static bool get isReady => _isAdFresh;

  // FUNGSI 1: MEMUAT IKLAN KE MEMORI HP (Single-Flight & Aman dari Spam)
  static void loadAd({bool forceResetRetry = false}) {
    if (forceResetRetry) {
      _retryAttempt = 0;
    }

    // Jika iklan sudah ada tapi kedaluwarsa (>50 menit), buang dan muat baru
    if (_rewardedAd != null && !_isAdFresh) {
      debugPrint('[RewardedAdManager] Iklan di memori sudah kedaluwarsa, memuat ulang...');
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _loadedAt = null;
    }

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
    _loadCompleter = Completer<bool>();
    debugPrint('[RewardedAdManager] Memuat RewardedAd dari AdMob/Mediasi...');

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint(
            '[RewardedAdManager] RewardedAd BERHASIL dimuat '
            '(Mediation: ${ad.responseInfo?.mediationAdapterClassName ?? "AdMob"})',
          );
          _rewardedAd = ad;
          _loadedAt = DateTime.now();
          _isAdLoading = false;
          _retryAttempt = 0;
          _retryTimer?.cancel();
          if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
            _loadCompleter!.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[RewardedAdManager] RewardedAd GAGAL dimuat '
            '(code=${error.code}, message=${error.message})',
          );
          _rewardedAd = null;
          _loadedAt = null;
          _isAdLoading = false;
          if (_loadCompleter != null && !_loadCompleter!.isCompleted) {
            _loadCompleter!.complete(false);
          }
          _scheduleRetry();
        },
      ),
    );
  }

  /// Menjadwalkan muat ulang otomatis di latar belakang dengan jeda sehat
  /// (15s -> 30s -> 60s, maksimal 3x) agar tidak memicu penalti Match Rate AdMob.
  static void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryAttempt >= _maxBackgroundRetries) {
      debugPrint(
        '[RewardedAdManager] Batas retry background ($_maxBackgroundRetries x) tercapai. '
        'Menunggu interaksi user berikutnya agar tidak spam request ke AdMob.',
      );
      return;
    }

    final delaySec = _backoffSeconds[_retryAttempt.clamp(0, _backoffSeconds.length - 1)];
    _retryAttempt++;
    debugPrint('[RewardedAdManager] Menjadwalkan muat ulang otomatis (#$_retryAttempt) dalam $delaySec detik...');
    _retryTimer = Timer(Duration(seconds: delaySec), () {
      loadAd();
    });
  }

  /// Menunggu sampai iklan siap tanpa melakukan spam loop 150ms.
  ///
  /// - Bila iklan sudah siap di memori: selesai SEKETIKA (0 ms).
  /// - Bila sedang dimuat / belum ada: memicu 1 request bersih dan menunggu
  ///   hasil callback-nya (maksimal hingga [timeout]).
  static Future<bool> ensureLoaded({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (isReady) return true;

    if (!_isAdLoading) {
      loadAd(forceResetRetry: true);
    }

    final completer = _loadCompleter;
    if (completer != null) {
      final loaded = await completer.future.timeout(
        timeout,
        onTimeout: () => isReady,
      );
      if (loaded || isReady) return true;
    }

    return isReady;
  }

  static bool _isShowingAd = false;

  // FUNGSI 2: MENAMPILKAN IKLAN & MEMBERIKAN HADIAH
  static Future<void> showAd(
    BuildContext context,
    VoidCallback onRewardEarned, {
    VoidCallback? onUnavailable,
    VoidCallback? onDismissed,
  }) async {
    if (_isShowingAd) return;

    // Jika iklan belum siap di memori saat tombol ditekan (mis. di layar Hasil Tes / Chat AI),
    // tunggu hingga 6 detik dengan indikator loading ringan agar iklan langsung tampil
    // pada klik pertama tanpa melempar pesan "Iklan belum siap".
    if (!isReady) {
      _isShowingAd = true;
      BuildContext? dialogCtx;
      bool dialogOpen = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogCtx = ctx;
          return PopScope(
            canPop: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Material(
                      color: Colors.transparent,
                      child: Text(
                        'daily.ad_preparing'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ).then((_) => dialogOpen = false);

      final loaded = await ensureLoaded(timeout: const Duration(seconds: 6));

      if (dialogOpen && dialogCtx != null && dialogCtx!.mounted) {
        Navigator.of(dialogCtx!).pop();
      }
      _isShowingAd = false;

      if (!context.mounted) return;

      if (!loaded || !isReady) {
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
    }

    _isShowingAd = true;
    bool earned = false;
    final adToShow = _rewardedAd!;
    _rewardedAd = null;
    _loadedAt = null;

    adToShow.fullScreenContentCallback = FullScreenContentCallback(
      onAdImpression: (ad) {
        debugPrint('[RewardedAdManager] Impression RewardedAd tercatat.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[RewardedAdManager] RewardedAd ditutup oleh pengguna.');
        _isShowingAd = false;
        ad.dispose();

        // Beri jeda 800ms agar Activity iklan full-screen Android selesai ditutup
        // dengan bersih sebelum meminta iklan cadangan berikutnya.
        Future.delayed(const Duration(milliseconds: 800), () {
          loadAd(forceResetRetry: true);
        });

        if (!earned) {
          onDismissed?.call();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[RewardedAdManager] RewardedAd gagal tampil: $error');
        _isShowingAd = false;
        ad.dispose();
        Future.delayed(const Duration(milliseconds: 800), () {
          loadAd(forceResetRetry: true);
        });
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

