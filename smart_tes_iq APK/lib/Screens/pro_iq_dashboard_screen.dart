import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU
import '../helpers/database_helper.dart';
import '../helpers/credit_store.dart';
import '../services/auth_service.dart';
import '../helpers/test_label_helper.dart'; // BARU

import 'verbal_pro_test_screen.dart';
import 'deret_angka_pro_test_screen.dart';
import 'penalaran_logis_pro_test_screen.dart';
import 'spasial_pro_test_screen.dart';
import 'klasifikasi_gambar_pro_test_screen.dart';

class ProIqDashboardScreen extends StatefulWidget {
  const ProIqDashboardScreen({super.key});

  @override
  State<ProIqDashboardScreen> createState() => _ProIqDashboardScreenState();
}

class _ProIqDashboardScreenState extends State<ProIqDashboardScreen> {
  int _kreditPro = 0;
  bool _isSessionActive = false;
  bool _isLoadingAI = false;
  List<String> _completedSubTests = [];
  List<Map<String, dynamic>> _historyData = [];

  final GlobalKey _shareKey = GlobalKey();
  bool _isSharingImage = false;
  Map<String, dynamic>? _posterData;

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _iapSubscription;
  List<ProductDetails> _products = [];
  final String _iqProProductId = 'iq_pro_10_kredit';
  bool _isStoreAvailable = false;

  // List Statis berbahasa Indonesia untuk Database matching
  final List<String> _subTests = [
    'Analogi Verbal (PRO)',
    'Deret Angka (PRO)',
    'Penalaran Logis (PRO)',
    'Spasial (Gambar) (PRO)',
    'Klasifikasi Gambar (PRO)'
  ];

