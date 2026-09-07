import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../helpers/ad_helper.dart';

class StroopGameScreen extends StatefulWidget {
  const StroopGameScreen({super.key});

  @override
  State<StroopGameScreen> createState() => _StroopGameScreenState();
}

class _StroopGameScreenState extends State<StroopGameScreen> {
  // Status Game
  bool _isPlaying = false;
  bool _isGameOver = false;

  // Variabel Permainan
  int _score = 0;
  int _timeLeft = 60; // Waktu main 60 detik
  Timer? _timer;

  // Data Warna - Menggunakan Key Translasi agar dinamis lintas bahasa
  final Map<String, Color> _colorData = {
    'stroop.color_red': Colors.red,
    'stroop.color_blue': Colors.blue,
    'stroop.color_green': Colors.green,
    'stroop.color_yellow': const Color(0xFFFFD600),
    'stroop.color_purple': Colors.purple,
    'stroop.color_black': Colors.black,
  };

  late String _currentText; // Key teks yang muncul (misal: "stroop.color_red")
  late String _correctColorName; // Key jawaban benar (misal warna tintanya: "stroop.color_blue")
  late Color _currentColor; // Warna tinta asli yang dirender
  List<String> _options = []; // 4 Pilihan tombol

  void _startGame() {
    setState(() {
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
    List<String> colorNames = _colorData.keys.toList();

    // 1. Pilih teks secara acak
    _currentText = colorNames[random.nextInt(colorNames.length)];

    // 2. Pilih warna tinta secara acak (Pastikan BEDA dengan teksnya agar mengecoh)
    _correctColorName = colorNames[random.nextInt(colorNames.length)];
    while (_correctColorName == _currentText) {
      _correctColorName = colorNames[random.nextInt(colorNames.length)];
    }

    _currentColor = _colorData[_correctColorName]!;

    // 3. Buat 4 pilihan jawaban (1 Benar, 3 Salah)
    Set<String> optionsSet = {_correctColorName, _currentText}; // Masukkan jawaban benar & pengecoh utama
    while (optionsSet.length < 4) {
      optionsSet.add(colorNames[random.nextInt(colorNames.length)]);
    }

    _options = optionsSet.toList();
    _options.shuffle(random); // Acak posisi tombol

    setState(() {});
  }

  void _checkAnswer(String selectedAnswer) {
    // Cocokkan key translasinya untuk verifikasi
    if (selectedAnswer == _correctColorName) {
      // Benar: Poin bertambah (+10)
      setState(() => _score += 10);
      _generateQuestion();
    } else {
      // Salah: Poin berkurang (-5) dan layar bergetar / merah sebentar (efek visual)
      setState(() {
        _score = (_score - 5 < 0) ? 0 : _score - 5; // Skor tidak boleh minus
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('stroop.msg_wrong'.tr()), backgroundColor: Colors.red, duration: const Duration(milliseconds: 400)),
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

  // Layar Menu & Game Over
  Widget _buildMenuScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.palette, size: 80, color: Color(0xFF0D47A1)),
            const SizedBox(height: 20),
            Text(
              _isGameOver ? 'stroop.time_up'.tr() : 'stroop.game_title'.tr(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 10),
            if (_isGameOver) ...[
              Text('stroop.final_score'.tr(args: [_score.toString()]), style: const TextStyle(fontSize: 24, color: Colors.orange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
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
                label: Text(_isGameOver ? 'stroop.btn_play_again'.tr() : 'stroop.btn_start'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

  // Layar Saat Bermain
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
                child: Text('stroop.score'.tr(args: [_score.toString()]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),

          const Spacer(),

          // KATA PENGECOH
          Text('stroop.question'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 10),
          Text(
            _currentText.tr(), // Teks yang mengecoh DITERJEMAHKAN di sini
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: _currentColor, // Warna asli (Jawaban yang benar)
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          // TOMBOL JAWABAN (GRID 2x2)
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
                  _options[index].tr(), // Opsi DITERJEMAHKAN di sini
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