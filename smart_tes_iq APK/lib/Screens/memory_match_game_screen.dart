import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../helpers/game_high_score_helper.dart';

class MemoryMatchGameScreen extends StatefulWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  State<MemoryMatchGameScreen> createState() => _MemoryMatchGameScreenState();
}

class _MemoryMatchGameScreenState extends State<MemoryMatchGameScreen> {
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isLevelClear = false;
  bool _hasUsedContinueAd = false;
  bool _isNewHighScore = false;

  int _level = 1;
  int _highLevel = 0;
  int _timeLeft = 60;
  Timer? _timer;

  List<IconData> _cards = [];
  List<bool> _isFlipped = [];
  List<bool> _isMatched = [];

  int _previousIndex = -1;
  bool _isProcessing = false;

  final List<IconData> _allIcons = [
    Icons.favorite, Icons.star, Icons.pets, Icons.directions_car,
    Icons.flight, Icons.local_florist, Icons.music_note, Icons.sports_basketball,
    Icons.anchor, Icons.lightbulb, Icons.cake, Icons.camera_alt,
    Icons.headset, Icons.watch, Icons.umbrella, Icons.coffee,
    Icons.castle, Icons.rocket, Icons.directions_bike, Icons.fastfood,
  ];

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    RewardedAdManager.loadAd();
  }

  Future<void> _loadHighScore() async {
    final best = await GameHighScoreHelper.getHighScore(GameHighScoreHelper.kMemoryMatch);
    if (mounted) {
      setState(() => _highLevel = best);
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _isLevelClear = false;
      _hasUsedContinueAd = false;
      _isNewHighScore = false;
      _level = 1;
      _timeLeft = 60;
    });

    RewardedAdManager.loadAd();
    _updateRecordIfNeeded(1);
    _startTimer();
    _setupLevel();
  }

  Future<void> _updateRecordIfNeeded(int reachedLevel) async {
    if (reachedLevel > _highLevel) {
      setState(() {
        _highLevel = reachedLevel;
        _isNewHighScore = true;
      });
    }
    await GameHighScoreHelper.updateHighScore(
      GameHighScoreHelper.kMemoryMatch,
      reachedLevel,
    );
  }

  void _continueWithAd() {
    RewardedAdManager.showAd(context, () {
      if (!mounted) return;
      setState(() {
        _hasUsedContinueAd = true;
        _isGameOver = false;
        _isPlaying = true;
        _timeLeft = 15;
        _previousIndex = -1;
        _isProcessing = false;
        // Kembalikan kartu yang belum cocok menjadi tertutup, kartu yang sudah cocok tetap terbuka
        for (int i = 0; i < _cards.length; i++) {
          _isFlipped[i] = _isMatched[i];
        }
      });
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('game_menu.msg_continue_15s'.tr()),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _nextLevel() {
    final int nextLvl = _level + 1;
    setState(() {
      _level = nextLvl;
      _isLevelClear = false;
      _timeLeft += 15;
    });
    _updateRecordIfNeeded(nextLvl);
    _setupLevel();
  }

  void _setupLevel() {
    int pairCount = min(4 + (_level * 2), 16);

    List<IconData> shuffledIcons = List.from(_allIcons)..shuffle();
    List<IconData> selectedIcons = shuffledIcons.take(pairCount).toList();

    _cards = [...selectedIcons, ...selectedIcons];
    _cards.shuffle();

    _isFlipped = List<bool>.filled(_cards.length, false);
    _isMatched = List<bool>.filled(_cards.length, false);
    _previousIndex = -1;
    _isProcessing = false;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0 && !_isLevelClear) {
        setState(() => _timeLeft--);
      } else if (_timeLeft <= 0) {
        _endGame();
      }
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showTimeIndicator(String key, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(key.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        backgroundColor: color,
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 50, right: 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _onCardTap(int index) {
    if (_isProcessing || _isFlipped[index] || _isMatched[index] || _isGameOver || _isLevelClear) return;

    setState(() {
      _isFlipped[index] = true;
    });

    if (_previousIndex == -1) {
      _previousIndex = index;
    } else {
      _isProcessing = true;

      if (_cards[_previousIndex] == _cards[index]) {
        setState(() {
          _isMatched[_previousIndex] = true;
          _isMatched[index] = true;
          _timeLeft += 5;
        });
        _showTimeIndicator('memory_match.bonus_indicator', Colors.green);

        _previousIndex = -1;
        _isProcessing = false;
        _checkWinCondition();
      } else {
        setState(() {
          _timeLeft -= 5;
          if (_timeLeft < 0) _timeLeft = 0;
        });
        _showTimeIndicator('memory_match.penalty_indicator', Colors.red);

        if (_timeLeft <= 0) {
          _endGame();
          return;
        }

        final int prevIdx = _previousIndex;
        Timer(const Duration(milliseconds: 700), () {
          if (mounted && _isPlaying && !_isGameOver) {
            setState(() {
              _isFlipped[prevIdx] = false;
              _isFlipped[index] = false;
              _previousIndex = -1;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  void _checkWinCondition() {
    if (!_isMatched.contains(false)) {
      _updateRecordIfNeeded(_level);
      setState(() {
        _isLevelClear = true;
      });
    }
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    final isNew = await GameHighScoreHelper.updateHighScore(
      GameHighScoreHelper.kMemoryMatch,
      _level,
    );
    if (!mounted) return;
    setState(() {
      if (isNew || _level > _highLevel) {
        _highLevel = _level;
        _isNewHighScore = true;
      }
      _isPlaying = false;
      _isGameOver = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('memory_match.appbar_title'.tr()),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !_isPlaying
                  ? _buildMenuScreen()
                  : (_isLevelClear ? _buildLevelClearScreen() : _buildGameScreen()),
            ),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
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

  Widget _buildMenuScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isGameOver ? Icons.timer_off : Icons.dashboard_customize,
              size: 76,
              color: _isGameOver ? Colors.red : const Color(0xFF0D47A1),
            ),
            const SizedBox(height: 16),
            Text(
              _isGameOver ? 'memory_match.time_up'.tr() : 'memory_match.game_title'.tr(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 10),

            if (_highLevel > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber.shade900, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'game_menu.best_level_label'.tr(args: [_highLevel.toString()]),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            if (_isGameOver) ...[
              if (_isNewHighScore && _level > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'game_menu.new_high_score'.tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.green),
                  ),
                ),
              Text(
                'memory_match.level_survived'.tr(args: [_level.toString()]),
                style: const TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              if (!_hasUsedContinueAd) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _continueWithAd,
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 24),
                    label: Text(
                      'game_menu.btn_continue_15s'.tr(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepOrange,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ] else ...[
              Text(
                'memory_match.instructions'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 15),
              ),
              const SizedBox(height: 30),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                label: Text(
                  _isGameOver ? 'memory_match.btn_play'.tr() : 'memory_match.btn_start'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelClearScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, size: 100, color: Colors.orange),
          const SizedBox(height: 20),
          Text('memory_match.level_clear'.tr(args: [_level.toString()]), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('memory_match.bonus_time'.tr(), style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _nextLevel,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              backgroundColor: const Color(0xFF0D47A1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('memory_match.btn_next_level'.tr(), style: const TextStyle(fontSize: 18, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    int crossAxisCount = _cards.length <= 12 ? 3 : 4;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'memory_match.level_label'.tr(args: [_level.toString()]),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              if (_highLevel > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 4),
                      Text(
                        'Lv.$_highLevel',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeLeft <= 15 ? Colors.red.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _timeLeft <= 15 ? Colors.red : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: _timeLeft <= 15 ? Colors.red : const Color(0xFF0D47A1)),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_timeLeft),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft <= 15 ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              bool isFlipped = _isFlipped[index] || _isMatched[index];
              return GestureDetector(
                onTap: () => _onCardTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _isMatched[index] ? Colors.green.shade100 : (isFlipped ? Colors.white : const Color(0xFF0D47A1)),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _isMatched[index] ? Colors.green : (isFlipped ? Colors.blue.shade200 : Colors.transparent),
                      width: 2,
                    ),
                    boxShadow: [
                      if (!isFlipped) BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(2, 2))
                    ],
                  ),
                  child: Center(
                    child: isFlipped
                        ? Icon(_cards[index], size: 36, color: const Color(0xFF333333))
                        : const Icon(Icons.help_outline, size: 28, color: Colors.white54),
                  ),
                ),
              );
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}