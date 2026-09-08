import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../helpers/database_helper.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';

class FinalResultScreen extends StatefulWidget {
  const FinalResultScreen({super.key});

  @override
  State<FinalResultScreen> createState() => _FinalResultScreenState();
}

class _FinalResultScreenState extends State<FinalResultScreen> {
  bool _isLoadingDB = true;

  int _iqRegulerScore = 0;
  String _iqRegulerCategory = "";

  int _iqProScore = 0;
  String _iqProCategory = "";

  String _vakResult = "";
  String _riasecResult = "";
  String _mbtiResult = "";

  bool _isAiUnlocked = false;
  bool _isLoadingAI = false;
  String _aiAnalysis = "";

  bool _hasPromptedReview = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi nilai awal dengan nilai terjemahan
    _iqRegulerCategory = 'final_result.calculating'.tr();
    _iqProCategory = 'final_result.not_tested'.tr();
    _vakResult = 'final_result.not_tested'.tr();
    _riasecResult = 'final_result.not_tested'.tr();
    _mbtiResult = 'final_result.not_tested'.tr();

    _loadFinalData();
  }

  Future<void> _loadFinalData() async {
    final results = await DatabaseHelper.instance.getAllTestResults();

    Map<String, Map<String, dynamic>> latestData = {};

    for (var test in results) {
      String name = test['test_name'];
      if (name == 'Tes Wartegg (AI)') continue;

      int currentId = test['id'] ?? 0;
      int score = test['score'] ?? 0;
      int total = test['total_questions'] ?? 1;
      double percentage = total > 0 ? score / total : 0;

      if (!latestData.containsKey(name) || currentId > (latestData[name]!['id'] as int)) {
        latestData[name] = {
          'id': currentId,
          'score': score,
          'total': total,
          'percentage': percentage,
          'analysis': test['ai_analysis'] ?? "",
        };
      }
    }

    // 1. MENGHITUNG SKOR IQ REGULER
    int totalCognitiveCorrect = 0, totalCognitiveQuestions = 0;
    latestData.forEach((key, data) {
      // '(PRO)' SENGAJA dikecualikan. Sebelum ini, hasil tes PRO ikut
      // tercampur ke skor "IQ Reguler" karena contains('Deret') juga cocok
      // dengan 'Deret Angka (PRO)'. Akibatnya user yang membeli PRO diukur
      // pada dasar yang berbeda dari user gratis — tidak setara untuk
      // papan peringkat, dan salah label untuk skor pribadi.
      //
      // Diukur di produksi sebelum diubah: 6 user skornya bergeser (semua
      // NAIK, +2..+25) dan 7 user kehilangan IQ Reguler karena hanya
      // mengerjakan tes PRO. Ketujuhnya tetap punya skor IQ PRO, jadi tidak
      // ada yang berakhir tanpa skor.
      //
      // Rumus ini harus SAMA PERSIS dengan UserIqScore::kognitifGratis()
      // di backend, kalau tidak angka di aplikasi dan di papan berbeda.
      final bool kognitifGratis = !key.contains('(PRO)') &&
          (key.contains('Verbal') || key.contains('Deret') || key.contains('Logis') || key.contains('Spasial') || key.contains('Klasifikasi'));

      if (kognitifGratis) {
        totalCognitiveCorrect += data['score'] as int;
        totalCognitiveQuestions += data['total'] as int;
      }
    });

    if (totalCognitiveQuestions > 0) {
      double pct = totalCognitiveCorrect / totalCognitiveQuestions;
      _iqRegulerScore = 70 + (pct * 70).round();

      if (_iqRegulerScore >= 130) _iqRegulerCategory = 'final_result.iq_genius'.tr();
      else if (_iqRegulerScore >= 120) _iqRegulerCategory = 'final_result.iq_superior'.tr();
      else if (_iqRegulerScore >= 110) _iqRegulerCategory = 'final_result.iq_above_avg'.tr();
      else if (_iqRegulerScore >= 90) _iqRegulerCategory = 'final_result.iq_avg'.tr();
      else _iqRegulerCategory = 'final_result.iq_below_avg'.tr();
    }

    // 2. MEMBACA IQ PRO
    if (latestData.containsKey('Tes IQ Komprehensif (PRO)')) {
      _iqProScore = latestData['Tes IQ Komprehensif (PRO)']!['score'] as int;

      if (_iqProScore >= 130) _iqProCategory = 'final_result.iq_genius'.tr();
      else if (_iqProScore >= 120) _iqProCategory = 'final_result.iq_superior'.tr();
      else if (_iqProScore >= 110) _iqProCategory = 'final_result.iq_above_avg'.tr();
      else if (_iqProScore >= 90) _iqProCategory = 'final_result.iq_avg'.tr();
      else _iqProCategory = 'final_result.iq_below_avg'.tr();
    }

    // 3. MEMBACA VAK TERBARU
    if (latestData.containsKey('Gaya Belajar (VAK)')) {
      String rawVak = latestData['Gaya Belajar (VAK)']!['analysis'].toString();
      RegExp regExp = RegExp(r'\[KODE:\s*(.*?)\]');
      var match = regExp.firstMatch(rawVak);
      _vakResult = match != null ? match.group(1)! : 'final_result.done'.tr();
    }

    // 4. MEMBACA RIASEC TERBARU
    if (latestData.containsKey('Bakat Minat (RIASEC)')) {
      String rawRiasec = latestData['Bakat Minat (RIASEC)']!['analysis'].toString();
      RegExp regExp = RegExp(r'\[KODE:\s*(.*?)\]');
      var match = regExp.firstMatch(rawRiasec);
      _riasecResult = match != null ? match.group(1)! : 'final_result.done'.tr();
    }

    // 5. MEMBACA MBTI TERBARU
    String mbtiKey = latestData.keys.firstWhere((k) => k.contains('MBTI'), orElse: () => '');
    if (mbtiKey.isNotEmpty) {
      String rawMbti = latestData[mbtiKey]!['analysis'].toString();
      RegExp regExp = RegExp(r'\[KODE:\s*(.*?)\]');
      var match = regExp.firstMatch(rawMbti);
      _mbtiResult = match != null ? match.group(1)! : 'final_result.done'.tr();
    }

    setState(() => _isLoadingDB = false);
  }

  Future<void> _unlockFinalAI() async {
    RewardedAdManager.showAd(context, () async {
      setState(() => _isLoadingAI = true);
      try {
        final String proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash-lite";
        final String appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

        // PROMPT AI HOLISTIK BILINGUAL
        String proScoreText = _iqProScore > 0 ? '$_iqProScore ($_iqProCategory)' : 'final_result.not_tested'.tr();

        final String prompt = 'final_result.prompt_ai'.tr(args: [
          _iqRegulerScore.toString(),
          _iqRegulerCategory,
          proScoreText,
          _vakResult,
          _riasecResult,
          _mbtiResult
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
        } else {
          throw Exception('Status: ${response.statusCode}');
        }

      } catch (e) {
        setState(() => _isLoadingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('final_result.error_ai'.tr(args: [e.toString()]))));
      }
    });
  }

  Widget _buildProfileCard(IconData icon, MaterialColor color, String topLabel, String mainValue, String bottomLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.shade100)
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(topLabel, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 10), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(mainValue, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(bottomLabel, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDB) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1))));
    }

    return PopScope(
      canPop: _hasPromptedReview,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (!_hasPromptedReview) {
          setState(() {
            _hasPromptedReview = true;
          });

          try {
            final InAppReview inAppReview = InAppReview.instance;
            if (await inAppReview.isAvailable()) {
              await inAppReview.requestReview();
            }
          } catch (e) {}

          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text('final_result.appbar_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 20, bottom: 40),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D47A1),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text('final_result.header_regular'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(
                            '$_iqRegulerScore',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              _iqRegulerCategory,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_iqProScore > 0)
                      Container(width: 2, height: 80, color: Colors.white.withOpacity(0.2)),

                    if (_iqProScore > 0)
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text('final_result.header_pro'.tr(), style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$_iqProScore',
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 1),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.amber.shade800, borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                _iqProCategory,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('final_result.profile_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(child: _buildProfileCard(Icons.menu_book, Colors.blue, 'final_result.card_vak_title'.tr(), _vakResult, 'final_result.card_vak_desc'.tr())),
                        const SizedBox(width: 10),
                        Expanded(child: _buildProfileCard(Icons.work, Colors.green, 'final_result.card_riasec_title'.tr(), _riasecResult, 'final_result.card_riasec_desc'.tr())),
                        const SizedBox(width: 10),
                        Expanded(child: _buildProfileCard(Icons.groups, Colors.purple, 'final_result.card_mbti_title'.tr(), _mbtiResult, 'final_result.card_mbti_desc'.tr())),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Text('final_result.report_title'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade300, width: 2),
                        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: _isLoadingAI
                          ? const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: CircularProgressIndicator(color: Colors.orange)),
                      )
                          : _isAiUnlocked
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology, color: Colors.orange),
                              const SizedBox(width: 10),
                              Text('final_result.ai_conclusion'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()),

                          MarkdownBody(
                            data: _aiAnalysis,
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
                          const Icon(Icons.lock_outline, size: 50, color: Colors.grey),
                          const SizedBox(height: 15),
                          Text('final_result.ai_locked_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          Text(
                            'final_result.ai_locked_desc'.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _unlockFinalAI,
                              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                              label: Text('final_result.btn_unlock_ai'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
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
          child: const CustomBannerAd(),
        ),
      ),
    );
  }
}