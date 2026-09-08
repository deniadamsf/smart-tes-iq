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

  /// Apakah iklan sudah siap ditampilkan sekarang juga.
  static bool get isReady => _rewardedAd != null;

  /// Menunggu sampai iklan siap, memuat ulang kalau perlu.
  ///
  /// KENAPA PERLU: loadAd() hanya dipanggil sekali saat aplikasi dibuka, dan
  /// pemuatan berikutnya baru jalan setelah sebuah iklan ditutup. Jadi ada
  /// jendela beberapa detik di mana iklan belum siap.
  ///
  /// Layar lama menangani ini dengan menampilkan snackbar lalu berhenti,
  /// sehingga user menekan lagi dan iklannya muncul. Layar yang meneruskan
  /// begitu saja saat iklan belum siap justru TIDAK PERNAH menampilkan
  /// iklan sama sekali. Fungsi ini menunggu sebentar dulu supaya iklannya
  /// benar-benar dapat kesempatan tampil.
  ///
  /// Mengembalikan true kalau iklan siap sebelum [timeout] habis.
  static Future<bool> ensureLoaded({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_rewardedAd != null) return true;

    loadAd();

    final batas = DateTime.now().add(timeout);
    var percobaanUlang = 0;

    while (_rewardedAd == null && DateTime.now().isBefore(batas)) {
      await Future.delayed(const Duration(milliseconds: 250));

      // Kalau pemuatan gagal, _isAdLoading kembali false. Coba lagi paling
      // banyak dua kali supaya tidak menghujani jaringan saat offline.
      if (_rewardedAd == null && !_isAdLoading && percobaanUlang < 2) {
        percobaanUlang++;
        loadAd();
      }
    }

    return _rewardedAd != null;
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
