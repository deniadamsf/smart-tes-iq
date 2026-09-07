import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/game_menu_screen.dart';
import 'screens/chat_ai_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/language_selection_screen.dart';
import 'helpers/rewarded_ad_manager.dart';

// PERBAIKAN: Ubah void main menjadi async dan tambahkan inisialisasi Firebase
void main() async {
  // Wajib ditambahkan agar Firebase siap sebelum aplikasi menggambar layar
  WidgetsFlutterBinding.ensureInitialized();

  // BARU: wajib dipanggil sebelum EasyLocalization dipakai
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp();
  RewardedAdManager.loadAd();

  await dotenv.load(fileName: ".env");

  // BARU: cek apakah user (baru ATAU lama yang baru saja update) sudah
  // pernah memilih bahasa. Kalau belum, key ini akan null/false, dan kita
  // tampilkan halaman pilih bahasa SEKALI saja.
  //
  // Ini TIDAK menyentuh key SharedPreferences lain (api_token, ai_coins,
  // kredit_iq_pro, dll), jadi login & kredit premium user lama tetap aman.
  final prefs = await SharedPreferences.getInstance();
  final hasChosenLanguage = prefs.getBool('has_chosen_language') ?? false;

  runApp(
    EasyLocalization(
      // Baru menambah dukungan Indonesia & Inggris. Tambah locale lain di
      // sini kalau nanti diperlukan.
      supportedLocales: const [Locale('id'), Locale('en')],
      path: 'assets/lang', // berisi id.json & en.json
      // fallbackLocale & startLocale sengaja diset ke 'id' (bukan auto
      // deteksi bahasa HP) supaya PERILAKU DEFAULT PERSIS SAMA seperti
      // sebelum update ini untuk siapa pun yang belum sempat memilih.
      fallbackLocale: const Locale('id'),
      startLocale: const Locale('id'),
      saveLocale: true,
      child: SmartTesIqApp(hasChosenLanguage: hasChosenLanguage),
    ),
  );
}

class SmartTesIqApp extends StatelessWidget {
  final bool hasChosenLanguage;

  const SmartTesIqApp({super.key, required this.hasChosenLanguage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // BARU: sambungkan MaterialApp ke easy_localization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
        useMaterial3: true,
      ),
      // BARU: kalau belum pernah pilih bahasa -> tampilkan halaman pilih
      // bahasa dulu. Kalau sudah -> langsung ke aplikasi seperti biasa
      // (perilaku lama, tidak berubah).
      home: hasChosenLanguage
          ? const MainNavigator()
          : const LanguageSelectionScreen(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  // Halaman yang sudah terhubung sepenuhnya
  final List<Widget> _pages = [
    const HomeScreen(),
    const GameMenuScreen(),
    const ChatAiScreen(),
    const ProfileScreen(), // <--- SEKARANG HALAMAN PROFIL AKTIF!
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PERBAIKAN UTAMA: Menggunakan IndexedStack agar Tab Chat AI tidak mereset chat saat ditinggalkan
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // FITUR LAMA ANDA DIKEMBALIKAN: Tombol FAB "Main Game"
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () {
          _onItemTapped(1); // Melompat ke tab Asah Otak
        },
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.sports_esports, color: Colors.white),
        // DIUBAH: pakai key terjemahan, bukan teks mentah
        label: Text(
          'home.play_game_fab'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0D47A1),
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        // DIUBAH: label bottom nav sekarang pakai key terjemahan
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            label: 'nav.home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.extension),
            label: 'nav.games'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble),
            label: 'nav.chat_ai'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'nav.profile'.tr(),
          ),
        ],
      ),
    );
  }
}