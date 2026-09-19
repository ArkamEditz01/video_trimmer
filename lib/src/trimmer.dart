import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

enum TrimmerEvent { initialized }

class Trimmer {
  File? currentVideoFile;
  VideoPlayerController? videoPlayerController;

  final StreamController<TrimmerEvent> _eventStreamController =
      StreamController<TrimmerEvent>.broadcast();

  Stream<TrimmerEvent> get eventStream => _eventStreamController.stream;

  VideoPlayerController? get videoPlayerControllerRef => videoPlayerController;

  Future<void> loadVideo({required File videoFile}) async {
    currentVideoFile = videoFile;
    if (videoPlayerController != null) {
      await videoPlayerController!.dispose();
    }
    videoPlayerController = VideoPlayerController.file(currentVideoFile!);
    await videoPlayerController!.initialize();
    _eventStreamController.add(TrimmerEvent.initialized);
  }

  Future<bool> videoPlaybackControl({
    required double startValue,
    required double endValue,
  }) async {
    if (videoPlayerController == null || !videoPlayerController!.value.isInitialized) {
      return false;
    }
    if (videoPlayerController!.value.isPlaying) {
      await videoPlayerController!.pause();
      return false;
    } else {
      if (videoPlayerController!.value.position.inMilliseconds >= endValue.toInt()) {
        await videoPlayerController!.seekTo(Duration(milliseconds: startValue.toInt()));
      }
      await videoPlayerController!.play();
      return true;
    }
  }

  Future<void> saveTrimmedVideo({
    required double startValue,
    required double endValue,
    required Function(String? outputPath) onSave,
    bool ffmpegCommand = false,
    String? customVideoFormat,
  }) async {
    if (currentVideoFile == null) {
      onSave(null);
      return;
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath =
          '${tempDir.path}/trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await currentVideoFile!.copy(outputPath);
      onSave(outputPath);
    } catch (e) {
      debugPrint("Error exporting video: $e");
      onSave(null);
    }
  }

  void dispose() {
    _eventStreamController.close();
    videoPlayerController?.dispose();
  }
}
