import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:easy_localization/easy_localization.dart'; // BARU: Untuk terjemahan
import '../helpers/database_helper.dart';
import '../services/auth_service.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';

class ChatAiScreen extends StatefulWidget {
  const ChatAiScreen({super.key});

  @override
  State<ChatAiScreen> createState() => _ChatAiScreenState();
}

class _ChatAiScreenState extends State<ChatAiScreen> {
  int _coins = 3;
  final int _costPerQuestion = 1;
  final int _rewardPerAd = 2;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isInitReady = false;

  String _systemInstruction = "";
  List<Map<String, dynamic>> _apiHistory = [];
  final String _proxyUrl = "https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash-lite";
  final String _appSecret = "CLARA_RAHASIA_123_SUPER_AMAN";

  String _userName = ""; // Dikosongkan sementara untuk diisi di inisialisasi

  @override
  void initState() {
    super.initState();
    _initializeApp();
    AuthService.refreshTrigger.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    AuthService.refreshTrigger.removeListener(_onRefreshTriggered);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onRefreshTriggered() {
    if (mounted) {
      setState(() => _isInitReady = false);
      _initializeApp();
    }
  }

  String _getIqCategory(int iq) {
    if (iq >= 130) return 'chat_ai.iq_genius'.tr();
    if (iq >= 120) return 'chat_ai.iq_superior'.tr();
    if (iq >= 110) return 'chat_ai.iq_above_avg'.tr();
    if (iq >= 90) return 'chat_ai.iq_avg'.tr();
    return 'chat_ai.iq_below_avg'.tr();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _coins = prefs.getInt('ai_coins') ?? 3;
      _userName = prefs.getString('user_name') ?? 'chat_ai.default_username'.tr();
    });

    final testResults = await DatabaseHelper.instance.getAllTestResults();
    String testContext = 'chat_ai.ctx_intro'.tr();

