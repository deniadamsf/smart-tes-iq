import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';

class AuthService {
  static final ValueNotifier<int> refreshTrigger = ValueNotifier(0);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final String baseUrl = 'https://smarttesiq.cellanoma.my.id/public/api';

  Future<bool> loginAndSync() async {
    try {
      await _googleSignIn.initialize();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', userCredential.user?.displayName ?? 'Pengguna');
      await prefs.setString('user_email', userCredential.user?.email ?? '');

      try {
        final loginResponse = await http.post(
          Uri.parse('$baseUrl/auth/google'),
          body: {
            'name': userCredential.user?.displayName ?? 'Pengguna',
            'email': userCredential.user?.email ?? '',
            'google_id': userCredential.user?.uid ?? googleUser.id,
          },
        );

        if (loginResponse.statusCode == 200 || loginResponse.statusCode == 201) {
          final loginData = jsonDecode(loginResponse.body);
          final token = loginData['access_token'];
          await prefs.setString('api_token', token);

          await syncDataNow();
          await restoreDataFromServer();

        } else {
          await prefs.setString('api_token', 'firebase_only_token');
        }
      } catch (e) {
        await prefs.setString('api_token', 'firebase_only_token');
      }

      return true;
    } catch (e) {
      print('Error Login Firebase: $e');
      return false;
    }
  }

  Future<bool> restoreDataFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null || token == 'firebase_only_token') return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-data'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // --- TAMBAHAN BARU: Tarik koin dari server ke HP ---
        if (data['wartegg_credits'] != null) await prefs.setInt('wartegg_credits', int.tryParse(data['wartegg_credits'].toString()) ?? 0);
        if (data['eq_sq_credits'] != null) await prefs.setInt('eq_sq_credits', int.tryParse(data['eq_sq_credits'].toString()) ?? 0);
        if (data['kredit_iq_pro'] != null) await prefs.setInt('kredit_iq_pro', int.tryParse(data['kredit_iq_pro'].toString()) ?? 0);
        // ---------------------------------------------------

        final db = await DatabaseHelper.instance.database;

        await db.delete('test_results');
        await db.delete('chat_history');

        int timeOffset = 0;
        // ... (Kode untuk loop test dan chat Anda di bawah ini tidak berubah) ...
        if (data['tests'] != null) {
          for (var test in data['tests']) {
            DateTime artificialTime = DateTime.now().subtract(const Duration(hours: 1)).add(Duration(seconds: timeOffset));
            String timeString = artificialTime.toIso8601String().replaceFirst('T', ' ').substring(0, 19);

            await db.insert('test_results', {
              'test_name': test['test_name'].toString(),
              'score': int.tryParse(test['score'].toString()) ?? 0,
              'total_questions': int.tryParse(test['total_questions'].toString()) ?? 1,
              'ai_analysis': test['ai_analysis']?.toString(),
              'is_synced': 1,
              'created_at': timeString,
            });
            timeOffset++;
          }
        }

        if (data['chats'] != null) {
          for (var chat in data['chats']) {
            await db.insert('chat_history', {
              'sender': chat['sender'].toString(),
              'message': chat['message'].toString(),
              'is_synced': 1,
            });
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Gagal menarik data: $e');
      return false;
    }
  }

  Future<void> syncDataNow() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null || token == 'firebase_only_token') return;

    final unsyncedTests = await DatabaseHelper.instance.getUnsyncedResults();
    final unsyncedChats = await DatabaseHelper.instance.getUnsyncedChats();

    // --- TAMBAHAN BARU: Ambil Koin Lokal ---
    int localWartegg = prefs.getInt('wartegg_credits') ?? 0;
    int localEqSq = prefs.getInt('eq_sq_credits') ?? 0;
    int localIqPro = prefs.getInt('kredit_iq_pro') ?? 0;
    // ---------------------------------------

    // PENTING: Ubah kondisi early return ini agar jika tes kosong tapi user punya koin, koinnya tetap ter-sync.
    if (unsyncedTests.isEmpty && unsyncedChats.isEmpty && localWartegg == 0 && localEqSq == 0 && localIqPro == 0) return;

    try {
      final syncResponse = await http.post(
        Uri.parse('$baseUrl/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'tests': unsyncedTests,
          'chats': unsyncedChats,
          // --- TAMBAHAN BARU: Kirim Koin Lokal ke Server ---
          'wartegg_credits': localWartegg,
          'eq_sq_credits': localEqSq,
          'kredit_iq_pro': localIqPro,
        }),
      );

      if (syncResponse.statusCode == 200) {
        for (var test in unsyncedTests) {
          await DatabaseHelper.instance.markAsSynced(test['id']);
        }
        for (var chat in unsyncedChats) {
          await DatabaseHelper.instance.markChatAsSynced(chat['id']);
        }
      }
    } catch (e) {
      print('Gagal Backup: $e');
    }
  }

  // FUNGSI BARU: MENGHAPUS CHAT DI SERVER
  Future<void> clearServerChats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    // Jika belum login / Tamu, tidak perlu hapus ke server
    if (token == null || token == 'firebase_only_token') return;

    try {
      await http.delete(
        Uri.parse('$baseUrl/clear-chats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      print('Gagal menghapus chat di server: $e');
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    // --- TAMBAHAN BARU: Bersihkan koin lokal HP saat logout ---
    await prefs.remove('wartegg_credits');
    await prefs.remove('eq_sq_credits');
    await prefs.remove('kredit_iq_pro');
    // ----------------------------------------------------------

    final db = await DatabaseHelper.instance.database;
    await db.delete('test_results');
    await db.delete('chat_history');
  }
}