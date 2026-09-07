import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../helpers/test_label_helper.dart'; // BARU: Untuk menerjemahkan judul tes

class ResultScreen extends StatefulWidget {
  final String testName; // Tetap versi Indonesia dari database
  final int score;
  final int totalQuestions;

  const ResultScreen({
    super.key,
    required this.testName,
    required this.score,
    required this.totalQuestions,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isAdWatched = false;
  bool _isLoadingAI = false;
  bool _isSharing = false;
  String _aiAnalysis = "";

  final GlobalKey _shareKey = GlobalKey();

  // Menerjemahkan kategori berdasarkan bahasa aktif
  String get _category {
    double percentage = widget.totalQuestions > 0 ? widget.score / widget.totalQuestions : 0;
    if (percentage >= 0.8) return 'result.cat_excellent'.tr();
    if (percentage >= 0.6) return 'result.cat_good'.tr();
    return 'result.cat_practice'.tr();
  }

  // =========================================================
  // FUNGSI MEMANGGIL AI SETELAH NONTON IKLAN
  // =========================================================
  Future<void> _unlockAIAnalysis() async {
    RewardedAdManager.showAd(context, () async {
      setState(() => _isLoadingAI = true);

      try {
        final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash-lite";
        final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

        // Dapatkan nama tes terjemahan untuk AI Prompt
        final displayTestName = getLocalizedTestLabel(widget.testName, context.locale.languageCode);

        // Prompt menyesuaikan dengan bahasa
        final String prompt = 'result.prompt_ai'.tr(args: [
          displayTestName,
          widget.score.toString(),
          widget.totalQuestions.toString(),
          _category
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
            _isAdWatched = true;
            _isLoadingAI = false;
          });
        } else {
          throw Exception('Status: ${response.statusCode}');
        }

      } catch (e) {
        setState(() => _isLoadingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('result.error_ai'.tr(args: [e.toString()]))));
      }
    });
  }

  // =========================================================
  // FUNGSI MEMBAGIKAN POSTER HASIL TES
  // =========================================================
  Future<void> _shareResultPoster() async {
    setState(() => _isSharing = true);
    try {
      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      // Amankan nama file dengan mengganti spasi
      final safeTestName = widget.testName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final imagePath = await File('${directory.path}/hasil_$safeTestName.png').create();
      await imagePath.writeAsBytes(pngBytes);

      final displayTestName = getLocalizedTestLabel(widget.testName, context.locale.languageCode);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'result.share_text'.tr(args: [
          widget.score.toString(), displayTestName, _category
        ]),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('result.msg_share_fail'.tr(args: [e.toString()]))));
    }
    setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final displayTestName = getLocalizedTestLabel(widget.testName, context.locale.languageCode);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('result.appbar_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ---------------------------------------------------------
          // 1. POSTER RAHASIA (DISEMBUNYIKAN DI LUAR LAYAR)
          // ---------------------------------------------------------
          Positioned(
            left: -3000,
            top: -3000,
            child: RepaintBoundary(
              key: _shareKey,
              child: Container(
                width: 400,
                height: 400,
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology, size: 50, color: Colors.amber),
                    const SizedBox(height: 10),
                    Text('result.poster_app_name'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 25),
                    Text(displayTestName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))]),
                      child: Column(
                        children: [
                          Text('result.poster_score_title'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${widget.score}', style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 60, fontWeight: FontWeight.w900, height: 1.1)),
                          Container(margin: const EdgeInsets.symmetric(vertical: 5), width: 100, height: 2, color: Colors.orange),
                          Text(_category.toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text('result.poster_footer'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ),

          // ---------------------------------------------------------
          // 2. LAYAR UTAMA (YANG DILIHAT USER)
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
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            Text(displayTestName, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text('${widget.score}', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                            const SizedBox(height: 5),
                            Text('result.points'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                              child: Text('result.category_label'.tr(args: [_category]), style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _isSharing
                          ? const Center(child: CircularProgressIndicator())
                          : OutlinedButton.icon(
                        onPressed: _shareResultPoster,
                        icon: const Icon(Icons.share, size: 18),
                        label: Text('result.btn_share'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D47A1),
                          side: const BorderSide(color: Color(0xFF0D47A1)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text('result.ai_analysis_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: _isAdWatched ? Colors.white : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: _isAdWatched ? Colors.orange.shade200 : Colors.transparent),
                        ),
                        child: _isLoadingAI
                            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                            : _isAdWatched
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.psychology, color: Colors.orange),
                                const SizedBox(width: 10),
                                Text('result.ai_conclusion'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            MarkdownBody(
                              data: _aiAnalysis,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                                strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                listBullet: const TextStyle(color: Colors.orange, fontSize: 16),
                              ),
                            ),
                          ],
                        )
                            : Column(
                          children: [
                            const Icon(Icons.lock_outline, size: 40, color: Colors.grey),
                            const SizedBox(height: 15),
                            Text('result.ai_locked_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            Text(
                              'result.ai_locked_desc'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _unlockAIAnalysis,
                                icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
                                label: Text('result.btn_watch_ad'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                width: double.infinity,
                height: 60,
                color: Colors.white,
                child: const Center(
                  child: CustomBannerAd(),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}