  @override
  void initState() {
    super.initState();
    _loadSessionData();

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _iapSubscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _iapSubscription.cancel();
    }, onError: (error) {
      debugPrint("Error IAP: $error");
    });

    _loadProducts();
  }

  @override
  void dispose() {
    _iapSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    _isStoreAvailable = await _iap.isAvailable();
    if (!_isStoreAvailable) return;

    ProductDetailsResponse response = await _iap.queryProductDetails({_iqProProductId});
    setState(() {
      _products = response.productDetails;
    });
  }

  ProductDetails? _getProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('iq_pro_dashboard.msg_payment_cancel'.tr())));
      } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == _iqProProductId) {
          final saldo = await CreditStore.beri(CreditStore.kIqPro, 10);
          if (mounted) setState(() => _kreditPro = saldo);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('iq_pro_dashboard.msg_payment_success'.tr()), backgroundColor: Colors.green)
          );
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _showPurchaseSheet() {
    ProductDetails? prod = _getProduct(_iqProProductId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.diamond, size: 45, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 15),

            Text('iq_pro_dashboard.sheet_title'.tr(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF333333))),
            const SizedBox(height: 8),
            Text(
                'iq_pro_dashboard.sheet_desc'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5)
            ),
            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0D47A1), width: 2),
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.blue.shade50
              ),
              child: Column(
                children: [
                  Text('iq_pro_dashboard.sheet_chances'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 5),
                  Text(
                      prod != null ? prod.price : 'Rp 10.000',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (prod != null) {
                    final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);
                    _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('iq_pro_dashboard.msg_store_loading'.tr()), backgroundColor: Colors.orange)
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF0D47A1),
                    elevation: 4,
                    shadowColor: Colors.blue.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                child: Text('iq_pro_dashboard.btn_buy_now'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> historyStrings = prefs.getStringList('iq_pro_history') ?? [];
    List<Map<String, dynamic>> parsedHistory = historyStrings
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    setState(() {
      _kreditPro = prefs.getInt('kredit_iq_pro') ?? 0;
      _isSessionActive = prefs.getBool('is_pro_session_active') ?? false;
      _completedSubTests = prefs.getStringList('pro_completed_tests') ?? [];
      _historyData = parsedHistory;
    });
  }

  Future<void> _startSession() async {
    if (_kreditPro <= 0) {
      _showPurchaseSheet();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final int sisaKredit = await CreditStore.pakai(CreditStore.kIqPro, 1);
    await prefs.setBool('is_pro_session_active', true);
    await prefs.setStringList('pro_completed_tests', []);

    setState(() {
      _kreditPro = sisaKredit;
      _isSessionActive = true;
      _completedSubTests = [];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('iq_pro_dashboard.msg_session_started'.tr()), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _finishAndSeeResults() async {
    if (_completedSubTests.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('iq_pro_dashboard.msg_complete_tests'.tr()), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoadingAI = true);

    try {
      final dbResults = await DatabaseHelper.instance.getAllTestResults();
      int totalScore = 0;
      int totalQuestions = 0;
      String breakdownText = "";

      for (String testName in _subTests) {
        var testData = dbResults.where((t) => t['test_name'] == testName).toList();
        if (testData.isNotEmpty) {
          int score = testData.last['score'] as int;
          int questions = testData.last['total_questions'] as int;
          totalScore += score;
          totalQuestions += questions;
          // Localized nama tes untuk Prompt AI
          String localizedTestName = getLocalizedTestLabel(testName, context.locale.languageCode);
          breakdownText += "- $localizedTestName: $score / $questions\n";
        }
      }

      int estimatedIQ = 0;
      if (totalQuestions > 0) {
        double chanceCorrect = totalQuestions * 0.2;
        if (totalScore <= chanceCorrect) {
          estimatedIQ = 70 + ((totalScore / chanceCorrect) * 5).round();
        } else {
          double realPerformance = (totalScore - chanceCorrect) / (totalQuestions - chanceCorrect);
          estimatedIQ = 75 + (realPerformance * 70).round();
        }
      }

      final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash";
      final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

      final String prompt = 'iq_pro_dashboard.prompt_ai'.tr(args: [
        estimatedIQ.toString(),
        totalScore.toString(),
        totalQuestions.toString(),
        breakdownText,
        estimatedIQ.toString()
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

        Map<String, dynamic> historyEntry = {
          'date': DateTime.now().toIso8601String(),
          'score': totalScore,
          'total_q': totalQuestions,
          'iq': estimatedIQ,
          'analysis': aiText
        };

        final prefs = await SharedPreferences.getInstance();
        List<String> historyStrings = prefs.getStringList('iq_pro_history') ?? [];
        historyStrings.insert(0, jsonEncode(historyEntry));
        await prefs.setStringList('iq_pro_history', historyStrings);

        int currentUserId = prefs.getInt('user_id') ?? 0;

        await DatabaseHelper.instance.insertTestResult({
          'user_id': currentUserId,
          'test_name': 'Tes IQ Komprehensif (PRO)', // TETAP INDONESIA UNTUK DB
          'score': estimatedIQ,
          'total_questions': totalQuestions,
          'ai_analysis': aiText,
          'is_synced': 0,
        });

        AuthService().syncDataNow();

        await prefs.setBool('is_pro_session_active', false);
        await prefs.setStringList('pro_completed_tests', []);

        setState(() {
          _isSessionActive = false;
          _completedSubTests = [];
          _isLoadingAI = false;
          _historyData.insert(0, historyEntry);
        });

        _showResultModal(historyEntry);

      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoadingAI = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('iq_pro_dashboard.error_ai'.tr(args: [e.toString()]))));
    }
  }

  String _getIQCategory(int iq) {
    if (iq >= 130) return 'iq_pro_dashboard.iq_genius'.tr();
    if (iq >= 120) return 'iq_pro_dashboard.iq_superior'.tr();
    if (iq >= 110) return 'iq_pro_dashboard.iq_above_avg'.tr();
    if (iq >= 90) return 'iq_pro_dashboard.iq_avg'.tr();
    return 'iq_pro_dashboard.iq_below_avg'.tr();
  }

  Future<void> _sharePosterAsImage(Map<String, dynamic> data) async {
    setState(() {
      _posterData = data;
      _isSharingImage = true;
    });

    await Future.delayed(const Duration(milliseconds: 150));

    try {
      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/smart_iq_pro_poster.png').create();
      await imagePath.writeAsBytes(pngBytes);

      String category = _getIQCategory(data['iq']);
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'iq_pro_dashboard.share_poster_text'.tr(args: [data['iq'].toString(), category]),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('iq_pro_dashboard.msg_share_fail'.tr(args: [e.toString()]))));
    }

    setState(() => _isSharingImage = false);
  }

  void _shareAnalysisText(Map<String, dynamic> data) {
    String category = _getIQCategory(data['iq']);
    String textToShare = 'iq_pro_dashboard.share_text_title'.tr(args: [
      data['iq'].toString(), category, data['score'].toString(), data['total_q'].toString(), data['analysis']
    ]);
    Share.share(textToShare);
  }

  void _showResultModal(Map<String, dynamic> resultData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Icon(Icons.workspace_premium, color: Colors.orange, size: 50),
                  const SizedBox(height: 10),
                  Text('iq_pro_dashboard.modal_title'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox('iq_pro_dashboard.stat_correct'.tr(), '${resultData['score']}/${resultData['total_q']}', Colors.blue),
                      _buildStatBox('iq_pro_dashboard.stat_iq'.tr(), '${resultData['iq']}', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSharingImage ? null : () async {
                            setModalState(() => _isSharingImage = true);
                            await _sharePosterAsImage(resultData);
                            setModalState(() => _isSharingImage = false);
                          },
                          icon: _isSharingImage
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.image, size: 18),
                          label: Text('iq_pro_dashboard.btn_poster'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0D47A1), side: const BorderSide(color: Color(0xFF0D47A1)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareAnalysisText(resultData),
                          icon: const Icon(Icons.share, size: 18),
                          label: Text('iq_pro_dashboard.btn_text_analysis'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Divider(),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('iq_pro_dashboard.report_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          data: resultData['analysis'],
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                            strong: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                            listBullet: const TextStyle(color: Colors.orange, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('iq_pro_dashboard.btn_close'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
                    ),
                  )
                ],
              ),
            );
          }
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    DateTime dt = DateTime.parse(isoDate);
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('iq_pro_dashboard.appbar_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: _showPurchaseSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 6),
                      Text('$_kreditPro ${'iq_pro_dashboard.credits'.tr()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                      const SizedBox(width: 6),
                      const Icon(Icons.add_circle, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [

          // --- KANVAS POSTER RAHASIA (RASIO 9:16) ---
          Positioned(
            left: -5000,
            top: -5000,
            child: RepaintBoundary(
              key: _shareKey,
              child: Container(
                width: 540,
                height: 960,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: _posterData == null
                    ? const SizedBox()
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology, size: 100, color: Colors.amber),
                    const SizedBox(height: 20),
                    Text('iq_pro_dashboard.poster_app_name'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 40),
                    Text('iq_pro_dashboard.poster_cert_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
                    const SizedBox(height: 30),

                    Container(
                      width: 400,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]),
                      child: Column(
                        children: [
                          Text('iq_pro_dashboard.poster_iq_score'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 10),
                          Text('${_posterData!['iq']}', style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 110, fontWeight: FontWeight.w900, height: 1.1)),
                          Container(margin: const EdgeInsets.symmetric(vertical: 15), width: 250, height: 4, color: Colors.orange),
                          Text(_getIQCategory(_posterData!['iq']).toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 26, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          Text('iq_pro_dashboard.poster_accuracy'.tr(args: [_posterData!['score'].toString(), _posterData!['total_q'].toString()]), style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    Text('iq_pro_dashboard.poster_footer_1'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 10),
                    Text('iq_pro_dashboard.poster_footer_2'.tr(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // --- LAYAR UTAMA DASBOR ---
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 5),
                              Text('iq_pro_dashboard.credit_remain'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('$_kreditPro', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showPurchaseSheet,
                        icon: const Icon(Icons.add, size: 18, color: Colors.white),
                        label: Text('iq_pro_dashboard.btn_topup'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.psychology, size: 55, color: Colors.white),
                      const SizedBox(height: 12),
                      Text('iq_pro_dashboard.card_title'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 1)),
                      const SizedBox(height: 10),
                      Text(
                        _isSessionActive ? 'iq_pro_dashboard.session_active'.tr() : 'iq_pro_dashboard.session_inactive'.tr(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),

                      if (!_isSessionActive)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _startSession,
                            icon: const Icon(Icons.play_circle_fill, color: Color(0xFF0D47A1)),
                            label: Text('iq_pro_dashboard.btn_start_session'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0D47A1),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                Text('iq_pro_dashboard.list_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subTests.length,
                  itemBuilder: (context, index) {
                    // testName ini tetap Indo untuk logika database
                    String testName = _subTests[index];
                    bool isCompleted = _completedSubTests.contains(testName);
                    // Dapatkan nama test versi terjemahan untuk UI
                    String displayTestName = getLocalizedTestLabel(testName, langCode);

                    return Card(
                      elevation: 1, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: _isSessionActive ? (isCompleted ? Colors.green.shade100 : Colors.blue.shade50) : Colors.grey.shade200,
                          child: Icon(isCompleted ? Icons.check : Icons.assignment, color: _isSessionActive ? (isCompleted ? Colors.green : Colors.blue) : Colors.grey),
                        ),
                        title: Text(displayTestName, style: TextStyle(fontWeight: FontWeight.bold, color: _isSessionActive ? Colors.black87 : Colors.grey)),
                        subtitle: Text(isCompleted ? 'iq_pro_dashboard.status_done'.tr() : (_isSessionActive ? 'iq_pro_dashboard.status_pending'.tr() : 'iq_pro_dashboard.status_locked'.tr()), style: TextStyle(fontSize: 12, color: isCompleted ? Colors.green : Colors.grey)),
                        trailing: _isSessionActive
                            ? (isCompleted
                            ? const Icon(Icons.check_circle, color: Colors.green, size: 30)
                            : ElevatedButton(
                          onPressed: () async {
                            if (testName == 'Analogi Verbal (PRO)') {
                              await Navigator.push(context, MaterialPageRoute(builder: (context) => const VerbalProTestScreen()));
                            } else if (testName == 'Deret Angka (PRO)') {
                              await Navigator.push(context, MaterialPageRoute(builder: (context) => const DeretAngkaProTestScreen()));
                            } else if (testName == 'Penalaran Logis (PRO)') {
                              await Navigator.push(context, MaterialPageRoute(builder: (context) => const PenalaranLogisProTestScreen()));
                            } else if (testName == 'Spasial (Gambar) (PRO)') {
                              await Navigator.push(context, MaterialPageRoute(builder: (context) => const SpasialProTestScreen()));
                            } else if (testName == 'Klasifikasi Gambar (PRO)') {
                              await Navigator.push(context, MaterialPageRoute(builder: (context) => const KlasifikasiGambarProTestScreen()));
                            }
                            _loadSessionData();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
                          child: Text('iq_pro_dashboard.btn_start_test'.tr()),
                        ))
                            : const Icon(Icons.lock, color: Colors.grey),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isSessionActive && _completedSubTests.length == 5 && !_isLoadingAI) ? _finishAndSeeResults : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    child: _isLoadingAI
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('iq_pro_dashboard.btn_see_result'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                if (_historyData.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.history, color: Colors.grey),
                      const SizedBox(width: 10),
                      Text('iq_pro_dashboard.history_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _historyData.length,
                    itemBuilder: (context, index) {
                      final item = _historyData[index];
                      return Card(
                        elevation: 1, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.workspace_premium, color: Colors.orange),
                          ),
                          title: Text('iq_pro_dashboard.history_score'.tr(args: [item['iq'].toString()]), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${_formatDate(item['date'])} • Skor: ${item['score']}/${item['total_q']}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => _showResultModal(item),
                        ),
                      );
                    },
                  )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}