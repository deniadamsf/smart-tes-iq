import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU
import '../data/riasec_data.dart';
import '../helpers/database_helper.dart';
import '../services/auth_service.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../helpers/test_label_helper.dart'; // BARU

class RiasecTestScreen extends StatefulWidget {
  const RiasecTestScreen({super.key});

  @override
  State<RiasecTestScreen> createState() => _RiasecTestScreenState();
}

class _RiasecTestScreenState extends State<RiasecTestScreen> {
  int _currentIndex = 0;
  final Map<int, bool> _answers = {};

  int _timeLeft = 780;
  Timer? _timer;

  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();

    List<Map<String, dynamic>> allQuestions = List<Map<String, dynamic>>.from(RiasecData.questions);
    allQuestions.shuffle();
    _questions = allQuestions.take(50).toList();

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
                content: Text('riasec.msg_incomplete'.tr()),
                backgroundColor: Colors.red
            )
        );
        return;
      }
      _finishTest();
    }
  }

  void _answerQuestion(bool isYes) {
    setState(() {
      _answers[_currentIndex] = isYes;
    });

    if (_currentIndex < _questions.length - 1) {
      Future.delayed(const Duration(milliseconds: 150), () {
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

    Map<String, int> finalScores = {"R": 0, "I": 0, "A": 0, "S": 0, "E": 0, "C": 0};

    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == true) {
        String type = _questions[i]['type'];
        finalScores[type] = finalScores[type]! + 1;
      }
    }

    var sortedEntries = finalScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String dominantCode = "${sortedEntries[0].key}${sortedEntries[1].key}${sortedEntries[2].key}";

    await DatabaseHelper.instance.insertTestResult({
      'test_name': 'Bakat Minat (RIASEC)',
      'score': sortedEntries[0].value,
      'total_questions': _questions.length,
      'ai_analysis': 'Menunggu sinkronisasi AI... [KODE: $dominantCode]',
      'is_synced': 0,
    });

    AuthService().syncDataNow();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RiasecResultScreen(
          scores: finalScores,
          dominantCode: dominantCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return Scaffold(body: Center(child: Text('riasec.msg_empty_bank'.tr())));
    final currentQ = _questions[_currentIndex];

    final isYesSelected = _answers[_currentIndex] == true;
    final isNoSelected = _answers[_currentIndex] == false;
    final langCode = context.locale.languageCode;

    /// Tarik soal dinamis berdasarkan bahasa dengan sistem fallback
    final String displayQuestion = langCode == 'en'
        ? (currentQ['questionEn'] ?? currentQ['question'])
        : (currentQ['questionId'] ?? currentQ['question']);

    final displayTestName = getLocalizedTestLabel('Bakat Minat (RIASEC)', langCode);

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

              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                  child: Center(
                    child: Text(displayQuestion, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4), textAlign: TextAlign.center),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: () => _answerQuestion(true),
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 28),
                label: Text('riasec.btn_yes'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: isYesSelected ? const Color(0xFF1976D2) : Colors.white,
                  foregroundColor: isYesSelected ? Colors.white : Colors.black87,
                  elevation: isYesSelected ? 4 : 1,
                  side: BorderSide(color: isYesSelected ? const Color(0xFF1976D2) : Colors.grey.shade300, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () => _answerQuestion(false),
                icon: const Icon(Icons.thumb_down_alt_outlined, size: 28),
                label: Text('riasec.btn_no'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: isNoSelected ? Colors.red.shade400 : Colors.white,
                  foregroundColor: isNoSelected ? Colors.white : Colors.black87,
                  elevation: isNoSelected ? 4 : 1,
                  side: BorderSide(color: isNoSelected ? Colors.red.shade400 : Colors.grey.shade300, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 30),

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
                      child: Text('riasec.btn_prev'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        _currentIndex < _questions.length - 1 ? 'riasec.btn_next'.tr() : 'riasec.btn_finish'.tr(),
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

// ==========================================
// HALAMAN HASIL KHUSUS RIASEC
// ==========================================
class RiasecResultScreen extends StatefulWidget {
  final Map<String, int> scores;
  final String dominantCode;

  const RiasecResultScreen({super.key, required this.scores, required this.dominantCode});

  @override
  State<RiasecResultScreen> createState() => _RiasecResultScreenState();
}

class _RiasecResultScreenState extends State<RiasecResultScreen> {
  bool _isAiUnlocked = false;
  bool _isLoadingAI = false;
  String _aiAnalysis = "";

  Future<void> _watchAdToUnlock() async {
    RewardedAdManager.showAd(context, () async {
      setState(() => _isLoadingAI = true);

      try {
        final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash-lite";
        final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

        final String prompt = 'riasec.prompt_ai'.tr(args: [widget.dominantCode]);

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
            'Bakat Minat (RIASEC)',
            '$_aiAnalysis \n\n[KODE: ${widget.dominantCode}]',
          );

          AuthService().syncDataNow();
        } else {
          throw Exception('Status: ${response.statusCode}');
        }

      } catch (e) {
        setState(() => _isLoadingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('riasec.error_ai'.tr(args: [e.toString()]))));
      }
    });
  }

  String _translateCode(String letter) {
    switch (letter) {
      case "R": return 'riasec.code_R'.tr();
      case "I": return 'riasec.code_I'.tr();
      case "A": return 'riasec.code_A'.tr();
      case "S": return 'riasec.code_S'.tr();
      case "E": return 'riasec.code_E'.tr();
      case "C": return 'riasec.code_C'.tr();
      default: return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('riasec.result_appbar'.tr()),
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
                  Text('riasec.result_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(widget.dominantCode, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), letterSpacing: 5.0), textAlign: TextAlign.center),
                  const SizedBox(height: 20),

                  ListTile(leading: const CircleAvatar(backgroundColor: Colors.blue, child: Text('1', style: TextStyle(color: Colors.white))), title: Text(_translateCode(widget.dominantCode[0]), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ListTile(leading: const CircleAvatar(backgroundColor: Colors.orange, child: Text('2', style: TextStyle(color: Colors.white))), title: Text(_translateCode(widget.dominantCode[1]), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ListTile(leading: const CircleAvatar(backgroundColor: Colors.green, child: Text('3', style: TextStyle(color: Colors.white))), title: Text(_translateCode(widget.dominantCode[2]), style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Text('riasec.ai_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  Row(children: [const Icon(Icons.auto_awesome, color: Colors.orange), const SizedBox(width: 8), Text('riasec.ai_unlocked_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold))]),
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
                  Text('riasec.ai_locked_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _watchAdToUnlock,
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                    label: Text('riasec.btn_watch_ad'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1))),
        child: const CustomBannerAd(),      ),
    );
  }
}