    if (testResults.isEmpty) {
      testContext += 'chat_ai.ctx_no_test'.tr();
    } else {
      // --- FIX 1: FILTER CERDAS (KOGNITIF vs KEPRIBADIAN) ---
      Map<String, Map<String, dynamic>> highestData = {};

      for (var result in testResults) {
        String name = result['test_name'];
        int currentScore = result['score'] ?? 0;
        int currentId = result['id'] ?? 0;

        bool isNewBest = false;

        if (!highestData.containsKey(name)) {
          isNewBest = true;
        } else {
          bool isPersonality = name.contains('VAK') || name.contains('RIASEC') || name.contains('MBTI') || name.contains('Kepribadian') || name.contains('Wartegg') || name.contains('EQ') || name.contains('SQ');

          if (isPersonality) {
            // KHUSUS KEPRIBADIAN: Wajib ambil ID TERBARU (Mencegah nyangkut di data kuno)
            if (currentId >= (highestData[name]!['id'] as int)) {
              isNewBest = true;
            }
          } else {
            // KHUSUS KOGNITIF: Ambil Skor TERTINGGI
            if (currentScore > (highestData[name]!['score'] as int)) {
              isNewBest = true;
            } else if (currentScore == (highestData[name]!['score'] as int) && currentId > (highestData[name]!['id'] as int)) {
              isNewBest = true; // Jika skor seri, ambil yang terbaru
            }
          }
        }

        if (isNewBest) {
          highestData[name] = result;
        }
      }

      int totalCognitiveCorrect = 0;
      int totalCognitiveQuestions = 0;
      int iqProScore = 0;

      String characterContext = "";
      String cognitiveRawContext = "";

      highestData.forEach((testName, result) {
        String rawAnalysis = result['ai_analysis'] ?? "";
        bool hasValidAnalysis = rawAnalysis.isNotEmpty && !rawAnalysis.contains('Menunggu');

        // 1. Tes Proyektif (Wartegg)
        if (testName.toLowerCase().contains('wartegg')) {
          if (hasValidAnalysis) {
            characterContext += 'chat_ai.ctx_projective'.tr(args: [testName]);
          }
        }
        // 2. Tes IQ PRO (Dukung nama English)
        else if (testName.contains('Komprehensif (PRO)') || testName.contains('Comprehensive IQ')) {
          iqProScore = result['score'] as int? ?? 0;
        }
        // 3. Sub-tes Kognitif Reguler (Dukung nama English agar IQ Reguler tidak hilang)
        else if (testName.contains('Verbal') || testName.contains('Analogy') ||
            testName.contains('Deret') || testName.contains('Sequence') ||
            testName.contains('Logis') || testName.contains('Reasoning') ||
            testName.contains('Spasial') || testName.contains('Spatial') || testName.contains('Image') ||
            testName.contains('Klasifikasi') || testName.contains('Classification') ||
            testName.contains('Silogisme') || testName.contains('Syllogism')) {

          int score = result['score'] ?? 0;
          int total = result['total_questions'] ?? 1;

          if (!testName.contains('PRO')) {
            totalCognitiveCorrect += score;
            totalCognitiveQuestions += total;
          }

          cognitiveRawContext += 'chat_ai.ctx_cognitive_raw'.tr(args: [testName, score.toString(), total.toString()]);
        }
        // 4. Tes Lainnya (Sapu Jagat: MBTI, EQ, SQ, VAK, RIASEC)
        else {
          String dominantCode = "";
          bool isPersonality = testName.contains('VAK') || testName.contains('RIASEC') || testName.contains('MBTI') || testName.contains('Kepribadian') || testName.contains('EQ') || testName.contains('SQ');

          RegExp regExp = RegExp(r'\[KODE:\s*(.*?)\]');
          var match = regExp.firstMatch(rawAnalysis);

          if (match != null) {
            // Jika ada kode rahasia, ekstrak dengan benar
            if (testName.contains('EQ') || testName.contains('SQ')) {
              dominantCode = 'Skor: ${result['score']} (${match.group(1)!})';
            } else {
              dominantCode = match.group(1)!; // MBTI akan masuk ke sini (misal: INTJ)
            }
          } else {
            // --- FIX 2: PENYELAMAT JIKA REGEX GAGAL / DATA KUNO ---
            if (isPersonality) {
              // Jangan pernah tampilkan "Completed Score 100" untuk tes kepribadian!
              if (testName.contains('MBTI')) {
                // Coba sedot paksa 4 huruf kapital dari teks jika format [KODE:] hilang
                RegExp mbtiBackup = RegExp(r'\b(INTJ|INTP|ENTJ|ENTP|INFJ|INFP|ENFJ|ENFP|ISTJ|ISFJ|ESTJ|ESFJ|ISTP|ISFP|ESTP|ESFP)\b');
                var backupMatch = mbtiBackup.firstMatch(rawAnalysis);
                if (backupMatch != null) {
                  dominantCode = backupMatch.group(1)!;
                } else {
                  dominantCode = "Selesai (Karakter Tersimpan)";
                }
              } else {
                dominantCode = "Selesai (Karakter Tersimpan)";
              }
            } else {
              // Tes lain yang memang butuh skor angka
              dominantCode = 'chat_ai.ctx_done_score'.tr(args: [result['score'].toString()]);
            }
          }

          characterContext += 'chat_ai.ctx_test_result'.tr(args: [testName, dominantCode]);
        }
      });

      // Kalkulasi IQ Reguler
      int iqReguler = 0;
      if (totalCognitiveQuestions > 0) {
        double pct = totalCognitiveCorrect / totalCognitiveQuestions;
        iqReguler = 70 + (pct * 70).round();
      }

      // Susun Konteks Kognitif
      if (iqReguler > 0 || iqProScore > 0) {
        testContext += 'chat_ai.ctx_iq_header'.tr();
        if (iqReguler > 0) {
          testContext += 'chat_ai.ctx_iq_regular'.tr(args: [iqReguler.toString(), _getIqCategory(iqReguler)]);
        }
        if (iqProScore > 0) {
          testContext += 'chat_ai.ctx_iq_pro'.tr(args: [iqProScore.toString(), _getIqCategory(iqProScore)]);
        }
      }

      if (cognitiveRawContext.isNotEmpty) {
        testContext += 'chat_ai.ctx_cognitive_header'.tr() + "$cognitiveRawContext\n";
      }

      if (characterContext.isNotEmpty) {
        testContext += 'chat_ai.ctx_character_header'.tr() + "$characterContext\n";
      }
    }

    _messages.clear();
    _apiHistory.clear();

    final savedChats = await DatabaseHelper.instance.getChatHistory();

    if (savedChats.isEmpty) {
      String welcomeMsg = 'chat_ai.welcome_msg'.tr(args: [_userName]);

      _messages.add({'sender': 'ai', 'text': welcomeMsg});
      _apiHistory.add({"role": "model", "parts": [{"text": welcomeMsg}]});

    } else {
      for (var chat in savedChats) {
        String sender = chat['sender'];
        String text = chat['message'];

        if (sender == 'ai' &&
            (text.contains('Saya Smart AI') || text.contains('I am Smart AI')) &&
            (text.contains('rekam jejak') || text.contains('dibersihkan') || text.contains('track record') || text.contains('cleared'))) {
          continue;
        }

        _messages.add({'sender': sender, 'text': text});
        _apiHistory.add({
          "role": sender == 'user' ? "user" : "model",
          "parts": [{"text": text}]
        });
      }
    }

