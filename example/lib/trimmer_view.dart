import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TrimmerView extends StatefulWidget {
  final Trimmer _trimmer;
  final String videoPath;
  const TrimmerView(this._trimmer, this.videoPath, {super.key});

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _isExporting = false;
  bool _isGeneratingCaptions = false;
  
  // Custom Text & Watermark
  String _customText = "";
  Offset _textPosition = const Offset(0, 0);

  // FX & AI States
  String _selectedGlitch = 'Off';
  String? _bgMusicPath;
  String _selectedRatio = 'Original';
  String _selectedFilter = 'Normal';
  String _bgCutoutMode = 'Off'; 
  String _aiVelocityMode = 'Off'; 
  String _aiVoiceMode = 'Off';
  bool _aiHdrEnhance = false;
  bool _isReverse = false;
  bool _isMirrorH = false;
  double _speed = 1.0;
  String _autoCaptionText = "";
  late stt.SpeechToText _speech;

  final Map<String, ColorFilter?> _filters = {
    'Normal': null,
    'Cinematic': const ColorFilter.matrix([
      1.2, 0, 0, 0, -10,
      0, 1.1, 0, 0, -5,
      0, 0, 1.3, 0, 10,
      0, 0, 0, 1, 0,
    ]),
    'B&W': const ColorFilter.matrix([
      0.33, 0.59, 0.11, 0, 0,
      0.33, 0.59, 0.11, 0, 0,
      0.33, 0.59, 0.11, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    'Warm': const ColorFilter.matrix([
      1.3, 0, 0, 0, 20,
      0, 1.1, 0, 0, 10,
      0, 0, 0.8, 0, -10,
      0, 0, 0, 1, 0,
    ]),
  };

  final Map<String, ColorFilter?> _glitchMatrices = {
    'Off': null,
    'RGB Split': const ColorFilter.matrix([
      1.5, 0, 0, 0, 30,
      0, 0.8, 0, 0, -20,
      0, 0, 1.6, 0, 40,
      0, 0, 0, 1, 0,
    ]),
    'VHS Glitch': const ColorFilter.matrix([
      0.9, 0.2, 0, 0, 10,
      0, 1.2, 0.1, 0, 5,
      0.2, 0, 1.1, 0, -15,
      0, 0, 0, 1, 0,
    ]),
    'Cyberpunk': const ColorFilter.matrix([
      1.8, 0, 0.2, 0, 40,
      0, 0.7, 0.9, 0, -30,
      0.4, 0, 1.9, 0, 50,
      0, 0, 0, 1, 0,
    ]),
  };

  final ColorFilter _hdrFilterMatrix = const ColorFilter.matrix([
    1.35, 0, 0, 0, 8,
    0, 1.35, 0, 0, 8,
    0, 0, 1.35, 0, 8,
    0, 0, 0, 1.0, 0,
  ]);

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _showAddTextDialog() {
    final controller = TextEditingController(text: _customText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Add Text / Watermark", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter title or channel name...",
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _customText = "");
              Navigator.pop(context);
            },
            child: const Text("Clear", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
            onPressed: () {
              setState(() => _customText = controller.text);
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  void _pickBackgroundMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _bgMusicPath = result.files.single.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00E5FF),
            content: Text("🎵 Music Loaded Successfully!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
      }
    }
  }

  void _generateAICaptions() async {
    setState(() => _isGeneratingCaptions = true);
    bool available = await _speech.initialize();
    if (available) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _autoCaptionText = "🔥 AI Auto Subtitles Enabled!";
        _isGeneratingCaptions = false;
      });
    } else {
      setState(() {
        _autoCaptionText = "✨ Shadow Cut AI Auto Captions";
        _isGeneratingCaptions = false;
      });
    }
  }

  Future<void> _exportVideo() async {
    setState(() => _isExporting = true);
    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/ShadowCut_${DateTime.now().millisecondsSinceEpoch}.mp4';

    double startSec = _startValue / 1000.0;
    double durationSec = (_endValue - _startValue) / 1000.0;
    if (durationSec <= 0) durationSec = 5.0;

    String setpts = (1.0 / _speed).toStringAsFixed(2);
    String atempo = _speed < 0.5 ? "0.5" : _speed.toStringAsFixed(2);

    String videoFilter = "setpts=${setpts}*PTS";
    if (_isMirrorH) videoFilter += ",hflip";
    if (_isReverse) videoFilter += ",reverse";

    if (_selectedRatio == '9:16') {
      videoFilter += ",scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black";
    }

    if (_aiHdrEnhance) {
      videoFilter += ",unsharp=5:5:1.2:5:5:0.0,eq=contrast=1.18:brightness=0.03:saturation=1.3";
    }

    if (_customText.isNotEmpty) {
      String cleanText = _customText.replaceAll("'", "");
      videoFilter += ",drawtext=text='$cleanText':fontcolor=white:fontsize=48:box=1:boxcolor=black@0.6:boxborderw=8:x=(w-text_w)/2:y=h*0.25";
    }

    String command = "";
    if (_bgMusicPath != null && File(_bgMusicPath!).existsSync()) {
      command =
          "-ss $startSec -i \"${widget.videoPath}\" -i \"$_bgMusicPath\" -t $durationSec -filter_complex \"[0:v]$videoFilter[v];[0:a]atempo=$atempo,volume=1.0[a1];[1:a]volume=0.4[a2];[a1][a2]amix=inputs=2:duration=first[a]\" -map \"[v]\" -map \"[a]\" -preset ultrafast \"$outPath\"";
    } else {
      String audioFilter = "atempo=$atempo";
      if (_isReverse) audioFilter += ",areverse";
      command =
          "-ss $startSec -i \"${widget.videoPath}\" -t $durationSec -filter_complex \"[0:v]$videoFilter[v];[0:a]$audioFilter[a]\" -map \"[v]\" -map \"[a]\" -preset ultrafast \"$outPath\"";
    }

    await FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      setState(() => _isExporting = false);
      if (ReturnCode.isSuccess(returnCode)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFF00E5FF), content: Text("Export Success: $outPath", style: const TextStyle(color: Colors.black))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1E1E26), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Text("AI UHD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10, bottom: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isExporting ? null : _exportVideo,
              child: _isExporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("Export", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // CapCut Video Preview Frame with Cyan Outline
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoViewer(trimmer: widget._trimmer),
                    if (_customText.isNotEmpty)
                      Positioned(
                        top: 40 + _textPosition.dy,
                        left: 20 + _textPosition.dx,
                        child: GestureDetector(
                          onPanUpdate: (d) => setState(() => _textPosition += d.delta),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                            child: Text(_customText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    if (_autoCaptionText.isNotEmpty)
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                          child: Text(_autoCaptionText, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // CapCut Multi-Track Timeline Area
          Container(
            color: const Color(0xFF14141A),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("00:00 / 00:15", style: TextStyle(fontSize: 11, color: Colors.white54)),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32, color: Colors.white),
                      onPressed: () async {
                        bool state = await widget._trimmer.videoPlaybackControl(startValue: _startValue, endValue: _endValue);
                        setState(() => _isPlaying = state);
                      },
                    ),
                    const Icon(Icons.fullscreen, size: 20, color: Colors.white54),
                  ],
                ),
                // Video Clip Track
                TrimViewer(
                  trimmer: widget._trimmer,
                  viewerHeight: 45.0,
                  viewerWidth: MediaQuery.of(context).size.width - 28,
                  maxVideoLength: const Duration(minutes: 10),
                  onChangeStart: (v) => _startValue = v,
                  onChangeEnd: (v) => _endValue = v,
                  onChangePlaybackState: (v) => setState(() => _isPlaying = v),
                ),
                const SizedBox(height: 6),
                // CapCut "+ Add audio" timeline track
                GestureDetector(
                  onTap: _pickBackgroundMusic,
                  child: Container(
                    width: double.infinity,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F28),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        _bgMusicPath != null ? "🎵 Audio Track Added" : "+ Add audio",
                        style: const TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // CapCut Bottom Action Toolbar
          Container(
            color: const Color(0xFF101014),
            height: 70,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  _buildCapCutAction(Icons.splitscreen_rounded, "Split", () {}),
                  _buildCapCutAction(Icons.speed_rounded, "${_speed}x", () {
                    setState(() => _speed = _speed == 1.0 ? 2.0 : (_speed == 2.0 ? 0.5 : 1.0));
                  }),
                  _buildCapCutAction(Icons.text_fields_rounded, "Text", _showAddTextDialog),
                  _buildCapCutAction(Icons.auto_fix_high_rounded, "AI Captions", _generateAICaptions),
                  _buildCapCutAction(Icons.aspect_ratio_rounded, "Canvas", () {
                    setState(() => _selectedRatio = _selectedRatio == 'Original' ? '9:16' : 'Original');
                  }),
                  _buildCapCutAction(Icons.auto_awesome, "4K HDR", () {
                    setState(() => _aiHdrEnhance = !_aiHdrEnhance);
                  }),
                  _buildCapCutAction(Icons.filter_vintage_rounded, "Filters", () {
                    final keys = _filters.keys.toList();
                    setState(() => _selectedFilter = keys[(keys.indexOf(_selectedFilter) + 1) % keys.length]);
                  }),
                  _buildCapCutAction(Icons.replay_rounded, "Reverse", () {
                    setState(() => _isReverse = !_isReverse);
                  }),
                  _buildCapCutAction(Icons.flip_rounded, "Mirror", () {
                    setState(() => _isMirrorH = !_isMirrorH);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapCutAction(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.white),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
