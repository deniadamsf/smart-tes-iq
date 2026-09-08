import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../services/daily_challenge_service.dart';
import 'daily_challenge_screen.dart';

/// Papan peringkat harian.
///
/// Nama yang tampil di sini SELALU `display_name` pilihan user sendiri,
/// tidak pernah nama akun Google. User yang belum memilih nama tetap
/// dihitung peringkatnya tapi tidak dipajang — ikut serta harus lewat
/// persetujuan aktif, bukan default.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const Color _brand = Color(0xFF0D47A1);
  static const Color _gold = Color(0xFFEF6C00);

  bool _loading = true;
  String _errorCode = '';
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorCode = '';
    });

    final res = await DailyChallengeService.leaderboardDaily();
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (res['code'] == DailyChallengeService.ok) {
        _data = res['data'] as Map<String, dynamic>;
      } else {
        _errorCode = res['code'] as String;
      }
    });
  }

  // ===================================================================
  // Dialog nama tampilan
  // ===================================================================
  Future<void> _askDisplayName() async {
    final controller = TextEditingController(
      text: (_data['display_name'] ?? '') as String? ?? '',
    );
    String? errorText;
    var saving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text('leaderboard.join_title'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
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
            ],
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

                      final res = await DailyChallengeService.setDisplayName(
                          controller.text.trim());

                      if (res['code'] == DailyChallengeService.ok) {
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                        return;
                      }

                      // Pesan validasi dari server sudah ramah dan
                      // berbahasa Indonesia — tampilkan apa adanya.
                      final data = res['data'] as Map<String, dynamic>;
                      setLocal(() {
                        saving = false;
                        errorText = (data['message'] as String?) ??
                            'leaderboard.failed_desc'.tr();
                      });
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
      _load();
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
        title: Text('leaderboard.appbar_title'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'leaderboard.btn_retry'.tr(),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorCode.isNotEmpty) return _buildError();

    final top = (_data['top'] ?? []) as List<dynamic>;
    final me = _data['me'] as Map<String, dynamic>?;
    final participants = (_data['participants'] ?? 0) as int;
    final ikut = _data['ikut_papan'] == true;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text('leaderboard.daily_title'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text('leaderboard.participants'.tr(args: ['$participants']),
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 16),

          // Kartu posisi sendiri — selalu tampil walau di luar 20 besar.
          if (me != null) _buildMyRank(me, participants) else _buildNotPlayed(),

          if (me != null && !ikut) ...[
            const SizedBox(height: 10),
            _buildJoinPrompt(),
          ],

          const SizedBox(height: 20),
          if (top.isEmpty)
            _buildEmpty()
          else
            ...top.map((e) => _buildRow(e as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _buildMyRank(Map<String, dynamic> me, int participants) {
    final secs = ((me['duration_ms'] ?? 0) as int) / 1000;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _brand,
        borderRadius: BorderRadius.circular(12),
      ),
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
                  'leaderboard.rank_of'
                      .tr(args: ['${me['rank']}', '$participants']),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  '${me['correct']}/${me['total']}  ·  ${secs.toStringAsFixed(1)}s  ·  IQ ${me['iq_harian']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.emoji_events, color: Colors.white24, size: 44),
        ],
      ),
    );
  }

  Widget _buildNotPlayed() {
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
          Text('leaderboard.not_played_title'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text('leaderboard.not_played_desc'.tr(),
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _gold, foregroundColor: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DailyChallengeScreen()),
                );
                if (mounted) _load();
              },
              child: Text('leaderboard.btn_play'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinPrompt() {
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
          Text('leaderboard.not_joined_desc'.tr(),
              style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _askDisplayName,
              icon: const Icon(Icons.badge_outlined, size: 18),
              label: Text('leaderboard.btn_set_name'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> r) {
    final rank = r['rank'] as int;
    final isMe = r['saya'] == true;
    final secs = ((r['duration_ms'] ?? 0) as int) / 1000;

    Color medal(int n) {
      if (n == 1) return const Color(0xFFD4A017);
      if (n == 2) return const Color(0xFF8E9AAF);
      if (n == 3) return const Color(0xFFB07040);
      return Colors.grey.shade400;
    }

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
            width: 34,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: rank <= 3 ? 19 : 15,
                color: medal(rank),
              ),
            ),
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
                const SizedBox(height: 2),
                Text(
                  '${r['correct']}/${r['total']}  ·  ${secs.toStringAsFixed(1)}s',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'IQ ${r['iq_harian']}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: _brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, size: 52, color: Colors.grey.shade400),
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

  Widget _buildError() {
    late IconData icon;
    late String title;
    late String desc;
    var canRetry = true;

    switch (_errorCode) {
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
            Icon(icon, size: 60, color: Colors.grey.shade500),
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
                onPressed: _load,
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