    _systemInstruction = 'chat_ai.sys_instruction'.tr(args: [_userName]) + testContext;

    setState(() {
      _isInitReady = true;
    });

    _scrollToBottom();
  }

  Future<void> _saveCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_coins', _coins);
  }

  void _showRewardedAd() {
    RewardedAdManager.showAd(context, () {
      if (!mounted) return;
      setState(() {
        _coins += _rewardPerAd;
      });
      _saveCoins();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('chat_ai.ad_reward_msg'.tr(args: [_rewardPerAd.toString()])), backgroundColor: Colors.green),
      );
    });
  }

  void _clearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('chat_ai.dialog_clear_title'.tr()),
        content: Text('chat_ai.dialog_clear_content'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('chat_ai.btn_cancel'.tr(), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);

              await DatabaseHelper.instance.clearChatHistory();
              await AuthService().clearServerChats();

              _messages.clear();

              String welcomeMsg = 'chat_ai.msg_cleared'.tr(args: [_userName]);

              setState(() {
                _messages.add({'sender': 'ai', 'text': welcomeMsg});
                _apiHistory = [{"role": "model", "parts": [{"text": welcomeMsg}]}];
                _isLoading = false;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('chat_ai.btn_delete'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_coins < _costPerQuestion) {
      _showOutOfCoinsDialog();
      return;
    }

    await DatabaseHelper.instance.insertChatMessage('user', text);
    setState(() {
      _coins -= _costPerQuestion;
      _messages.add({'sender': 'user', 'text': text});
      _isLoading = true;
    });

    _saveCoins();
    _messageController.clear();
    _scrollToBottom();

    try {
      _apiHistory.add({"role": "user", "parts": [{"text": text}]});

      List<Map<String, dynamic>> trimmedHistory = _apiHistory;
      if (trimmedHistory.length > 10) {
        trimmedHistory = trimmedHistory.sublist(trimmedHistory.length - 10);
      }

      final url = Uri.parse(_proxyUrl);
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_appSecret',
        },
        body: jsonEncode({
          "systemInstruction": {
            "parts": [{"text": _systemInstruction}]
          },
          "contents": trimmedHistory
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];

        await DatabaseHelper.instance.insertChatMessage('ai', aiText);
        setState(() {
          _messages.add({'sender': 'ai', 'text': aiText});
          _apiHistory.add({"role": "model", "parts": [{"text": aiText}]});
        });
      } else {
        print("ERROR DARI API: ${response.statusCode} - ${response.body}");
        throw Exception('Gagal dari server proxy');
      }
    } catch (e) {
      final errorText = 'chat_ai.msg_error'.tr();
      await DatabaseHelper.instance.insertChatMessage('ai', errorText);
      setState(() {
        _messages.add({'sender': 'ai', 'text': errorText});
        _coins += _costPerQuestion;
      });
      _saveCoins();
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
      AuthService().syncDataNow();
    }
  }

  void _showOutOfCoinsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.orange), const SizedBox(width: 8), Text('chat_ai.dialog_out_of_coins_title'.tr())]),
        content: Text('chat_ai.dialog_out_of_coins_content'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('chat_ai.btn_cancel'.tr(), style: const TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showRewardedAd();
            },
            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
            label: Text('chat_ai.btn_watch_ad'.tr(), style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('chat_ai.appbar_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: _clearChatDialog,
            tooltip: 'chat_ai.tooltip_clear'.tr(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: _showRewardedAd,
              icon: const Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
              label: Text('chat_ai.btn_add_coins'.tr(args: [_coins.toString()]), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]['sender'] == 'user';
                return _buildChatBubble(isUser, _messages[index]['text']);
              },
            ),
          ),

          if (_isLoading)
            const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Color(0xFF0D47A1))),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: const SafeArea(
              top: false,
              bottom: false,
              child: SizedBox(
                height: 60,
                child: Center(
                  child: CustomBannerAd(),
                ),
              ),
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'chat_ai.hint_input'.tr(),
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(color: Color(0xFF0D47A1), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : () => _sendMessage(),
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

  Widget _buildChatBubble(bool isUser, String text) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0D47A1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: isUser
            ? Text(text, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4))
            : MarkdownBody(
          data: text,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 14, color: Color(0xFF333333), height: 1.5),
            strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            listBullet: const TextStyle(color: Color(0xFF0D47A1), fontSize: 16),
          ),
        ),
      ),
    );
  }
}