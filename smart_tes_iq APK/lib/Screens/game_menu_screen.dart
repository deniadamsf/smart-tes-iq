import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import 'anagram_game_screen.dart';
import 'stroop_game_screen.dart';
import 'math_rush_game_screen.dart';
import 'memory_match_game_screen.dart';
import '../helpers/ad_helper.dart';

class GameMenuScreen extends StatelessWidget {
  const GameMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('game_menu.appbar_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Menghilangkan tombol back karena ini adalah Tab Utama
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF0D47A1),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('game_menu.header_subtitle'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text('game_menu.header_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LIST GAME
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // GAME 1: ANAGRAM (SUDAH AKTIF)
                  _buildGameCard(
                    context,
                    title: 'game_menu.game1_title'.tr(),
                    subtitle: 'game_menu.game1_desc'.tr(),
                    icon: Icons.sort_by_alpha,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AnagramGameScreen()));
                    },
                  ),
                  const SizedBox(height: 15),

                  // GAME 2: WARNA PENGECOH (AKTIF)
                  _buildGameCard(
                    context,
                    title: 'game_menu.game2_title'.tr(),
                    subtitle: 'game_menu.game2_desc'.tr(),
                    icon: Icons.palette,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const StroopGameScreen()));
                    },
                  ),
                  const SizedBox(height: 15),

                  // GAME 3: HITUNG CEPAT (AKTIF)
                  _buildGameCard(
                    context,
                    title: 'game_menu.game3_title'.tr(),
                    subtitle: 'game_menu.game3_desc'.tr(),
                    icon: Icons.calculate,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MathRushGameScreen()));
                    },
                  ),
                  const SizedBox(height: 15),

                  // GAME 4: MEMORI VISUAL (AKTIF)
                  _buildGameCard(
                    context,
                    title: 'game_menu.game4_title'.tr(),
                    subtitle: 'game_menu.game4_desc'.tr(),
                    icon: Icons.dashboard_customize,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MemoryMatchGameScreen()));
                    },
                  ),
                ],
              ),
            ),

            // ==========================================
            // KOTAK BANNER IKLAN (DIPASANG NANTI)
            // ==========================================
            Container(
              width: double.infinity,
              height: 50,
              color: Colors.grey.shade300,
              child: const Center(
                child: CustomBannerAd(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Desain Kartu Menu Game
  Widget _buildGameCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 5),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}