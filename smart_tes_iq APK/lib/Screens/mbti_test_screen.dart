import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU
import '../data/mbti_data.dart';
import '../helpers/database_helper.dart';
import '../services/auth_service.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../helpers/test_label_helper.dart'; // BARU

class MbtiTestScreen extends StatefulWidget {
  const MbtiTestScreen({super.key});

  @override
  State<MbtiTestScreen> createState() => _MbtiTestScreenState();
}

class _MbtiTestScreenState extends State<MbtiTestScreen> {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};

  int _timeLeft = 900; // 15 Menit
  Timer? _timer;

  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();

    // LOGIKA PENGACAKAN CERDAS MBTI (10 Soal per Dimensi)
    List<Map<String, dynamic>> allQuestions = List.from(MbtiData.questions);

    var eiQuestions = allQuestions.where((q) => q['dimension'] == 'EI').toList()..shuffle();
    var snQuestions = allQuestions.where((q) => q['dimension'] == 'SN').toList()..shuffle();
    var tfQuestions = allQuestions.where((q) => q['dimension'] == 'TF').toList()..shuffle();
    var jpQuestions = allQuestions.where((q) => q['dimension'] == 'JP').toList()..shuffle();

    _questions = [
      ...eiQuestions.take(10),
      ...snQuestions.take(10),
      ...tfQuestions.take(10),
      ...jpQuestions.take(10),
    ];

    // Acak kembali agar urutan dimensinya bercampur
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
                content: Text('mbti.msg_incomplete'.tr()),
                backgroundColor: Colors.red
            )
        );
        return;
      }
      _finishTest();
    }
  }

  void _answerQuestion(String option) {
    setState(() {
      _answers[_currentIndex] = option;
    });

    if (_currentIndex < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _currentIndex++;
          });
        }
      });
    } else {
      _nextQuestion();
    }
  }

  Future<void> _finishTest() async {
    _timer?.cancel();

    // MENGHITUNG SKOR MBTI
    int e = 0, i = 0;
    int s = 0, n = 0;
    int t = 0, f = 0;
    int j = 0, p = 0;

    for (int idx = 0; idx < _questions.length; idx++) {
      if (_answers.containsKey(idx)) {
        String dimension = _questions[idx]['dimension'];
        String answerLetter = _answers[idx]!.substring(0, 1); // "A" atau "B"

        if (dimension == 'EI') {
          answerLetter == 'A' ? e++ : i++;
        } else if (dimension == 'SN') {
          answerLetter == 'A' ? s++ : n++;
        } else if (dimension == 'TF') {
          answerLetter == 'A' ? t++ : f++;
        } else if (dimension == 'JP') {
          answerLetter == 'A' ? j++ : p++;
        }
      }
    }

    String mbtiCode = "";
    mbtiCode += (e >= i) ? "E" : "I";
    mbtiCode += (s >= n) ? "S" : "N";
    mbtiCode += (t >= f) ? "T" : "F";
    mbtiCode += (j >= p) ? "J" : "P";

    // Simpan ke DB dengan nama Indo statis
    await DatabaseHelper.instance.insertTestResult({
      'test_name': 'Tes 16 Kepribadian (MBTI)',
      'score': 100, // Tes kepribadian tidak ada benar/salah
      'total_questions': _questions.length,
      'ai_analysis': 'Menunggu sinkronisasi AI... [KODE: $mbtiCode]',
      'is_synced': 0,
    });

    AuthService().syncDataNow();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MbtiResultScreen(mbtiCode: mbtiCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return Scaffold(body: Center(child: Text('mbti.msg_empty_bank'.tr())));

    final currentQ = _questions[_currentIndex];
    final langCode = context.locale.languageCode;

    // Tentukan text soal/opsi dinamis berdasarkan bahasa yang aktif dengan sistem keamanan (fallback)
    final String displayQuestion = langCode == 'en' ? currentQ['questionEn'] ?? currentQ['question'] : currentQ['questionId'] ?? currentQ['question'];
    final options = (langCode == 'en' ? currentQ['optionsEn'] ?? currentQ['options'] : currentQ['optionsId'] ?? currentQ['options']) as List<String>;

    // Dapatkan label judul tes
    final displayTestName = getLocalizedTestLabel('Tes 16 Kepribadian (MBTI)', langCode);

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
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                  child: Center(
                    child: Text(displayQuestion, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.4), textAlign: TextAlign.center),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Expanded(
                flex: 4,
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    // Validasi tetap menggunakan substring(0,1) yaitu A/B
                    final isSelected = _answers.containsKey(_currentIndex) && _answers[_currentIndex]!.substring(0, 1) == option.substring(0, 1);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: ElevatedButton(
                        onPressed: () => _answerQuestion(option), // Simpan keseluruhan string yang ada awalan A/B nya
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          alignment: Alignment.centerLeft,
                          backgroundColor: isSelected ? const Color(0xFF1976D2) : Colors.white,
                          foregroundColor: isSelected ? Colors.white : Colors.black87,
                          elevation: isSelected ? 4 : 1,
                          side: BorderSide(color: isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(option, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4)),
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
                      child: Text('mbti.btn_prev'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        _currentIndex < _questions.length - 1 ? 'mbti.btn_next'.tr() : 'mbti.btn_finish'.tr(),
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
        width: double.infinity, height: 60,
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1))),
        child: const Center(child: CustomBannerAd()),
      ),
    );
  }
}

