import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../data/klasifikasi_data.dart';
import '../helpers/database_helper.dart';
import '../helpers/test_label_helper.dart'; // BARU: Untuk terjemahan judul tes
import 'result_screen.dart';
import '../services/auth_service.dart';
import '../helpers/ad_helper.dart';

class KlasifikasiTestScreen extends StatefulWidget {
  const KlasifikasiTestScreen({super.key});

  @override
  State<KlasifikasiTestScreen> createState() => _KlasifikasiTestScreenState();
}

class _KlasifikasiTestScreenState extends State<KlasifikasiTestScreen> {
  int _currentIndex = 0;

  final Map<int, String> _answers = {};

  int _timeLeft = 900;
  Timer? _timer;

  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List<Map<String, dynamic>>.from(KlasifikasiData.questions);
    _questions.shuffle();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _finishTest(timeUp: true);
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      if (_answers.length < _questions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('klasifikasi.msg_incomplete'.tr()),
                backgroundColor: Colors.red
            )
        );
        return;
      }
      _finishTest(timeUp: false);
    }
  }

  int _calculateFinalScore() {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers.containsKey(i)) {
        String selectedLetter = _answers[i]!;
        if (selectedLetter == _questions[i]['answer']) {
          score++;
        }
      }
    }
    return score;
  }

  Future<void> _finishTest({required bool timeUp}) async {
    _timer?.cancel();
    int finalScore = _calculateFinalScore();

    // PENTING: String 'Klasifikasi Gambar' tetap statis untuk Database
    await DatabaseHelper.instance.insertTestResult({
      'test_name': 'Klasifikasi Gambar',
      'score': finalScore,
      'total_questions': _questions.length,
      'ai_analysis': 'Menunggu sinkronisasi AI...',
      'is_synced': 0,
    });

    AuthService().syncDataNow();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          testName: 'Klasifikasi Gambar', // Tetap dikirim versi statisnya
          score: finalScore,
          totalQuestions: _questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menarik teks terjemahan untuk judul App Bar
    final displayTestName = getLocalizedTestLabel('Klasifikasi Gambar', context.locale.languageCode);

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(displayTestName), backgroundColor: const Color(0xFF0D47A1)),
        body: Center(child: Text('klasifikasi.msg_empty_bank'.tr())),
      );
    }

    final currentQ = _questions[_currentIndex];
    final options = currentQ['options'] as List<String>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(displayTestName, style: const TextStyle(fontSize: 18)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _timeLeft < 60 ? Colors.red : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 18, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_timeLeft),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    bool isAnswered = _answers.containsKey(index);
                    bool isCurrent = _currentIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      child: Container(
                        width: 45,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFF0D47A1)
                              : (isAnswered ? Colors.green : Colors.grey.shade200),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isCurrent ? Colors.orange : Colors.transparent,
                              width: isCurrent ? 2 : 0
                          ),
                        ),
                        child: Center(
                          child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                  color: isCurrent || isAnswered ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                              )
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'klasifikasi.test_instruction'.tr(),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: InteractiveViewer(
                    child: Image.asset(
                      currentQ['image'],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                flex: 2,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: options.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 2.0,
                  ),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = _answers[_currentIndex] == option;

                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _answers[_currentIndex] = option;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? const Color(0xFF1976D2) : Colors.white,
                        foregroundColor: isSelected ? Colors.white : Colors.black87,
                        elevation: isSelected ? 4 : 1,
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentIndex > 0 ? _prevQuestion : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey.shade200,
                        disabledBackgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('klasifikasi.btn_prev'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0D47A1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentIndex < _questions.length - 1 ? 'klasifikasi.btn_next'.tr() : 'klasifikasi.btn_finish'.tr(),
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
    );
  }
}