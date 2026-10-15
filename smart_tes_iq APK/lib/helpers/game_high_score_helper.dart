import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class GameHighScoreHelper {
  static const String kAnagram = 'anagram';
  static const String kStroop = 'stroop';
  static const String kMathRush = 'math_rush';
  static const String kMemoryMatch = 'memory_match';
  static const String kSudoku = 'sudoku';

  static const List<String> allGames = [
    kAnagram,
    kStroop,
    kMathRush,
    kMemoryMatch,
    kSudoku,
  ];

  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  static String _prefKey(String gameKey) => 'hs_game_$gameKey';

  /// Mengambil rekor tertinggi satu game dari penyimpanan lokal.
  static Future<int> getHighScore(String gameKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKey(gameKey)) ?? 0;
  }

  /// Mengambil seluruh rekor tertinggi untuk ditampilkan di Menu Asah Otak
  /// maupun dikirim ke server saat sinkronisasi.
  static Future<Map<String, int>> getAllHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> result = {};
    for (final key in allGames) {
      result[key] = prefs.getInt(_prefKey(key)) ?? 0;
    }
    return result;
  }

  /// Memperbarui rekor tertinggi jika [newScore] melampaui rekor lama.
  /// Mengembalikan `true` jika berhasil memecahkan rekor baru!
  static Future<bool> updateHighScore(
    String gameKey,
    int newScore, {
    bool syncToServer = true,
  }) async {
    if (newScore <= 0) return false;
    final prefs = await SharedPreferences.getInstance();
    final int currentBest = prefs.getInt(_prefKey(gameKey)) ?? 0;

    if (newScore > currentBest) {
      await prefs.setInt(_prefKey(gameKey), newScore);
      refreshNotifier.value++;
      if (syncToServer) {
        // Backup otomatis ke cloud jika pengguna sudah login
        AuthService().syncDataNow();
      }
      return true;
    }
    return false;
  }

  /// Menggabungkan rekor dari server ke penyimpanan lokal (ambil nilai tertinggi).
  static Future<void> applyFromServer(Map<String, dynamic>? serverData) async {
    if (serverData == null) return;
    final prefs = await SharedPreferences.getInstance();
    bool changed = false;

    for (final key in allGames) {
      final raw = serverData[key];
      if (raw == null) continue;
      final int serverScore = int.tryParse(raw.toString()) ?? 0;
      final int localScore = prefs.getInt(_prefKey(key)) ?? 0;
      if (serverScore > localScore) {
        await prefs.setInt(_prefKey(key), serverScore);
        changed = true;
      }
    }

    if (changed) {
      refreshNotifier.value++;
    }
  }

  /// Menghapus rekor lokal saat pengguna logout.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in allGames) {
      await prefs.remove(_prefKey(key));
    }
    refreshNotifier.value++;
  }
}
