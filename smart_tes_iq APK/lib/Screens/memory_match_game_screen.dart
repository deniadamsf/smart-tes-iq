import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart'; // BARU: Impor ini
import '../helpers/ad_helper.dart';

class MemoryMatchGameScreen extends StatefulWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  State<MemoryMatchGameScreen> createState() => _MemoryMatchGameScreenState();
}

class _MemoryMatchGameScreenState extends State<MemoryMatchGameScreen> {
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isLevelClear = false;

  int _level = 1;
  int _timeLeft = 600;
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

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _isLevelClear = false;
      _level = 1;
      _timeLeft = 600;
    });

    _startTimer();
    _setupLevel();
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _isLevelClear = false;
      _timeLeft += 30;
    });
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
          _timeLeft += 10;
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

        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _isFlipped[_previousIndex] = false;
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
      setState(() {
        _isLevelClear = true;
      });
    }
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isGameOver = true;
      _isFlipped = List<bool>.filled(_cards.length, true);
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

  Widget _buildMenuScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isGameOver ? Icons.timer_off : Icons.dashboard_customize, size: 80, color: _isGameOver ? Colors.red : const Color(0xFF0D47A1)),
            const SizedBox(height: 20),
            Text(_isGameOver ? 'memory_match.time_up'.tr() : 'memory_match.game_title'.tr(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(height: 10),

            if (_isGameOver) ...[
              Text('memory_match.level_survived'.tr(args: [_level.toString()]), style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
            ] else ...[
              Text('memory_match.instructions'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 16)),
              const SizedBox(height: 30),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                label: Text(_isGameOver ? 'memory_match.btn_play'.tr() : 'memory_match.btn_start'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(20)),
                child: Text('memory_match.level_label'.tr(args: [_level.toString()]), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: _timeLeft < 60 ? Colors.red.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _timeLeft < 60 ? Colors.red : Colors.grey.shade300)
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: _timeLeft < 60 ? Colors.red : const Color(0xFF0D47A1)),
                    const SizedBox(width: 8),
                    Text(_formatTime(_timeLeft), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _timeLeft < 60 ? Colors.red : Colors.black87)),
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
                      if (!isFlipped) BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(2, 2))
                    ],
                  ),
                  child: Center(
                    child: isFlipped
                        ? Icon(_cards[index], size: 40, color: const Color(0xFF333333))
                        : const Icon(Icons.help_outline, size: 30, color: Colors.white54),
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