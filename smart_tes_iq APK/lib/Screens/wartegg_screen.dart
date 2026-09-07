import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../helpers/database_helper.dart';
import '../services/auth_service.dart';

class WarteggScreen extends StatefulWidget {
  const WarteggScreen({super.key});

  @override
  State<WarteggScreen> createState() => _WarteggScreenState();
}

class _WarteggScreenState extends State<WarteggScreen> {
  final List<SignatureController> _controllers = List.generate(
    8,
        (_) => SignatureController(
      penStrokeWidth: 1.8,
      penColor: const Color(0xFF2D2D2D),
    ),
  );

  final GlobalKey _globalKey = GlobalKey();

  int _currentIndex = 0;
  bool _isProcessing = false;
  bool _isFinished = false;

  late Timer _timer;
  int _timeRemaining = 20 * 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showGuideDialog());
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _timer.cancel();
        _forceFinishTest();
      }
    });
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: Colors.blue),
            const SizedBox(width: 10),
            Text('wartegg.guide_title'.tr()),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('wartegg.guide_1'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('wartegg.guide_2'.tr()),
              const SizedBox(height: 8),
              Text('wartegg.guide_3'.tr()),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
            child: Text('wartegg.btn_understand'.tr()),
          )
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _forceFinishTest() {
    setState(() => _isFinished = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('wartegg.msg_timeout'.tr()), backgroundColor: Colors.red),
    );
  }

  void _nextImage() {
    if (_currentIndex < 7) {
      setState(() => _currentIndex++);
    } else {
      bool anyEmpty = _controllers.any((controller) => controller.isEmpty);
      if (anyEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('wartegg.msg_incomplete'.tr()), backgroundColor: Colors.orange),
        );
        return;
      }
      _timer.cancel();
      setState(() => _isFinished = true);
    }
  }

  void _prevImage() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  Future<void> _mergeAndProcessImages() async {
    setState(() => _isProcessing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List finalMergedImage = byteData!.buffer.asUint8List();

      await _analyzeWithGemini(finalMergedImage);
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('wartegg.msg_process_fail'.tr(args: [e.toString()]))));
    }
  }

  Future<void> _analyzeWithGemini(Uint8List imageBytes) async {
    try {
      final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash";
      final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

      final String promptText = 'wartegg.prompt_ai'.tr();

      final String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appSecret',
        },
        body: jsonEncode({
          "contents": [{
            "parts": [
              {"text": promptText},
              {
                "inlineData": {
                  "mimeType": "image/png",
                  "data": base64Image
                }
              }
            ]
          }]
        }),
      );

      setState(() => _isProcessing = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiAnalysis = data['candidates'][0]['content']['parts'][0]['text'];
        _showAIResultDialog(imageBytes, aiAnalysis);
      } else {
        print("ERROR DARI API WARTEGG: ${response.statusCode} - ${response.body}");
        throw Exception('wartegg.error_proxy'.tr(args: [response.statusCode.toString()]));
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('wartegg.error_ai'.tr(args: [e.toString()]))));
    }
  }

  void _showAIResultDialog(Uint8List mergedImage, String aiAnalysis) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Colors.purple, size: 28),
            const SizedBox(width: 10),
            Text('wartegg.ai_result_title'.tr()),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  child: Image.memory(mergedImage, fit: BoxFit.contain),
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 10),
                MarkdownBody(
                  data: aiAnalysis,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                    strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    listBullet: const TextStyle(color: Colors.purple, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // PENTING: Nama tes tetap statis agar aman di Database
              await DatabaseHelper.instance.insertTestResult({
                'test_name': 'Tes Wartegg (AI)',
                'score': 100,
                'total_questions': 8,
                'ai_analysis': aiAnalysis,
                'is_synced': 0,
              });

              AuthService().syncDataNow();

              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
            child: Text('wartegg.btn_save'.tr()),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return Scaffold(
        appBar: AppBar(title: Text('wartegg.appbar_processing'.tr()), automaticallyImplyLeading: false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  width: 350,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
                        child: IgnorePointer(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 300,
                              height: 300,
                              child: Stack(
                                children: [
                                  SizedBox.expand(child: CustomPaint(painter: WarteggStimulusPainter(index))),
                                  Signature(controller: _controllers[index], width: 300, height: 300, backgroundColor: Colors.transparent),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _isProcessing
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                onPressed: _mergeAndProcessImages,
                icon: const Icon(Icons.psychology),
                label: Text('wartegg.btn_analyze'.tr()),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('wartegg.appbar_box'.tr(args: [(_currentIndex + 1).toString()])),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _timeRemaining < 300 ? Colors.red : Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(_formatTime(_timeRemaining), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Text(
              'wartegg.hint_${_currentIndex + 1}'.tr(), // Memanggil hint dinamis per nomor
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 3),
                color: Colors.white,
              ),
              width: 300,
              height: 300,
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: CustomPaint(painter: WarteggStimulusPainter(_currentIndex)),
                  ),
                  Signature(
                    controller: _controllers[_currentIndex],
                    width: 300,
                    height: 300,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _controllers[_currentIndex].undo(),
                icon: const Icon(Icons.undo),
                label: Text('wartegg.btn_undo'.tr()),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade700),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _controllers[_currentIndex].clear(),
                icon: const Icon(Icons.delete_sweep),
                label: Text('wartegg.btn_clear'.tr()),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentIndex == 0 ? null : _prevImage,
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  label: Text('wartegg.btn_prev'.tr()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87),
                ),
                ElevatedButton(
                  onPressed: _nextImage,
                  style: ElevatedButton.styleFrom(backgroundColor: _currentIndex == 7 ? Colors.green : const Color(0xFF0D47A1), foregroundColor: Colors.white),
                  child: Row(
                    children: [
                      Text(_currentIndex == 7 ? 'wartegg.btn_finish'.tr() : 'wartegg.btn_next'.tr()),
                      const SizedBox(width: 5),
                      if (_currentIndex < 7) const Icon(Icons.arrow_forward_ios, size: 16),
                      if (_currentIndex == 7) const Icon(Icons.check_circle, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class WarteggStimulusPainter extends CustomPainter {
  final int boxIndex;
  WarteggStimulusPainter(this.boxIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double w = size.width;
    double h = size.height;

    switch (boxIndex) {
      case 0: paint.style = PaintingStyle.fill; canvas.drawCircle(Offset(w / 2, h / 2), 2.5, paint); break;
      case 1: final path = Path(); path.moveTo(w * 0.2, h * 0.2); path.quadraticBezierTo(w * 0.3, h * 0.15, w * 0.4, h * 0.25); canvas.drawPath(path, paint); break;
      case 2: canvas.drawLine(Offset(w * 0.2, h * 0.8), Offset(w * 0.2, h * 0.6), paint); canvas.drawLine(Offset(w * 0.3, h * 0.8), Offset(w * 0.3, h * 0.5), paint); canvas.drawLine(Offset(w * 0.4, h * 0.8), Offset(w * 0.4, h * 0.4), paint); break;
      case 3: paint.style = PaintingStyle.fill; canvas.drawRect(Rect.fromLTWH(w * 0.7, h * 0.2, w * 0.1, h * 0.1), paint); break;
      case 4: canvas.drawLine(Offset(w * 0.2, h * 0.8), Offset(w * 0.4, h * 0.6), paint); canvas.drawLine(Offset(w * 0.8, h * 0.2), Offset(w * 0.6, h * 0.4), paint); break;
      case 5: canvas.drawLine(Offset(w * 0.5, h * 0.2), Offset(w * 0.5, h * 0.45), paint); canvas.drawLine(Offset(w * 0.6, h * 0.55), Offset(w * 0.9, h * 0.55), paint); break;
      case 6: paint.style = PaintingStyle.fill; for (double i = 0; i < 5; i++) { double x = w * 0.6 + (i * 15); double y = h * 0.8 - (i * i * 3); canvas.drawCircle(Offset(x, y), 2, paint); } break;
      case 7: final path = Path(); path.moveTo(w * 0.2, h * 0.3); path.quadraticBezierTo(w * 0.5, h * 0.1, w * 0.8, h * 0.3); canvas.drawPath(path, paint); break;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}