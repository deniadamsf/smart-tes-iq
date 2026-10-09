import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../services/daily_challenge_service.dart';
import 'daily_challenge_screen.dart';
import 'rank_share_sheet.dart';

/// Papan peringkat: Harian, IQ Reguler, IQ PRO.
///
/// Tiga hal yang tidak boleh berubah tanpa dipikir ulang:
///
/// 1. Semua peserta yang punya skor dipajang. Selama user belum memilih
///    nama sendiri, server memakai nama akun Google-nya dan menyalakan
///    `nama_otomatis` — layar ini wajib memberi jalan untuk menggantinya,
///    dan jalan itu harus selalu ada, bukan cuma saat pertama kali.
///
/// 2. Angka IQ orang lain TIDAK ADA di response, jadi tidak ada yang bisa
///    ditampilkan walau kodenya salah. Yang muncul di layar ini hanya
///    angka milik user sendiri: di kartu peringkatnya dan di kartu bagikan.
///
/// 3. Hanya papan Harian yang dinilai server dan karena itu tidak bisa
///    dipalsukan. Papan Reguler dan PRO memakai skor yang dihitung di
///    perangkat, dan layar ini mengatakannya terang-terangan ke user
///    lewat `terverifikasi` dari server.
class LeaderboardScreen extends StatefulWidget {
  final String initialKey;

  const LeaderboardScreen({super.key, this.initialKey = 'daily'});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _BoardState {
  bool loading = true;
  String error = '';
  Map<String, dynamic> data = {};
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color _brand = Color(0xFF0D47A1);
  static const Color _gold = Color(0xFFEF6C00);

  static const List<String> _keys = ['top_daily', 'daily', 'reguler', 'pro'];

  late final TabController _tabs;
  final Map<String, _BoardState> _state = {
    'top_daily': _BoardState(),
    'daily': _BoardState(),
    'reguler': _BoardState(),
    'pro': _BoardState(),
  };

  @override
  void initState() {
    super.initState();
    final initialIndex = _keys.contains(widget.initialKey)
        ? _keys.indexOf(widget.initialKey)
        : 1;
    _tabs = TabController(length: _keys.length, vsync: this, initialIndex: initialIndex);
    _tabs.addListener(_onTab);
    _load(_keys[initialIndex]);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTab);
    _tabs.dispose();
    super.dispose();
  }

  String get _activeKey => _keys[_tabs.index];

  /// Muat tab hanya saat pertama dibuka, bukan setiap kali digeser.
  void _onTab() {
    if (_tabs.indexIsChanging) return;
    final k = _activeKey;
    if (_state[k]!.data.isEmpty && _state[k]!.error.isEmpty) _load(k);
  }

  Future<void> _load(String key) async {
    setState(() {
      _state[key]!.loading = true;
      _state[key]!.error = '';
    });

    final res = key == 'top_daily'
        ? await DailyChallengeService.leaderboardTopDaily()
        : (key == 'daily'
            ? await DailyChallengeService.leaderboardDaily()
            : await DailyChallengeService.leaderboardIq(key));

    if (!mounted) return;
    setState(() {
      final st = _state[key]!;
      st.loading = false;
      if (res['code'] == DailyChallengeService.ok) {
        st.data = res['data'] as Map<String, dynamic>;
      } else {
        st.error = res['code'] as String;
      }
    });
  }

  /// Nama pilihan sendiri, dari papan mana pun yang sudah termuat.
  ///
  /// Null berarti user masih memakai nama akun Google. Dipakai untuk
  /// mengisi dialog ganti nama, termasuk saat dibuka dari tombol AppBar
  /// sebelum satu papan pun selesai dimuat.
  String? get _namaPilihan {
    for (final st in _state.values) {
      if (st.data.isNotEmpty) return st.data['display_name'] as String?;
    }
    return null;
  }

  /// Apakah user sedang menarik diri dari papan.
  bool get _sembunyi {
    for (final st in _state.values) {
      if (st.data.isNotEmpty) return st.data['sembunyi'] == true;
    }
    return false;
  }

