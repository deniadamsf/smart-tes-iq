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
// WIDGET BANNER PRAKTIS (ANCHORED ADAPTIVE + 320x50 FALLBACK)
// ========================================================
class CustomBannerAd extends StatefulWidget {
  const CustomBannerAd({super.key});

  @override
  State<CustomBannerAd> createState() => _CustomBannerAdState();
}

class _CustomBannerAdState extends State<CustomBannerAd>
    with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _useStandardBannerFallback = false;
  bool _wasTickerEnabled = false;
  int _retryAttempt = 0;
  Timer? _retryTimer;
  double? _lastMaxWidth;
  double? _lastMaxHeight;

  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        mounted &&
        _bannerAd == null &&
        !_isLoading &&
        TickerMode.valuesOf(context).enabled) {
      _retryAttempt = 0;
      _useStandardBannerFallback = false;
      _loadBanner(maxWidth: _lastMaxWidth, maxHeight: _lastMaxHeight);
    }
  }

  Future<void> _loadBanner({double? maxWidth, double? maxHeight}) async {
    if (!mounted || _isLoading) return;
    // Jangan memuat banner saat tab masih tersembunyi di belakang IndexedStack
    if (!TickerMode.valuesOf(context).enabled) return;

    _isLoading = true;
    _lastMaxWidth = maxWidth;
    _lastMaxHeight = maxHeight;

    final mediaWidth = MediaQuery.of(context).size.width;
    final int adWidth = (maxWidth != null && maxWidth.isFinite && maxWidth > 0)
        ? maxWidth.truncate()
        : mediaWidth.truncate();
    final int allowedHeight =
        (maxHeight != null && maxHeight.isFinite && maxHeight > 0)
            ? maxHeight.truncate()
            : 60;

    AdSize adSize = AdSize.banner; // Default 320x50 (kompatibel penuh dengan AdMob, Unity & Liftoff)

    if (!_useStandardBannerFallback) {
      final anchoredSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        adWidth,
      );
      if (anchoredSize != null &&
          anchoredSize.height > 0 &&
          anchoredSize.height <= allowedHeight) {
        adSize = anchoredSize;
      }
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
          debugPrint(
            '[CustomBannerAd] Banner BERHASIL dimuat (${adSize.width}x${adSize.height}, '
            'Mediation: ${ad.responseInfo?.mediationAdapterClassName ?? "AdMob"})',
          );
          _isLoading = false;
          _retryAttempt = 0;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint(
            '[CustomBannerAd] Banner (${adSize.width}x${adSize.height}) gagal dimuat: $err',
          );
          ad.dispose();
          _bannerAd = null;
          _isLoading = false;
          if (!mounted) return;
          setState(() => _isLoaded = false);

          // Jika tadi mencoba Anchored Adaptive dan gagal (No Fill),
          // langsung fallback ke ukuran standar 320x50 (AdSize.banner) dalam 2 detik
          // agar stok iklan 320x50 dari Unity Ads, Liftoff, dan AdMob dapat masuk.
          if (!_useStandardBannerFallback && adSize != AdSize.banner) {
            _useStandardBannerFallback = true;
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 2), () {
              if (mounted) {
                _loadBanner(maxWidth: maxWidth, maxHeight: maxHeight);
              }
            });
            return;
          }

          // Retry sopan maksimal 2x dengan jeda 30 detik (bukan spam)
          if (_retryAttempt < _maxRetries) {
            _retryAttempt++;
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 30), () {
              if (mounted) {
                _loadBanner(maxWidth: maxWidth, maxHeight: maxHeight);
              }
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTickerEnabled = TickerMode.valuesOf(context).enabled;

    // Jika tab baru saja menjadi aktif (mis. user membuka tab Asah Otak / Chat AI)
    // dan banner belum ada, reset retry agar langsung dimuat.
    if (isTickerEnabled && !_wasTickerEnabled && _bannerAd == null && !_isLoading) {
      _retryAttempt = 0;
      _useStandardBannerFallback = false;
    }
    _wasTickerEnabled = isTickerEnabled;

    return LayoutBuilder(
      builder: (context, constraints) {
        _lastMaxWidth = constraints.maxWidth;
        _lastMaxHeight = constraints.maxHeight;

        if (isTickerEnabled &&
            _bannerAd == null &&
            !_isLoading &&
            _retryAttempt == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _bannerAd == null && !_isLoading) {
              _loadBanner(
                maxWidth: constraints.maxWidth,
                maxHeight: constraints.maxHeight,
              );
            }
          });
        }

        if (_isLoaded && _bannerAd != null) {
          final double w = _bannerAd!.size.width > 0
              ? _bannerAd!.size.width.toDouble()
              : 320.0;
          final double h = _bannerAd!.size.height > 0
              ? _bannerAd!.size.height.toDouble()
              : 50.0;

          return Container(
            color: Colors.white,
            alignment: Alignment.center,
            width: w,
            height: h,
            child: AdWidget(ad: _bannerAd!),
          );
        }
        return const SizedBox(height: 50);
      },
    );
  }
}