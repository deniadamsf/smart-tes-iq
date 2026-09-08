import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';

import '../helpers/database_helper.dart';
import '../helpers/ad_helper.dart';
import '../helpers/rewarded_ad_manager.dart';
import '../services/daily_challenge_service.dart';
import 'leaderboard_screen.dart';

/// Tantangan IQ Harian.
///
/// Layar ini SENGAJA tidak tahu kunci jawaban. Ia mengirim indeks pilihan
/// ke server dan menerima skor jadi. Kalau suatu saat ada logika benar/salah
/// di file ini, berarti kunci sudah bocor ke HP dan papan peringkat tidak
/// bisa dipercaya lagi.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

enum _Phase { loading, intro, rules, playing, submitting, resultGate, result, blocked }

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  static const Color _brand = Color(0xFF0D47A1);

  /// Hanya untuk teks pengantar. Batas waktu yang berlaku tetap datang dari
  /// server lewat 'sisa_detik'; kalau TIME_LIMIT_SEC di backend berubah,
  /// angka ini ikut disesuaikan agar tidak membingungkan.
  static const int _menit = 15;

  // Model yang sama dipakai tujuh layar analisa lain di aplikasi ini.
  static const String _proxyUrl =
      'https://smarttesiq.cellanoma.my.id/public/gemini_proxy.php?model=gemini-2.5-flash-lite';
  static const String _appSecret = 'CLARA_RAHASIA_123_SUPER_AMAN';

  String _aiAnalysis = '';
  bool _loadingAi = false;
  bool _aiGagal = false;

  _Phase _phase = _Phase.loading;
  String _blockCode = DailyChallengeService.failed;

  List<dynamic> _questions = [];
  final Map<int, int> _answers = {}; // indeks soal -> indeks pilihan
  int _current = 0;

  Timer? _timer;
  int _secondsLeft = 0;

  Map<String, dynamic>? _result;
  int _streak = 0;
  bool _busy = false;
  bool _menyiapkanIklan = false;

  /// Untuk menggulirkan pita nomor ke soal yang sedang dibuka. Dengan 30
  /// soal, soal aktif akan keluar layar kalau pitanya tidak ikut bergeser.
  final ScrollController _pitaCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    RewardedAdManager.loadAd(); // siapkan sebelum user menekan tombol
    _loadIntro();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pitaCtrl.dispose();
    super.dispose();
  }

  /// Geser pita nomor supaya soal aktif selalu terlihat.
  void _gulirKePita(int index) {
    if (!_pitaCtrl.hasClients) return;
    const lebarItem = 46.0; // 38 lebar + 8 jarak
    final target = (index * lebarItem) - 100;
    _pitaCtrl.animateTo(
      target.clamp(0.0, _pitaCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _keSoal(int index) {
    setState(() => _current = index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _gulirKePita(index));
  }

  // ===================================================================
  // Pemuatan awal
  // ===================================================================
  Future<void> _loadIntro() async {
    final res = await DailyChallengeService.me();
    if (!mounted) return;

    if (res['code'] != DailyChallengeService.ok) {
      setState(() {
        _blockCode = res['code'];
        _phase = _Phase.blocked;
      });
      return;
    }

    final data = res['data'] as Map<String, dynamic>;
    setState(() {
      _streak = (data['streak'] ?? 0) as int;
      _phase = (data['sudah_main_hari_ini'] == true)
          ? _Phase.blocked
          : _Phase.intro;
      if (_phase == _Phase.blocked) {
        _blockCode = DailyChallengeService.alreadyDone;
      }
    });
  }

  // ===================================================================
  // Gerbang iklan -> mulai
  // ===================================================================
  Future<void> _gateStart() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _menyiapkanIklan = true;
    });

    // Tunggu iklan benar-benar siap. Tanpa ini, saat iklan belum termuat
    // gerbang langsung diteruskan dan iklannya tidak pernah tampil.
    final siap = await RewardedAdManager.ensureLoaded();
    if (!mounted) return;
    setState(() => _menyiapkanIklan = false);

    if (!siap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('daily.ad_unavailable'.tr())),
      );
      _tampilkanAturan();
      return;
    }

    RewardedAdManager.showAd(
      context,
      _tampilkanAturan,
      // Iklan tidak tersedia bukan salah user — tetap loloskan.
      // Kehilangan satu impresi jauh lebih murah daripada mengunci
      // user dari fiturnya.
      onUnavailable: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('daily.ad_unavailable'.tr())),
        );
        _tampilkanAturan();
      },
      onDismissed: () {
        if (mounted) setState(() => _busy = false);
      },
    );
  }

  /// Layar aturan muncul SETELAH iklan, sebelum soal dimuat.
  ///
  /// /daily/start sengaja belum dipanggil di sini: server menandai
  /// started_at saat endpoint itu diminta, jadi kalau dipanggil sekarang
  /// waktu membaca aturan akan memakan jatah waktu mengerjakan.
  void _tampilkanAturan() {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _phase = _Phase.rules;
    });
  }

  Future<void> _begin() async {
    final lang = context.locale.languageCode == 'en' ? 'en' : 'id';
    final res = await DailyChallengeService.start(lang);
    if (!mounted) return;

    setState(() => _busy = false);

    if (res['code'] == DailyChallengeService.alreadyDone) {
      final data = res['data'] as Map<String, dynamic>;
      _finishWithResult(data['result'] as Map<String, dynamic>?, gate: false);
      return;
    }

    if (res['code'] != DailyChallengeService.ok) {
      setState(() {
        _blockCode = res['code'];
        _phase = _Phase.blocked;
      });
      return;
    }

    final data = res['data'] as Map<String, dynamic>;
    setState(() {
      _questions = (data['questions'] ?? []) as List<dynamic>;
      _current = 0;
      _answers.clear();
      // Sisa waktu dari SERVER, bukan dihitung ulang di sini — kalau tidak,
      // menutup lalu membuka aplikasi akan mereset timer.
      // .toNum().toInt(), BUKAN `as int`: server pernah mengirim double
      // (bug Carbon 3), dan `as int` pada double membuat aplikasi crash.
      _secondsLeft =
          ((data['sisa_detik'] ?? data['time_limit_sec'] ?? 300) as num).toInt();
      _phase = _Phase.playing;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('daily.time_up'.tr())),
        );
        _submit();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  // ===================================================================
  // Kirim jawaban
  // ===================================================================
  Future<void> _confirmSubmit() async {
    if (_answers.length < _questions.length) {
      final go = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text('daily.msg_incomplete'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('daily.btn_check_again'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('daily.btn_send_anyway'.tr()),
            ),
          ],
        ),
      );
      if (go != true) return;
    }
    _submit();
  }

  Future<void> _submit() async {
    if (_phase == _Phase.submitting) return;
    _timer?.cancel();
    setState(() => _phase = _Phase.submitting);

    final answers = List<int?>.generate(
      _questions.length,
      (i) => _answers[i],
    );

    final res = await DailyChallengeService.submit(answers);
    if (!mounted) return;

    if (res['code'] == DailyChallengeService.ok ||
        res['code'] == DailyChallengeService.alreadyDone) {
      final data = res['data'] as Map<String, dynamic>;
      _finishWithResult(data['result'] as Map<String, dynamic>?);
      return;
    }

    setState(() {
      _blockCode = res['code'];
      _phase = _Phase.blocked;
    });
  }

  /// Simpan hasil ke cache lokal lalu masuk gerbang iklan.
  Future<void> _finishWithResult(Map<String, dynamic>? r, {bool gate = true}) async {
    if (r == null) {
      setState(() {
        _blockCode = DailyChallengeService.failed;
        _phase = _Phase.blocked;
      });
      return;
    }

    try {
      await DatabaseHelper.instance.saveDailyChallenge({
        'challenge_date': r['challenge_date'],
        'correct': r['correct'] ?? 0,
        'total': r['total'] ?? 0,
        'duration_ms': r['duration_ms'] ?? 0,
        'iq_harian': r['iq_harian'] ?? 70,
        'rank_today': r['rank_today'],
        'synced_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Gagal menyimpan cache lokal tidak boleh menghalangi user melihat
      // hasilnya — sumber kebenarannya tetap ada di server.
    }

    if (!mounted) return;
    setState(() => _result = r);

    if (gate) {
      setState(() => _phase = _Phase.resultGate);
    } else {
      _masukHasil();
    }
  }

  Future<void> _gateResult() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _menyiapkanIklan = true;
    });

    final siap = await RewardedAdManager.ensureLoaded();
    if (!mounted) return;
    setState(() => _menyiapkanIklan = false);

    if (!siap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('daily.ad_unavailable'.tr())),
      );
      setState(() => _busy = false);
      _masukHasil();
      return;
    }

    RewardedAdManager.showAd(
      context,
      () {
        if (mounted) {
          setState(() => _busy = false);
          _masukHasil();
        }
      },
      onUnavailable: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('daily.ad_unavailable'.tr())),
        );
        setState(() => _busy = false);
        _masukHasil();
      },
      onDismissed: () {
        if (mounted) setState(() => _busy = false);
      },
    );
  }

  /// Masuk ke layar hasil sekaligus meminta analisa AI.
  ///
  /// Analisa TIDAK digerbangi iklan terpisah: user sudah menonton satu iklan
  /// untuk membuka hasil ini. Menambah gerbang kedua di sini berlebihan.
  void _masukHasil() {
    setState(() => _phase = _Phase.result);
    _ambilAnalisaAi();
  }

  Future<void> _ambilAnalisaAi() async {
    final r = _result;
    if (r == null || _loadingAi || _aiAnalysis.isNotEmpty) return;

    setState(() {
      _loadingAi = true;
      _aiGagal = false;
    });

    try {
      final prompt = 'daily.prompt_ai'.tr(args: [
        '${r['total'] ?? 0}',
        '${r['correct'] ?? 0}',
        '${r['iq_harian'] ?? 0}',
        '${(((r['duration_ms'] ?? 0) as int) / 1000).round()}',
        '${r['rank_today'] ?? '-'}',
        '${r['participants'] ?? 0}',
      ]);

      final res = await http
          .post(
            Uri.parse(_proxyUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_appSecret',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final teks = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _aiAnalysis = teks.toString();
          _loadingAi = false;
        });
      } else {
        throw Exception('Status ${res.statusCode}');
      }
    } catch (_) {
      // Analisa gagal bukan hal fatal: skor sudah tersimpan di server.
      if (mounted) {
        setState(() {
          _loadingAi = false;
          _aiGagal = true;
        });
      }
    }
  }

  // ===================================================================
  // Tampilan
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text('daily.appbar_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: _buildBody()),
      // Banner melayang di bawah, sama seperti layar tes lain.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: const SafeArea(
          top: false,
          child: Center(child: CustomBannerAd()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator());
      case _Phase.submitting:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('daily.result_saving'.tr()),
            ],
          ),
        );
      case _Phase.intro:
        return _buildIntro();
      case _Phase.rules:
        return _buildRules();
      case _Phase.playing:
        return _buildPlaying();
      case _Phase.resultGate:
        return _buildResultGate();
      case _Phase.result:
        return _buildResult();
      case _Phase.blocked:
        return _buildBlocked();
    }
  }

  Widget _buildIntro() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 72, color: _brand),
            const SizedBox(height: 20),
            Text('daily.intro_title'.tr(),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: _brand)),
            const SizedBox(height: 10),
            Text(
              'daily.intro_desc'.tr(args: ['$_menit']),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              'daily.intro_note'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            if (_streak > 0) ...[
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🔥 ${'daily.streak'.tr(args: ['$_streak'])}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900),
                ),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _gateStart,
                icon: _menyiapkanIklan
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_circle_outline),
                label: Text(_menyiapkanIklan
                    ? 'daily.ad_preparing'.tr()
                    : 'daily.btn_watch_start'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text('daily.btn_later'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRules() {
    const nomor = ['rules_1', 'rules_2', 'rules_3', 'rules_4', 'rules_5', 'rules_6'];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_outlined, color: _brand, size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('daily.rules_title'.tr(),
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: _brand)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...List.generate(nomor.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _brand.withValues(alpha: .1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _brand)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('daily.${nomor[i]}'.tr(),
                              style: const TextStyle(
                                  fontSize: 14, height: 1.45, color: Colors.black87)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      // Kunci tombol selama permintaan ke server berjalan,
                      // supaya tidak tertekan dua kali.
                      setState(() => _busy = true);
                      _begin();
                    },
              icon: _busy
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.timer_outlined),
              label: Text('daily.btn_start_now'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaying() {
    if (_questions.isEmpty) return _buildBlocked();

    final q = _questions[_current] as Map<String, dynamic>;
    final options = (q['options'] ?? []) as List<dynamic>;
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final urgent = _secondsLeft <= 30;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'daily.question_of'
                    .tr(args: ['${_current + 1}', '${_questions.length}']),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 17,
                      color: urgent ? Colors.red : Colors.black54),
                  const SizedBox(width: 5),
                  Text(
                    '$minutes:$seconds',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: urgent ? Colors.red : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: (_current + 1) / _questions.length,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(_brand),
          minHeight: 3,
        ),

        // ==========================================
        // PITA NOMOR SOAL
        // ==========================================
        // Dengan 30 soal, tanpa pita ini user tidak punya cara tahu nomor
        // mana yang terlewat. Hijau = sudah dijawab, abu-abu = belum.
        Container(
          height: 54,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListView.builder(
            controller: _pitaCtrl,
            scrollDirection: Axis.horizontal,
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final terjawab = _answers.containsKey(index);
              final aktif = _current == index;

              return GestureDetector(
                onTap: () => _keSoal(index),
                child: Container(
                  width: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: aktif
                        ? _brand
                        : (terjawab ? const Color(0xFF1B6B4C) : Colors.grey.shade200),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: aktif ? const Color(0xFFEF6C00) : Colors.transparent,
                      width: aktif ? 2 : 0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: aktif || terjawab ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (q['image'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      q['image'] as String,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                    ),
                  ),
                if (q['question'] != null) ...[
                  if (q['image'] != null) const SizedBox(height: 14),
                  Text(
                    q['question'] as String,
                    style: const TextStyle(
                        fontSize: 17, height: 1.45, color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 18),
                ...List.generate(options.length, (i) {
                  final selected = _answers[_current] == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: InkWell(
                      onTap: () => setState(() => _answers[_current] = i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? _brand.withValues(alpha: .08) : Colors.white,
                          border: Border.all(
                            color: selected ? _brand : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          options[i].toString(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? _brand : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Row(
            children: [
              if (_current > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _keSoal(_current - 1),
                    child: Text('daily.btn_prev'.tr()),
                  ),
                ),
              if (_current > 0) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    if (_current < _questions.length - 1) {
                      _keSoal(_current + 1);
                    } else {
                      _confirmSubmit();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_current < _questions.length - 1
                      ? 'daily.btn_next'.tr()
                      : 'daily.btn_finish'.tr()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock, size: 64, color: _brand),
            const SizedBox(height: 18),
            Text(
              'daily.result_title'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _gateResult,
                icon: _menyiapkanIklan
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.ondemand_video),
                label: Text(_menyiapkanIklan
                    ? 'daily.ad_preparing'.tr()
                    : 'daily.btn_watch_result'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            // Jawaban sudah tersimpan di server sebelum gerbang ini, jadi
            // keluar di sini tidak menghilangkan hasil apa pun.
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: Text('daily.btn_later'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final r = _result ?? {};
    final correct = r['correct'] ?? 0;
    final total = r['total'] ?? 0;
    final iq = r['iq_harian'] ?? 70;
    final rank = r['rank_today'];
    final participants = r['participants'] ?? 0;
    final secs = ((r['duration_ms'] ?? 0) as int) ~/ 1000;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text('daily.result_title'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 26),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('$iq',
                    style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('daily.result_iq'.tr(),
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statBox('daily.result_correct'.tr(), '$correct/$total'),
              const SizedBox(width: 12),
              _statBox('daily.result_time'.tr(), '${secs}s'),
            ],
          ),
          if (rank != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '🏆 ${'daily.result_rank'.tr(args: ['$rank', '$participants'])}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _buildAnalisaAi(),

          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              ),
              icon: const Icon(Icons.leaderboard),
              label: Text('leaderboard.appbar_title'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('daily.btn_close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalisaAi() {
    if (_loadingAi) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('daily.ai_loading'.tr(),
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
            ),
          ],
        ),
      );
    }

    if (_aiGagal) {
      return Text('daily.ai_failed'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: Colors.black45));
    }

    if (_aiAnalysis.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: _brand),
              const SizedBox(width: 7),
              Text('daily.ai_title'.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: _brand)),
            ],
          ),
          const SizedBox(height: 10),
          MarkdownBody(
            data: _aiAnalysis,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 13.5, height: 1.5, color: Colors.black87),
              strong: const TextStyle(fontWeight: FontWeight.bold, color: _brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: _brand)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildBlocked() {
    late IconData icon;
    late String title;
    late String desc;
    var canRetry = true;

    switch (_blockCode) {
      case DailyChallengeService.needLogin:
        icon = Icons.account_circle_outlined;
        title = 'daily.need_login_title'.tr();
        desc = 'daily.need_login_desc'.tr();
        canRetry = false;
        break;
      case DailyChallengeService.offline:
        icon = Icons.wifi_off;
        title = 'daily.offline_title'.tr();
        desc = 'daily.offline_desc'.tr();
        break;
      case DailyChallengeService.alreadyDone:
        icon = Icons.check_circle_outline;
        title = 'daily.already_title'.tr();
        desc = 'daily.already_desc'.tr();
        canRetry = false;
        break;
      default:
        icon = Icons.error_outline;
        title = 'daily.failed_title'.tr();
        desc = 'daily.failed_desc'.tr();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 62, color: Colors.grey.shade500),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4)),
            const SizedBox(height: 24),
            if (canRetry)
              ElevatedButton(
                onPressed: () {
                  setState(() => _phase = _Phase.loading);
                  _loadIntro();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                ),
                child: Text('daily.btn_retry'.tr()),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('daily.btn_close'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
