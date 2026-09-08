import 'package:shared_preferences/shared_preferences.dart';

/// Satu-satunya tempat kredit dibaca dan ditulis.
///
/// KENAPA ADA: sebelumnya aplikasi hanya menyimpan SALDO, dan server hanya
/// menyimpan nilai tertinggi yang pernah dimiliki lalu mengembalikannya
/// sebagai saldo. Akibatnya user bisa memakai habis kreditnya, menekan
/// tombol sinkronisasi di layar Profil, dan kreditnya kembali penuh —
/// berulang kali, tanpa membongkar apa pun.
///
/// Sekarang yang dicatat adalah dua penghitung yang HANYA NAIK:
///
///   diberikan  : total kredit yang pernah diberikan (bertambah saat beli)
///   terpakai   : total kredit yang pernah dipakai   (bertambah saat pakai)
///   saldo      = diberikan - terpakai
///
/// Keduanya monoton naik, jadi aman disinkronkan dengan max() di server:
/// perangkat yang tertinggal tidak bisa menurunkan angka perangkat lain.
///
/// Kunci lama (`wartegg_credits`, dst.) TETAP menyimpan saldo, supaya kode
/// lain yang membacanya langsung tidak perlu diubah.
class CreditStore {
  static const String kWartegg = 'wartegg_credits';
  static const String kEqSq = 'eq_sq_credits';
  static const String kIqPro = 'kredit_iq_pro';

  static const List<String> semua = [kWartegg, kEqSq, kIqPro];

  static String _kDiberikan(String k) => '${k}_diberikan';
  static String _kTerpakai(String k) => '${k}_terpakai';

  /// Menyiapkan prefs sekaligus menjalankan migrasi sekali jalan.
  ///
  /// User yang update dari versi lama hanya punya saldo. Saldo itu dianggap
  /// sebagai "diberikan", dan "terpakai" mulai dari 0 — sehingga saldo yang
  /// mereka lihat tidak berubah sedikit pun setelah update.
  static Future<SharedPreferences> _prefs() async {
    final p = await SharedPreferences.getInstance();

    for (final k in semua) {
      if (p.getInt(_kDiberikan(k)) == null) {
        await p.setInt(_kDiberikan(k), p.getInt(k) ?? 0);
        await p.setInt(_kTerpakai(k), p.getInt(_kTerpakai(k)) ?? 0);
      }
    }
    return p;
  }

  static Future<int> _hitungUlangSaldo(SharedPreferences p, String k) async {
    final diberikan = p.getInt(_kDiberikan(k)) ?? 0;
    final terpakai = p.getInt(_kTerpakai(k)) ?? 0;
    final saldo = (diberikan - terpakai) < 0 ? 0 : diberikan - terpakai;
    await p.setInt(k, saldo);
    return saldo;
  }

  static Future<int> saldo(String k) async {
    final p = await _prefs();
    return _hitungUlangSaldo(p, k);
  }

  /// Dipanggil saat pembelian berhasil.
  static Future<int> beri(String k, int jumlah) async {
    final p = await _prefs();
    await p.setInt(_kDiberikan(k), (p.getInt(_kDiberikan(k)) ?? 0) + jumlah);
    return _hitungUlangSaldo(p, k);
  }

  /// Dipanggil saat kredit dipakai. Tidak pernah membuat saldo negatif.
  static Future<int> pakai(String k, int jumlah) async {
    final p = await _prefs();
    final saldoKini = await _hitungUlangSaldo(p, k);
    final dipakai = jumlah > saldoKini ? saldoKini : jumlah;

    await p.setInt(_kTerpakai(k), (p.getInt(_kTerpakai(k)) ?? 0) + dipakai);
    return _hitungUlangSaldo(p, k);
  }

  /// Nilai yang dikirim ke server saat sync. Keduanya monoton naik.
  static Future<Map<String, int>> diberikanSemua() async {
    final p = await _prefs();
    return {for (final k in semua) k: p.getInt(_kDiberikan(k)) ?? 0};
  }

  static Future<Map<String, int>> terpakaiSemua() async {
    final p = await _prefs();
    return {for (final k in semua) k: p.getInt(_kTerpakai(k)) ?? 0};
  }

  /// Menyerap angka dari server saat login atau pemulihan.
  ///
  /// Diambil nilai TERBESAR antara perangkat dan server untuk kedua
  /// penghitung. Karena keduanya hanya naik, ini tidak pernah menghilangkan
  /// pembelian maupun menghidupkan lagi kredit yang sudah terpakai.
  ///
  /// Kalau server belum mengirim rinciannya (mis. backend versi lama),
  /// [saldoServer] dipakai sebagai penyetelan terakhir supaya tetap masuk akal.
  static Future<void> terapkanDariServer({
    required String k,
    int? diberikanServer,
    int? terpakaiServer,
    int? saldoServer,
  }) async {
    final p = await _prefs();

    if (diberikanServer != null) {
      final kini = p.getInt(_kDiberikan(k)) ?? 0;
      await p.setInt(
          _kDiberikan(k), diberikanServer > kini ? diberikanServer : kini);
    }

    if (terpakaiServer != null) {
      final kini = p.getInt(_kTerpakai(k)) ?? 0;
      await p.setInt(
          _kTerpakai(k), terpakaiServer > kini ? terpakaiServer : kini);
    }

    if (diberikanServer == null && terpakaiServer == null && saldoServer != null) {
      // Backend lama: hanya saldo yang tersedia. Selaraskan lewat penghitung
      // 'diberikan' supaya saldo hasil hitungnya cocok.
      final terpakai = p.getInt(_kTerpakai(k)) ?? 0;
      await p.setInt(_kDiberikan(k), saldoServer + terpakai);
    }

    await _hitungUlangSaldo(p, k);
  }

  /// Dipanggil saat logout — semuanya dibersihkan, termasuk penghitungnya.
  static Future<void> bersihkan() async {
    final p = await SharedPreferences.getInstance();
    for (final k in semua) {
      await p.remove(k);
      await p.remove(_kDiberikan(k));
      await p.remove(_kTerpakai(k));
    }
  }
}
