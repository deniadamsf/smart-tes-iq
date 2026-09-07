import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../helpers/ad_helper.dart';

class MathRushGameScreen extends StatefulWidget {
  const MathRushGameScreen({super.key});

  @override
  State<MathRushGameScreen> createState() => _MathRushGameScreenState();
}

class _MathRushGameScreenState extends State<MathRushGameScreen> {
  // Status Game
  bool _isPlaying = false;
  bool _isGameOver = false;
  String _difficulty = 'easy'; // DIUBAH: Gunakan key internal agar aman dilokalisasi

  // Variabel Permainan
  int _score = 0;
  int _timeLeft = 60; // 60 detik waktu bermain
  Timer? _timer;

  // Variabel Soal
  String _questionText = '';
  int _correctAnswer = 0;
  List<int> _options = [];

  void _startGame(String levelKey) {
    setState(() {
      _difficulty = levelKey;
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _timeLeft = 60;
    });
    _generateQuestion();
    _startTimer();
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

    // Logika Kesulitan memakai Key Internal
    if (_difficulty == 'easy') {
      // Mudah: Penjumlahan & Pengurangan (Angka 1 - 20)
      num1 = random.nextInt(20) + 1;
      num2 = random.nextInt(20) + 1;
      operator = random.nextBool() ? '+' : '-';
    } else if (_difficulty == 'medium') {
      // Sedang: +, -, x (Angka agak besar, perkalian 1-10)
      int opChoice = random.nextInt(3);
      if (opChoice == 0) { operator = '+'; num1 = random.nextInt(50) + 10; num2 = random.nextInt(50) + 10; }
      else if (opChoice == 1) { operator = '-'; num1 = random.nextInt(100) + 20; num2 = random.nextInt(50) + 1; }
      else { operator = 'x'; num1 = random.nextInt(10) + 2; num2 = random.nextInt(10) + 2; }
    } else {
      // Sulit: +, -, x, / (Perkalian besar, Pembagian bulat)
      int opChoice = random.nextInt(4);
      if (opChoice == 0) { operator = '+'; num1 = random.nextInt(100) + 50; num2 = random.nextInt(100) + 50; }
      else if (opChoice == 1) { operator = '-'; num1 = random.nextInt(200) + 50; num2 = random.nextInt(100) + 10; }
      else if (opChoice == 2) { operator = 'x'; num1 = random.nextInt(15) + 5; num2 = random.nextInt(15) + 5; }
      else {
        operator = ':';
        num2 = random.nextInt(10) + 2; // Pembagi
        int multiplier = random.nextInt(15) + 3; // Hasil bulat
        num1 = num2 * multiplier; // Angka yang dibagi
      }
    }

    // Mencegah hasil minus di SEMUA level.
    // Jawaban minus membuat pembuatan opsi pengecoh di bawah tidak punya kandidat
    // yang valid (semua opsi minus ditolak) sehingga loop-nya menggantung.
    if (operator == '-' && num1 < num2) {
      int temp = num1;
      num1 = num2;
      num2 = temp;
    }

    // Menghitung Jawaban Benar
    if (operator == '+') _correctAnswer = num1 + num2;
    if (operator == '-') _correctAnswer = num1 - num2;
    if (operator == 'x') _correctAnswer = num1 * num2;
    if (operator == ':') _correctAnswer = num1 ~/ num2;

    _questionText = '$num1 $operator $num2 = ?';

    // Membuat Pilihan Jawaban Mengecoh (Mirip-mirip)
    Set<int> optionsSet = {_correctAnswer};
    int attempt = 0;
    while (optionsSet.length < 4 && attempt < 60) {
      attempt++;
      int offset = random.nextInt(10) + 1; // Selisih 1 sampai 10
      bool add = random.nextBool();
      int fakeAnswer = add ? _correctAnswer + offset : _correctAnswer - offset;
      if (fakeAnswer >= 0) optionsSet.add(fakeAnswer); // Cegah opsi minus jika tidak perlu
    }

    // Pengaman: kalau undian acak belum mengumpulkan 4 opsi (mis. jawaban benar
    // bernilai sangat kecil), lengkapi secara berurutan. Loop ini pasti berhenti.
    int filler = _correctAnswer + 1;
    while (optionsSet.length < 4) {
      if (filler >= 0) optionsSet.add(filler);
      filler++;
    }

    _options = optionsSet.toList();
    _options.shuffle(random); // Acak posisi jawaban

    setState(() {});
  }

  void _checkAnswer(int selectedAnswer) {
    if (selectedAnswer == _correctAnswer) {
      // Benar
      int poin = _difficulty == 'easy' ? 10 : _difficulty == 'medium' ? 20 : 30;
      setState(() => _score += poin);
      _generateQuestion();
    } else {
      // Salah (Pengurangan Poin)
      setState(() {
        _score = (_score - 5 < 0) ? 0 : _score - 5;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('math_rush.msg_wrong'.tr()), backgroundColor: Colors.red, duration: const Duration(milliseconds: 300)),
      );
    }
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

            // ==========================================
            // KOTAK BANNER IKLAN
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

  // Tampilan Menu Awal & Game Over
  Widget _buildMenuScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calculate, size: 80, color: Color(0xFF0D47A1)),
            const SizedBox(height: 20),
            Text(
              _isGameOver ? 'math_rush.time_up'.tr() : 'math_rush.game_title'.tr(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 10),
            if (_isGameOver) ...[
              Text('math_rush.final_score'.tr(args: [_score.toString()]), style: const TextStyle(fontSize: 24, color: Colors.purple, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
            ] else ...[
              Text('math_rush.select_difficulty'.tr(), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
            ],

            _buildDifficultyButton('easy', 'math_rush.level_easy'.tr(), Colors.green),
            const SizedBox(height: 15),
            _buildDifficultyButton('medium', 'math_rush.level_medium'.tr(), Colors.orange),
            const SizedBox(height: 15),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text('${'math_rush.level_button'.tr()} $levelLabel', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  // Tampilan Saat Bermain
  Widget _buildGameScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header Status (Waktu & Skor)
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
                child: Text('math_rush.score'.tr(args: [_score.toString()]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),

          const Spacer(),

          // KOTAK SOAL MATEMATIKA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
              border: Border.all(color: Colors.purple.shade100, width: 2),
            ),
            child: Text(
              _questionText,
              style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Color(0xFF333333)),
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(),

          // TOMBOL PILIHAN JAWABAN (GRID 2x2)
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