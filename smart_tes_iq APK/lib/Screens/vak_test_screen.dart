import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../data/vak_data.dart';
import '../helpers/database_helper.dart';
import '../services/auth_service.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../helpers/test_label_helper.dart'; // BARU: Untuk terjemahan judul tes

class VakTestScreen extends StatefulWidget {
  const VakTestScreen({super.key});

  @override
  State<VakTestScreen> createState() => _VakTestScreenState();
}

class _VakTestScreenState extends State<VakTestScreen> {
  int _currentIndex = 0;
  final Map<int, String> _answers = {};

  int _timeLeft = 720; // 12 menit
  Timer? _timer;

  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();

    List<Map<String, dynamic>> allQuestions = List.from(VakData.questions);
    allQuestions.shuffle();
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
                content: Text('vak.msg_incomplete'.tr()),
                backgroundColor: Colors.red
            )
        );
        return;
      }
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    _timer?.cancel();

    int visualCount = 0;
    int auditoryCount = 0;
    int kinestheticCount = 0;

    for (int i = 0; i < _questions.length; i++) {
      if (_answers.containsKey(i)) {
        // Asumsi data opsi tetap diawali A, B, C meskipun diterjemahkan
        if (_answers[i]!.startsWith('A')) visualCount++;
        else if (_answers[i]!.startsWith('B')) auditoryCount++;
        else if (_answers[i]!.startsWith('C')) kinestheticCount++;
      }
    }

    String dominant = "Visual";
    if (auditoryCount > visualCount && auditoryCount > kinestheticCount) dominant = "Auditori";
    if (kinestheticCount > visualCount && kinestheticCount > auditoryCount) dominant = "Kinestetik";
    if (visualCount == auditoryCount || visualCount == kinestheticCount || auditoryCount == kinestheticCount) dominant = "Kombinasi Seimbang";

    await DatabaseHelper.instance.insertTestResult({
      'test_name': 'Gaya Belajar (VAK)', // Tetap string asli Indo untuk database
      'score': dominant == 'Visual' ? visualCount : (dominant == 'Auditori' ? auditoryCount : kinestheticCount),
      'total_questions': _questions.length,
      'ai_analysis': 'Menunggu sinkronisasi AI... [KODE: $dominant]',
      'is_synced': 0,
    });

    AuthService().syncDataNow();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VakResultScreen(
          visual: visualCount,
          auditory: auditoryCount,
          kinesthetic: kinestheticCount,
          dominant: dominant, // String asli untuk database
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return Scaffold(body: Center(child: Text('vak.msg_empty_bank'.tr())));

    final currentQ = _questions[_currentIndex];
    final langCode = context.locale.languageCode;

    // Teks soal & opsi yang mendukung JSON lama dan JSON baru dwibahasa
    final String displayQuestion = langCode == 'en' ? currentQ['questionEn'] ?? currentQ['question'] : currentQ['questionId'] ?? currentQ['question'];
    final options = (langCode == 'en' ? currentQ['optionsEn'] ?? currentQ['options'] : currentQ['optionsId'] ?? currentQ['options']) as List<String>;

    final displayTestName = getLocalizedTestLabel('Gaya Belajar (VAK)', langCode);

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

              Expanded(
                flex: 2,
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
                flex: 3,
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    // Validasi cek substring(0,1) yaitu A/B/C agar aman beda bahasa
                    final isSelected = _answers.containsKey(_currentIndex) && _answers[_currentIndex]!.substring(0, 1) == option.substring(0, 1);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _answers[_currentIndex] = option; // Simpan opsi sesuai bahasa saat ini
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
                      child: Text('vak.btn_prev'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        _currentIndex < _questions.length - 1 ? 'vak.btn_next'.tr() : 'vak.btn_finish'.tr(),
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
// HALAMAN HASIL KHUSUS VAK
// ==========================================
class VakResultScreen extends StatefulWidget {
  final int visual;
  final int auditory;
  final int kinesthetic;
  final String dominant;

  const VakResultScreen({super.key, required this.visual, required this.auditory, required this.kinesthetic, required this.dominant});

  @override
  State<VakResultScreen> createState() => _VakResultScreenState();
}

class _VakResultScreenState extends State<VakResultScreen> {
  bool _isAiUnlocked = false;
  bool _isLoadingAI = false;
  String _aiAnalysis = "";

  Future<void> _watchAdToUnlock() async {
    RewardedAdManager.showAd(context, () async {
      setState(() => _isLoadingAI = true);

      try {
        final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash-lite";
        final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

        // Translasi label gaya dominan ke bahasa aktif untuk prompt AI
        String localizedDominant = widget.dominant;
        if (widget.dominant == 'Visual') localizedDominant = 'vak.visual'.tr();
        else if (widget.dominant == 'Auditori') localizedDominant = 'vak.auditory'.tr();
        else if (widget.dominant == 'Kinestetik') localizedDominant = 'vak.kinesthetic'.tr();
        else if (widget.dominant == 'Kombinasi Seimbang') localizedDominant = 'vak.balanced'.tr();

        final String prompt = 'vak.prompt_ai'.tr(args: [
          localizedDominant,
          widget.visual.toString(),
          widget.auditory.toString(),
          widget.kinesthetic.toString()
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

          setState(() {
            _aiAnalysis = aiText;
            _isAiUnlocked = true;
            _isLoadingAI = false;
          });

          await DatabaseHelper.instance.updateLatestTestAnalysis(
            'Gaya Belajar (VAK)',
            '$_aiAnalysis \n\n[KODE: ${widget.dominant}]', // Simpan dengan kode dominan asli Indo
          );

          AuthService().syncDataNow();
        } else {
          throw Exception('Status: ${response.statusCode}');
        }

      } catch (e) {
        setState(() => _isLoadingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('vak.error_ai'.tr(args: [e.toString()]))));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Translasi label dominan khusus untuk UI
    String localizedDominant = widget.dominant;
    if (widget.dominant == 'Visual') localizedDominant = 'vak.visual'.tr();
    else if (widget.dominant == 'Auditori') localizedDominant = 'vak.auditory'.tr();
    else if (widget.dominant == 'Kinestetik') localizedDominant = 'vak.kinesthetic'.tr();
    else if (widget.dominant == 'Kombinasi Seimbang') localizedDominant = 'vak.balanced'.tr();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('vak.result_appbar'.tr()),
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
                  Text('vak.result_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(localizedDominant.toUpperCase(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)), textAlign: TextAlign.center),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildScoreBox('vak.visual'.tr(), widget.visual, Colors.blue),
                      _buildScoreBox('vak.auditory'.tr(), widget.auditory, Colors.orange),
                      _buildScoreBox('vak.kinesthetic'.tr(), widget.kinesthetic, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Text('vak.ai_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  Row(children: [const Icon(Icons.auto_awesome, color: Colors.orange), const SizedBox(width: 8), Text('vak.ai_unlocked_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold))]),
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
                  Text('vak.ai_locked_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _watchAdToUnlock,
                    icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                    label: Text('vak.btn_watch_ad'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildScoreBox(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        CircleAvatar(radius: 24, backgroundColor: color.withOpacity(0.2), child: Text('$score', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))),
      ],
    );
  }
}