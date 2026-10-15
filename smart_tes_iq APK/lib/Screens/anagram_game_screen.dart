import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../helpers/game_high_score_helper.dart';

class AnagramGameScreen extends StatefulWidget {
  const AnagramGameScreen({super.key});

  @override
  State<AnagramGameScreen> createState() => _AnagramGameScreenState();
}

class _AnagramGameScreenState extends State<AnagramGameScreen> {
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _hasUsedContinueAd = false;
  bool _isNewHighScore = false;

  String _difficulty = 'easy';

  int _score = 0;
  int _highScore = 0;
  int _timeLeft = 60;
  Timer? _timer;

  String _currentWord = '';
  String _scrambledWord = '';
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final Map<String, Map<String, List<String>>> _localizedWordBanks = {
    'id': {
      'easy': [
        'BUKU', 'MEJA', 'KACA', 'PENA', 'KOPI', 'BOLA', 'TOPI', 'BUMI', 'KUE', 'ROTI',
        'BATU', 'KAYU', 'SAPI', 'KUDA', 'LAUT', 'AWAN', 'PAGI', 'KOTA', 'DESA', 'GURU'
      ],
      'medium': [
        'KUCING', 'SEPATU', 'LEMARI', 'KERTAS', 'KAMERA', 'PISANG', 'CELANA', 'SEPEDA', 'RUMPUT',
        'JENDELA', 'BANTAL', 'PAYUNG', 'CERMIN', 'PERAHU', 'BINTANG', 'PELANGI', 'BONEKA'
      ],
      'hard': [
        'MATAHARI', 'KOMPUTER', 'PESAWAT', 'TELEVISI', 'KALKULATOR', 'PERPUSTAKAAN', 'KENDARAAN', 'NUSANTARA',
        'LABORATORIUM', 'UNIVERSITAS', 'PENGETAHUAN', 'KECERDASAN', 'ANTARIKSA', 'TEKNOLOGI'
      ],
    },
    'en': {
      'easy': [
        'BOOK', 'DESK', 'GLASS', 'PEN', 'COFFEE', 'BALL', 'HAT', 'EARTH', 'CAKE', 'BREAD',
        'ROCK', 'WOOD', 'STAR', 'MOON', 'RAIN', 'TREE', 'BIRD', 'FISH', 'CITY', 'GOLD'
      ],
      'medium': [
        'CAT', 'SHOES', 'CLOSET', 'PAPER', 'CAMERA', 'BANANA', 'PANTS', 'BICYCLE', 'GRASS',
        'WINDOW', 'PILLOW', 'MIRROR', 'ROCKET', 'PLANET', 'GARDEN', 'BRIDGE', 'CASTLE'
      ],
      'hard': [
        'SUN', 'COMPUTER', 'AIRPLANE', 'TELEVISION', 'CALCULATOR', 'LIBRARY', 'VEHICLES', 'ARCHIPELAGO',
        'LABORATORY', 'UNIVERSITY', 'KNOWLEDGE', 'INTELLIGENCE', 'ASTRONAUT', 'TECHNOLOGY'
      ],
    }
  };

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    RewardedAdManager.loadAd();
  }

  Future<void> _loadHighScore() async {
    final best = await GameHighScoreHelper.getHighScore(GameHighScoreHelper.kAnagram);
    if (mounted) {
      setState(() => _highScore = best);
    }
  }

  void _startGame(String difficultyKey) {
    setState(() {
      _difficulty = difficultyKey;
      _isPlaying = true;
      _isGameOver = false;
      _hasUsedContinueAd = false;
      _isNewHighScore = false;
      _score = 0;
      _timeLeft = 60;
    });

    RewardedAdManager.loadAd();
    _generateNewWord();
    _startTimer();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
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
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      });
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

  void _generateNewWord() {
    final random = Random();
    final String langCode = context.locale.languageCode == 'en' ? 'en' : 'id';
    List<String> words = _localizedWordBanks[langCode]![_difficulty]!;

    String newWord = words[random.nextInt(words.length)];

    while (newWord == _currentWord && words.length > 1) {
      newWord = words[random.nextInt(words.length)];
    }

    _currentWord = newWord;
    _scrambledWord = _scrambleString(_currentWord);
    _answerController.clear();
    setState(() {});
  }

  String _scrambleString(String word) {
    List<String> chars = word.split('');
    chars.shuffle(Random());
    String scrambled = chars.join('');

    if (scrambled == word && word.length > 1) {
      return _scrambleString(word);
    }
    return scrambled;
  }

  Future<void> _checkAnswer() async {
    String userAnswer = _answerController.text.trim().toUpperCase();
    if (userAnswer == _currentWord) {
      final int addPts = (_difficulty == 'easy' ? 10 : _difficulty == 'medium' ? 20 : 30);
      final int nextScore = _score + addPts;
      setState(() {
        _score = nextScore;
        if (nextScore > _highScore) {
          _highScore = nextScore;
          _isNewHighScore = true;
        }
      });
      GameHighScoreHelper.updateHighScore(GameHighScoreHelper.kAnagram, nextScore);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('anagram.msg_correct'.tr()),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 500),
        ),
      );
      _generateNewWord();
      FocusScope.of(context).requestFocus(_focusNode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('anagram.msg_wrong'.tr()),
          backgroundColor: Colors.red,
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _skipWord() {
    _generateNewWord();
    FocusScope.of(context).requestFocus(_focusNode);
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    final isNew = await GameHighScoreHelper.updateHighScore(
      GameHighScoreHelper.kAnagram,
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
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('anagram.title'.tr()),
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
            const Icon(Icons.extension, size: 72, color: Color(0xFF0D47A1)),
            const SizedBox(height: 16),
            Text(
              _isGameOver ? 'anagram.time_up'.tr() : 'anagram.game_title'.tr(),
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
                '${'anagram.final_score'.tr()} $_score',
                style: const TextStyle(fontSize: 22, color: Colors.orange, fontWeight: FontWeight.bold),
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
              Text('anagram.select_difficulty'.tr(), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
            ],

            _buildDifficultyButton('easy', 'anagram.level_easy'.tr(), Colors.green),
            const SizedBox(height: 12),
            _buildDifficultyButton('medium', 'anagram.level_medium'.tr(), Colors.orange),
            const SizedBox(height: 12),
            _buildDifficultyButton('hard', 'anagram.level_hard'.tr(), Colors.red),
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
          '${'anagram.level_button'.tr()} $levelLabel',
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
                  '${'anagram.score'.tr()} $_score',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const Spacer(),

          Text('anagram.instruction'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 15),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _scrambledWord,
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFF333333)),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),

          TextField(
            controller: _answerController,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => _checkAnswer(),
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'anagram.hint_text'.tr(),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _skipWord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text('anagram.btn_skip'.tr(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text('anagram.btn_answer'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}