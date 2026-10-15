import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../helpers/game_high_score_helper.dart';

class MathRushGameScreen extends StatefulWidget {
  const MathRushGameScreen({super.key});

  @override
  State<MathRushGameScreen> createState() => _MathRushGameScreenState();
}

class _MathRushGameScreenState extends State<MathRushGameScreen> {
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _hasUsedContinueAd = false;
  bool _isNewHighScore = false;
  String _difficulty = 'easy';

  int _score = 0;
  int _highScore = 0;
  int _timeLeft = 60;
  Timer? _timer;

  String _questionText = '';
  int _correctAnswer = 0;
  List<int> _options = [];

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    RewardedAdManager.loadAd();
  }

  Future<void> _loadHighScore() async {
    final best = await GameHighScoreHelper.getHighScore(GameHighScoreHelper.kMathRush);
    if (mounted) {
      setState(() => _highScore = best);
    }
  }

  void _startGame(String levelKey) {
    setState(() {
      _difficulty = levelKey;
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
    int num1 = 0;
    int num2 = 0;
    String operator = '+';

    if (_difficulty == 'easy') {
      num1 = random.nextInt(20) + 1;
      num2 = random.nextInt(20) + 1;
      operator = random.nextBool() ? '+' : '-';
    } else if (_difficulty == 'medium') {
      int opChoice = random.nextInt(3);
      if (opChoice == 0) {
        operator = '+';
        num1 = random.nextInt(50) + 10;
        num2 = random.nextInt(50) + 10;
      } else if (opChoice == 1) {
        operator = '-';
        num1 = random.nextInt(100) + 20;
        num2 = random.nextInt(50) + 1;
      } else {
        operator = 'x';
        num1 = random.nextInt(10) + 2;
        num2 = random.nextInt(10) + 2;
      }
    } else {
      int opChoice = random.nextInt(4);
      if (opChoice == 0) {
        operator = '+';
        num1 = random.nextInt(100) + 50;
        num2 = random.nextInt(100) + 50;
      } else if (opChoice == 1) {
        operator = '-';
        num1 = random.nextInt(200) + 50;
        num2 = random.nextInt(100) + 10;
      } else if (opChoice == 2) {
        operator = 'x';
        num1 = random.nextInt(15) + 5;
        num2 = random.nextInt(15) + 5;
      } else {
        operator = ':';
        num2 = random.nextInt(10) + 2;
        int multiplier = random.nextInt(15) + 3;
        num1 = num2 * multiplier;
      }
    }

    if (operator == '-' && num1 < num2) {
      int temp = num1;
      num1 = num2;
      num2 = temp;
    }

    if (operator == '+') _correctAnswer = num1 + num2;
    if (operator == '-') _correctAnswer = num1 - num2;
    if (operator == 'x') _correctAnswer = num1 * num2;
    if (operator == ':') _correctAnswer = num1 ~/ num2;

    _questionText = '$num1 $operator $num2 = ?';

    Set<int> optionsSet = {_correctAnswer};
    int attempt = 0;
    while (optionsSet.length < 4 && attempt < 60) {
      attempt++;
      int offset = random.nextInt(10) + 1;
      bool add = random.nextBool();
      int fakeAnswer = add ? _correctAnswer + offset : _correctAnswer - offset;
      if (fakeAnswer >= 0) optionsSet.add(fakeAnswer);
    }

    int filler = _correctAnswer + 1;
    while (optionsSet.length < 4) {
      if (filler >= 0) optionsSet.add(filler);
      filler++;
    }

    _options = optionsSet.toList();
    _options.shuffle(random);

    setState(() {});
  }

  void _checkAnswer(int selectedAnswer) {
    if (selectedAnswer == _correctAnswer) {
      int poin = _difficulty == 'easy' ? 10 : _difficulty == 'medium' ? 20 : 30;
      final int nextScore = _score + poin;
      setState(() {
        _score = nextScore;
        if (nextScore > _highScore) {
          _highScore = nextScore;
          _isNewHighScore = true;
        }
      });
      GameHighScoreHelper.updateHighScore(GameHighScoreHelper.kMathRush, nextScore);
      _generateQuestion();
    } else {
      setState(() {
        _score = (_score - 5 < 0) ? 0 : _score - 5;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('math_rush.msg_wrong'.tr()),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    final isNew = await GameHighScoreHelper.updateHighScore(
      GameHighScoreHelper.kMathRush,
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
        title: Text('math_rush.appbar_title'.tr()),
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
            const Icon(Icons.calculate, size: 76, color: Color(0xFF0D47A1)),
            const SizedBox(height: 16),
            Text(
              _isGameOver ? 'math_rush.time_up'.tr() : 'math_rush.game_title'.tr(),
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
                'math_rush.final_score'.tr(args: [_score.toString()]),
                style: const TextStyle(fontSize: 24, color: Colors.purple, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 20),
              ],
            ] else ...[
              Text('math_rush.select_difficulty'.tr(), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
            ],

            _buildDifficultyButton('easy', 'math_rush.level_easy'.tr(), Colors.green),
            const SizedBox(height: 12),
            _buildDifficultyButton('medium', 'math_rush.level_medium'.tr(), Colors.orange),
            const SizedBox(height: 12),
            _buildDifficultyButton('hard', 'math_rush.level_hard'.tr(), Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String levelKey, String levelLabel, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startGame(levelKey),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          '${'math_rush.level_button'.tr()} $levelLabel',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
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
                  'math_rush.score'.tr(args: [_score.toString()]),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),

          const Spacer(),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
              border: Border.all(color: Colors.purple.shade100, width: 2),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _questionText,
                style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Color(0xFF333333)),
                textAlign: TextAlign.center,
              ),
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
              childAspectRatio: 1.8,
            ),
            itemBuilder: (context, index) {
              return ElevatedButton(
                onPressed: () => _checkAnswer(_options[index]),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  '${_options[index]}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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