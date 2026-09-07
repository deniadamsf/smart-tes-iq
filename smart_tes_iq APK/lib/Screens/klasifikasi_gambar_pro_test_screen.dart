import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../data/klasifikasi_gambar_pro_data.dart';
import '../helpers/database_helper.dart';
import '../helpers/test_label_helper.dart'; // BARU: Untuk judul layar

class KlasifikasiGambarProTestScreen extends StatefulWidget {
  const KlasifikasiGambarProTestScreen({super.key});

  @override
  State<KlasifikasiGambarProTestScreen> createState() => _KlasifikasiGambarProTestScreenState();
}

class _KlasifikasiGambarProTestScreenState extends State<KlasifikasiGambarProTestScreen> {
  bool _isTestStarted = false;
  int _currentIndex = 0;
  final Map<int, String> _answers = {};

  int _timeLeft = 900; // 15 Menit (dalam detik)
  Timer? _timer;

  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();

    // 1. Tarik semua 40 soal dari bank soal
    List<Map<String, dynamic>> allQuestions = List.from(KlasifikasiGambarProData.questions);

    // 2. Acak seluruh 40 soal tersebut
    allQuestions.shuffle();

    // 3. Ambil 24 soal pertama dari hasil acakan (Murni acak tanpa keranjang kesulitan)
    _questions = allQuestions.take(24).toList();
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
        _finishTest();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _prevQuestion() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      if (_answers.length < _questions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('klasifikasi_pro.msg_incomplete'.tr()), backgroundColor: Colors.red)
        );
        return;
      }
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    _timer?.cancel();

    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i]['answer']) {
        score++;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    int currentUserId = prefs.getInt('user_id') ?? 0;

    // SIMPAN KE DATABASE (TETAP PAKAI NAMA INDO UNTUK SYNC)
    await DatabaseHelper.instance.insertTestResult({
      'user_id': currentUserId,
      'test_name': 'Klasifikasi Gambar (PRO)',
      'score': score,
      'total_questions': _questions.length,
      'ai_analysis': 'Menunggu kalkulasi IQ Akhir...',
      'is_synced': 0,
    });

    List<String> completed = prefs.getStringList('pro_completed_tests') ?? [];
    if (!completed.contains('Klasifikasi Gambar (PRO)')) {
      completed.add('Klasifikasi Gambar (PRO)');
      await prefs.setStringList('pro_completed_tests', completed);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('klasifikasi_pro.msg_finished'.tr()), backgroundColor: Colors.green)
    );
    Navigator.pop(context);
  }

  // --- LAYAR PANDUAN UTAMA ---
  Widget _buildInstructions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.style, size: 50, color: Color(0xFF0D47A1)),
              const SizedBox(height: 10),
              Text('klasifikasi_pro.instruction_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)), textAlign: TextAlign.center),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRuleRow(Icons.format_list_numbered, 'klasifikasi_pro.rule_questions'.tr(args: [_questions.length.toString()])),
                    const SizedBox(height: 10),
                    _buildRuleRow(Icons.timer, 'klasifikasi_pro.rule_time'.tr()),
                    const SizedBox(height: 10),
                    _buildRuleRow(Icons.touch_app, 'klasifikasi_pro.rule_tap'.tr()),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 20, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('klasifikasi_pro.tips_title'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'klasifikasi_pro.tips_content'.tr(),
                      style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _isTestStarted = true);
                    _startTimer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text('klasifikasi_pro.btn_start'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0D47A1)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return Scaffold(body: Center(child: Text('klasifikasi_pro.msg_empty_bank'.tr())));

    final currentQ = _questions[_currentIndex];
    final displayTestName = getLocalizedTestLabel('Klasifikasi Gambar (PRO)', context.locale.languageCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(displayTestName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        child: !_isTestStarted
            ? _buildInstructions()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PITA NOMOR SOAL
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    bool isAnswered = _answers.containsKey(index);
                    bool isCurrent = _currentIndex == index;

                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Container(
                        width: 45, margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF0D47A1) : (isAnswered ? Colors.green : Colors.white),
                          shape: BoxShape.circle,
                          border: Border.all(color: isCurrent ? Colors.orange : (isAnswered ? Colors.transparent : Colors.grey.shade300), width: isCurrent ? 2 : 1),
                        ),
                        child: Center(
                          child: Text('${index + 1}', style: TextStyle(color: isCurrent || isAnswered ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),

              // INSTRUKSI SINGKAT DI ATAS SOAL
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100)
                ),
                child: Text(
                  'klasifikasi_pro.test_instruction'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),

              // GAMBAR SOAL EKSTERNAL DENGAN ZOOM
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: InteractiveViewer(
                      child: Image.asset(
                        currentQ['image_path'],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text('klasifikasi_pro.img_error'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // TOMBOL JAWABAN (HANYA A, B, C, D, E)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['A', 'B', 'C', 'D', 'E'].map((option) {
                  final isSelected = _answers[_currentIndex] == option;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: InkWell(
                      onTap: () => setState(() => _answers[_currentIndex] = option),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 55, height: 55,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1976D2) : Colors.white,
                          border: Border.all(color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                        ),
                        child: Center(
                          child: Text(option, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),

              // TOMBOL NAVIGASI BAWAH
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentIndex > 0 ? _prevQuestion : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('klasifikasi_pro.btn_prev'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      child: Text(_currentIndex < _questions.length - 1 ? 'klasifikasi_pro.btn_next'.tr() : 'klasifikasi_pro.btn_finish'.tr(), style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}