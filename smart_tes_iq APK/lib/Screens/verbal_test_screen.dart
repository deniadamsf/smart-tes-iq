import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../data/verbal_data.dart';
import '../helpers/database_helper.dart';
import '../helpers/test_label_helper.dart'; // BARU: Untuk terjemahan judul tes
import 'result_screen.dart';
import '../services/auth_service.dart';
import '../helpers/ad_helper.dart';

class VerbalTestScreen extends StatefulWidget {
  const VerbalTestScreen({super.key});

  @override
  State<VerbalTestScreen> createState() => _VerbalTestScreenState();
}

class _VerbalTestScreenState extends State<VerbalTestScreen> {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};
  int _timeLeft = 600; // 12 menit (12 x 60 detik) -> Sesuai kode awal Anda
  Timer? _timer;

  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();

    // 1. Salin data asli ke variabel lokal agar data asli tidak teracak permanen
    List<Map<String, dynamic>> allQuestions = List.from(VerbalData.questions);

    // 2. Acak urutan soal
    allQuestions.shuffle();

    // 3. Ambil 30 soal saja dari hasil pengacakan
    _questions = allQuestions.take(30).toList();

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
        setState(() => _timeLeft--);
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
                content: Text('verbal.msg_incomplete'.tr()),
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
        // Amankan pencocokan dengan mengambil 1 karakter pertama (A/B/C/D)
        String selectedLetter = _answers[i]!.substring(0, 1);
        String correctLetter = _questions[i]['answer'].toString().substring(0, 1);
        if (selectedLetter == correctLetter) {
          score++;
        }
      }
    }
    return score;
  }

  Future<void> _finishTest({required bool timeUp}) async {
    _timer?.cancel();
    int finalScore = _calculateFinalScore();

    // PENTING: String 'Analogi Verbal' tetap statis untuk Database
    await DatabaseHelper.instance.insertTestResult({
      'test_name': 'Analogi Verbal',
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
          testName: 'Analogi Verbal', // Tetap dikirim versi statisnya
          score: finalScore,
          totalQuestions: _questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;
    final displayTestName = getLocalizedTestLabel('Analogi Verbal', langCode);

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(displayTestName), backgroundColor: const Color(0xFF0D47A1)),
        body: Center(child: Text('verbal.msg_empty_bank'.tr())),
      );
    }

    final currentQ = _questions[_currentIndex];

    // Logika fallback: Menggunakan bahasa aktif ATAU data lama jika belum diupdate
    final String displayQuestion = langCode == 'en' ? currentQ['questionEn'] ?? currentQ['question'] : currentQ['questionId'] ?? currentQ['question'];
    final options = (langCode == 'en' ? currentQ['optionsEn'] ?? currentQ['options'] : currentQ['optionsId'] ?? currentQ['options']) as List<String>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(displayTestName),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _timeLeft < 60 ? Colors.red : Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 18, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(_formatTime(_timeLeft), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              // ==========================================
              // PITA NAVIGASI NOMOR SOAL
              // ==========================================
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
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(
                    displayQuestion,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    // Validasi menggunakan substring(0,1) untuk mengamankan opsi 2 bahasa
                    final isSelected = _answers.containsKey(_currentIndex) && _answers[_currentIndex]!.substring(0, 1) == option.substring(0, 1);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _answers[_currentIndex] = option;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          alignment: Alignment.centerLeft,
                          backgroundColor: isSelected ? const Color(0xFF1976D2) : Colors.white,
                          foregroundColor: isSelected ? Colors.white : Colors.black87,
                          elevation: isSelected ? 4 : 1,
                          side: BorderSide(color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(option, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                      child: Text('verbal.btn_prev'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        _currentIndex < _questions.length - 1 ? 'verbal.btn_next'.tr() : 'verbal.btn_finish'.tr(),
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