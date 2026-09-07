import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart'; // BARU: Wajib diimpor
import '../helpers/ad_helper.dart';

class AnagramGameScreen extends StatefulWidget {
  const AnagramGameScreen({super.key});

  @override
  State<AnagramGameScreen> createState() => _AnagramGameScreenState();
}

class _AnagramGameScreenState extends State<AnagramGameScreen> {
  bool _isPlaying = false;
  bool _isGameOver = false;

  // BARU: Kita ubah difficulty menjadi key internal (bukan teks label)
  String _difficulty = 'easy';

  int _score = 0;
  int _timeLeft = 60;
  Timer? _timer;

  String _currentWord = '';
  String _scrambledWord = '';
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // BARU: Bank Kosakata Bilingual (Disesuaikan dengan bahasa yang aktif)
  final Map<String, Map<String, List<String>>> _localizedWordBanks = {
    'id': {
      'easy': ['BUKU', 'MEJA', 'KACA', 'PENA', 'KOPI', 'BOLA', 'TOPI', 'BUMI', 'KUE', 'ROTI'],
      'medium': ['KUCING', 'SEPATU', 'LEMARI', 'KERTAS', 'KAMERA', 'PISANG', 'CELANA', 'SEPEDA', 'RUMPUT'],
      'hard': ['MATAHARI', 'KOMPUTER', 'PESAWAT', 'TELEVISI', 'KALKULATOR', 'PERPUSTAKAAN', 'KENDARAAN', 'NUSANTARA'],
    },
    'en': {
      'easy': ['BOOK', 'DESK', 'GLASS', 'PEN', 'COFFEE', 'BALL', 'HAT', 'EARTH', 'CAKE', 'BREAD'],
      'medium': ['CAT', 'SHOES', 'CLOSET', 'PAPER', 'CAMERA', 'BANANA', 'PANTS', 'BICYCLE', 'GRASS'],
      'hard': ['SUN', 'COMPUTER', 'AIRPLANE', 'TELEVISION', 'CALCULATOR', 'LIBRARY', 'VEHICLES', 'ARCHIPELAGO'],
    }
  };

  void _startGame(String difficultyKey) {
    setState(() {
      _difficulty = difficultyKey;
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _timeLeft = 60;
    });

    _generateNewWord();
    _startTimer();

    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_focusNode);
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
    // BARU: Tarik bahasa yang sedang aktif, lalu ambil bank kata yang sesuai
    final String langCode = context.locale.languageCode;
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

  void _checkAnswer() {
    String userAnswer = _answerController.text.trim().toUpperCase();
    if (userAnswer == _currentWord) {
      setState(() {
        _score += (_difficulty == 'easy' ? 10 : _difficulty == 'medium' ? 20 : 30);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('anagram.msg_correct'.tr()), backgroundColor: Colors.green, duration: const Duration(milliseconds: 500)),
      );
      _generateNewWord();
      FocusScope.of(context).requestFocus(_focusNode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('anagram.msg_wrong'.tr()), backgroundColor: Colors.red, duration: const Duration(milliseconds: 500)),
      );
    }
  }

  void _skipWord() {
    _generateNewWord();
    FocusScope.of(context).requestFocus(_focusNode);
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
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
            const Icon(Icons.extension, size: 80, color: Color(0xFF0D47A1)),
            const SizedBox(height: 20),
            Text(
              _isGameOver ? 'anagram.time_up'.tr() : 'anagram.game_title'.tr(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 10),
            if (_isGameOver) ...[
              Text('${'anagram.final_score'.tr()} $_score', style: const TextStyle(fontSize: 20, color: Colors.orange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
            ] else ...[
              Text('anagram.select_difficulty'.tr(), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
            ],

            _buildDifficultyButton('easy', 'anagram.level_easy'.tr(), Colors.green),
            const SizedBox(height: 15),
            _buildDifficultyButton('medium', 'anagram.level_medium'.tr(), Colors.orange),
            const SizedBox(height: 15),
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
        onPressed: () => _startGame(levelKey), // Mengirim internal key ('easy', 'medium')
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text('${'anagram.level_button'.tr()} $levelLabel', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('00:${_timeLeft.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(20)),
                child: Text('${'anagram.score'.tr()} $_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const Spacer(),

          Text('anagram.instruction'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 15),
          Text(
            _scrambledWord,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFF333333)),
            textAlign: TextAlign.center,
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
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _skipWord,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: Text('anagram.btn_skip'.tr(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _checkAnswer,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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