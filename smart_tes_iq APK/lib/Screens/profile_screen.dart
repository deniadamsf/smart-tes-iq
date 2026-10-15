import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:easy_localization/easy_localization.dart';
import '../helpers/database_helper.dart';
import '../services/auth_service.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../helpers/test_label_helper.dart';
import '../helpers/game_high_score_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isSharing = false;
  final GlobalKey _shareKey = GlobalKey();

  bool _isLoggedIn = false;
  String _userName = "";
  String _userEmail = "";

  // VARIABEL DIPISAHKAN AGAR TIDAK SALING MENIMPA
  int _iqFreeScore = 0;
  String _iqFreeCategory = "";

  int _iqProHighestScore = 0;
  String _iqProHighestCategory = "";

  List<Map<String, dynamic>> _iqProHistory = [];
  List<Map<String, dynamic>> _warteggHistory = [];
  List<Map<String, dynamic>> _eqHistory = [];
  List<Map<String, dynamic>> _sqHistory = [];

  Map<String, double> _categoryScores = {
    'Verbal': 0.0,
    'Angka': 0.0,
    'Logika': 0.0,
    'Spasial': 0.0,
    'Klasifikasi': 0.0,
  };
  String _kesimpulanSingkat = "";

  List<Map<String, dynamic>> _completedTestsDetail = [];
  Map<String, int> _gameHighScores = {};
  bool _showAllHistory = false;
  String _generatingTestName = "";

  @override
  void initState() {
    super.initState();
    RewardedAdManager.loadAd();
    AuthService.refreshTrigger.addListener(_onExternalChange);
    DatabaseHelper.dataChangedNotifier.addListener(_onExternalChange);
    GameHighScoreHelper.refreshNotifier.addListener(_onExternalChange);
    _initializeApp();
  }

  @override
  void dispose() {
    AuthService.refreshTrigger.removeListener(_onExternalChange);
    DatabaseHelper.dataChangedNotifier.removeListener(_onExternalChange);
    GameHighScoreHelper.refreshNotifier.removeListener(_onExternalChange);
    super.dispose();
  }

  void _onExternalChange() {
    if (mounted) {
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    await _checkLoginStatus();
    await _loadGameHighScores();
    await _loadCertificateData();
  }

  Future<void> _loadGameHighScores() async {
    final scores = await GameHighScoreHelper.getAllHighScores();
    if (mounted) {
      setState(() {
        _gameHighScores = scores;
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (!mounted) return;
    if (token != null) {
      setState(() {
        _isLoggedIn = true;
        _userName =
            prefs.getString('user_name') ?? 'profile.premium_user'.tr();
        _userEmail =
            prefs.getString('user_email') ?? 'profile.synced_account'.tr();
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _userName = 'profile.guest_name'.tr();
        _userEmail = 'profile.guest_email'.tr();
      });
    }
  }

  Future<void> _handleLogin() async {
    setState(() => _isSyncing = true);
    final success = await AuthService().loginAndSync();
    if (success) {
      await _checkLoginStatus();
      AuthService.refreshTrigger.value++;
      await _loadGameHighScores();
      await _loadCertificateData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.msg_login_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.msg_login_fail'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);
    await AuthService().syncDataNow();
    final success = await AuthService().restoreDataFromServer();
    AuthService.refreshTrigger.value++;
    await _loadGameHighScores();
    await _loadCertificateData();

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'profile.msg_sync_success'.tr()
                : 'profile.msg_sync_fail'.tr(),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    await AuthService().logout();
    await _checkLoginStatus();
    AuthService.refreshTrigger.value++;
    await _loadGameHighScores();
    await _loadCertificateData();
  }

  Future<void> _loadCertificateData() async {
    final results = await DatabaseHelper.instance.getAllTestResults();

    Map<String, Map<String, dynamic>> highestScores = {};
    final List<Map<String, dynamic>> iqProList = [];
    final List<Map<String, dynamic>> warteggList = [];
    final List<Map<String, dynamic>> eqList = [];
    final List<Map<String, dynamic>> sqList = [];

    for (var test in results) {
      String name = test['test_name'];
      String rawAnalysis = test['ai_analysis'] ?? "";
      bool hasValidAnalysis =
          rawAnalysis.isNotEmpty && !rawAnalysis.contains('Menunggu');

      if (name == 'Tes IQ Komprehensif (PRO)') {
        iqProList.add(test);
        continue;
      }
      if (name == 'Tes Wartegg (AI)') {
        if (hasValidAnalysis) warteggList.add(test);
        continue;
      }
      if (name == 'Tes EQ (AI)') {
        if (hasValidAnalysis) eqList.add(test);
        continue;
      }
      if (name == 'Tes SQ (AI)') {
        if (hasValidAnalysis) sqList.add(test);
        continue;
      }

      int currentId = test['id'] ?? 0;
      int score = test['score'] ?? 0;
      int total = test['total_questions'] ?? 1;
      double percentage = total > 0 ? score / total : 0.0;

      String dominantCode = "";
      if (name.contains('VAK') ||
          name.contains('RIASEC') ||
          name.contains('MBTI') ||
          name.contains('Kepribadian')) {
        RegExp regExp = RegExp(r'\[KODE:\s*(.*?)\]');
        var match = regExp.firstMatch(rawAnalysis);
        if (match != null) dominantCode = match.group(1)!;
      }

      bool isNewBest = false;

      if (!highestScores.containsKey(name)) {
        isNewBest = true;
      } else {
        bool isPersonality = name.contains('VAK') ||
            name.contains('RIASEC') ||
            name.contains('MBTI') ||
            name.contains('Kepribadian');

        if (isPersonality) {
          if (currentId > (highestScores[name]!['id'] as int)) {
            isNewBest = true;
          }
        } else {
          if (percentage > highestScores[name]!['percentage']) {
            isNewBest = true;
          } else if (percentage == highestScores[name]!['percentage'] &&
              currentId > (highestScores[name]!['id'] as int)) {
            isNewBest = true;
          }
        }
      }

      if (isNewBest) {
        highestScores[name] = {
          'id': currentId,
          'name': name,
          'score': score,
          'total': total,
          'percentage': percentage,
          'analysis':
              rawAnalysis.isEmpty ? 'profile.waiting_ai'.tr() : rawAnalysis,
          'code': dominantCode,
        };
      }
    }

    int totalCognitiveCorrect = 0, totalCognitiveQuestions = 0;
    final List<Map<String, dynamic>> completedDetail = [];

    final Map<String, double> catScores = {
      'Verbal': 0.0,
      'Angka': 0.0,
      'Logika': 0.0,
      'Spasial': 0.0,
      'Klasifikasi': 0.0,
    };
    String summaryText = 'profile.default_summary'.tr();

    highestScores.forEach((key, data) {
      bool isCognitiveSubtest = key.contains('Verbal') ||
          key.contains('Analogy') ||
          key.contains('Deret') ||
          key.contains('Sequence') ||
          key.contains('Logis') ||
          key.contains('Reasoning') ||
          key.contains('Spasial') ||
          key.contains('Spatial') ||
          key.contains('Image') ||
          key.contains('Klasifikasi') ||
          key.contains('Classification') ||
          key.contains('Silogisme') ||
          key.contains('Syllogism');

      if (isCognitiveSubtest) {
        if (!key.contains('PRO')) {
          totalCognitiveCorrect += data['score'] as int;
          totalCognitiveQuestions += data['total'] as int;
        }
      }

      if (!key.contains('PRO')) {
        completedDetail.add(data);
      }
    });

    completedDetail.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));

    catScores['Verbal'] = (highestScores['Analogi Verbal']?['percentage'] ??
            highestScores['Verbal Analogy']?['percentage']) ??
        0.0;
    catScores['Angka'] = (highestScores['Deret Angka']?['percentage'] ??
            highestScores['Number Sequence']?['percentage']) ??
        0.0;
    catScores['Logika'] = (highestScores['Penalaran Logis']?['percentage'] ??
            highestScores['Logical Reasoning']?['percentage']) ??
        0.0;
    catScores['Spasial'] = (highestScores['Spasial (Gambar)']?['percentage'] ??
            highestScores['Spatial (Image)']?['percentage']) ??
        0.0;
    catScores['Klasifikasi'] =
        (highestScores['Klasifikasi Gambar']?['percentage'] ??
                highestScores['Image Classification']?['percentage']) ??
            0.0;

    // 1. Kalkulasi IQ Reguler (FREE) Tertinggi
    int iqFree = 0;
    String iqFreeCat = 'profile.no_predicate'.tr();
    if (totalCognitiveQuestions > 0) {
      double pct = totalCognitiveCorrect / totalCognitiveQuestions;
      iqFree = 70 + (pct * 70).round();
    }

    if (iqFree > 0) {
      if (iqFree >= 130) {
        iqFreeCat = 'profile.iq_genius'.tr();
      } else if (iqFree >= 120) {
        iqFreeCat = 'profile.iq_superior'.tr();
      } else if (iqFree >= 110) {
        iqFreeCat = 'profile.iq_above_avg'.tr();
      } else if (iqFree >= 90) {
        iqFreeCat = 'profile.iq_avg'.tr();
      } else {
        iqFreeCat = 'profile.iq_below_avg'.tr();
      }
    }

    // 2. Cari Skor IQ PRO Tertinggi
    int iqProBest = 0;
    String iqProCat = 'profile.no_predicate'.tr();
    if (iqProList.isNotEmpty) {
      for (var proTest in iqProList) {
        int currentPro = proTest['score'] as int? ?? 0;
        if (currentPro > iqProBest) {
          iqProBest = currentPro;
        }
      }
    }

    if (iqProBest > 0) {
      if (iqProBest >= 130) {
        iqProCat = 'profile.iq_genius'.tr();
      } else if (iqProBest >= 120) {
        iqProCat = 'profile.iq_superior'.tr();
      } else if (iqProBest >= 110) {
        iqProCat = 'profile.iq_above_avg'.tr();
      } else if (iqProBest >= 90) {
        iqProCat = 'profile.iq_avg'.tr();
      } else {
        iqProCat = 'profile.iq_below_avg'.tr();
      }
    }

    if (totalCognitiveQuestions > 0) {
      String bestCategory =
          catScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      Map<String, String> penjelasanKekuatan = {
        'Verbal': 'profile.strength_verbal'.tr(),
        'Angka': 'profile.strength_angka'.tr(),
        'Logika': 'profile.strength_logika'.tr(),
        'Spasial': 'profile.strength_spasial'.tr(),
        'Klasifikasi': 'profile.strength_klasifikasi'.tr(),
      };
      summaryText = 'profile.summary_template'.tr(
        args: [bestCategory, penjelasanKekuatan[bestCategory]!],
      );
    }

    if (!mounted) return;
    setState(() {
      _iqProHistory = iqProList;
      _warteggHistory = warteggList;
      _eqHistory = eqList;
      _sqHistory = sqList;
      _completedTestsDetail = completedDetail;
      _categoryScores = catScores;
      _kesimpulanSingkat = summaryText;
      _iqFreeScore = iqFree;
      _iqFreeCategory = iqFreeCat;
      _iqProHighestScore = iqProBest;
      _iqProHighestCategory = iqProCat;
      _isLoading = false;
    });
  }

  Future<void> _generateAIFromProfile(
    String testName,
    int score,
    int totalQuestions,
    String dominantCode,
  ) async {
    setState(() => _generatingTestName = testName);

    try {
      final String proxyUrl =
          "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash-lite";
      final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";
      String promptText = '';

      final displayTestName =
          getLocalizedTestLabel(testName, context.locale.languageCode);

      if (testName.contains('RIASEC') ||
          testName.contains('VAK') ||
          testName.contains('MBTI') ||
          testName.contains('16 Kepribadian')) {
        promptText = 'profile.prompt_personality'.tr(
          args: [displayTestName, dominantCode],
        );
      } else {
        double percentage = totalQuestions > 0 ? score / totalQuestions : 0;
        String category = percentage >= 0.8
            ? 'profile.prompt_cat_excellent'.tr()
            : (percentage >= 0.6
                ? 'profile.prompt_cat_good'.tr()
                : 'profile.prompt_cat_practice'.tr());
        promptText = 'profile.prompt_cognitive'.tr(
          args: [
            displayTestName,
            score.toString(),
            totalQuestions.toString(),
            category,
          ],
        );
      }

      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appSecret',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": promptText}
              ]
            }
          ]
        }),
      );

      String aiResult;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        aiResult = data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception(
          'profile.msg_ai_error'.tr(args: [response.statusCode.toString()]),
        );
      }

      if (dominantCode.isNotEmpty) {
        aiResult = '$aiResult \n\n[KODE: $dominantCode]';
      }

      await DatabaseHelper.instance.updateLatestTestAnalysis(
        testName,
        aiResult,
      );
      AuthService().syncDataNow();
      await _loadCertificateData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generatingTestName = "");
      }
    }
  }

  Future<void> _shareIQPoster() async {
    setState(() => _isSharing = true);
    try {
      RenderRepaintBoundary boundary = _shareKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath =
          await File('${directory.path}/smart_iq_score.png').create();
      await imagePath.writeAsBytes(pngBytes);

      String shareText = 'profile.share_poster_text'.tr(
        args: [_iqFreeScore.toString(), _iqFreeCategory],
      );
      await Share.shareXFiles([XFile(imagePath.path)], text: shareText);
    } catch (e) {
      debugPrint('Gagal membagikan: $e');
    }
    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  void _showPremiumHistoryDialog(
    String title,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> historyList,
  ) {
    final sortedHistory = List<Map<String, dynamic>>.from(historyList)
      ..sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'profile.history_title'.tr(args: [title]),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: sortedHistory.isEmpty
              ? Text('profile.history_empty'.tr(args: [title]))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedHistory.length,
                  itemBuilder: (context, index) {
                    String label = index == 0
                        ? 'profile.history_latest'.tr()
                        : 'profile.history_past'.tr(
                            args: [(sortedHistory.length - index).toString()],
                          );
                    String analysis =
                        sortedHistory[index]['ai_analysis'] ?? "";

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: color,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MarkdownBody(
                                  data: analysis,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                    strong: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    listBullet: TextStyle(color: color),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Share.share(
                                        'profile.share_analysis_text'.tr(
                                          args: [title, analysis],
                                        ),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.share,
                                      size: 16,
                                      color: color,
                                    ),
                                    label: Text(
                                      'profile.btn_share_analysis'.tr(),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: color),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'profile.btn_close'.tr(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'profile.privacy_title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              'profile.privacy_content'.tr(),
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('profile.btn_close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'profile.disclaimer_title'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              'profile.disclaimer_content'.tr(),
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'profile.btn_understand'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'profile.dialog_change_lang_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Text('🇮🇩', style: TextStyle(fontSize: 24)),
              title: Text(
                'profile.lang_id'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: context.locale.languageCode == 'id'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await context.setLocale(const Locale('id'));
                if (context.mounted) Navigator.pop(context);
                _initializeApp();
              },
            ),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: Text(
                'profile.lang_en'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: context.locale.languageCode == 'en'
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () async {
                await context.setLocale(const Locale('en'));
                if (context.mounted) Navigator.pop(context);
                _initializeApp();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getUserInitials() {
    final trimmed = _userName.trim();
    if (!_isLoggedIn || trimmed.isEmpty) return '';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  Widget _buildSectionHeader(IconData icon, String title, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFF0D47A1))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor ?? const Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String label, double percentage, Color color) {
    final int pctInt = (percentage * 100).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: percentage > 0
                ? color.withValues(alpha: 0.12)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$pctInt%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: percentage > 0 ? color : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Flexible(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            width: 28,
            height: percentage > 0 ? (96 * percentage).clamp(12.0, 96.0) : 10,
            decoration: BoxDecoration(
              gradient: percentage > 0
                  ? LinearGradient(
                      colors: [color.withValues(alpha: 0.75), color],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: percentage > 0 ? null : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildTraitBubbles(String markdownText, Color color) {
    if (markdownText.contains("Belum ada analisa") ||
        markdownText.contains("Menunggu") ||
        markdownText.contains("Waiting")) {
      return const SizedBox.shrink();
    }

    List<String> keywords = [];
    RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    Iterable<RegExpMatch> matches = boldRegex.allMatches(markdownText);

    for (var match in matches) {
      if (match.group(1) != null && match.group(1)!.length > 1) {
        String cleanText =
            match.group(1)!.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (cleanText.isNotEmpty &&
            !keywords.contains(cleanText) &&
            cleanText.length <= 25) {
          keywords.add(cleanText);
        }
      }
    }

    if (keywords.isEmpty) {
      LineSplitter.split(markdownText).forEach((line) {
        if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
          String cleanLine = line
              .trim()
              .substring(2)
              .replaceAll(RegExp(r'[^\w\s]'), '')
              .trim();
          if (cleanLine.isNotEmpty && cleanLine.split(' ').length <= 3) {
            keywords.add(cleanLine);
          }
        }
      });
    }

    final displayKeywords = keywords.take(6).toList();
    if (displayKeywords.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 6.0,
        children: displayKeywords
            .map(
              (trait) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: color.withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
                child: Text(
                  trait,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPremiumTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> historyList,
    VoidCallback onTap,
  ) {
    final bool hasData = historyList.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData
              ? color.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (hasData) {
              onTap();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('profile.msg_not_completed'.tr(args: [title])),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (hasData) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${historyList.length}x',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: hasData ? color : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'profile.btn_history'.tr(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasData ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStatItem({
    required String label,
    required String value,
    required String subLabel,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subLabel.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subLabel,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrainGamesSection() {
    final games = [
      {
        'key': GameHighScoreHelper.kAnagram,
        'title': 'game_menu.game1_title'.tr(),
        'icon': Icons.sort_by_alpha,
        'color': Colors.orange,
        'isLevel': false,
      },
      {
        'key': GameHighScoreHelper.kStroop,
        'title': 'game_menu.game2_title'.tr(),
        'icon': Icons.palette,
        'color': Colors.green,
        'isLevel': false,
      },
      {
        'key': GameHighScoreHelper.kMathRush,
        'title': 'game_menu.game3_title'.tr(),
        'icon': Icons.calculate,
        'color': Colors.purple,
        'isLevel': false,
      },
      {
        'key': GameHighScoreHelper.kMemoryMatch,
        'title': 'game_menu.game4_title'.tr(),
        'icon': Icons.dashboard_customize,
        'color': Colors.blue,
        'isLevel': true,
      },
      {
        'key': GameHighScoreHelper.kSudoku,
        'title': 'game_menu.game5_title'.tr(),
        'icon': Icons.grid_on_rounded,
        'color': Colors.indigo,
        'isLevel': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.emoji_events_rounded,
          'profile.brain_game_records_title'.tr(),
          iconColor: Colors.amber.shade800,
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final g = games[index];
              final String key = g['key'] as String;
              final int score = _gameHighScores[key] ?? 0;
              final Color color = g['color'] as Color;
              final bool isLevel = g['isLevel'] as bool;
              final String rawTitle = (g['title'] as String).split('(').first.trim();

              return Container(
                width: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: score > 0
                        ? color.withValues(alpha: 0.35)
                        : Colors.grey.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            g['icon'] as IconData,
                            color: color,
                            size: 16,
                          ),
                        ),
                        if (score > 0)
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Colors.amber,
                            size: 16,
                          ),
                      ],
                    ),
                    Text(
                      rawTitle,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      score > 0
                          ? (isLevel ? 'Lv. $score' : '$score')
                          : 'profile.brain_game_no_record'.tr(),
                      style: TextStyle(
                        fontSize: score > 0 ? 16 : 11,
                        fontWeight: FontWeight.w900,
                        color: score > 0
                            ? const Color(0xFF1E293B)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayList = _completedTestsDetail;
    bool hasMore = displayList.length > 10;
    if (!_showAllHistory && hasMore) {
      displayList = displayList.sublist(0, 10);
    }

    final int totalTestsCompleted = _completedTestsDetail.length +
        (_iqProHistory.isNotEmpty ? 1 : 0) +
        (_warteggHistory.isNotEmpty ? 1 : 0) +
        (_eqHistory.isNotEmpty ? 1 : 0) +
        (_sqHistory.isNotEmpty ? 1 : 0);

    final String initials = _getUserInitials();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          'profile.appbar_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Tombol Cepat Ganti Bahasa di AppBar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: InkWell(
              onTap: _showLanguageDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.locale.languageCode == 'id' ? '🇮🇩 ID' : '🇬🇧 EN',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoggedIn)
            IconButton(
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.cloud_sync_rounded),
              onPressed: _isSyncing ? null : _manualSync,
              tooltip: 'profile.tooltip_sync'.tr(),
            ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  title: Text('profile.dialog_logout_title'.tr()),
                  content: Text('profile.dialog_logout_content'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('profile.btn_cancel'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(
                        'profile.btn_logout'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Poster tersembunyi untuk fitur Bagikan Poster IQ
          Positioned(
            left: -3000,
            top: -3000,
            child: RepaintBoundary(
              key: _shareKey,
              child: Container(
                width: 450,
                height: 450,
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.psychology,
                      size: 60,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'profile.poster_app_name'.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      _userName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'profile.poster_score_title'.tr(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$_iqFreeScore',
                            style: const TextStyle(
                              color: Color(0xFF0D47A1),
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            width: 150,
                            height: 2,
                            color: Colors.orange,
                          ),
                          Text(
                            _iqFreeCategory.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'profile.poster_footer'.tr(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    if (_isLoggedIn) {
                      await _manualSync();
                    } else {
                      await _initializeApp();
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // ==========================================
                        // HERO HEADER PROFIL MELENGKUNG
                        // ==========================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Baris Avatar + Info Akun
                              Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFB300),
                                              Color(0xFFF57C00),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: initials.isNotEmpty
                                            ? Text(
                                                initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white,
                                                size: 38,
                                              ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: _isLoggedIn
                                                ? Colors.green
                                                : Colors.amber.shade700,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            _isLoggedIn
                                                ? Icons.cloud_done_rounded
                                                : Icons.person_outline_rounded,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _userName,
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              _isLoggedIn
                                                  ? Icons.verified_user_rounded
                                                  : Icons.info_outline_rounded,
                                              size: 14,
                                              color: _isLoggedIn
                                                  ? Colors.greenAccent
                                                  : Colors.white70,
                                            ),
                                            const SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                _userEmail,
                                                style: TextStyle(
                                                  color: _isLoggedIn
                                                      ? Colors.greenAccent
                                                      : Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              if (!_isLoggedIn) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: _isSyncing
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : ElevatedButton.icon(
                                          onPressed: _handleLogin,
                                          icon: const Icon(
                                            Icons.cloud_upload_rounded,
                                            color: Color(0xFF0D47A1),
                                            size: 20,
                                          ),
                                          label: Text(
                                            'profile.btn_login_sync'.tr(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor:
                                                const Color(0xFF0D47A1),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                ),
                              ],

                              const SizedBox(height: 18),

                              // 3 Kotak Ringkasan Cepat di Header
                              Row(
                                children: [
                                  _buildHeroStatItem(
                                    label: 'profile.hero_iq_free'.tr(),
                                    value: _iqFreeScore > 0
                                        ? '$_iqFreeScore'
                                        : '-',
                                    subLabel: _iqFreeScore > 0
                                        ? _iqFreeCategory
                                        : '',
                                    icon: Icons.psychology_rounded,
                                    accentColor: Colors.lightBlueAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildHeroStatItem(
                                    label: 'profile.hero_iq_pro'.tr(),
                                    value: _iqProHighestScore > 0
                                        ? '$_iqProHighestScore'
                                        : '-',
                                    subLabel: _iqProHighestScore > 0
                                        ? _iqProHighestCategory
                                        : '',
                                    icon: Icons.workspace_premium_rounded,
                                    accentColor: Colors.amberAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  _buildHeroStatItem(
                                    label: 'profile.hero_tests_done'.tr(),
                                    value: '$totalTestsCompleted',
                                    subLabel: '',
                                    icon: Icons.task_alt_rounded,
                                    accentColor: Colors.greenAccent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // KONTEN UTAMA PROFIL
                        // ==========================================
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. GRAFIK STATISTIK KECERDASAN
                              _buildSectionHeader(
                                Icons.bar_chart_rounded,
                                'profile.stat_title'.tr(),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 145,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          _buildChartBar(
                                            'VRB',
                                            _categoryScores['Verbal'] ?? 0,
                                            Colors.blue,
                                          ),
                                          _buildChartBar(
                                            'DRT',
                                            _categoryScores['Angka'] ?? 0,
                                            Colors.green,
                                          ),
                                          _buildChartBar(
                                            'LOG',
                                            _categoryScores['Logika'] ?? 0,
                                            Colors.purple,
                                          ),
                                          _buildChartBar(
                                            'SPS',
                                            _categoryScores['Spasial'] ?? 0,
                                            Colors.orange,
                                          ),
                                          _buildChartBar(
                                            'KLS',
                                            _categoryScores['Klasifikasi'] ?? 0,
                                            Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.amber.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.amber
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.lightbulb_rounded,
                                            color: Colors.amber,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _kesimpulanSingkat,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade800,
                                                height: 1.45,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 2. REKOR TERTINGGI ASAH OTAK (5 GAME)
                              _buildBrainGamesSection(),

                              // 3. REKAP SKOR KESELURUHAN (GRID)
                              Builder(
                                builder: (context) {
                                  List<Map<String, dynamic>> allTableData = [];

                                  if (_iqProHistory.isNotEmpty) {
                                    var bestPro = _iqProHistory.reduce(
                                      (a, b) =>
                                          (a['score'] as int? ?? 0) >
                                                  (b['score'] as int? ?? 0)
                                              ? a
                                              : b,
                                    );
                                    allTableData.add({
                                      'name': 'Tes IQ Komprehensif (PRO)',
                                      'score': bestPro['score'] ?? 0,
                                      'total': bestPro['total_questions'] ?? 1,
                                      'code': '',
                                    });
                                  }

                                  if (_iqFreeScore > 0) {
                                    allTableData.add({
                                      'name': 'IQ Reguler (FREE)',
                                      'score': _iqFreeScore,
                                      'total': 0,
                                      'code': _iqFreeCategory,
                                    });
                                  }

                                  if (_eqHistory.isNotEmpty) {
                                    var bestEq = _eqHistory.reduce(
                                      (a, b) =>
                                          (a['score'] as int? ?? 0) >
                                                  (b['score'] as int? ?? 0)
                                              ? a
                                              : b,
                                    );
                                    String code = "";
                                    var match = RegExp(r'\[KODE:\s*(.*?)\]')
                                        .firstMatch(
                                            bestEq['ai_analysis'] ?? "");
                                    if (match != null) code = match.group(1)!;
                                    allTableData.add({
                                      'name': 'Tes EQ (AI)',
                                      'score': bestEq['score'] ?? 0,
                                      'total': 172,
                                      'code': code,
                                    });
                                  }

                                  if (_sqHistory.isNotEmpty) {
                                    var bestSq = _sqHistory.reduce(
                                      (a, b) =>
                                          (a['score'] as int? ?? 0) >
                                                  (b['score'] as int? ?? 0)
                                              ? a
                                              : b,
                                    );
                                    String code = "";
                                    var match = RegExp(r'\[KODE:\s*(.*?)\]')
                                        .firstMatch(
                                            bestSq['ai_analysis'] ?? "");
                                    if (match != null) code = match.group(1)!;
                                    allTableData.add({
                                      'name': 'Tes SQ (AI)',
                                      'score': bestSq['score'] ?? 0,
                                      'total': 300,
                                      'code': code,
                                    });
                                  }

                                  if (_warteggHistory.isNotEmpty) {
                                    allTableData.add({
                                      'name': 'Tes Wartegg (AI)',
                                      'score': 0,
                                      'total': 0,
                                      'code': '✓',
                                    });
                                  }

                                  for (var item in _completedTestsDetail) {
                                    String itemName = item['name'];
                                    bool isCognitive =
                                        itemName.contains('Verbal') ||
                                            itemName.contains('Analogy') ||
                                            itemName.contains('Deret') ||
                                            itemName.contains('Sequence') ||
                                            itemName.contains('Logis') ||
                                            itemName.contains('Reasoning') ||
                                            itemName.contains('Spasial') ||
                                            itemName.contains('Spatial') ||
                                            itemName.contains('Image') ||
                                            itemName.contains('Klasifikasi') ||
                                            itemName.contains(
                                                'Classification') ||
                                            itemName.contains('Silogisme') ||
                                            itemName.contains('Syllogism');

                                    if (!isCognitive) {
                                      allTableData.add(item);
                                    }
                                  }

                                  if (allTableData.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader(
                                        Icons.grid_view_rounded,
                                        'profile.table_score_title'.tr(),
                                      ),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 0.85,
                                        ),
                                        itemCount: allTableData.length,
                                        itemBuilder: (context, index) {
                                          final item = allTableData[index];
                                          String rawName = item['name'];

                                          String testName = rawName ==
                                                  'IQ Reguler (FREE)'
                                              ? 'profile.iq_free_title'.tr()
                                              : getLocalizedTestLabel(
                                                  rawName,
                                                  context.locale.languageCode,
                                                );

                                          String mainValue = "";
                                          String bottomLabel = "";

                                          if (rawName.contains('Wartegg')) {
                                            mainValue = '✓';
                                            bottomLabel =
                                                'profile.label_completed'.tr();
                                          } else if (rawName.contains('PRO')) {
                                            mainValue = '${item['score']}';
                                            bottomLabel = _iqProHighestCategory
                                                    .isNotEmpty
                                                ? _iqProHighestCategory
                                                : 'profile.label_iq_score'.tr();
                                          } else if (rawName ==
                                              'IQ Reguler (FREE)') {
                                            mainValue = '${item['score']}';
                                            bottomLabel = item['code'] != ""
                                                ? item['code']
                                                : 'profile.label_iq_score'.tr();
                                          } else if (rawName.contains('EQ') ||
                                              rawName.contains('SQ')) {
                                            mainValue = '${item['score']}';
                                            String catCode = item['code'] != ""
                                                ? item['code']
                                                : 'profile.label_points'.tr();
                                            if (catCode.contains('/')) {
                                              catCode = catCode
                                                  .split('/')[0]
                                                  .trim();
                                            }
                                            if (catCode
                                                .contains('Pencerahan')) {
                                              catCode = 'Pencerahan';
                                            }
                                            bottomLabel = catCode;
                                          } else if (rawName.contains('VAK') ||
                                              rawName.contains('RIASEC') ||
                                              rawName.contains('MBTI') ||
                                              rawName.contains('Kepribadian')) {
                                            mainValue = item['code'] != ""
                                                ? item['code']
                                                : '-';
                                            bottomLabel =
                                                'profile.label_character'.tr();
                                          } else {
                                            mainValue =
                                                '${item['score']}/${item['total']}';
                                            int pct = item['total'] > 0
                                                ? ((item['score'] /
                                                            item['total']) *
                                                        100)
                                                    .toInt()
                                                : 0;
                                            bottomLabel =
                                                'profile.label_accuracy'.tr(
                                              args: [pct.toString()],
                                            );
                                          }

                                          IconData cardIcon = Icons.quiz;
                                          MaterialColor cardColor = Colors.blue;

                                          if (rawName.contains('PRO')) {
                                            cardIcon = Icons.workspace_premium;
                                            cardColor = Colors.amber;
                                          } else if (rawName ==
                                              'IQ Reguler (FREE)') {
                                            cardIcon = Icons.psychology;
                                            cardColor = Colors.lightBlue;
                                          } else if (rawName
                                              .contains('Wartegg')) {
                                            cardIcon = Icons.draw;
                                            cardColor = Colors.purple;
                                          } else if (rawName.contains('EQ')) {
                                            cardIcon = Icons.favorite;
                                            cardColor = Colors.pink;
                                          } else if (rawName.contains('SQ')) {
                                            cardIcon = Icons.self_improvement;
                                            cardColor = Colors.teal;
                                          } else if (rawName.contains('VAK')) {
                                            cardIcon = Icons.menu_book;
                                            cardColor = Colors.blue;
                                          } else if (rawName
                                              .contains('RIASEC')) {
                                            cardIcon = Icons.work;
                                            cardColor = Colors.green;
                                          } else if (rawName.contains('MBTI') ||
                                              rawName.contains('Kepribadian')) {
                                            cardIcon = Icons.groups;
                                            cardColor = Colors.purple;
                                          }

                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: cardColor.shade100,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.025),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: cardColor.withValues(
                                                      alpha: 0.1,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    cardIcon,
                                                    color: cardColor,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  testName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: cardColor.shade700,
                                                    fontSize: 9.5,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  mainValue,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF1E293B),
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  bottomLabel,
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  );
                                },
                              ),

                              // 4. SERTIFIKAT & RIWAYAT PREMIUM
                              _buildSectionHeader(
                                Icons.workspace_premium_rounded,
                                'profile.premium_title'.tr(),
                              ),

                              // KARTU IQ FREE (DENGAN TOMBOL BAGIKAN POSTER)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      if (_iqFreeScore > 0) {
                                        _shareIQPoster();
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'profile.msg_complete_test'.tr(),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(11),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: const Icon(
                                              Icons.workspace_premium_rounded,
                                              color: Color(0xFF0D47A1),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'profile.iq_free_title'.tr(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  'profile.final_score'.tr(
                                                    args: [
                                                      _iqFreeScore.toString(),
                                                      _iqFreeCategory,
                                                    ],
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _isSharing
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.green,
                                                  ),
                                                )
                                              : ElevatedButton.icon(
                                                  onPressed: _iqFreeScore > 0
                                                      ? _shareIQPoster
                                                      : () => ScaffoldMessenger
                                                              .of(context)
                                                          .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'profile.msg_complete_test'
                                                                    .tr(),
                                                              ),
                                                            ),
                                                          ),
                                                  icon: const Icon(
                                                    Icons.share_rounded,
                                                    size: 15,
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    'profile.btn_share'.tr(),
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green.shade600,
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        20,
                                                      ),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 14,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              _buildPremiumTile(
                                'profile.pro_iq_title'.tr(),
                                _iqProHighestScore > 0
                                    ? 'profile.final_score'.tr(
                                        args: [
                                          _iqProHighestScore.toString(),
                                          _iqProHighestCategory,
                                        ],
                                      )
                                    : 'profile.pro_iq_desc'.tr(),
                                Icons.psychology_rounded,
                                Colors.orange,
                                _iqProHistory,
                                () => _showPremiumHistoryDialog(
                                  'profile.pro_iq_title'.tr(),
                                  Icons.psychology_rounded,
                                  Colors.orange,
                                  _iqProHistory,
                                ),
                              ),
                              _buildPremiumTile(
                                'profile.wartegg_title'.tr(),
                                'profile.wartegg_desc'.tr(),
                                Icons.draw_rounded,
                                Colors.purple,
                                _warteggHistory,
                                () => _showPremiumHistoryDialog(
                                  'profile.wartegg_title'.tr(),
                                  Icons.draw_rounded,
                                  Colors.purple,
                                  _warteggHistory,
                                ),
                              ),
                              _buildPremiumTile(
                                'profile.eq_title'.tr(),
                                'profile.eq_desc'.tr(),
                                Icons.favorite_rounded,
                                Colors.pink,
                                _eqHistory,
                                () => _showPremiumHistoryDialog(
                                  'profile.eq_title'.tr(),
                                  Icons.favorite_rounded,
                                  Colors.pink,
                                  _eqHistory,
                                ),
                              ),
                              _buildPremiumTile(
                                'profile.sq_title'.tr(),
                                'profile.sq_desc'.tr(),
                                Icons.self_improvement_rounded,
                                Colors.teal,
                                _sqHistory,
                                () => _showPremiumHistoryDialog(
                                  'profile.sq_title'.tr(),
                                  Icons.self_improvement_rounded,
                                  Colors.teal,
                                  _sqHistory,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // 5. RIWAYAT ANALISA KOGNITIF & KEPRIBADIAN REGULER
                              if (_completedTestsDetail.isNotEmpty) ...[
                                _buildSectionHeader(
                                  Icons.history_edu_rounded,
                                  'profile.regular_history_title'.tr(),
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: displayList.length,
                                  itemBuilder: (context, index) {
                                    final item = displayList[index];
                                    bool isWaitingAI = item['analysis']
                                            .toString()
                                            .contains('Menunggu') ||
                                        item['analysis']
                                            .toString()
                                            .contains('Waiting');
                                    bool isGeneratingThis =
                                        _generatingTestName == item['name'];

                                    bool isPersonalityTest = item['name']
                                            .contains('VAK') ||
                                        item['name'].contains('RIASEC') ||
                                        item['name'].contains('MBTI') ||
                                        item['name'].contains('Kepribadian');

                                    String displayTestName =
                                        getLocalizedTestLabel(
                                      item['name'],
                                      context.locale.languageCode,
                                    );

                                    String subtitleText = isPersonalityTest
                                        ? (item['code'] != ""
                                            ? '${'profile.label_type'.tr()}: ${item['code']}'
                                            : 'profile.waiting_analysis'.tr())
                                        : 'profile.score_correct'.tr(
                                            args: [
                                              item['score'].toString(),
                                              item['total'].toString(),
                                            ],
                                          );

                                    return Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          dividerColor: Colors.transparent,
                                        ),
                                        child: ExpansionTile(
                                          key: PageStorageKey(item['name']),
                                          leading: CircleAvatar(
                                            backgroundColor: isPersonalityTest
                                                ? Colors.purple.shade50
                                                : Colors.blue.shade50,
                                            child: isPersonalityTest
                                                ? Icon(
                                                    Icons.psychology_alt_rounded,
                                                    color:
                                                        Colors.purple.shade700,
                                                    size: 20,
                                                  )
                                                : Text(
                                                    '${(item['percentage'] * 100).toInt()}%',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade900,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                          title: Text(
                                            displayTestName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          subtitle: Text(
                                            subtitleText,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                16,
                                                0,
                                                16,
                                                16,
                                              ),
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(15),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFF8FAFC),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                ),
                                                child: isWaitingAI
                                                    ? Column(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .lock_outline_rounded,
                                                            color: Colors.grey,
                                                            size: 30,
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            'profile.ai_locked'
                                                                .tr(),
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          isGeneratingThis
                                                              ? Column(
                                                                  children: [
                                                                    const CircularProgressIndicator(
                                                                      color: Colors
                                                                          .orange,
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          10,
                                                                    ),
                                                                    Text(
                                                                      'profile.ai_analyzing'
                                                                          .tr(),
                                                                      style:
                                                                          const TextStyle(
                                                                        color: Colors
                                                                            .orange,
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                              : ElevatedButton
                                                                  .icon(
                                                                  onPressed:
                                                                      () {
                                                                    RewardedAdManager
                                                                        .showAd(
                                                                      context,
                                                                      () {
                                                                        _generateAIFromProfile(
                                                                          item[
                                                                              'name'],
                                                                          item[
                                                                              'score'],
                                                                          item[
                                                                              'total'],
                                                                          item[
                                                                              'code'],
                                                                        );
                                                                      },
                                                                    );
                                                                  },
                                                                  icon:
                                                                      const Icon(
                                                                    Icons
                                                                        .play_circle_fill_rounded,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 18,
                                                                  ),
                                                                  label: Text(
                                                                    'profile.btn_watch_analyze'
                                                                        .tr(),
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .orange,
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                        20,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                        ],
                                                      )
                                                    : Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          _buildTraitBubbles(
                                                            item['analysis'],
                                                            isPersonalityTest
                                                                ? Colors.purple
                                                                : Colors.blue,
                                                          ),
                                                          MarkdownBody(
                                                            data: item[
                                                                'analysis'],
                                                            styleSheet:
                                                                MarkdownStyleSheet(
                                                              p: TextStyle(
                                                                fontSize: 12.5,
                                                                color: Colors
                                                                    .grey
                                                                    .shade800,
                                                                height: 1.6,
                                                              ),
                                                              strong:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                              listBullet:
                                                                  const TextStyle(
                                                                color: Color(
                                                                  0xFF0D47A1,
                                                                ),
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          Align(
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child: TextButton
                                                                .icon(
                                                              onPressed: () {
                                                                Share.share(
                                                                  'profile.share_regular_text'
                                                                      .tr(
                                                                    args: [
                                                                      displayTestName,
                                                                      subtitleText,
                                                                      item[
                                                                          'analysis'],
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                              icon: const Icon(
                                                                Icons
                                                                    .share_rounded,
                                                                size: 16,
                                                                color: Color(
                                                                  0xFF0D47A1,
                                                                ),
                                                              ),
                                                              label: Text(
                                                                'profile.btn_share_analysis'
                                                                    .tr(),
                                                                style:
                                                                    const TextStyle(
                                                                  color: Color(
                                                                    0xFF0D47A1,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (!_showAllHistory && hasMore)
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() => _showAllHistory = true);
                                      },
                                      child: Text(
                                        'profile.btn_view_all'.tr(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D47A1),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],

                              const SizedBox(height: 10),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: _showPrivacyPolicyDialog,
                                    child: Text(
                                      'profile.privacy_title'.tr(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showDisclaimerDialog,
                                    child: Text(
                                      'profile.disclaimer_title'.tr(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}