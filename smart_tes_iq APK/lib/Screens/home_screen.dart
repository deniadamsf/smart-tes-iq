import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../helpers/database_helper.dart';
import '../services/auth_service.dart';
import 'daily_challenge_screen.dart';
import 'leaderboard_screen.dart';
import '../helpers/test_label_helper.dart'; // BARU: Untuk menerjemahkan judul tes di layar
import 'test_screen.dart';
import 'verbal_test_screen.dart';
import 'deret_angka_test_screen.dart';
import 'penalaran_logis_test_screen.dart';
import 'spasial_test_screen.dart';
import 'klasifikasi_test_screen.dart';
import 'vak_test_screen.dart';
import 'riasec_test_screen.dart';
import 'mbti_test_screen.dart';
import 'final_result_screen.dart';
import 'wartegg_screen.dart';
import 'eq_test_screen.dart';
import 'sq_test_screen.dart';
import 'pro_iq_dashboard_screen.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _completedTestsCount = 0;
  List<String> _completedTests = [];

  // Variabel Kredit Premium
  int _warteggCredits = 0;
  int _eqSqCredits = 0;

  // --- VARIABEL BARU UNTUK TOGGLE DIAGRAM PRO ---
  bool _hasCompletedPro = false;
  bool _showProChart = false;

  final Map<String, double> _categoryScores = {
    'Verbal': 0.0, 'Angka': 0.0, 'Logika': 0.0, 'Spasial': 0.0, 'Klasifikasi': 0.0,
  };

  final Map<String, double> _proCategoryScores = {
    'Verbal': 0.0, 'Angka': 0.0, 'Logika': 0.0, 'Spasial': 0.0, 'Klasifikasi': 0.0,
  };

  bool _isOnline = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // === VARIABEL IAP ===
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _iapSubscription;
  List<ProductDetails> _products = [];

  final String _warteggProductId = 'wartegg_premium_01';
  final String _eqSqProductId = 'premium_credits_eq_sq_5';
  bool _isStoreAvailable = false;
  // =====================================

  // MENU TES GRATIS
  // PENTING: "judul" harus tetap string Indonesia untuk mencocokkan di database
  // "soal" diubah menjadi angka saja agar bisa ditranslasikan dengan .tr()
  final List<Map<String, dynamic>> menuTes = const [
    {"judul": "Analogi Verbal", "ikon": Icons.sort_by_alpha, "soal": "30", "id_tes": "verbal"},
    {"judul": "Deret Angka", "ikon": Icons.format_list_numbered, "soal": "20", "id_tes": "deret"},
    {"judul": "Penalaran Logis", "ikon": Icons.psychology, "soal": "25", "id_tes": "logika"},
    {"judul": "Spasial (Gambar)", "ikon": Icons.dashboard_customize, "soal": "15", "id_tes": "spasial"},
    {"judul": "Klasifikasi Gambar", "ikon": Icons.category, "soal": "15", "id_tes": "klasifikasi"},
    {"judul": "Gaya Belajar (VAK)", "ikon": Icons.menu_book, "soal": "30", "id_tes": "vak"},
    {"judul": "Bakat Minat (RIASEC)", "ikon": Icons.work, "soal": "50", "id_tes": "riasec"},
    {"judul": "Tes 16 Kepribadian (MBTI)", "ikon": Icons.groups, "soal": "40", "id_tes": "mbti"},
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _checkInitialConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (mounted) setState(() => _isOnline = result != ConnectivityResult.none);
    });
    AuthService.refreshTrigger.addListener(_onRefreshTriggered);

    // INIT IAP
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _iapSubscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _iapSubscription.cancel();
    }, onError: (error) {
      print("Error IAP: $error");
    });
    _loadProducts();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    AuthService.refreshTrigger.removeListener(_onRefreshTriggered);
    _iapSubscription.cancel();
    super.dispose();
  }

  void _onRefreshTriggered() {
    if (mounted) _loadProgress();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _isOnline = result != ConnectivityResult.none);
  }

  Future<void> _loadProgress() async {
    final results = await DatabaseHelper.instance.getAllTestResults();

    Set<String> completedNames = {};
    Map<String, Map<String, dynamic>> latestData = {};
    bool foundPro = false;

    for (var test in results) {
      String name = test['test_name'];

      if (name == 'Tes Wartegg (AI)' || name == 'Tes EQ (AI)' || name == 'Tes SQ (AI)') continue;

      if (name == 'Tes IQ Komprehensif (PRO)') {
        foundPro = true;
        continue;
      }

      completedNames.add(name);

      int currentId = test['id'] ?? 0;
      int score = test['score'] ?? 0;
      int total = test['total_questions'] ?? 1;
      double percentage = total > 0 ? score / total : 0.0;

      if (!latestData.containsKey(name) || currentId > (latestData[name]!['id'] as int)) {
        latestData[name] = {
          'id': currentId,
          'percentage': percentage,
        };
      }
    }

    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        _warteggCredits = prefs.getInt('wartegg_credits') ?? 0;
        _eqSqCredits = prefs.getInt('eq_sq_credits') ?? 0;

        _completedTests = completedNames.toList();
        _completedTestsCount = menuTes.where((m) => completedNames.contains(m['judul'])).length;

        _hasCompletedPro = foundPro;
        if (_hasCompletedPro) _showProChart = true;

        _categoryScores['Verbal'] = latestData['Analogi Verbal']?['percentage'] ?? 0.0;
        _categoryScores['Angka'] = latestData['Deret Angka']?['percentage'] ?? 0.0;
        _categoryScores['Logika'] = latestData['Penalaran Logis']?['percentage'] ?? 0.0;
        _categoryScores['Spasial'] = latestData['Spasial (Gambar)']?['percentage'] ?? 0.0;
        _categoryScores['Klasifikasi'] = latestData['Klasifikasi Gambar']?['percentage'] ?? 0.0;

        _proCategoryScores['Verbal'] = latestData['Analogi Verbal (PRO)']?['percentage'] ?? 0.0;
        _proCategoryScores['Angka'] = latestData['Deret Angka (PRO)']?['percentage'] ?? 0.0;
        _proCategoryScores['Logika'] = latestData['Penalaran Logis (PRO)']?['percentage'] ?? 0.0;
        _proCategoryScores['Spasial'] = latestData['Spasial (Gambar) (PRO)']?['percentage'] ?? 0.0;
        _proCategoryScores['Klasifikasi'] = latestData['Klasifikasi Gambar (PRO)']?['percentage'] ?? 0.0;
      });
    }
  }

  Widget _buildBar(String label, double percentage, Color color, bool isCompleted) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
            isCompleted ? '${(percentage * 100).toInt()}%' : '?',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? color : Colors.grey.shade500)
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 1000), curve: Curves.easeOutQuart, width: 22, height: isCompleted ? (percentage * 80) : 12,
          decoration: BoxDecoration(color: isCompleted ? color : Colors.grey.shade300, borderRadius: BorderRadius.circular(6)),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
      ],
    );
  }

  Future<void> _loadProducts() async {
    _isStoreAvailable = await _iap.isAvailable();
    if (!_isStoreAvailable) return;

    ProductDetailsResponse response = await _iap.queryProductDetails({_warteggProductId, _eqSqProductId});
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
      } else if (purchaseDetails.status == PurchaseStatus.purchased || purchaseDetails.status == PurchaseStatus.restored) {

        final prefs = await SharedPreferences.getInstance();
        if (purchaseDetails.productID == _warteggProductId) {
          setState(() => _warteggCredits += 5);
          await prefs.setInt('wartegg_credits', _warteggCredits);
        } else if (purchaseDetails.productID == _eqSqProductId) {
          setState(() => _eqSqCredits += 5);
          await prefs.setInt('eq_sq_credits', _eqSqCredits);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('home.msg_payment_success'.tr()), backgroundColor: Colors.green)
          );
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _handleEqSqTap() {
    if (_eqSqCredits > 0) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('home.sheet_select_test_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('home.sheet_select_test_desc'.tr(args: [_eqSqCredits.toString()]), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 20),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.pink.shade100, child: const Icon(Icons.favorite, color: Colors.pink)),
                title: Text('home.test_eq'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _consumeEqSqCreditAndGo("eq"),
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.purple.shade100, child: const Icon(Icons.self_improvement, color: Colors.purple)),
                title: Text('home.test_sq'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _consumeEqSqCreditAndGo("sq"),
              ),
            ],
          ),
        ),
      );
    } else {
      _showEqSqPurchaseSheet();
    }
  }

  Future<void> _consumeEqSqCreditAndGo(String testType) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _eqSqCredits -= 1);
    await prefs.setInt('eq_sq_credits', _eqSqCredits);

    if (!mounted) return;
    Navigator.pop(context);

    if (testType == "eq") {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const EqTestScreen())).then((_) => _loadProgress());
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SqTestScreen())).then((_) => _loadProgress());
    }
  }

  void _showEqSqPurchaseSheet() {
    ProductDetails? prod = _getProduct(_eqSqProductId);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 45, color: Colors.pink),
                  SizedBox(width: 15),
                  Icon(Icons.self_improvement, size: 45, color: Colors.purple),
                ]
            ),
            const SizedBox(height: 10),
            Text('home.sheet_eqsq_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('home.sheet_eqsq_desc'.tr(), textAlign: TextAlign.center),
            const SizedBox(height: 20),
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
                        SnackBar(content: Text('home.msg_store_loading'.tr()), backgroundColor: Colors.orange)
                    );
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF00796B), foregroundColor: Colors.white),
                child: Text(
                    prod != null ? 'home.btn_buy_credits'.tr(args: [prod.price]) : 'home.btn_buy_credits_fallback'.tr(args: ['3.000']),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> requiredCognitive = [
      'Analogi Verbal', 'Deret Angka', 'Penalaran Logis',
      'Spasial (Gambar)', 'Klasifikasi Gambar'
    ];

    bool isCognitiveFinished = requiredCognitive.every((tes) => _completedTests.contains(tes)) || _hasCompletedPro;
    List<String> unfinishedCognitive = requiredCognitive.where((tes) => !_completedTests.contains(tes)).toList();

    double progressValue = _completedTestsCount / menuTes.length;
    final langCode = context.locale.languageCode;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 30,
                  left: 24,
                  right: 24
              ),
              decoration: const BoxDecoration(color: Color(0xFF0D47A1), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('home.welcome'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _isOnline ? Colors.white.withOpacity(0.2) : Colors.redAccent.withOpacity(0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: _isOnline ? Colors.transparent : Colors.red, width: 1)),
                        child: Row(
                          children: [
                            Icon(_isOnline ? Icons.wifi : Icons.wifi_off, color: _isOnline ? Colors.greenAccent : Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(_isOnline ? 'home.online'.tr() : 'home.offline'.tr(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('home.app_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Text('home.progress'.tr(args: [_completedTestsCount.toString(), menuTes.length.toString()]), style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progressValue, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent), minHeight: 8, borderRadius: BorderRadius.circular(10)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))],
                    border: Border.all(color: isCognitiveFinished ? Colors.orange.shade300 : Colors.transparent, width: 2)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER DIAGRAM DENGAN TOGGLE PRO ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(isCognitiveFinished ? Icons.analytics : Icons.lock, color: isCognitiveFinished ? Colors.orange : Colors.grey, size: 24),
                            const SizedBox(width: 8),
                            Text('home.analysis_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                          ],
                        ),

                        if (_hasCompletedPro)
                          Container(
                            height: 28,
                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(15)),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _showProChart = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: !_showProChart ? Colors.orange : Colors.transparent, borderRadius: BorderRadius.circular(15)),
                                    child: Text('home.tab_regular'.tr(), style: TextStyle(fontSize: 11, color: !_showProChart ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _showProChart = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _showProChart ? const Color(0xFF0D47A1) : Colors.transparent, borderRadius: BorderRadius.circular(15)),
                                    child: Text('home.tab_pro'.tr(), style: TextStyle(fontSize: 11, color: _showProChart ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          )
                      ],
                    ),
                    const SizedBox(height: 25),

                    // --- DIAGRAM DATA DINAMIS ---
                    SizedBox(
                      height: 120,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBar('home.chart_vrb'.tr(), _showProChart ? _proCategoryScores['Verbal']! : _categoryScores['Verbal']!, Colors.blue, _showProChart ? _hasCompletedPro : _completedTests.contains('Analogi Verbal')),
                          _buildBar('home.chart_drt'.tr(), _showProChart ? _proCategoryScores['Angka']! : _categoryScores['Angka']!, Colors.green, _showProChart ? _hasCompletedPro : _completedTests.contains('Deret Angka')),
                          _buildBar('home.chart_log'.tr(), _showProChart ? _proCategoryScores['Logika']! : _categoryScores['Logika']!, Colors.purple, _showProChart ? _hasCompletedPro : _completedTests.contains('Penalaran Logis')),
                          _buildBar('home.chart_sps'.tr(), _showProChart ? _proCategoryScores['Spasial']! : _categoryScores['Spasial']!, Colors.orange, _showProChart ? _hasCompletedPro : _completedTests.contains('Spasial (Gambar)')),
                          _buildBar('home.chart_kls'.tr(), _showProChart ? _proCategoryScores['Klasifikasi']! : _categoryScores['Klasifikasi']!, Colors.red, _showProChart ? _hasCompletedPro : _completedTests.contains('Klasifikasi Gambar')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    isCognitiveFinished
                        ? Column(
                      children: [
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FinalResultScreen())),
                            icon: const Icon(Icons.auto_awesome, color: Colors.white),
                            label: Text('home.btn_open_result'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade100)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text('home.info_complete_vak'.tr(), style: TextStyle(fontSize: 12, color: Colors.blue.shade900, height: 1.4))),
                            ],
                          ),
                        )
                      ],
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('home.req_open_iq'.tr(args: [unfinishedCognitive.length.toString()]), style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: unfinishedCognitive.map((tes) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), border: Border.all(color: Colors.red.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(getLocalizedTestLabel(tes, langCode), style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // =====================================
            // 0. BANNER TANTANGAN IQ HARIAN
            // =====================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEF6C00), Color(0xFFF9A825)]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.emoji_events, color: Colors.white, size: 36),
                    title: Text('daily.appbar_title'.tr(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('daily.banner_desc'.tr(),
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyChallengeScreen())).then((_) => _loadProgress());
                    },
                  ),
                ),
              ),
            ),

            // =====================================
            // 0b. BANNER PAPAN PERINGKAT
            // =====================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: const Icon(Icons.leaderboard, color: Color(0xFFEF6C00), size: 32),
                  title: Text('leaderboard.appbar_title'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text('leaderboard.banner_desc'.tr(),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
                  },
                ),
              ),
            ),

            // =====================================
            // 1. BANNER IQ KOMPREHENSIF PRO
            // =====================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const Icon(Icons.workspace_premium, color: Colors.white, size: 36),
                    title: Row(
                      children: [
                        // PERBAIKAN: Bungkus Text dengan Flexible
                        Flexible(
                          child: Text('home.banner_pro_title'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)), child: const Text('PRO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)))
                      ],
                    ),
                    subtitle: Text('home.banner_pro_desc'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProIqDashboardScreen())).then((_) => _loadProgress());
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0D47A1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(60, 35)
                      ),
                      child: Text('home.btn_open_dashboard'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // =====================================
            // JUDUL PEMISAH TES PSIKOLOGI PREMIUM
            // =====================================
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
                child: Text('home.premium_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)))
            ),

            // =====================================
            // 2. BANNER PREMIUM WARTEGG
            // =====================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: Container(
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      if (_warteggCredits > 0) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('home.dialog_use_credit_title'.tr()),
                            content: Text('home.dialog_use_credit_desc'.tr(args: [_warteggCredits.toString(), 'Smart AI Wartegg'])),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text('home.btn_cancel'.tr())),
                              ElevatedButton(
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  setState(() => _warteggCredits -= 1);
                                  await prefs.setInt('wartegg_credits', _warteggCredits);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const WarteggScreen())).then((_) => _loadProgress());
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                child: Text('home.btn_start_test'.tr()),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ProductDetails? wProd = _getProduct(_warteggProductId);
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.psychology, size: 60, color: Colors.purple), const SizedBox(height: 10),
                                Text('home.sheet_wartegg_title'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
                                Text('home.sheet_wartegg_desc'.tr(), textAlign: TextAlign.center), const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      if (wProd != null) {
                                        final PurchaseParam purchaseParam = PurchaseParam(productDetails: wProd);
                                        _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('home.msg_store_loading'.tr()), backgroundColor: Colors.purple)
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                    child: Text(
                                        wProd != null ? 'home.btn_buy_credits'.tr(args: [wProd.price]) : 'home.btn_buy_credits_fallback'.tr(args: ['7.000']),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.psychology_alt, color: Colors.amber, size: 28)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('home.banner_wartegg_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4), Text('home.banner_wartegg_desc'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // =====================================
            // 3. BANNER PREMIUM EQ & SQ
            // =====================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              child: Container(
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00897B)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: _handleEqSqTap,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.self_improvement, color: Colors.amber, size: 28)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('home.banner_eqsq_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4), Text('home.banner_eqsq_desc'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Padding(
                padding: const EdgeInsets.only(left: 20.0, top: 10.0, bottom: 8.0),
                child: Text('home.regular_test_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)))
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuTes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1
                ),
                itemBuilder: (context, index) {
                  bool isDone = _completedTests.any((namaTes) =>
                  namaTes.trim().toLowerCase() == menuTes[index]["judul"].toString().trim().toLowerCase()
                  );
                  // Menerjemahkan Judul Tes Dinamis
                  final displayJudul = getLocalizedTestLabel(menuTes[index]["judul"], langCode);

                  return Card(
                    elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDone ? Colors.green.shade300 : Colors.transparent, width: 2)), color: Colors.white,
                    child: InkWell(
                      onTap: () => _navigateToTest(menuTes[index]["id_tes"], menuTes[index]["judul"]).then((_) => _loadProgress()),
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(radius: 25, backgroundColor: isDone ? Colors.green.withOpacity(0.1) : const Color(0xFFE3F2FD), child: Icon(menuTes[index]["ikon"], size: 24, color: isDone ? Colors.green : const Color(0xFF1976D2))),
                                const SizedBox(height: 10),
                                Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(displayJudul, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF333333)))),
                                const SizedBox(height: 4), Text('home.questions_count'.tr(args: [menuTes[index]["soal"]]), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          if (isDone) Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.check, size: 12, color: Colors.white))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToTest(String idTes, String judul) async {
    // "judul" yang di-pass ke sini adalah String Asli Indo untuk konsistensi Database
    if (idTes == "verbal") await Navigator.push(context, MaterialPageRoute(builder: (context) => const VerbalTestScreen()));
    else if (idTes == "deret") await Navigator.push(context, MaterialPageRoute(builder: (context) => const DeretAngkaTestScreen()));
    else if (idTes == "logika") await Navigator.push(context, MaterialPageRoute(builder: (context) => const PenalaranLogisTestScreen()));
    else if (idTes == "spasial") await Navigator.push(context, MaterialPageRoute(builder: (context) => const SpasialTestScreen()));
    else if (idTes == "klasifikasi") await Navigator.push(context, MaterialPageRoute(builder: (context) => const KlasifikasiTestScreen()));
    else if (idTes == "vak") await Navigator.push(context, MaterialPageRoute(builder: (context) => const VakTestScreen()));
    else if (idTes == "riasec") await Navigator.push(context, MaterialPageRoute(builder: (context) => const RiasecTestScreen()));
    else if (idTes == "mbti") await Navigator.push(context, MaterialPageRoute(builder: (context) => const MbtiTestScreen()));
    else await Navigator.push(context, MaterialPageRoute(builder: (context) => TestScreen(testName: judul, testId: idTes)));
  }
}