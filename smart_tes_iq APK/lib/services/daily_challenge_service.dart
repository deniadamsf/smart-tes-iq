import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Jembatan ke endpoint Tantangan Harian.
///
/// Semua penilaian, penentuan tanggal, dan perhitungan durasi terjadi di
/// server. Di sini tidak ada logika benar/salah sama sekali — kalau ada,
/// berarti kunci jawaban bocor ke HP dan peringkat bisa dipalsukan.
class DailyChallengeService {
  static const String baseUrl = 'https://smarttesiq.cellanoma.my.id/public/api';
  static const Duration _timeout = Duration(seconds: 20);

  /// Kode hasil yang dipahami layar.
  static const String ok = 'ok';
  static const String needLogin = 'butuh_login';
  static const String offline = 'offline';
  static const String alreadyDone = 'sudah_selesai';
  static const String notStarted = 'belum_mulai';
  static const String failed = 'gagal';
  static const String invalid = 'tidak_valid';

  /// Token Laravel. `firebase_only_token` adalah penanda user yang masuk
  /// lewat Firebase tapi tidak punya token API — mereka tidak bisa memakai
  /// endpoint ini, jadi diperlakukan sama dengan belum login.
  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null || token.isEmpty || token == 'firebase_only_token') {
      return null;
    }
    return token;
  }

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, dynamic> _wrap(String code, [Map<String, dynamic>? data]) =>
      {'code': code, 'data': data ?? <String, dynamic>{}};

  /// Terjemahkan respons HTTP jadi kode yang dipahami layar.
  static Map<String, dynamic> _read(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return _wrap(failed);
    }

    if (res.statusCode == 200) return _wrap(ok, body);
    if (res.statusCode == 401) return _wrap(needLogin);

    // 409 = sudah selesai hari ini, 422 = belum mulai. Keduanya bukan error;
    // layar memakai isinya untuk menampilkan keadaan yang benar.
    final status = body['status'];
    if (status == alreadyDone) return _wrap(alreadyDone, body);
    if (status == notStarted) return _wrap(notStarted, body);
    // 422 dari nama tampilan: pesannya sudah ramah dan berbahasa Indonesia,
    // jadi diteruskan apa adanya ke layar.
    if (status == invalid) return _wrap(invalid, body);

    return _wrap(failed, body);
  }

  static Future<Map<String, dynamic>> start(String lang) async {
    final token = await _token();
    if (token == null) return _wrap(needLogin);

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/daily/start'),
            headers: _headers(token),
            body: jsonEncode({'lang': lang}),
          )
          .timeout(_timeout);
      return _read(res);
    } catch (_) {
      return _wrap(offline);
    }
  }

  /// [answers] berisi indeks pilihan (0-based) atau null kalau dilewati.
  /// Server yang menerjemahkannya jadi huruf dan menilainya.
  static Future<Map<String, dynamic>> submit(List<int?> answers) async {
    final token = await _token();
    if (token == null) return _wrap(needLogin);

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/daily/submit'),
            headers: _headers(token),
            body: jsonEncode({'answers': answers}),
          )
          .timeout(_timeout);
      return _read(res);
    } catch (_) {
      return _wrap(offline);
    }
  }

  static Future<Map<String, dynamic>> me() async {
    final token = await _token();
    if (token == null) return _wrap(needLogin);

    try {
      final res = await http
          .get(Uri.parse('$baseUrl/daily/me'), headers: _headers(token))
          .timeout(_timeout);
      return _read(res);
    } catch (_) {
      return _wrap(offline);
    }
  }

  // ===================================================================
  // PAPAN PERINGKAT
  // ===================================================================

  static Future<Map<String, dynamic>> leaderboardDaily() async {
    final token = await _token();
    if (token == null) return _wrap(needLogin);

    try {
      final res = await http
          .get(Uri.parse('$baseUrl/leaderboard/daily'), headers: _headers(token))
          .timeout(_timeout);
      return _read(res);
    } catch (_) {
      return _wrap(offline);
    }
  }

  /// Nama tampilan bersifat opt-in dan terpisah dari nama akun Google.
  /// Server yang memvalidasi panjang, karakter, dan keunikannya.
  static Future<Map<String, dynamic>> setDisplayName(String name) async {
    final token = await _token();
    if (token == null) return _wrap(needLogin);

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/leaderboard/display-name'),
            headers: _headers(token),
            body: jsonEncode({'display_name': name}),
          )
          .timeout(_timeout);
      return _read(res);
    } catch (_) {
      return _wrap(offline);
    }
  }

  /// [jenis] 'reguler' atau 'pro'.
  ///
  /// Skor kedua papan ini dihitung di HP lalu dikirim lewat /sync, jadi
  /// tidak bisa dijamin jujur seperti papan harian. Respons membawa
  /// 'terverifikasi': false — layar menampilkan bedanya ke user.
  static Future<Map<String, dynamic>> leaderboardIq(String jenis) async {
    final token = await _token();
    if (token == null) return _wrap(needLogin);

    try {
      final res = await http
          .get(Uri.parse('$baseUrl/leaderboard/$jenis'), headers: _headers(token))
          .timeout(_timeout);
      return _read(res);
    } catch (_) {
      return _wrap(offline);
    }
  }
}
