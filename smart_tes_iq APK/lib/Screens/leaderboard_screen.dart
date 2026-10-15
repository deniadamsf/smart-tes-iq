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
  // Modal Petunjuk & Aturan Papan (Modern Sheet)
  // ===================================================================
  void _showRulesSheet(BuildContext context, String key) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: _brand, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'leaderboard.info_rules_title'.tr(),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRuleTile(
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFFEF6C00),
                title: 'leaderboard.rule_point_system_title'.tr(),
                desc: 'leaderboard.rule_point_system_desc'.tr(),
              ),
              const SizedBox(height: 10),
              _buildRuleTile(
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF2E7D32),
                title: 'leaderboard.rule_verification_title'.tr(),
                desc: 'leaderboard.rule_verification_desc'.tr(),
              ),
              const SizedBox(height: 10),
              _buildRuleTile(
                icon: Icons.lock_person_rounded,
                iconColor: const Color(0xFF1565C0),
                title: 'leaderboard.rule_privacy_title'.tr(),
                desc: 'leaderboard.rule_privacy_desc'.tr(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'leaderboard.btn_understand'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  // Rangka Utama
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'leaderboard.appbar_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, letterSpacing: -0.3),
        ),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showRulesSheet(context, _activeKey),
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'leaderboard.info_rules_title'.tr(),
          ),
          IconButton(
            onPressed: () => _openSettings(),
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'leaderboard.btn_set_name'.tr(),
          ),
          IconButton(
            onPressed: () => _load(_activeKey),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'leaderboard.btn_retry'.tr(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFFFB300),
          indicatorWeight: 3.2,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 16, color: Color(0xFFFFD54F)),
                  const SizedBox(width: 6),
                  Text('leaderboard.tab_top_daily'.tr()),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFFFFB74D)),
                  const SizedBox(width: 6),
                  Text('leaderboard.tab_daily'.tr()),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology_rounded, size: 16, color: Color(0xFF90CAF9)),
                  const SizedBox(width: 6),
                  Text('leaderboard.tab_reguler'.tr()),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFFFE082)),
                  const SizedBox(width: 6),
                  Text('leaderboard.tab_pro'.tr()),
                ],
              ),
            ),
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

    final String title = isTopDaily
        ? 'leaderboard.top_daily_title'.tr()
        : (isDaily
            ? 'leaderboard.daily_title'.tr()
            : (key == 'reguler'
                ? 'leaderboard.reguler_title'.tr()
                : 'leaderboard.pro_title'.tr()));

    final String subtitle = isTopDaily
        ? 'leaderboard.participants_top_daily'.tr(args: ['$peserta', '$totalDays'])
        : (isDaily
            ? 'leaderboard.participants'.tr(args: ['$peserta'])
            : 'leaderboard.participants_iq'.tr(args: ['$peserta']));

    final hasMyScore = me != null && (me['rank'] != null ||
        (isTopDaily && (me['total_points'] != null && (me['total_points'] as int) > 0)));

    return RefreshIndicator(
      onRefresh: () => _load(key),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. Ringkasan Kategori & Status Terverifikasi (Kompak & Elegan)
          _buildSummaryBar(key, title, subtitle, terverifikasi),

          // 2. Kartu Peringkat Saya (Desain Royal Gradient)
          if (hasMyScore)
            _buildMyRank(me, peserta, isDaily, isTopDaily, key, namaTampil, terverifikasi)
          else
            _buildNoScore(key),

          // 3. Catatan Sembunyi / Ganti Nama
          if (sembunyi) ...[
            _buildHiddenNote(),
            const SizedBox(height: 12),
          ] else if (namaOtomatis) ...[
            _buildJoinPrompt(namaTampil),
            const SizedBox(height: 12),
          ],

          // 4. Header Pemisah Daftar Peringkat
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Peringkat Teratas (${top.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          // 5. Daftar Baris Peringkat
          if (top.isEmpty)
            _buildEmpty()
          else
            ...top.map((e) => _buildRow(e as Map<String, dynamic>, key)),
        ],
      ),
    );
  }

  /// Baris Ringkasan Kompak di atas layar (menggantikan tumpukan teks disclaimer yang berantakan)
  Widget _buildSummaryBar(String key, String title, String subtitle, bool terverifikasi) {
    final isTopDaily = key == 'top_daily';
    final isDaily = key == 'daily';

    Color iconBg = isTopDaily
        ? const Color(0xFFFFF8E1)
        : (isDaily ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD));
    Color iconColor = isTopDaily
        ? _gold
        : (isDaily ? const Color(0xFFEF6C00) : _brand);

    IconData icon = isTopDaily
        ? Icons.emoji_events_rounded
        : (isDaily ? Icons.local_fire_department_rounded : Icons.psychology_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Status Chip (dapat diklik untuk membaca rincian aturan)
          InkWell(
            onTap: () => _showRulesSheet(context, key),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: terverifikasi ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: terverifikasi ? const Color(0xFFA5D6A7) : const Color(0xFFFFCC80),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    terverifikasi ? Icons.verified_rounded : Icons.info_outline_rounded,
                    size: 12,
                    color: terverifikasi ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    terverifikasi
                        ? 'leaderboard.verified_short'.tr()
                        : 'leaderboard.unverified_short'.tr(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: terverifikasi ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00),
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

  /// Format angka poin agar ringkas jika mencapai ribuan (misal 1.2K, 15K).
  static String formatPoints(int points) {
    if (points >= 1000000) {
      final val = points / 1000000;
      return '${val.toStringAsFixed(val >= 10 || val % 1 == 0 ? 0 : 1)}M';
    } else if (points >= 1000) {
      final val = points / 1000;
      return '${val.toStringAsFixed(val >= 10 || val % 1 == 0 ? 0 : 1)}K';
    }
    return '$points';
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

    final myPoints = (me['total_points'] as int? ?? 0);
    final detail = isTopDaily
        ? 'leaderboard.my_points_count'.tr(args: [formatPoints(myPoints)])
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

  /// Kartu Peringkat Saya (Desain Royal Gradient)
  Widget _buildMyRank(Map<String, dynamic> me, int peserta, bool isDaily,
      bool isTopDaily, String key, String nama, bool terverifikasi) {
    final myPoints = (me['total_points'] as int? ?? 0);
    final detail = isTopDaily
        ? 'leaderboard.my_points_count'.tr(args: [formatPoints(myPoints)])
        : (isDaily
            ? '${me['correct']}/${me['total']}  ·  ${(((me['duration_ms'] ?? 0) as int) / 1000).toStringAsFixed(1)}s  ·  IQ ${me['iq_harian']}'
            : 'IQ ${me['iq']}');

    final rankText = me['rank'] != null
        ? 'leaderboard.rank_of'.tr(args: ['${me['rank']}', '$peserta'])
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar profil saya
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                child: Text(
                  nama.trim().isNotEmpty ? nama.trim().substring(0, 1).toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'leaderboard.my_rank_title'.tr().toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rankText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (me['rank'] != null)
                Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: const CircleBorder(),
                  child: IconButton(
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(8),
                    onPressed: () =>
                        _openShare(me, peserta, isDaily, isTopDaily, key, nama, terverifikasi),
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                    tooltip: 'leaderboard.btn_share_rank'.tr(),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nama tampilan dengan tombol ganti
                InkWell(
                  onTap: () => _openSettings(),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.edit_rounded, color: Colors.white70, size: 13),
                      ],
                    ),
                  ),
                ),
                // Skor / Poin badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isTopDaily ? const Color(0xFFFFD54F) : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTopDaily
                            ? Icons.stars_rounded
                            : (isDaily ? Icons.timer_rounded : Icons.psychology_rounded),
                        size: 13,
                        color: isTopDaily ? const Color(0xFF6D4C41) : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        detail,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isTopDaily ? const Color(0xFF4E342E) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Desain Modern saat user belum memiliki skor
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (key == 'top_daily' || key == 'daily')
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (key == 'top_daily' || key == 'daily')
                      ? Icons.emoji_events_rounded
                      : Icons.psychology_rounded,
                  size: 20,
                  color: (key == 'top_daily' || key == 'daily') ? _gold : _brand,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4),
          ),
          if (key == 'daily' || key == 'top_daily') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyChallengeScreen()),
                  );
                  if (mounted) _reloadAll();
                },
                label: Text(
                  'leaderboard.btn_play_daily'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Catatan jika user menyembunyikan diri dari papan
  Widget _buildHiddenNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_off_outlined, size: 17, color: Color(0xFF475569)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'leaderboard.hidden_title'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'leaderboard.hidden_desc'.tr(),
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openSettings(),
              icon: const Icon(Icons.visibility_outlined, size: 17),
              label: Text('leaderboard.btn_show_again'.tr()),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ajakan mengganti nama jika masih memakai nama Google akun
  Widget _buildJoinPrompt(String namaOtomatis) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'leaderboard.not_joined_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF92400E)),
          ),
          const SizedBox(height: 3),
          Text(
            'leaderboard.not_joined_desc'.tr(args: [namaOtomatis]),
            style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.35),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openSettings(),
              icon: const Icon(Icons.badge_outlined, size: 17, color: Color(0xFF92400E)),
              label: Text(
                'leaderboard.btn_set_name'.tr(),
                style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCD34D)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Baris Peringkat Terpadu & Mewah
  Widget _buildRow(Map<String, dynamic> r, String key) {
    final isTopDaily = key == 'top_daily';
    final isDaily = key == 'daily';
    final rank = r['rank'] as int;
    final isMe = r['saya'] == true;
    final String name = (r['display_name'] ?? 'Peserta').toString();
    final String initial = name.trim().isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : '?';

    final sub = isDaily
        ? '${r['correct']}/${r['total']}  ·  ${(((r['duration_ms'] ?? 0) as int) / 1000).toStringAsFixed(1)}s'
        : (isTopDaily && r['last_win_date'] != null
            ? 'leaderboard.last_win'.tr(args: ['${r['last_win_date']}'])
            : null);

    final iq = isDaily ? r['iq_harian'] : r['iq'];
    final totalPoints = isTopDaily ? (r['total_points'] as int? ?? 0) : null;

    // Warna & border sesuai tier juara
    Color cardBg = isMe ? const Color(0xFFF0F7FF) : Colors.white;
    Color borderColor = isMe ? _brand : const Color(0xFFE2E8F0);
    double borderWidth = isMe ? 1.5 : 1.0;

    if (!isMe) {
      if (rank == 1) {
        cardBg = const Color(0xFFFFFDF7);
        borderColor = const Color(0xFFFFD54F);
        borderWidth = 1.2;
      } else if (rank == 2) {
        borderColor = const Color(0xFFCFD8DC);
      } else if (rank == 3) {
        borderColor = const Color(0xFFD7CCC8);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Badge Peringkat (Emas, Perak, Perunggu, atau Angka)
          _buildRankBadge(rank),

          const SizedBox(width: 10),

          // 2. Avatar Inisial Profil
          _buildAvatar(initial, rank),

          const SizedBox(width: 12),

          // 3. Nama Pemain & Detail Tambahan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13.5,
                          color: isMe ? _brand : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _brand,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'leaderboard.you'.tr(),
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 4. Badge Skor / Poin di sebelah kanan
          if (isTopDaily && totalPoints != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
              decoration: BoxDecoration(
                color: rank == 1
                    ? const Color(0xFFFFF8E1)
                    : (rank <= 3 ? Colors.orange.shade50 : const Color(0xFFE8EAF6)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: rank == 1
                      ? const Color(0xFFFFD54F)
                      : (rank <= 3 ? Colors.orange.shade200 : const Color(0xFFC5CAE9)),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: 14,
                    color: rank == 1
                        ? const Color(0xFFD4A017)
                        : (rank <= 3 ? _gold : _brand),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'leaderboard.points_badge'.tr(args: [formatPoints(totalPoints)]),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: rank == 1
                          ? const Color(0xFFB78103)
                          : (rank <= 3 ? const Color(0xFFBF360C) : _brand),
                    ),
                  ),
                ],
              ),
            )
          else if (isDaily && iq != null)
            // Untuk baris saya sendiri di tantangan harian: tampilkan IQ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Text(
                'IQ $iq',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _brand),
              ),
            )
          else if (!isDaily && iq != null)
            // Untuk baris saya sendiri di Reguler & PRO: tampilkan IQ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Text(
                'IQ $iq',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _brand),
              ),
            )
          else if (!isTopDaily)
            // Untuk pengguna lain di Reguler / PRO / Daily: TIDAK ADA gembok abu-abu yang merusak UI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'leaderboard.status_completed'.tr(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Badge Medali Peringkat
  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.white),
      );
    } else if (rank == 2) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          '2',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    } else if (rank == 3) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD7CCC8), Color(0xFFA1887F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          '3',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    } else {
      return SizedBox(
        width: 26,
        child: Text(
          '$rank',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }
  }

  /// Avatar Lingkaran Inisial
  Widget _buildAvatar(String initial, int rank) {
    Color bg;
    Color textColor;
    Color border;

    if (rank == 1) {
      bg = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFB78103);
      border = const Color(0xFFFFE082);
    } else if (rank == 2) {
      bg = const Color(0xFFECEFF1);
      textColor = const Color(0xFF455A64);
      border = const Color(0xFFCFD8DC);
    } else if (rank == 3) {
      bg = const Color(0xFFEFEBE9);
      textColor = const Color(0xFF5D4037);
      border = const Color(0xFFD7CCC8);
    } else {
      bg = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF475569);
      border = const Color(0xFFE2E8F0);
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'leaderboard.empty_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            'leaderboard.empty_desc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 12.5),
          ),
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
        icon = Icons.wifi_off_rounded;
        title = 'leaderboard.offline_title'.tr();
        desc = 'leaderboard.offline_desc'.tr();
        break;
      default:
        icon = Icons.error_outline_rounded;
        title = 'leaderboard.failed_title'.tr();
        desc = 'leaderboard.failed_desc'.tr();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.4, fontSize: 12.5),
            ),
            const SizedBox(height: 20),
            if (canRetry)
              ElevatedButton(
                onPressed: () => _load(key),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
