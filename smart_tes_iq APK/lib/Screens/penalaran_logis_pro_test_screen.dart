import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU
import '../data/penalaran_logis_pro_data.dart';
import '../helpers/database_helper.dart';
import '../helpers/test_label_helper.dart'; // BARU

class PenalaranLogisProTestScreen extends StatefulWidget {
  const PenalaranLogisProTestScreen({super.key});

  @override
  State<PenalaranLogisProTestScreen> createState() => _PenalaranLogisProTestScreenState();
}

class _PenalaranLogisProTestScreenState extends State<PenalaranLogisProTestScreen> {
  bool _isTestStarted = false;

  int _currentIndex = 0;
  final Map<int, String> _answers = {};

  int _timeLeft = 720; // 12 Menit
  Timer? _timer;

  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();

    List<Map<String, dynamic>> allQuestions = List.from(PenalaranLogisProData.questions);

    List<Map<String, dynamic>> mudah = allQuestions.where((q) => q['difficulty'] == 'mudah').toList();
    List<Map<String, dynamic>> sedang = allQuestions.where((q) => q['difficulty'] == 'sedang').toList();
    List<Map<String, dynamic>> sulit = allQuestions.where((q) => q['difficulty'] == 'sulit').toList();

    mudah.shuffle();
    sedang.shuffle();
    sulit.shuffle();

    _questions = [
      ...mudah.take(8),
      ...sedang.take(10),
      ...sulit.take(7),
    ];
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
            SnackBar(content: Text('logika_pro.msg_incomplete'.tr()), backgroundColor: Colors.red)
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
      // PERBAIKAN: Mengecek awalan jawaban "A." atau "B." agar aman untuk dwibahasa
      if (_answers.containsKey(i)) {
        String userAnsPrefix = _answers[i]!.substring(0, 2);
        String correctAnsPrefix = _questions[i]['answer'].substring(0, 2);
        if (userAnsPrefix == correctAnsPrefix) {
          score++;
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    int currentUserId = prefs.getInt('user_id') ?? 0;

    // TETAP GUNAKAN STRING INDO UNTUK DATABASE
    await DatabaseHelper.instance.insertTestResult({
      'user_id': currentUserId,
      'test_name': 'Penalaran Logis (PRO)',
      'score': score,
      'total_questions': _questions.length,
      'ai_analysis': 'Menunggu kalkulasi IQ Akhir...',
      'is_synced': 0,
    });

    List<String> completed = prefs.getStringList('pro_completed_tests') ?? [];
    if (!completed.contains('Penalaran Logis (PRO)')) {
      completed.add('Penalaran Logis (PRO)');
      await prefs.setStringList('pro_completed_tests', completed);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('logika_pro.msg_finished'.tr()), backgroundColor: Colors.green)
    );
    Navigator.pop(context);
  }

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
              const Icon(Icons.psychology, size: 50, color: Color(0xFF0D47A1)),
              const SizedBox(height: 10),
              Text('logika_pro.instruction_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRuleRow(Icons.assignment, 'logika_pro.rule_questions'.tr(args: [_questions.length.toString()])),
                    const SizedBox(height: 10),
                    _buildRuleRow(Icons.timer, 'logika_pro.rule_time'.tr()),
                    const SizedBox(height: 10),
                    _buildRuleRow(Icons.touch_app, 'logika_pro.rule_next'.tr()),
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
                        Text('logika_pro.tips_title'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'logika_pro.tips_content'.tr(),
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
                    setState(() {
                      _isTestStarted = true;
                    });
                    _startTimer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text('logika_pro.btn_start'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
    if (_questions.isEmpty) return Scaffold(body: Center(child: Text('logika_pro.msg_empty_bank'.tr())));

    final currentQ = _questions[_currentIndex];
    final langCode = context.locale.languageCode;

    // Fallback logic: Jika file data belum diupdate, panggil 'question' & 'options' lama
    final String displayQuestion = langCode == 'en' ? currentQ['questionEn'] ?? currentQ['question'] : currentQ['questionId'] ?? currentQ['question'];
    final options = (langCode == 'en' ? currentQ['optionsEn'] ?? currentQ['options'] : currentQ['optionsId'] ?? currentQ['options']) as List<String>;

    final displayTestName = getLocalizedTestLabel('Penalaran Logis (PRO)', langCode);

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
          padding: const EdgeInsets.all(20.0),
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
              const SizedBox(height: 20),

              // INSTRUKSI BIRU MUDA SAAT MENGERJAKAN SOAL
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100)
                ),
                child: Text(
                  'logika_pro.test_instruction'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),

              // KOTAK PERTANYAAN
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(displayQuestion, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5), textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // OPSI JAWABAN
              Expanded(
                flex: 4,
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    // Validasi tetap menggunakan substring(0,2) misal "A."
                    final isSelected = _answers.containsKey(_currentIndex) && _answers[_currentIndex]!.substring(0, 2) == option.substring(0, 2);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _answers[_currentIndex] = option);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          alignment: Alignment.centerLeft,
                          backgroundColor: isSelected ? const Color(0xFF1976D2) : Colors.white,
                          foregroundColor: isSelected ? Colors.white : Colors.black87,
                          elevation: isSelected ? 4 : 0,
                          side: BorderSide(color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(option, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
                      ),
                    );
                  },
                ),
              ),

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
                      child: Text('logika_pro.btn_prev'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                      child: Text(_currentIndex < _questions.length - 1 ? 'logika_pro.btn_next'.tr() : 'logika_pro.btn_finish'.tr(), style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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