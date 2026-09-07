import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // ==========================================
  // ID IKLAN BANNER ASLI ANDA
  // ==========================================
  static String get bannerAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-4891614770967901/4638949397';
    return '';
  }

  // ==========================================
  // ID IKLAN REWARDED VIDEO ASLI ANDA
  // ==========================================
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-4891614770967901/9624187342';
    return '';
  }
}

// ========================================================
// WIDGET BANNER PRAKTIS
// ========================================================
class CustomBannerAd extends StatefulWidget {
  const CustomBannerAd({super.key});

  @override
  State<CustomBannerAd> createState() => _CustomBannerAdState();
}

class _CustomBannerAdState extends State<CustomBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          print('Banner gagal dimuat: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IKLAN KEMBALI DINYALAKAN (MODE SCREENSHOT DIMATIKAN)
    if (_isLoaded && _bannerAd != null) {
      return Container(
        color: Colors.white,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Kotak kosong transparan saat menunggu iklan dimuat oleh Google
    return const SizedBox(height: 60);
  }
}