  /// Nama tampilan berlaku untuk semua papan, jadi muat ulang semuanya.
  void _reloadAll() {
    for (final k in _state.keys) {
      _state[k]!.data = {};
      _state[k]!.error = '';
    }
    _load(_activeKey);
  }

  // ===================================================================
  // Dialog pengaturan papan: nama tampilan + tarik diri
  // ===================================================================

  /// Dua pengaturan ini dijadikan satu dialog karena keduanya menjawab
  /// pertanyaan yang sama — "apa yang orang lain lihat tentang saya".
  /// Memisahkannya membuat user yang tidak nyaman harus mencari dua kali.
  Future<void> _openSettings() async {
    final namaAwal = _namaPilihan ?? '';
    final sembunyiAwal = _sembunyi;

    final controller = TextEditingController(text: namaAwal);
    var sembunyi = sembunyiAwal;
    String? errorText;
    var saving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text('leaderboard.join_title'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('leaderboard.join_desc'.tr(),
                    style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLength: 24,
                  autofocus: true,
                  enabled: !saving,
                  decoration: InputDecoration(
                    labelText: 'leaderboard.name_hint'.tr(),
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                    helperText: 'leaderboard.name_rule'.tr(),
                    helperMaxLines: 2,
                  ),
                ),
                const Divider(height: 26),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: sembunyi,
                  activeThumbColor: _brand,
                  onChanged: saving
                      ? null
                      : (v) => setLocal(() => sembunyi = v),
                  title: Text('leaderboard.hide_title'.tr(),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text('leaderboard.hide_desc'.tr(),
                      style: const TextStyle(fontSize: 12, height: 1.35)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
              child: Text('leaderboard.btn_not_now'.tr()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _brand, foregroundColor: Colors.white),
              onPressed: saving
                  ? null
                  : () async {
                      setLocal(() {
                        saving = true;
                        errorText = null;
                      });

                      final namaBaru = controller.text.trim();

                      // Nama hanya dikirim kalau memang diisi dan berubah.
                      // Kalau tidak, user yang cuma mau menarik diri akan
                      // ditolak validasi "nama minimal 3 karakter".
                      if (namaBaru.isNotEmpty && namaBaru != namaAwal) {
                        final res =
                            await DailyChallengeService.setDisplayName(namaBaru);

                        if (res['code'] != DailyChallengeService.ok) {
                          // Pesan penolakan dari server sudah jelas dan
                          // berbahasa Indonesia — tampilkan apa adanya.
                          final data = res['data'] as Map<String, dynamic>;
                          setLocal(() {
                            saving = false;
                            errorText = (data['message'] as String?) ??
                                'leaderboard.failed_desc'.tr();
                          });
                          return;
                        }
                      }

                      if (sembunyi != sembunyiAwal) {
                        final res =
                            await DailyChallengeService.setSembunyi(sembunyi);

                        if (res['code'] != DailyChallengeService.ok) {
                          setLocal(() {
                            saving = false;
                            errorText = 'leaderboard.failed_desc'.tr();
                          });
                          return;
                        }
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    },
              child: Text(saving
                  ? 'leaderboard.saving'.tr()
                  : 'leaderboard.btn_join'.tr()),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('leaderboard.name_saved'.tr())),
      );
      _reloadAll();
    }
  }

  // ===================================================================
  // Rangka
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text('leaderboard.appbar_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        actions: [
          // Ganti nama harus bisa dijangkau kapan saja, juga sebelum user
          // punya skor di papan mana pun.
          IconButton(
            onPressed: () => _openSettings(),
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'leaderboard.btn_set_name'.tr(),
          ),
          IconButton(
            onPressed: () => _load(_activeKey),
            icon: const Icon(Icons.refresh),
            tooltip: 'leaderboard.btn_retry'.tr(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 16, color: Color(0xFFFFD54F)),
                  const SizedBox(width: 5),
                  Text('leaderboard.tab_top_daily'.tr()),
                ],
              ),
            ),
            Tab(text: 'leaderboard.tab_daily'.tr()),
            Tab(text: 'leaderboard.tab_reguler'.tr()),
            Tab(text: 'leaderboard.tab_pro'.tr()),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            _buildTab('top_daily'),
            _buildTab('daily'),
            _buildTab('reguler'),
            _buildTab('pro'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String key) {
    final st = _state[key]!;
    if (st.loading) return const Center(child: CircularProgressIndicator());
    if (st.error.isNotEmpty) return _buildError(st.error, key);

    final d = st.data;
    final top = (d['top'] ?? []) as List<dynamic>;
    final me = d['me'] as Map<String, dynamic>?;
    final peserta = (d['participants'] ?? 0) as int;
    final totalDays = (d['total_days'] ?? 0) as int;
    final namaOtomatis = d['nama_otomatis'] == true;
    final namaTampil = (d['nama_tampil'] as String?) ?? '';
    final sembunyi = d['sembunyi'] == true;
    final terverifikasi = d['terverifikasi'] == true;
    final isTopDaily = key == 'top_daily';
    final isDaily = key == 'daily';

    return RefreshIndicator(
      onRefresh: () => _load(key),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text(
            isTopDaily
                ? 'leaderboard.top_daily_title'.tr()
                : (isDaily
                    ? 'leaderboard.daily_title'.tr()
                    : (key == 'reguler'
                        ? 'leaderboard.reguler_title'.tr()
                        : 'leaderboard.pro_title'.tr())),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            isTopDaily
                ? 'leaderboard.participants_top_daily'.tr(args: ['$peserta', '$totalDays'])
                : (isDaily
                    ? 'leaderboard.participants'.tr(args: ['$peserta'])
                    : '${'leaderboard.participants_iq'.tr(args: ['$peserta'])} · ${key == 'reguler' ? 'leaderboard.reguler_desc'.tr() : 'leaderboard.pro_desc'.tr()}'),
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
          if (isTopDaily) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEF6C00), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'leaderboard.top_daily_notice'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5D4037),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          _buildTrustNote(terverifikasi),
          if (!isTopDaily) ...[
            const SizedBox(height: 6),
            _buildPrivacyNote(),
          ],
          const SizedBox(height: 14),

          if (me != null && (!isTopDaily || (me['total_wins'] != null && (me['total_wins'] as int) > 0)))
            _buildMyRank(me, peserta, isDaily, isTopDaily, key, namaTampil, terverifikasi)
          else
            _buildNoScore(key),

          // Kalau user menarik diri, itu keadaan yang paling perlu dia
          // ketahui — didahulukan daripada ajakan mengganti nama.
          if (sembunyi) ...[
            const SizedBox(height: 10),
            _buildHiddenNote(),
          ] else if (namaOtomatis) ...[
            // Ajakan mengganti nama muncul selama namanya masih diambil
            // dari akun Google, walau user belum punya skor di papan ini.
            const SizedBox(height: 10),
            _buildJoinPrompt(namaTampil),
          ],

          const SizedBox(height: 18),
          if (top.isEmpty)
            _buildEmpty()
          else
            ...top.map((e) => _buildRow(e as Map<String, dynamic>, key)),
        ],
      ),
    );
  }

  /// Kejujuran soal keandalan angka. Papan harian dinilai server; dua papan
  /// lain memakai skor dari perangkat dan bisa dipalsukan. User berhak tahu.
  Widget _buildTrustNote(bool terverifikasi) {
    final warna = terverifikasi ? const Color(0xFF1B6B4C) : Colors.orange.shade800;
    return Row(
      children: [
        Icon(terverifikasi ? Icons.verified_outlined : Icons.info_outline,
            size: 15, color: warna),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            terverifikasi
                ? 'leaderboard.verified'.tr()
                : 'leaderboard.unverified'.tr(),
            style: TextStyle(
                fontSize: 11.5, color: warna, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /// Angka IQ orang lain tidak dikirim server sama sekali. Ini dikatakan
  /// terang-terangan supaya user tidak takut skornya terpajang.
  Widget _buildPrivacyNote() {
    return Row(
      children: [
        Icon(Icons.lock_outline, size: 15, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'leaderboard.iq_private'.tr(),
            style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _openShare(Map<String, dynamic> me, int peserta, bool isDaily,
      bool isTopDaily, String key, String nama, bool terverifikasi) {
    final judul = isTopDaily
        ? 'leaderboard.top_daily_title'.tr()
        : (isDaily
            ? 'leaderboard.daily_title'.tr()
            : (key == 'reguler'
                ? 'leaderboard.reguler_title'.tr()
                : 'leaderboard.pro_title'.tr()));

    final detail = isTopDaily
        ? 'leaderboard.my_wins_count'.tr(args: ['${me['total_wins']}'])
        : (isDaily
            ? '${me['correct']}/${me['total']}  ·  ${(((me['duration_ms'] ?? 0) as int) / 1000).toStringAsFixed(1)}s'
            : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => RankShareSheet(
        boardTitle: judul,
        displayName: nama,
        rank: (me['rank'] ?? 0) as int,
        participants: peserta,
        iq: isTopDaily ? null : (isDaily ? me['iq_harian'] : me['iq']) as int?,
        detail: detail,
        verified: terverifikasi,
      ),
    );
  }

  Widget _buildMyRank(Map<String, dynamic> me, int peserta, bool isDaily,
      bool isTopDaily, String key, String nama, bool terverifikasi) {
    // Angka IQ sendiri tetap ditampilkan di sini. Yang disembunyikan
    // adalah angka orang lain, bukan angka user terhadap dirinya sendiri.
    final detail = isTopDaily
        ? 'leaderboard.my_wins_count'.tr(args: ['${me['total_wins']}'])
        : (isDaily
            ? '${me['correct']}/${me['total']}  ·  ${(((me['duration_ms'] ?? 0) as int) / 1000).toStringAsFixed(1)}s  ·  IQ ${me['iq_harian']}'
            : 'IQ ${me['iq']}');

    final rankText = me['rank'] != null
        ? 'leaderboard.rank_of'.tr(args: ['${me['rank']}', '$peserta'])
        : '-';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: _brand, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('leaderboard.my_rank_title'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  rankText,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (isTopDaily) ...[
                      const Icon(Icons.emoji_events, color: Color(0xFFFFD54F), size: 14),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        detail,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                // Nama yang benar-benar dilihat orang lain, sekaligus
                // pintu masuk untuk menggantinya.
                InkWell(
                  onTap: () => _openSettings(),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit,
                            color: Colors.white70, size: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (me['rank'] != null)
            IconButton(
              onPressed: () =>
                  _openShare(me, peserta, isDaily, isTopDaily, key, nama, terverifikasi),
              icon: const Icon(Icons.ios_share, color: Colors.white, size: 24),
              tooltip: 'leaderboard.btn_share_rank'.tr(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoScore(String key) {
    final title = key == 'top_daily'
        ? 'leaderboard.top_daily_no_wins_title'.tr()
        : (key == 'daily'
            ? 'leaderboard.not_played_title'.tr()
            : 'leaderboard.no_score_title'.tr());

    final desc = key == 'top_daily'
        ? 'leaderboard.top_daily_no_wins_desc'.tr()
        : (key == 'daily'
            ? 'leaderboard.not_played_desc'.tr()
            : (key == 'reguler'
                ? 'leaderboard.no_score_reguler'.tr()
                : 'leaderboard.no_score_pro'.tr()));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (key == 'top_daily') ...[
                const Icon(Icons.emoji_events_outlined, color: _gold, size: 22),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          if (key == 'daily' || key == 'top_daily') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 18),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _gold, foregroundColor: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DailyChallengeScreen()),
                  );
                  if (mounted) _reloadAll();
                },
                label: Text('leaderboard.btn_play_daily'.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Ditampilkan saat user menarik diri dari papan. Peringkat di kartu
  /// atas tetap ada — itu posisi seandainya dia tampil, dan hanya dia
  /// sendiri yang melihatnya.
  Widget _buildHiddenNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_off_outlined,
                  size: 17, color: Colors.grey.shade800),
              const SizedBox(width: 7),
              Expanded(
                child: Text('leaderboard.hidden_title'.tr(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('leaderboard.hidden_desc'.tr(),
              style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openSettings(),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text('leaderboard.btn_show_again'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  /// [namaOtomatis] adalah nama akun Google yang sedang dipakai server.
  /// Ditampilkan apa adanya supaya user tahu persis apa yang dilihat
  /// orang lain sebelum memutuskan menggantinya.
  Widget _buildJoinPrompt(String namaOtomatis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('leaderboard.not_joined_title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 3),
          Text('leaderboard.not_joined_desc'.tr(args: [namaOtomatis]),
              style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openSettings(),
              icon: const Icon(Icons.badge_outlined, size: 18),
              label: Text('leaderboard.btn_set_name'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> r, String key) {
    final isTopDaily = key == 'top_daily';
    final isDaily = key == 'daily';
    final rank = r['rank'] as int;
    final isMe = r['saya'] == true;

    Color medal(int n) {
      if (n == 1) return const Color(0xFFD4A017);
      if (n == 2) return const Color(0xFF8E9AAF);
      if (n == 3) return const Color(0xFFB07040);
      return Colors.grey.shade400;
    }

    final sub = isDaily
        ? '${r['correct']}/${r['total']}  ·  ${(((r['duration_ms'] ?? 0) as int) / 1000).toStringAsFixed(1)}s'
        : (isTopDaily && r['last_win_date'] != null
            ? 'leaderboard.last_win'.tr(args: ['${r['last_win_date']}'])
            : null);

    final iq = isDaily ? r['iq_harian'] : r['iq'];
    final totalWins = isTopDaily ? (r['total_wins'] as int? ?? 0) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? _brand.withValues(alpha: .06) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe ? _brand : Colors.grey.shade300,
          width: isMe ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: rank == 1 && isTopDaily
                ? const Icon(Icons.workspace_premium, color: Color(0xFFD4A017), size: 24)
                : Text('$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: rank <= 3 ? 19 : 15,
                        color: medal(rank))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe
                      ? '${r['display_name']} (${'leaderboard.you'.tr()})'
                      : '${r['display_name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14.5,
                    color: isMe ? _brand : Colors.black87,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ],
            ),
          ),
          if (isTopDaily)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: rank == 1 ? const Color(0xFFFFF8E1) : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rank == 1 ? const Color(0xFFFFD54F) : Colors.orange.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 15, color: rank == 1 ? const Color(0xFFD4A017) : _gold),
                  const SizedBox(width: 4),
                  Text(
                    'leaderboard.win_badge'.tr(args: ['$totalWins']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rank == 1 ? const Color(0xFFB78103) : const Color(0xFFBF360C),
                    ),
                  ),
                ],
              ),
            )
          else if (iq != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6)),
              child: Text('IQ $iq',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _brand)),
            )
          else
            Icon(Icons.lock_outline, size: 15, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, size: 50, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('leaderboard.empty_title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text('leaderboard.empty_desc'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(String code, String key) {
    late IconData icon;
    late String title;
    late String desc;
    var canRetry = true;

    switch (code) {
      case DailyChallengeService.needLogin:
        icon = Icons.account_circle_outlined;
        title = 'leaderboard.need_login_title'.tr();
        desc = 'leaderboard.need_login_desc'.tr();
        canRetry = false;
        break;
      case DailyChallengeService.offline:
        icon = Icons.wifi_off;
        title = 'leaderboard.offline_title'.tr();
        desc = 'leaderboard.offline_desc'.tr();
        break;
      default:
        icon = Icons.error_outline;
        title = 'leaderboard.failed_title'.tr();
        desc = 'leaderboard.failed_desc'.tr();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: Colors.grey.shade500),
            const SizedBox(height: 15),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            Text(desc,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4)),
            const SizedBox(height: 22),
            if (canRetry)
              ElevatedButton(
                onPressed: () => _load(key),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _brand, foregroundColor: Colors.white),
                child: Text('leaderboard.btn_retry'.tr()),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('leaderboard.btn_close'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
