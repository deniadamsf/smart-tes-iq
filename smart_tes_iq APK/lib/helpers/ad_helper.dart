import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // ==========================================
  // ID IKLAN UTAMA GOOGLE ADMOB (MEDIATION CONTROLLER)
  // ==========================================
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-4891614770967901/4638949397';
    return '';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-4891614770967901/9624187342';
    return '';
  }

  // ==========================================
  // ID MITRA MEDIASI 1: UNITY ADS (BIDDING)
  // ==========================================
  static const String unityGameId = '800399256';
  static const String unityRewardedPlacementId = 'BP_Rewarded_Android';
  static const String unityBannerPlacementId = 'BP_Banner_Android';

  // ==========================================
  // ID MITRA MEDIASI 2: LIFTOFF MONETIZE / VUNGLE (BIDDING)
  // ==========================================
  static const String liftoffAppId = '6ad053875bdb53e5e0ed6499';
  static const String liftoffRewardedPlacementId = 'REWARDED_SMART_TES_IQ-4307244';
  static const String liftoffBannerPlacementId = 'BANNER_SMART_TES_IQ-0435868';
}

// ========================================================
// WIDGET BANNER PRAKTIS (ANCHORED / INLINE ADAPTIVE BANNER)
// ========================================================
class CustomBannerAd extends StatefulWidget {
  const CustomBannerAd({super.key});

  @override
  State<CustomBannerAd> createState() => _CustomBannerAdState();
}

class _CustomBannerAdState extends State<CustomBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;

  static const int _maxRetries = 2;

  Future<void> _loadAdaptiveBanner({double? maxWidth, double? maxHeight}) async {
    if (!mounted || _isLoading) return;
    _isLoading = true;

    final mediaWidth = MediaQuery.of(context).size.width;
    final int adWidth = (maxWidth != null && maxWidth.isFinite && maxWidth > 0)
        ? maxWidth.truncate()
        : mediaWidth.truncate();
    final int allowedHeight =
        (maxHeight != null && maxHeight.isFinite && maxHeight > 0)
            ? maxHeight.truncate()
            : 60;

    // 1. Coba Anchored Adaptive Banner (Format dengan eCPM & Match Rate tertinggi)
    AdSize? adSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth);

    // 2. Pastikan tingginya muat di dalam Container induk (mis. height: 50 atau 59).
    // Jika Anchored Adaptive lebih tinggi dari wadahnya, gunakan Inline Adaptive
    // dengan lebar penuh layar agar iklan tidak ditolak AdView karena kurang ruang.
    if (adSize == null || adSize.height > allowedHeight) {
      adSize = AdSize.getInlineAdaptiveBannerAdSize(
        adWidth,
        allowedHeight.clamp(50, 60),
      );
    }

    if (!mounted) {
      _isLoading = false;
      return;
    }

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: adSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          _isLoading = false;
          _retryAttempt = 0;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('[CustomBannerAd] Banner gagal dimuat: $err');
          ad.dispose();
          _bannerAd = null;
          _isLoading = false;
          if (!mounted) return;
          setState(() => _isLoaded = false);

          // Retry sopan maksimal 2x dengan jeda 45 detik (bukan spam)
          // supaya jika user sedang mengerjakan tes 10 menit, banner tetap bisa terisi.
          if (_retryAttempt < _maxRetries) {
            _retryAttempt++;
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 45), () {
              if (mounted) {
                _loadAdaptiveBanner(maxWidth: maxWidth, maxHeight: maxHeight);
              }
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_bannerAd == null && !_isLoading && _retryAttempt == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _bannerAd == null && !_isLoading) {
              _loadAdaptiveBanner(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              );
            }
          });
        }

        if (_isLoaded && _bannerAd != null) {
          return Container(
            color: Colors.white,
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          );
        }
        return const SizedBox(height: 50);
      },
    );
  }
}