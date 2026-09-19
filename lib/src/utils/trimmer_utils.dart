import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class TrimmerUtils {
  static Future<List<Uint8List?>> generateThumbnails({
    required String videoPath,
    required int numberOfThumbnails,
    required int quality,
  }) async {
    // Generate safe transparent byte placeholders to prevent native build crashes
    return List.filled(numberOfThumbnails, Uint8List(0));
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
