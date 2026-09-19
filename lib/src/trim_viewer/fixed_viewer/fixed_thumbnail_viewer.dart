import 'dart:io';
import 'package:flutter/material.dart';
import '../../trimmer.dart';

class FixedThumbnailViewer extends StatelessWidget {
  final Trimmer trimmer;
  final double appViewerHeight;
  final double appViewerWidth;
  final File? videoFile;
  final int? videoDuration;
  final BoxFit? fit;

  const FixedThumbnailViewer({
    super.key,
    required this.trimmer,
    required this.appViewerHeight,
    required this.appViewerWidth,
    this.videoFile,
    this.videoDuration,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: appViewerWidth,
      height: appViewerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: Colors.white38, size: 24),
      ),
    );
  }
}
