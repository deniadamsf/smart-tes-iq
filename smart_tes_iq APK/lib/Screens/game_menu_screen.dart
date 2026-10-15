import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'anagram_game_screen.dart';
import 'stroop_game_screen.dart';
import 'math_rush_game_screen.dart';
import 'memory_match_game_screen.dart';
import 'sudoku_game_screen.dart';
import '../helpers/ad_helper.dart';
import '../helpers/game_high_score_helper.dart';

class GameMenuScreen extends StatefulWidget {
  const GameMenuScreen({super.key});

  @override
  State<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends State<GameMenuScreen> {
  Map<String, int> _highScores = {};

  @override
  void initState() {
    super.initState();
    _loadScores();
    GameHighScoreHelper.refreshNotifier.addListener(_loadScores);
  }

  @override
  void dispose() {
    GameHighScoreHelper.refreshNotifier.removeListener(_loadScores);
    super.dispose();
  }

  Future<void> _loadScores() async {
    final scores = await GameHighScoreHelper.getAllHighScores();
    if (mounted) {
      setState(() {
        _highScores = scores;
      });
    }
  }

  Future<void> _openGame(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    _loadScores();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF0F172A)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'game_menu.appbar_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'game_menu.header_subtitle'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'game_menu.header_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LIST GAME
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // GAME 1: ANAGRAM
                  _buildGameCard(
                    context,
                    isDarkMode: isDarkMode,
                    title: 'game_menu.game1_title'.tr(),
                    subtitle: 'game_menu.game1_desc'.tr(),
                    icon: Icons.sort_by_alpha,
                    color: Colors.orange,
                    highScoreBadge: (_highScores[GameHighScoreHelper.kAnagram] ?? 0) > 0
                        ? 'game_menu.high_score_badge'.tr(
                            args: [
                              _highScores[GameHighScoreHelper.kAnagram]
                                  .toString(),
                            ],
                          )
                        : null,
                    onTap: () => _openGame(const AnagramGameScreen()),
                  ),
                  const SizedBox(height: 15),

                  // GAME 2: WARNA PENGECOH (STROOP)
                  _buildGameCard(
                    context,
                    isDarkMode: isDarkMode,
                    title: 'game_menu.game2_title'.tr(),
                    subtitle: 'game_menu.game2_desc'.tr(),
                    icon: Icons.palette,
                    color: Colors.green,
                    highScoreBadge: (_highScores[GameHighScoreHelper.kStroop] ?? 0) > 0
                        ? 'game_menu.high_score_badge'.tr(
                            args: [
                              _highScores[GameHighScoreHelper.kStroop]
                                  .toString(),
                            ],
                          )
                        : null,
                    onTap: () => _openGame(const StroopGameScreen()),
                  ),
                  const SizedBox(height: 15),

                  // GAME 3: HITUNG CEPAT (MATH RUSH)
                  _buildGameCard(
                    context,
                    isDarkMode: isDarkMode,
                    title: 'game_menu.game3_title'.tr(),
                    subtitle: 'game_menu.game3_desc'.tr(),
                    icon: Icons.calculate,
                    color: Colors.purple,
                    highScoreBadge: (_highScores[GameHighScoreHelper.kMathRush] ?? 0) > 0
                        ? 'game_menu.high_score_badge'.tr(
                            args: [
                              _highScores[GameHighScoreHelper.kMathRush]
                                  .toString(),
                            ],
                          )
                        : null,
                    onTap: () => _openGame(const MathRushGameScreen()),
                  ),
                  const SizedBox(height: 15),

                  // GAME 4: MEMORI VISUAL (MEMORY MATCH)
                  _buildGameCard(
                    context,
                    isDarkMode: isDarkMode,
                    title: 'game_menu.game4_title'.tr(),
                    subtitle: 'game_menu.game4_desc'.tr(),
                    icon: Icons.dashboard_customize,
                    color: Colors.blue,
                    highScoreBadge:
                        (_highScores[GameHighScoreHelper.kMemoryMatch] ?? 0) > 0
                            ? 'game_menu.high_level_badge'.tr(
                                args: [
                                  _highScores[GameHighScoreHelper.kMemoryMatch]
                                      .toString(),
                                ],
                              )
                            : null,
                    onTap: () => _openGame(const MemoryMatchGameScreen()),
                  ),
                  const SizedBox(height: 15),

                  // GAME 5: SUDOKU LOGIKA (9x9)
                  _buildGameCard(
                    context,
                    isDarkMode: isDarkMode,
                    title: 'game_menu.game5_title'.tr(),
                    subtitle: 'game_menu.game5_desc'.tr(),
                    icon: Icons.grid_on_rounded,
                    color: Colors.indigo,
                    highScoreBadge: (_highScores[GameHighScoreHelper.kSudoku] ?? 0) > 0
                        ? 'game_menu.high_score_badge'.tr(
                            args: [
                              _highScores[GameHighScoreHelper.kSudoku]
                                  .toString(),
                            ],
                          )
                        : null,
                    onTap: () => _openGame(const SudokuGameScreen()),
                  ),
                ],
              ),
            ),

            // ==========================================
            // KOTAK BANNER IKLAN
            // ==========================================
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDarkMode
                        ? Colors.white12
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: const Center(
                child: CustomBannerAd(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required bool isDarkMode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? highScoreBadge,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF333333),
                      ),
                    ),
                    if (highScoreBadge != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              highScoreBadge,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                    ? Colors.amber.shade300
                                    : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                        height: 1.4,
                      ),
                    ),
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