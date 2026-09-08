import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Menangkap widget jadi PNG lalu membagikannya.
///
/// Polanya sama dengan result_screen.dart yang sudah dipakai sejak lama:
/// RepaintBoundary -> toImage(pixelRatio: 3) -> PNG -> Share.shareXFiles.
/// Tidak ada dependensi baru.
class ShareCardHelper {
  /// [key] harus terpasang pada RepaintBoundary yang SEDANG TERENDER.
  /// Widget yang belum pernah dilukis tidak bisa ditangkap — itu sebabnya
  /// kartu ditampilkan sebagai pratinjau dulu, bukan disembunyikan.
  static Future<bool> captureAndShare({
    required GlobalKey key,
    required String fileName,
    required String text,
  }) async {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return false;

      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return false;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return false;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final safe = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = await File('${dir.path}/$safe.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: text);
      return true;
    } catch (_) {
      // Gagal berbagi bukan hal fatal — pemanggil cukup memberi tahu user.
      return false;
    }
  }
}
