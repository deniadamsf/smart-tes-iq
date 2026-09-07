import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU
import '../data/eq_data.dart';
import '../helpers/database_helper.dart';
import '../services/auth_service.dart';

class EqTestScreen extends StatefulWidget {
  const EqTestScreen({super.key});

  @override
  State<EqTestScreen> createState() => _EqTestScreenState();
}

class _EqTestScreenState extends State<EqTestScreen> {
  int _currentIndex = 0;
  final Map<int, int> _answers = {};
  int _timeLeft = 1200; // 20 Menit
  Timer? _timer;

  final List<Map<String, dynamic>> _questions = [];
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _generateRandomTest();
    _startTimer();
  }

  void _generateRandomTest() {
    var saPool = List<Map<String, dynamic>>.from(EqData.bankSelfAwareness)..shuffle();
    var srPool = List<Map<String, dynamic>>.from(EqData.bankSelfRegulation)..shuffle();
    var moPool = List<Map<String, dynamic>>.from(EqData.bankMotivation)..shuffle();
    var emPool = List<Map<String, dynamic>>.from(EqData.bankEmpathy)..shuffle();
    var ssPool = List<Map<String, dynamic>>.from(EqData.bankSocialSkills)..shuffle();

    _questions.addAll(saPool.take(7));
    _questions.addAll(srPool.take(10));
    _questions.addAll(moPool.take(6));
    _questions.addAll(emPool.take(7));
    _questions.addAll(ssPool.take(13));

    _questions.shuffle();
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
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      if (_answers.length < _questions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('eq_test.msg_incomplete'.tr()), backgroundColor: Colors.red)
        );
        return;
      }
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    _timer?.cancel();

    int totalScore = 0;
    int scoreSA = 0, scoreSR = 0, scoreMO = 0, scoreEM = 0, scoreSS = 0;

    _answers.forEach((index, value) {
      totalScore += value;
      String dim = _questions[index]['dimensi'];

      if (dim == 'SA') scoreSA += value;
      else if (dim == 'SR') scoreSR += value;
      else if (dim == 'MO') scoreMO += value;
      else if (dim == 'EM') scoreEM += value;
      else if (dim == 'SS') scoreSS += value;
    });

    // PENTING: Category asli (Indo) untuk disimpan di database
    String categoryDb = "Rendah";
    if (totalScore >= 130) categoryDb = "Sangat Tinggi";
    else if (totalScore >= 100) categoryDb = "Tinggi / Stabil";
    else if (totalScore >= 70) categoryDb = "Cukup / Rata-rata";

    await DatabaseHelper.instance.insertTestResult({
      'test_name': 'Tes EQ (AI)',
      'score': totalScore,
      'total_questions': _questions.length,
      'ai_analysis': 'Menunggu sinkronisasi AI... [KODE: $categoryDb]',
      'is_synced': 0,
    });

    AuthService().syncDataNow();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EqResultScreen(
          totalScore: totalScore,
          category: categoryDb, // Melempar kategori asli
          scoreSA: scoreSA,
          scoreSR: scoreSR,
          scoreMO: scoreMO,
          scoreEM: scoreEM,
          scoreSS: scoreSS,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return Scaffold(body: Center(child: Text('eq_test.loading'.tr())));

    final currentQ = _questions[_currentIndex];
    final langCode = context.locale.languageCode;

    // BARU: Menarik pertanyaan dan opsi secara dinamis sesuai bahasa
    final String displayQuestion = langCode == 'en' ? currentQ['questionEn'] : currentQ['questionId'];
    final options = (langCode == 'en' ? currentQ['optionsEn'] : currentQ['optionsId']) as List<Map<String, dynamic>>;

    return PopScope(
      canPop: _allowPop,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final bool? confirmExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Text('eq_test.dialog_exit_title'.tr(), style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: Text('eq_test.dialog_exit_content'.tr()),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('eq_test.btn_cancel'.tr(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: Text('eq_test.btn_yes_exit'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (confirmExit == true) {
          setState(() {
            _allowPop = true;
          });
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('eq_test.appbar_title'.tr(), style: const TextStyle(fontSize: 18)),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _timeLeft < 120 ? Colors.red : Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
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
                            color: isCurrent ? const Color(0xFF0D47A1) : (isAnswered ? Colors.green : Colors.grey.shade200),
                            shape: BoxShape.circle,
                            border: Border.all(color: isCurrent ? Colors.orange : Colors.transparent, width: isCurrent ? 2 : 0),
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

                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(displayQuestion, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.4), textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  flex: 4,
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      // Pengecekan jawaban berdasarkan score agar aman lintas bahasa
                      final isSelected = _answers[_currentIndex] == option['score'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ElevatedButton(
                          onPressed: () => setState(() => _answers[_currentIndex] = option['score']),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            alignment: Alignment.centerLeft,
                            backgroundColor: isSelected ? const Color(0xFF1976D2) : Colors.white,
                            foregroundColor: isSelected ? Colors.white : Colors.black87,
                            elevation: isSelected ? 4 : 1,
                            side: BorderSide(color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(option['text'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
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
                          backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('eq_test.btn_prev'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        child: Text(_currentIndex < _questions.length - 1 ? 'eq_test.btn_next'.tr() : 'eq_test.btn_finish'.tr(), style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HALAMAN HASIL EQ
// ==========================================
class EqResultScreen extends StatefulWidget {
  final int totalScore;
  final String category; // Database category (Raw Indonesian)
  final int scoreSA;
  final int scoreSR;
  final int scoreMO;
  final int scoreEM;
  final int scoreSS;

  const EqResultScreen({
    super.key,
    required this.totalScore,
    required this.category,
    required this.scoreSA,
    required this.scoreSR,
    required this.scoreMO,
    required this.scoreEM,
    required this.scoreSS,
  });

  @override
  State<EqResultScreen> createState() => _EqResultScreenState();
}

class _EqResultScreenState extends State<EqResultScreen> {
  bool _isLoadingAI = true;
  String _aiAnalysis = "";

  @override
  void initState() {
    super.initState();
    _generateAutomaticAiAnalysis();
  }

  Future<void> _generateAutomaticAiAnalysis() async {
    try {
      final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash";
      final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

      // Translasi nama Kategori untuk diumpankan ke AI Prompt
      String displayCategory = widget.category;
      if (widget.category == "Sangat Tinggi") displayCategory = 'eq_test.cat_very_high'.tr();
      else if (widget.category == "Tinggi / Stabil") displayCategory = 'eq_test.cat_high'.tr();
      else if (widget.category == "Cukup / Rata-rata") displayCategory = 'eq_test.cat_avg'.tr();
      else if (widget.category == "Rendah") displayCategory = 'eq_test.cat_low'.tr();

      // Prompt AI sekarang menyedot dari JSON (Bilingual)
      final String prompt = 'eq_test.prompt_ai'.tr(args: [
        widget.totalScore.toString(),
        displayCategory,
        widget.scoreSA.toString(),
        widget.scoreSR.toString(),
        widget.scoreMO.toString(),
        widget.scoreEM.toString(),
        widget.scoreSS.toString()
      ]);

      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appSecret',
        },
        body: jsonEncode({
          "contents": [{"parts": [{"text": prompt}]}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];

        if (!mounted) return;
        setState(() {
          _aiAnalysis = aiText;
          _isLoadingAI = false;
        });

        // Simpan ke DB tetap memakai Kategori Raw Indo (widget.category)
        await DatabaseHelper.instance.updateLatestTestAnalysis(
          'Tes EQ (AI)',
          '$_aiAnalysis \n\n[KODE: ${widget.category}]',
        );

        AuthService().syncDataNow();
      } else {
        throw Exception('Status: ${response.statusCode}');
      }

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAI = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('eq_test.error_ai'.tr(args: [e.toString()]))));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Translasi Kategori untuk UI Layar Hasil
    String uiCategory = widget.category;
    if (widget.category == "Sangat Tinggi") uiCategory = 'eq_test.cat_very_high'.tr();
    else if (widget.category == "Tinggi / Stabil") uiCategory = 'eq_test.cat_high'.tr();
    else if (widget.category == "Cukup / Rata-rata") uiCategory = 'eq_test.cat_avg'.tr();
    else if (widget.category == "Rendah") uiCategory = 'eq_test.cat_low'.tr();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('eq_test.result_appbar'.tr()),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop()
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                children: [
                  Text('eq_test.result_score_title'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text('${widget.totalScore} / 172', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 5),
                  Text(uiCategory, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: widget.totalScore > 100 ? Colors.green : Colors.orange)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            Text('eq_test.result_ai_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: _isLoadingAI
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.blue),
                    const SizedBox(height: 15),
                    Text('eq_test.result_loading_ai'.tr(), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                )
                    : MarkdownBody(
                    data: _aiAnalysis,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(height: 1.6, fontSize: 14),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    )
                )
            ),
          ],
        ),
      ),
    );
  }
}