// ==========================================
// HALAMAN HASIL MBTI
// ==========================================
class MbtiResultScreen extends StatefulWidget {
  final String mbtiCode;

  const MbtiResultScreen({super.key, required this.mbtiCode});

  @override
  State<MbtiResultScreen> createState() => _MbtiResultScreenState();
}

class _MbtiResultScreenState extends State<MbtiResultScreen> {
  bool _isAiUnlocked = false;
  bool _isLoadingAI = false;
  String _aiAnalysis = "";

  Future<void> _watchAdToUnlock() async {
    RewardedAdManager.showAd(context, () async {
      setState(() => _isLoadingAI = true);

      try {
        final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash-lite";
        final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

        final String prompt = 'mbti.prompt_ai'.tr(args: [widget.mbtiCode]);

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

          setState(() {
            _aiAnalysis = aiText;
            _isAiUnlocked = true;
            _isLoadingAI = false;
          });

          await DatabaseHelper.instance.updateLatestTestAnalysis(
            'Tes 16 Kepribadian (MBTI)',
            '$_aiAnalysis \n\n[KODE: ${widget.mbtiCode}]',
          );

          AuthService().syncDataNow();
        } else {
          throw Exception('Status: ${response.statusCode}');
        }

      } catch (e) {
        setState(() => _isLoadingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('mbti.error_ai'.tr(args: [e.toString()]))));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('mbti.result_appbar'.tr()),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
              child: Column(
                children: [
                  Text('mbti.result_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(widget.mbtiCode, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), letterSpacing: 8.0), textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                    child: Text('mbti.result_subtitle'.tr(), style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Text('mbti.result_ai_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: _isAiUnlocked ? Colors.white : Colors.grey.shade200, borderRadius: BorderRadius.circular(15), border: Border.all(color: _isAiUnlocked ? Colors.green.shade200 : Colors.transparent)),
              child: _isLoadingAI
                  ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                  : _isAiUnlocked
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.auto_awesome, color: Colors.orange), const SizedBox(width: 8), Text('mbti.result_ai_unlocked_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 15),
                  MarkdownBody(
                      data: _aiAnalysis,
                      styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                          strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          listBullet: const TextStyle(color: Colors.orange, fontSize: 16)
                      )
                  ),
                ],
              )
                  : Column(
                children: [
                  const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text('mbti.result_ai_locked_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _watchAdToUnlock,
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                    label: Text('mbti.btn_watch_ad'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity, height: 60,
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1))),
        child: const CustomBannerAd(),
      ),
    );
  }
}