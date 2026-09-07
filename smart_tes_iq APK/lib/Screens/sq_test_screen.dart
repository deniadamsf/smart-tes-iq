import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan

import '../data/sq_data.dart';
import '../helpers/database_helper.dart';
import '../services/auth_service.dart';

class SqTestScreen extends StatefulWidget {
  const SqTestScreen({super.key});

  @override
  State<SqTestScreen> createState() => _SqTestScreenState();
}

class _SqTestScreenState extends State<SqTestScreen> {
  int _currentIndex = 0;
  final Map<int, int> _answers = {};

  int _timeLeft = 1500; // 25 Menit
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
    var mePool = List<Map<String, dynamic>>.from(SqData.bankMeaning)..shuffle();
    var egPool = List<Map<String, dynamic>>.from(SqData.bankEgo)..shuffle();
    var coPool = List<Map<String, dynamic>>.from(SqData.bankCompassion)..shuffle();
    var inPool = List<Map<String, dynamic>>.from(SqData.bankIntegrity)..shuffle();
    var ipPool = List<Map<String, dynamic>>.from(SqData.bankInnerPeace)..shuffle();

    _questions.addAll(mePool.take(10));
    _questions.addAll(egPool.take(10));
    _questions.addAll(coPool.take(10));
    _questions.addAll(inPool.take(10));
    _questions.addAll(ipPool.take(10));

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
            SnackBar(content: Text('sq_test.msg_incomplete'.tr()), backgroundColor: Colors.red)
        );
        return;
      }
      _finishTest();
    }
  }

  Future<void> _finishTest() async {
    _timer?.cancel();

    int totalScore = 0;
    _answers.forEach((key, value) {
      totalScore += value;
    });

    // Kategori Statis INDO untuk Database
    String categoryDb = "Perlu Bimbingan";
    if (totalScore >= 170) categoryDb = "Tingkat Pencerahan / Sangat Bijaksana";
    else if (totalScore >= 140) categoryDb = "Tinggi (Sadar & Bertumbuh)";
    else if (totalScore >= 100) categoryDb = "Cukup Sadar (Rata-rata)";

    await DatabaseHelper.instance.insertTestResult({
      'test_name': 'Tes SQ (AI)',
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
        builder: (context) => SqResultScreen(
          totalScore: totalScore,
          category: categoryDb,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return Scaffold(body: Center(child: Text('sq_test.loading'.tr())));

    final currentQ = _questions[_currentIndex];
    final langCode = context.locale.languageCode;

    // Teks soal & opsi yang mendukung JSON lama dan JSON baru dwibahasa
    final String displayQuestion = langCode == 'en' ? currentQ['questionEn'] ?? currentQ['question'] : currentQ['questionId'] ?? currentQ['question'];
    final List<dynamic> optionsDynamic = langCode == 'en' ? currentQ['optionsEn'] ?? currentQ['options'] : currentQ['optionsId'] ?? currentQ['options'];

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
                Text('sq_test.dialog_exit_title'.tr(), style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: Text('sq_test.dialog_exit_content'.tr()),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('sq_test.btn_cancel'.tr(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: Text('sq_test.btn_yes_exit'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          title: Text('sq_test.appbar_title'.tr(), style: const TextStyle(fontSize: 16)),
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
                    itemCount: optionsDynamic.length,
                    itemBuilder: (context, index) {
                      final option = optionsDynamic[index] as Map<String, dynamic>;
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
                        child: Text('sq_test.btn_prev'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        child: Text(_currentIndex < _questions.length - 1 ? 'sq_test.btn_next'.tr() : 'sq_test.btn_finish'.tr(), style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
// HALAMAN HASIL SQ
// ==========================================
class SqResultScreen extends StatefulWidget {
  final int totalScore;
  final String category;

  const SqResultScreen({super.key, required this.totalScore, required this.category});

  @override
  State<SqResultScreen> createState() => _SqResultScreenState();
}

class _SqResultScreenState extends State<SqResultScreen> {
  bool _isLoadingAI = true;
  bool _isSharing = false;
  String _aiAnalysis = "";

  final GlobalKey _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _generateAutomaticAiAnalysis();
  }

  Future<void> _generateAutomaticAiAnalysis() async {
    try {
      final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash";
      final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

      // Translasi kategori khusus untuk prompt AI
      String displayCategory = widget.category;
      if (widget.category == "Tingkat Pencerahan / Sangat Bijaksana") displayCategory = 'sq_test.cat_enlightened'.tr();
      else if (widget.category == "Tinggi (Sadar & Bertumbuh)") displayCategory = 'sq_test.cat_high'.tr();
      else if (widget.category == "Cukup Sadar (Rata-rata)") displayCategory = 'sq_test.cat_avg'.tr();
      else if (widget.category == "Perlu Bimbingan") displayCategory = 'sq_test.cat_need_guidance'.tr();

      final String prompt = 'sq_test.prompt_ai'.tr(args: [
        widget.totalScore.toString(),
        displayCategory
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

        // Simpan tetap menggunakan widget.category asli (Indo) untuk database
        await DatabaseHelper.instance.updateLatestTestAnalysis(
          'Tes SQ (AI)',
          '$_aiAnalysis \n\n[KODE: ${widget.category}]',
        );

        AuthService().syncDataNow();
      } else {
        throw Exception('Status: ${response.statusCode}');
      }

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAI = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('sq_test.error_ai'.tr(args: [e.toString()]))));
    }
  }

  Future<void> _shareResultPoster() async {
    setState(() => _isSharing = true);
    try {
      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/hasil_sq.png').create();
      await imagePath.writeAsBytes(pngBytes);

      // Translasi kategori untuk share text
      String uiCategory = widget.category;
      if (widget.category == "Tingkat Pencerahan / Sangat Bijaksana") uiCategory = 'sq_test.cat_enlightened'.tr();
      else if (widget.category == "Tinggi (Sadar & Bertumbuh)") uiCategory = 'sq_test.cat_high'.tr();
      else if (widget.category == "Cukup Sadar (Rata-rata)") uiCategory = 'sq_test.cat_avg'.tr();
      else if (widget.category == "Perlu Bimbingan") uiCategory = 'sq_test.cat_need_guidance'.tr();

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'sq_test.share_poster_text'.tr(args: [widget.totalScore.toString(), uiCategory]),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('sq_test.msg_share_fail'.tr(args: [e.toString()]))));
    }
    setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    // Translasi kategori untuk UI Layar
    String uiCategory = widget.category;
    if (widget.category == "Tingkat Pencerahan / Sangat Bijaksana") uiCategory = 'sq_test.cat_enlightened'.tr();
    else if (widget.category == "Tinggi (Sadar & Bertumbuh)") uiCategory = 'sq_test.cat_high'.tr();
    else if (widget.category == "Cukup Sadar (Rata-rata)") uiCategory = 'sq_test.cat_avg'.tr();
    else if (widget.category == "Perlu Bimbingan") uiCategory = 'sq_test.cat_need_guidance'.tr();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('sq_test.result_appbar'.tr()),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // POSTER RAHASIA UNTUK DI-SHARE (DISEMBUNYIKAN)
          // ---------------------------------------------------------
          Positioned(
            left: -3000, top: -3000,
            child: RepaintBoundary(
              key: _shareKey,
              child: Container(
                width: 400, height: 400, padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.self_improvement, size: 50, color: Colors.amber),
                    const SizedBox(height: 10),
                    Text('sq_test.poster_app_name'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 25),
                    Text('sq_test.poster_cert_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]),
                      child: Column(
                        children: [
                          Text('sq_test.poster_score_title'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${widget.totalScore}', style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 60, fontWeight: FontWeight.w900, height: 1.1)),
                          Container(margin: const EdgeInsets.symmetric(vertical: 5), width: 100, height: 2, color: Colors.amber),
                          Text(uiCategory.toUpperCase(), style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text('sq_test.poster_footer'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ),

          // ---------------------------------------------------------
          // LAYAR UTAMA (YANG DILIHAT USER)
          // ---------------------------------------------------------
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                        child: Column(
                          children: [
                            Text('sq_test.result_score_title'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 10),
                            Text('${widget.totalScore}', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                            const Text('/ 300', style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                              child: Text(uiCategory, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.totalScore > 195 ? Colors.green : Colors.orange), textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TOMBOL BAGIKAN HASIL
                      _isSharing
                          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                          : OutlinedButton.icon(
                        onPressed: _shareResultPoster,
                        icon: const Icon(Icons.share, size: 18),
                        label: Text('sq_test.btn_share'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D47A1),
                          side: const BorderSide(color: Color(0xFF0D47A1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text('sq_test.result_ai_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                        child: _isLoadingAI
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Colors.orange),
                            const SizedBox(height: 15),
                            Text('sq_test.result_loading_ai'.tr(), style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        )
                            : MarkdownBody(
                            data: _aiAnalysis,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(height: 1.6, fontSize: 14),
                              strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                            )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}