import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../helpers/game_high_score_helper.dart';

class StroopGameScreen extends StatefulWidget {
  const StroopGameScreen({super.key});

  @override
  State<StroopGameScreen> createState() => _StroopGameScreenState();
}

class _StroopGameScreenState extends State<StroopGameScreen> {
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _hasUsedContinueAd = false;
  bool _isNewHighScore = false;

  int _score = 0;
  int _highScore = 0;
  int _timeLeft = 60;
  Timer? _timer;

  final Map<String, Color> _colorData = {
    'stroop.color_red': Colors.red,
    'stroop.color_blue': Colors.blue,
    'stroop.color_green': Colors.green,
    'stroop.color_yellow': const Color(0xFFFFD600),
    'stroop.color_purple': Colors.purple,
    'stroop.color_black': Colors.black,
  };

  late String _currentText;
  late String _correctColorName;
  late Color _currentColor;
  List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    RewardedAdManager.loadAd();
  }

  Future<void> _loadHighScore() async {
    final best = await GameHighScoreHelper.getHighScore(GameHighScoreHelper.kStroop);
    if (mounted) {
      setState(() => _highScore = best);
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _hasUsedContinueAd = false;
      _isNewHighScore = false;
      _score = 0;
      _timeLeft = 60;
    });
    RewardedAdManager.loadAd();
    _generateQuestion();
    _startTimer();
  }

  void _continueWithAd() {
    RewardedAdManager.showAd(context, () {
      if (!mounted) return;
      setState(() {
        _hasUsedContinueAd = true;
        _isGameOver = false;
        _isPlaying = true;
        _timeLeft = 15;
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

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _generateQuestion() {
    final random = Random();
    List<String> colorNames = _colorData.keys.toList();

    _currentText = colorNames[random.nextInt(colorNames.length)];

    _correctColorName = colorNames[random.nextInt(colorNames.length)];
    while (_correctColorName == _currentText) {
      _correctColorName = colorNames[random.nextInt(colorNames.length)];
    }

    _currentColor = _colorData[_correctColorName]!;

    Set<String> optionsSet = {_correctColorName, _currentText};
    while (optionsSet.length < 4) {
      optionsSet.add(colorNames[random.nextInt(colorNames.length)]);
    }

    _options = optionsSet.toList();
    _options.shuffle(random);

    setState(() {});
  }

  void _checkAnswer(String selectedAnswer) {
    if (selectedAnswer == _correctColorName) {
      final int nextScore = _score + 10;
      setState(() {
        _score = nextScore;
        if (nextScore > _highScore) {
          _highScore = nextScore;
          _isNewHighScore = true;
        }
      });
      GameHighScoreHelper.updateHighScore(GameHighScoreHelper.kStroop, nextScore);
      _generateQuestion();
    } else {
      setState(() {
        _score = (_score - 5 < 0) ? 0 : _score - 5;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('stroop.msg_wrong'.tr()),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    final isNew = await GameHighScoreHelper.updateHighScore(
      GameHighScoreHelper.kStroop,
      _score,
    );
    if (!mounted) return;
    setState(() {
      if (isNew || _score > _highScore) {
        _highScore = _score;
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
        title: Text('stroop.appbar_title'.tr()),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: !_isPlaying ? _buildMenuScreen() : _buildGameScreen(),
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
            const Icon(Icons.palette, size: 76, color: Color(0xFF0D47A1)),
            const SizedBox(height: 16),
            Text(
              _isGameOver ? 'stroop.time_up'.tr() : 'stroop.game_title'.tr(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 10),

            if (_highScore > 0)
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
                      'game_menu.best_score_label'.tr(args: [_highScore.toString()]),
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
              if (_isNewHighScore && _score > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'game_menu.new_high_score'.tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.green),
                  ),
                ),
              Text(
                'stroop.final_score'.tr(args: [_score.toString()]),
                style: const TextStyle(fontSize: 24, color: Colors.orange, fontWeight: FontWeight.bold),
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
                'stroop.rules'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 30),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                label: Text(
                  _isGameOver ? 'stroop.btn_play_again'.tr() : 'stroop.btn_start'.tr(),
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

  Widget _buildGameScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeLeft <= 10 ? Colors.red.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _timeLeft <= 10 ? Colors.red : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: _timeLeft <= 10 ? Colors.red : const Color(0xFF0D47A1)),
                    const SizedBox(width: 6),
                    Text(
                      '00:${_timeLeft.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft <= 10 ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (_highScore > 0)
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
                        '$_highScore',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'stroop.score'.tr(args: [_score.toString()]),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),

          const Spacer(),

          Text('stroop.question'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currentText.tr(),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: _currentColor,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 2.0,
            ),
            itemBuilder: (context, index) {
              return ElevatedButton(
                onPressed: () => _checkAnswer(_options[index]),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  side: BorderSide(color: Colors.grey.shade300, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  _options[index].tr(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}