import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../helpers/share_card_helper.dart';

/// Pratinjau kartu peringkat sebelum dibagikan.
///
/// Kartunya sengaja DITAMPILKAN, bukan disembunyikan di luar layar:
/// RepaintBoundary hanya bisa ditangkap kalau widgetnya benar-benar
/// terender. Sekalian user melihat persis apa yang akan dia bagikan.
class RankShareSheet extends StatefulWidget {
  /// Judul papan, mis. "Tantangan Harian" atau "Top 100 IQ Reguler".
  final String boardTitle;

  final String displayName;
  final int rank;
  final int participants;
  final int iq;

  /// Baris detail opsional, mis. "4/5 benar · 32,1 detik".
  final String? detail;

  /// Apakah angkanya dinilai server. Hanya papan harian yang true.
  final bool verified;

  const RankShareSheet({
    super.key,
    required this.boardTitle,
    required this.displayName,
    required this.rank,
    required this.participants,
    required this.iq,
    this.detail,
    this.verified = false,
  });

  @override
  State<RankShareSheet> createState() => _RankShareSheetState();
}

class _RankShareSheetState extends State<RankShareSheet> {
  static const Color _brand = Color(0xFF0D47A1);
  static const Color _brand2 = Color(0xFF1976D2);
  static const Color _gold = Color(0xFFEF6C00);

  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);

    final ok = await ShareCardHelper.captureAndShare(
      key: _cardKey,
      fileName: 'peringkat_${widget.boardTitle}_${widget.rank}',
      // "Peringkat 13 dari 842" jauh lebih layak dibagikan daripada
      // "Peringkat 13" — jumlah peserta yang memberi angka itu arti.
      text: 'leaderboard.share_text'.tr(args: [
        '${widget.rank}',
        '${widget.participants}',
        widget.boardTitle,
      ]),
    );

    if (!mounted) return;
    setState(() => _sharing = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('leaderboard.share_failed'.tr())),
      );
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ---- kartu yang akan ditangkap ----
            RepaintBoundary(key: _cardKey, child: _buildCard()),

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _sharing ? null : () => Navigator.pop(context),
                    child: Text('leaderboard.btn_cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.share, size: 18),
                    label: Text('leaderboard.btn_share'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    // Format angka, BUKAN DateFormat berlokal: DateFormat('d MMMM yyyy','id')
    // melempar exception kalau data locale intl belum diinisialisasi, dan
    // itu akan menjatuhkan kartu berbagi hanya demi nama bulan.
    final now = DateTime.now();
    final tanggal = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_brand, _brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'home.app_title'.tr().toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            widget.boardTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),

          Text(
            widget.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Peringkat sebagai angka besar, dengan jumlah peserta di bawahnya.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('#',
                  style: TextStyle(
                      color: _gold, fontSize: 30, fontWeight: FontWeight.bold)),
              Text('${widget.rank}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 62,
                      height: 1,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Text(
            'leaderboard.of_participants'.tr(args: ['${widget.participants}']),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text('IQ ${widget.iq}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                if (widget.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(widget.detail!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.verified) ...[
                const Icon(Icons.verified, color: Colors.white54, size: 13),
                const SizedBox(width: 4),
                Text('leaderboard.verified_short'.tr(),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10.5)),
                const SizedBox(width: 8),
              ],
              Text(tanggal,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}
