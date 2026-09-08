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
    'Verbal': 0.0, 'Angka': 0.0, 'Logika': 0.0, 'Spasial': 0.0, 'Klasifikasi': 0.0,
  };
  String _kesimpulanSingkat = "";

  List<Map<String, dynamic>> _completedTestsDetail = [];
  bool _showAllHistory = false;
  String _generatingTestName = "";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkLoginStatus();
    await _loadCertificateData();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token != null) {
      setState(() {
        _isLoggedIn = true;
        _userName = prefs.getString('user_name') ?? 'profile.premium_user'.tr();
        _userEmail = prefs.getString('user_email') ?? 'profile.synced_account'.tr();
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
      await _loadCertificateData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile.msg_login_success'.tr()), backgroundColor: Colors.green));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile.msg_login_fail'.tr()), backgroundColor: Colors.red));
    }
    setState(() => _isSyncing = false);
  }

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);
    await AuthService().syncDataNow();
    final success = await AuthService().restoreDataFromServer();
    AuthService.refreshTrigger.value++;
    await _loadCertificateData();

    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'profile.msg_sync_success'.tr() : 'profile.msg_sync_fail'.tr()), backgroundColor: success ? Colors.green : Colors.red)
      );
    }
  }

  Future<void> _handleLogout() async {
    await AuthService().logout();
    await _checkLoginStatus();
    AuthService.refreshTrigger.value++;
    await _loadCertificateData();
  }

  Future<void> _loadCertificateData() async {
    final results = await DatabaseHelper.instance.getAllTestResults();

    Map<String, Map<String, dynamic>> highestScores = {};
    _iqProHistory.clear();
    _warteggHistory.clear();
    _eqHistory.clear();
    _sqHistory.clear();

    for (var test in results) {
      String name = test['test_name'];
      String rawAnalysis = test['ai_analysis'] ?? "";
      bool hasValidAnalysis = rawAnalysis.isNotEmpty && !rawAnalysis.contains('Menunggu');

      if (name == 'Tes IQ Komprehensif (PRO)') {
        _iqProHistory.add(test);
        continue;
      }
      if (name == 'Tes Wartegg (AI)') {
        if (hasValidAnalysis) _warteggHistory.add(test);
        continue;
      }
      if (name == 'Tes EQ (AI)') {
        if (hasValidAnalysis) _eqHistory.add(test);
        continue;
      }
      if (name == 'Tes SQ (AI)') {
        if (hasValidAnalysis) _sqHistory.add(test);
        continue;
      }

      int currentId = test['id'] ?? 0;
      int score = test['score'] ?? 0;
      int total = test['total_questions'] ?? 1;
      double percentage = total > 0 ? score / total : 0.0;

      String dominantCode = "";
      if (name.contains('VAK') || name.contains('RIASEC') || name.contains('MBTI') || name.contains('Kepribadian')) {
        RegExp regExp = RegExp(r'\[KODE:\s*(.*?)\]');
        var match = regExp.firstMatch(rawAnalysis);
        if (match != null) dominantCode = match.group(1)!;
      }

      // --- LOGIKA FILTER CERDAS (KOGNITIF VS KEPRIBADIAN) ---
      bool isNewBest = false;

      if (!highestScores.containsKey(name)) {
        isNewBest = true;
      } else {
        bool isPersonality = name.contains('VAK') || name.contains('RIASEC') || name.contains('MBTI') || name.contains('Kepribadian');

        if (isPersonality) {
          // KHUSUS KEPRIBADIAN: Selalu timpa dengan hasil TERBARU (karena skornya statis)
          if (currentId > (highestScores[name]!['id'] as int)) {
            isNewBest = true;
          }
        } else {
          // KHUSUS KOGNITIF: Selalu ambil Skor TERTINGGI
          if (percentage > highestScores[name]!['percentage']) {
            isNewBest = true;
          } else if (percentage == highestScores[name]!['percentage'] && currentId > (highestScores[name]!['id'] as int)) {
            // Jika skornya sama persis (seri), tetap ambil data yang paling baru
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
          'analysis': rawAnalysis.isEmpty ? 'profile.waiting_ai'.tr() : rawAnalysis,
          'code': dominantCode,
        };
      }
      // ------------------------------------------------------
    }

    int totalCognitiveCorrect = 0, totalCognitiveQuestions = 0;
    _completedTestsDetail.clear();

    _categoryScores = { 'Verbal': 0.0, 'Angka': 0.0, 'Logika': 0.0, 'Spasial': 0.0, 'Klasifikasi': 0.0 };
    _kesimpulanSingkat = 'profile.default_summary'.tr();

    highestScores.forEach((key, data) {
      // --- FIX: Pendeteksi Dwibahasa (Indo & English) ---
      bool isCognitiveSubtest = key.contains('Verbal') || key.contains('Analogy') ||
          key.contains('Deret') || key.contains('Sequence') ||
          key.contains('Logis') || key.contains('Reasoning') ||
          key.contains('Spasial') || key.contains('Spatial') || key.contains('Image') ||
          key.contains('Klasifikasi') || key.contains('Classification') ||
          key.contains('Silogisme') || key.contains('Syllogism');

      if (isCognitiveSubtest) {
        if (!key.contains('PRO')) {
          totalCognitiveCorrect += data['score'] as int;
          totalCognitiveQuestions += data['total'] as int;
        }
      }

      // KEMBALIKAN KE RIWAYAT BAWAH: Tambahkan SEMUA tes (Kognitif & Kepribadian) kecuali pecahan PRO
      if (!key.contains('PRO')) {
        _completedTestsDetail.add(data);
      }
    });

    _completedTestsDetail.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));

    // --- FIX: Grafik Radar/Bar Chart mendukung nama English ---
    _categoryScores['Verbal'] = (highestScores['Analogi Verbal']?['percentage'] ?? highestScores['Verbal Analogy']?['percentage']) ?? 0.0;
    _categoryScores['Angka'] = (highestScores['Deret Angka']?['percentage'] ?? highestScores['Number Sequence']?['percentage']) ?? 0.0;
    _categoryScores['Logika'] = (highestScores['Penalaran Logis']?['percentage'] ?? highestScores['Logical Reasoning']?['percentage']) ?? 0.0;
    _categoryScores['Spasial'] = (highestScores['Spasial (Gambar)']?['percentage'] ?? highestScores['Spatial (Image)']?['percentage']) ?? 0.0;
    _categoryScores['Klasifikasi'] = (highestScores['Klasifikasi Gambar']?['percentage'] ?? highestScores['Image Classification']?['percentage']) ?? 0.0;

    // --- LOGIKA SKOR BARU (DIPISAHKAN) ---

    // 1. Kalkulasi IQ Reguler (FREE) Tertinggi
    _iqFreeScore = 0;
    _iqFreeCategory = 'profile.no_predicate'.tr();
    if (totalCognitiveQuestions > 0) {
      double pct = totalCognitiveCorrect / totalCognitiveQuestions;
      _iqFreeScore = 70 + (pct * 70).round();
    }

    if (_iqFreeScore > 0) {
      if (_iqFreeScore >= 130) _iqFreeCategory = 'profile.iq_genius'.tr();
      else if (_iqFreeScore >= 120) _iqFreeCategory = 'profile.iq_superior'.tr();
      else if (_iqFreeScore >= 110) _iqFreeCategory = 'profile.iq_above_avg'.tr();
      else if (_iqFreeScore >= 90) _iqFreeCategory = 'profile.iq_avg'.tr();
      else _iqFreeCategory = 'profile.iq_below_avg'.tr();
    }

    // 2. Cari Skor IQ PRO Tertinggi
    _iqProHighestScore = 0;
    _iqProHighestCategory = 'profile.no_predicate'.tr();
    if (_iqProHistory.isNotEmpty) {
      for (var proTest in _iqProHistory) {
        int currentPro = proTest['score'] as int? ?? 0;
        if (currentPro > _iqProHighestScore) {
          _iqProHighestScore = currentPro;
        }
      }
    }

    if (_iqProHighestScore > 0) {
      if (_iqProHighestScore >= 130) _iqProHighestCategory = 'profile.iq_genius'.tr();
      else if (_iqProHighestScore >= 120) _iqProHighestCategory = 'profile.iq_superior'.tr();
      else if (_iqProHighestScore >= 110) _iqProHighestCategory = 'profile.iq_above_avg'.tr();
      else if (_iqProHighestScore >= 90) _iqProHighestCategory = 'profile.iq_avg'.tr();
      else _iqProHighestCategory = 'profile.iq_below_avg'.tr();
    }
    // -------------------------------------

    if (totalCognitiveQuestions > 0) {
      String bestCategory = _categoryScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      Map<String, String> penjelasanKekuatan = {
        'Verbal': 'profile.strength_verbal'.tr(),
        'Angka': 'profile.strength_angka'.tr(),
        'Logika': 'profile.strength_logika'.tr(),
        'Spasial': 'profile.strength_spasial'.tr(),
        'Klasifikasi': 'profile.strength_klasifikasi'.tr()
      };
      _kesimpulanSingkat = 'profile.summary_template'.tr(args: [bestCategory, penjelasanKekuatan[bestCategory]!]);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _generateAIFromProfile(String testName, int score, int totalQuestions, String dominantCode) async {
    setState(() => _generatingTestName = testName);

    try {
      final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash-lite";
      final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";
      String promptText = '';

      final displayTestName = getLocalizedTestLabel(testName, context.locale.languageCode);

      if (testName.contains('RIASEC') || testName.contains('VAK') || testName.contains('MBTI') || testName.contains('16 Kepribadian')) {
        promptText = 'profile.prompt_personality'.tr(args: [displayTestName, dominantCode]);
      } else {
        double percentage = totalQuestions > 0 ? score / totalQuestions : 0;
        String category = percentage >= 0.8 ? 'profile.prompt_cat_excellent'.tr() : (percentage >= 0.6 ? 'profile.prompt_cat_good'.tr() : 'profile.prompt_cat_practice'.tr());
        promptText = 'profile.prompt_cognitive'.tr(args: [displayTestName, score.toString(), totalQuestions.toString(), category]);
      }

      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $appSecret',
        },
        body: jsonEncode({
          "contents": [{"parts": [{"text": promptText}]}]
        }),
      );

      String aiResult;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        aiResult = data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('profile.msg_ai_error'.tr(args: [response.statusCode.toString()]));
      }

      if (dominantCode.isNotEmpty) {
        aiResult = '$aiResult \n\n[KODE: $dominantCode]';
      }

      await DatabaseHelper.instance.updateLatestTestAnalysis(testName, aiResult);
      AuthService().syncDataNow();
      await _loadCertificateData();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _generatingTestName = "");
    }
  }

  Future<void> _shareIQPoster() async {
    setState(() => _isSharing = true);
    try {
      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/smart_iq_score.png').create();
      await imagePath.writeAsBytes(pngBytes);

      // Gunakan Skor FREE untuk poster reguler
      String shareText = 'profile.share_poster_text'.tr(args: [_iqFreeScore.toString(), _iqFreeCategory]);
      await Share.shareXFiles([XFile(imagePath.path)], text: shareText);
    } catch (e) {
      print('Gagal membagikan: $e');
    }
    setState(() => _isSharing = false);
  }

  void _showPremiumHistoryDialog(String title, IconData icon, Color color, List<Map<String, dynamic>> historyList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text('profile.history_title'.tr(args: [title]), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
        content: SizedBox(
          width: double.maxFinite,
          child: historyList.isEmpty
              ? Text('profile.history_empty'.tr(args: [title]))
              : ListView.builder(
            shrinkWrap: true,
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              historyList.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
              String label = index == 0 ? 'profile.history_latest'.tr() : 'profile.history_past'.tr(args: [(historyList.length - index).toString()]);
              String analysis = historyList[index]['ai_analysis'] ?? "";

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ExpansionTile(
                  title: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarkdownBody(
                            data: analysis,
                            styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87), strong: const TextStyle(fontWeight: FontWeight.bold), listBullet: TextStyle(color: color)),
                          ),
                          const SizedBox(height: 15),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Share.share('profile.share_analysis_text'.tr(args: [title, analysis]));
                              },
                              icon: Icon(Icons.share, size: 16, color: color),
                              label: Text('profile.btn_share_analysis'.tr(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(side: BorderSide(color: color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('profile.btn_close'.tr(), style: TextStyle(color: color)))],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [const Icon(Icons.shield_outlined, color: Colors.blue), const SizedBox(width: 8), Text('profile.privacy_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              'profile.privacy_content'.tr(),
              style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('profile.btn_close'.tr()))],
      ),
    );
  }

  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.red), const SizedBox(width: 8), Text('profile.disclaimer_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              'profile.disclaimer_content'.tr(),
              style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('profile.btn_understand'.tr(), style: const TextStyle(color: Colors.red)))],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.dialog_change_lang_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇮🇩', style: TextStyle(fontSize: 24)),
              title: Text('profile.lang_id'.tr(), style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: context.locale.languageCode == 'id' ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () async {
                await context.setLocale(const Locale('id'));
                Navigator.pop(context);
                _initializeApp();
              },
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: Text('profile.lang_en'.tr(), style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: context.locale.languageCode == 'en' ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () async {
                await context.setLocale(const Locale('en'));
                Navigator.pop(context);
                _initializeApp();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String label, double percentage, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('${(percentage * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: percentage > 0 ? color : Colors.grey)),
        const SizedBox(height: 5),
        // Lihat catatan yang sama di home_screen._buildBar: pada 100% batang
        // meluber beberapa piksel tanpa Flexible.
        Flexible(
          child: AnimatedContainer(duration: const Duration(milliseconds: 1000), curve: Curves.easeOutCubic, width: 24, height: percentage > 0 ? (100 * percentage) : 10, decoration: BoxDecoration(color: percentage > 0 ? color : Colors.grey.shade300, borderRadius: BorderRadius.circular(6))),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }

  Widget _buildTraitBubbles(String markdownText, Color color) {
    if (markdownText.contains("Belum ada analisa") || markdownText.contains("Menunggu") || markdownText.contains("Waiting")) {
      return const SizedBox.shrink();
    }

    List<String> keywords = [];
    RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    Iterable<RegExpMatch> matches = boldRegex.allMatches(markdownText);

    for (var match in matches) {
      if (match.group(1) != null && match.group(1)!.length > 1) {
        String cleanText = match.group(1)!.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (cleanText.isNotEmpty && !keywords.contains(cleanText) && cleanText.length <= 25) {
          keywords.add(cleanText);
        }
      }
    }

    if (keywords.isEmpty) {
      LineSplitter.split(markdownText).forEach((line) {
        if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
          String cleanLine = line.trim().substring(2).replaceAll(RegExp(r'[^\w\s]'), '').trim();
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
        children: displayKeywords.map((trait) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Text(
            trait,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
        )).toList(),
      ),
    );
  }

  // UPDATE UI: Kartu Premium sekarang lebih interaktif (Seluruh area bisa di-tap)
  Widget _buildPremiumTile(String title, String subtitle, IconData icon, Color color, List historyList, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (historyList.isNotEmpty) {
            onTap();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile.msg_not_completed'.tr(args: [title]))));
          }
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 26)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
          trailing: ElevatedButton(
            onPressed: () {
              if (historyList.isNotEmpty) {
                onTap();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile.msg_not_completed'.tr(args: [title]))));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: Text('profile.btn_history'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> displayList = _completedTestsDetail;
    bool hasMore = displayList.length > 10;
    if (!_showAllHistory && hasMore) {
      displayList = displayList.sublist(0, 10);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text('profile.appbar_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_isLoggedIn)
            IconButton(
              icon: _isSyncing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_sync),
              onPressed: _isSyncing ? null : _manualSync,
              tooltip: 'profile.tooltip_sync'.tr(),
            ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('profile.dialog_logout_title'.tr()),
                  content: Text('profile.dialog_logout_content'.tr()),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('profile.btn_cancel'.tr())),
                    ElevatedButton(onPressed: () { Navigator.pop(context); _handleLogout(); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text('profile.btn_logout'.tr(), style: const TextStyle(color: Colors.white))),
                  ],
                ),
              ),
            )
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            left: -3000, top: -3000,
            child: RepaintBoundary(
              key: _shareKey,
              child: Container(
                width: 450, height: 450, padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.psychology, size: 60, color: Colors.amber), const SizedBox(height: 10),
                    Text('profile.poster_app_name'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)), const SizedBox(height: 25),
                    Text(_userName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]),
                      child: Column(
                        children: [
                          Text('profile.poster_score_title'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),

                          Text('$_iqFreeScore', style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 60, fontWeight: FontWeight.w900, height: 1.1)),
                          Container(margin: const EdgeInsets.symmetric(vertical: 5), width: 150, height: 2, color: Colors.orange),
                          Text(_iqFreeCategory.toUpperCase(), style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25), Text('profile.poster_footer'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(radius: 40, backgroundColor: Colors.white, backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png')), const SizedBox(height: 15),
                Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 5),
                Text(_userEmail, style: TextStyle(color: _isLoggedIn ? Colors.green.shade600 : Colors.grey, fontSize: 13)), const SizedBox(height: 20),

                if (!_isLoggedIn)
                  _isSyncing ? const CircularProgressIndicator() : ElevatedButton.icon(onPressed: _handleLogin, icon: Image.network('https://cdn-icons-png.flaticon.com/512/3002/3002219.png', width: 20, height: 20), label: Text('profile.btn_login_sync'.tr()), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))),
                const SizedBox(height: 25),

                Card(
                  elevation: 1, margin: const EdgeInsets.only(bottom: 25), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _showLanguageDialog,
                    child: ListTile(
                      leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.language, color: Color(0xFF0D47A1))
                      ),
                      title: Text('profile.language_section_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ),
                  ),
                ),

                Align(alignment: Alignment.centerLeft, child: Text('profile.stat_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))), const SizedBox(height: 10),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildChartBar('VRB', _categoryScores['Verbal'] ?? 0, Colors.blue), _buildChartBar('DRT', _categoryScores['Angka'] ?? 0, Colors.green), _buildChartBar('LOG', _categoryScores['Logika'] ?? 0, Colors.purple), _buildChartBar('SPS', _categoryScores['Spasial'] ?? 0, Colors.orange), _buildChartBar('KLS', _categoryScores['Klasifikasi'] ?? 0, Colors.red),
                          ],
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 15.0), child: Divider()),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber, size: 24), const SizedBox(width: 10),
                          Expanded(child: Text(_kesimpulanSingkat, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // ===== REKAP SELURUH HASIL TES (DESAIN KARTU ALA FINAL RESULT) =====
                Builder(
                    builder: (context) {
                      List<Map<String, dynamic>> allTableData = [];

                      // 1. TES IQ PRO (Dijamin tampil paling atas)
                      if (_iqProHistory.isNotEmpty) {
                        var bestPro = _iqProHistory.reduce((a, b) => (a['score'] as int? ?? 0) > (b['score'] as int? ?? 0) ? a : b);
                        allTableData.add({
                          'name': 'Tes IQ Komprehensif (PRO)',
                          'score': bestPro['score'] ?? 0,
                          'total': bestPro['total_questions'] ?? 1,
                          'code': ''
                        });
                      }

                      // --- FIX: SUNTIKKAN IQ REGULER KE DALAM KARTU GRID ---
                      if (_iqFreeScore > 0) {
                        allTableData.add({
                          'name': 'IQ Reguler (FREE)',
                          'score': _iqFreeScore,
                          'total': 0,
                          'code': _iqFreeCategory
                        });
                      }

                      // 2. TES EQ (Menarik Skor Angka Asli & Kategori!)
                      if (_eqHistory.isNotEmpty) {
                        var bestEq = _eqHistory.reduce((a, b) => (a['score'] as int? ?? 0) > (b['score'] as int? ?? 0) ? a : b);
                        String code = "";
                        var match = RegExp(r'\[KODE:\s*(.*?)\]').firstMatch(bestEq['ai_analysis'] ?? "");
                        if (match != null) code = match.group(1)!;
                        allTableData.add({'name': 'Tes EQ (AI)', 'score': bestEq['score'] ?? 0, 'total': 172, 'code': code});
                      }

                      // 3. TES SQ (Menarik Skor Angka Asli & Kategori!)
                      if (_sqHistory.isNotEmpty) {
                        var bestSq = _sqHistory.reduce((a, b) => (a['score'] as int? ?? 0) > (b['score'] as int? ?? 0) ? a : b);
                        String code = "";
                        var match = RegExp(r'\[KODE:\s*(.*?)\]').firstMatch(bestSq['ai_analysis'] ?? "");
                        if (match != null) code = match.group(1)!;
                        allTableData.add({'name': 'Tes SQ (AI)', 'score': bestSq['score'] ?? 0, 'total': 300, 'code': code});
                      }

                      // 4. TES WARTEGG (Cukup centang saja)
                      if (_warteggHistory.isNotEmpty) {
                        allTableData.add({'name': 'Tes Wartegg (AI)', 'score': 0, 'total': 0, 'code': '✓'});
                      }

                      // 5. Gabungkan tes kepribadian (VAK, RIASEC, dll) ke dalam Grid.
                      // FILTER: Jangan masukkan tes kognitif eceran ke Grid agar layar tidak penuh.
                      for (var item in _completedTestsDetail) {
                        String itemName = item['name'];
                        bool isCognitive = itemName.contains('Verbal') || itemName.contains('Analogy') ||
                            itemName.contains('Deret') || itemName.contains('Sequence') ||
                            itemName.contains('Logis') || itemName.contains('Reasoning') ||
                            itemName.contains('Spasial') || itemName.contains('Spatial') || itemName.contains('Image') ||
                            itemName.contains('Klasifikasi') || itemName.contains('Classification') ||
                            itemName.contains('Silogisme') || itemName.contains('Syllogism');

                        if (!isCognitive) {
                          allTableData.add(item);
                        }
                      }

                      if (allTableData.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text('profile.table_score_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))
                          ),
                          const SizedBox(height: 15),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: allTableData.length,
                            itemBuilder: (context, index) {
                              final item = allTableData[index];
                              String rawName = item['name'];

                              String testName = rawName == 'IQ Reguler (FREE)'
                                  ? 'profile.iq_free_title'.tr()
                                  : getLocalizedTestLabel(rawName, context.locale.languageCode);

                              // LOGIKA TAMPILAN KARTU YANG CERDAS
                              String mainValue = "";
                              String bottomLabel = "";

                              if (rawName.contains('Wartegg')) {
                                mainValue = '✓';
                                bottomLabel = 'Selesai';
                              } else if (rawName.contains('PRO')) {
                                mainValue = '${item['score']}';
                                bottomLabel = _iqProHighestCategory.isNotEmpty ? _iqProHighestCategory : 'Skor IQ';
                              } else if (rawName == 'IQ Reguler (FREE)') {
                                // --- FIX: TAMPILAN KHUSUS IQ REGULER ---
                                mainValue = '${item['score']}';
                                bottomLabel = item['code'] != "" ? item['code'] : 'Skor IQ';
                              } else if (rawName.contains('EQ') || rawName.contains('SQ')) {
                                mainValue = '${item['score']}';

                                String catCode = item['code'] != "" ? item['code'] : 'Poin';
                                if (catCode.contains('/')) catCode = catCode.split('/')[0].trim();
                                if (catCode.contains('Pencerahan')) catCode = 'Pencerahan';

                                bottomLabel = catCode;
                              } else if (rawName.contains('VAK') || rawName.contains('RIASEC') || rawName.contains('MBTI') || rawName.contains('Kepribadian')) {
                                mainValue = item['code'] != "" ? item['code'] : '-';
                                bottomLabel = 'Karakter';
                              } else {
                                mainValue = '${item['score']}/${item['total']}';
                                int pct = item['total'] > 0 ? ((item['score'] / item['total']) * 100).toInt() : 0;
                                bottomLabel = '$pct% Akurasi';
                              }

                              // Menentukan Ikon dan Warna
                              IconData cardIcon = Icons.quiz;
                              MaterialColor cardColor = Colors.blue;

                              if (rawName.contains('PRO')) { cardIcon = Icons.workspace_premium; cardColor = Colors.amber; }
                              else if (rawName == 'IQ Reguler (FREE)') { cardIcon = Icons.psychology; cardColor = Colors.lightBlue; }
                              else if (rawName.contains('Wartegg')) { cardIcon = Icons.draw; cardColor = Colors.purple; }
                              else if (rawName.contains('EQ')) { cardIcon = Icons.favorite; cardColor = Colors.pink; }
                              else if (rawName.contains('SQ')) { cardIcon = Icons.self_improvement; cardColor = Colors.teal; }
                              else if (rawName.contains('VAK')) { cardIcon = Icons.menu_book; cardColor = Colors.blue; }
                              else if (rawName.contains('RIASEC')) { cardIcon = Icons.work; cardColor = Colors.green; }
                              else if (rawName.contains('MBTI') || rawName.contains('Kepribadian')) { cardIcon = Icons.groups; cardColor = Colors.purple; }
                              else if (rawName.contains('Verbal')) { cardIcon = Icons.font_download; cardColor = Colors.lightBlue; }
                              else if (rawName.contains('Angka')) { cardIcon = Icons.calculate; cardColor = Colors.lightGreen; }
                              else if (rawName.contains('Logis')) { cardIcon = Icons.extension; cardColor = Colors.deepPurple; }
                              else if (rawName.contains('Spasial')) { cardIcon = Icons.category; cardColor = Colors.orange; }
                              else if (rawName.contains('Klasifikasi')) { cardIcon = Icons.grid_view; cardColor = Colors.red; }

                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: cardColor.shade200)
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(cardIcon, color: cardColor, size: 22),
                                    const SizedBox(height: 6),
                                    Text(testName, style: TextStyle(fontWeight: FontWeight.bold, color: cardColor, fontSize: 9), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(mainValue, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), textAlign: TextAlign.center, maxLines: 1),
                                    const SizedBox(height: 4),
                                    Text(bottomLabel, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 25),
                        ],
                      );
                    }
                ),
                // ====================================================================

                Align(alignment: Alignment.centerLeft, child: Text('profile.premium_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))), const SizedBox(height: 10),

                // KARTU IQ FREE (MENGGUNAKAN VARIABEL FREE SCORE)
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      if (_iqFreeScore > 0) {
                        _shareIQPoster();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile.msg_complete_test'.tr())));
                      }
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.workspace_premium, color: Color(0xFF0D47A1), size: 28)
                      ),
                      title: Text('profile.iq_free_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('profile.final_score'.tr(args: [_iqFreeScore.toString(), _iqFreeCategory]), style: const TextStyle(fontSize: 12)),
                      trailing: _isSharing
                          ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                      )
                          : ElevatedButton.icon(
                        onPressed: _iqFreeScore > 0
                            ? _shareIQPoster
                            : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile.msg_complete_test'.tr()))),
                        icon: const Icon(Icons.share, size: 16, color: Colors.white),
                        label: Text('profile.btn_share'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, elevation: 3, shadowColor: Colors.green.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                ),

                // KARTU IQ PRO (MENGGUNAKAN VARIABEL PRO TERTINGGI)
                _buildPremiumTile(
                    'profile.pro_iq_title'.tr(),
                    _iqProHighestScore > 0 ? 'profile.final_score'.tr(args: [_iqProHighestScore.toString(), _iqProHighestCategory]) : 'profile.pro_iq_desc'.tr(),
                    Icons.psychology,
                    Colors.orange,
                    _iqProHistory,
                        () => _showPremiumHistoryDialog('profile.pro_iq_title'.tr(), Icons.psychology, Colors.orange, _iqProHistory)
                ),

                _buildPremiumTile('profile.wartegg_title'.tr(), 'profile.wartegg_desc'.tr(), Icons.draw, Colors.purple, _warteggHistory, () => _showPremiumHistoryDialog('profile.wartegg_title'.tr(), Icons.draw, Colors.purple, _warteggHistory)),
                _buildPremiumTile('profile.eq_title'.tr(), 'profile.eq_desc'.tr(), Icons.favorite, Colors.pink, _eqHistory, () => _showPremiumHistoryDialog('profile.eq_title'.tr(), Icons.favorite, Colors.pink, _eqHistory)),
                _buildPremiumTile('profile.sq_title'.tr(), 'profile.sq_desc'.tr(), Icons.self_improvement, Colors.teal, _sqHistory, () => _showPremiumHistoryDialog('profile.sq_title'.tr(), Icons.self_improvement, Colors.teal, _sqHistory)),

                const SizedBox(height: 25),

                if (_completedTestsDetail.isNotEmpty) ...[
                  Align(alignment: Alignment.centerLeft, child: Text('profile.regular_history_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87))), const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final item = displayList[index];
                      bool isWaitingAI = item['analysis'].toString().contains('Menunggu') || item['analysis'].toString().contains('Waiting');
                      bool isGeneratingThis = _generatingTestName == item['name'];

                      bool isPersonalityTest = item['name'].contains('VAK') || item['name'].contains('RIASEC') || item['name'].contains('MBTI') || item['name'].contains('Kepribadian');

                      String displayTestName = getLocalizedTestLabel(item['name'], context.locale.languageCode);

                      String subtitleText = isPersonalityTest
                          ? (item['code'] != "" ? '${'profile.label_type'.tr()}: ${item['code']}' : 'profile.waiting_analysis'.tr())
                          : 'profile.score_correct'.tr(args: [item['score'].toString(), item['total'].toString()]);

                      return Card(
                        elevation: 1, margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            key: PageStorageKey(item['name']),
                            leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Text('${(item['percentage'] * 100).toInt()}%', style: TextStyle(color: Colors.blue.shade900, fontSize: 11, fontWeight: FontWeight.bold))),
                            title: Text(displayTestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(subtitleText, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                                  child: isWaitingAI
                                      ? Column(
                                    children: [
                                      const Icon(Icons.lock_outline, color: Colors.grey, size: 30),
                                      const SizedBox(height: 5),
                                      Text('profile.ai_locked'.tr(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 10),
                                      isGeneratingThis
                                          ? Column(
                                        children: [
                                          const CircularProgressIndicator(color: Colors.orange),
                                          const SizedBox(height: 10),
                                          Text('profile.ai_analyzing'.tr(), style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                          : ElevatedButton.icon(
                                        onPressed: () {
                                          RewardedAdManager.showAd(context, () {
                                            _generateAIFromProfile(item['name'], item['score'], item['total'], item['code']);
                                          });
                                        },
                                        icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                                        label: Text('profile.btn_watch_analyze'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                      )
                                    ],
                                  )
                                      : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildTraitBubbles(item['analysis'], isPersonalityTest ? Colors.green : Colors.blue),
                                      MarkdownBody(
                                        data: item['analysis'],
                                        styleSheet: MarkdownStyleSheet(
                                            p: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.6),
                                            strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                            listBullet: const TextStyle(color: Color(0xFF0D47A1), fontSize: 14)
                                        ),
                                      ),
                                      const SizedBox(height: 15),

                                      Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              Share.share('profile.share_regular_text'.tr(args: [displayTestName, subtitleText, item['analysis']]));
                                            },
                                            icon: const Icon(Icons.share, size: 16, color: Color(0xFF0D47A1)),
                                            label: Text('profile.btn_share_analysis'.tr(), style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 12)),
                                          )
                                      )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  if (!_showAllHistory && hasMore)
                    TextButton(
                      onPressed: () {
                        setState(() => _showAllHistory = true);
                      },
                      child: Text('profile.btn_view_all'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    ),
                ],

                const SizedBox(height: 10),

                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _showPrivacyPolicyDialog,
                      child: Text('profile.privacy_title'.tr(), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    const Text('•', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    TextButton(
                      onPressed: _showDisclaimerDialog,
                      child: Text('profile.disclaimer_title'.tr(), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}