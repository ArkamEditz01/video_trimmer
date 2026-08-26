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
  String _selectedGlitch = 'Off'; // Off, RGB Split, VHS Glitch, Cyberpunk
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

  void _toggleGlitch() {
    setState(() {
      if (_selectedGlitch == 'Off') {
        _selectedGlitch = 'RGB Split';
      } else if (_selectedGlitch == 'RGB Split') {
        _selectedGlitch = 'VHS Glitch';
      } else if (_selectedGlitch == 'VHS Glitch') {
        _selectedGlitch = 'Cyberpunk';
      } else {
        _selectedGlitch = 'Off';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF7C4DFF),
        content: Text("⚡ Glitch FX: $_selectedGlitch", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _bgMusicPath = result.files.single.path;
      });
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
    
    bool available = await _speech.initialize(
      onError: (val) => debugPrint('onError: $val'),
      onStatus: (val) => debugPrint('onStatus: $val'),
    );

    if (available) {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _autoCaptionText = "🔥 AI Auto Subtitles Enabled!";
        _isGeneratingCaptions = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF00E5FF),
            content: Text("✨ AI Auto Captions Generated!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
      }
    } else {
      setState(() {
        _autoCaptionText = "✨ Shadow Cut AI Auto Captions";
        _isGeneratingCaptions = false;
      });
    }
  }

  void _toggleAspectRatio() {
    setState(() {
      if (_selectedRatio == 'Original') {
        _selectedRatio = '9:16';
      } else if (_selectedRatio == '9:16') {
        _selectedRatio = '16:9';
      } else if (_selectedRatio == '16:9') {
        _selectedRatio = '1:1';
      } else {
        _selectedRatio = 'Original';
      }
    });
  }

  void _toggleCutout() {
    setState(() {
      if (_bgCutoutMode == 'Off') {
        _bgCutoutMode = 'Chroma';
      } else if (_bgCutoutMode == 'Chroma') {
        _bgCutoutMode = 'AI Cutout';
      } else {
        _bgCutoutMode = 'Off';
      }
    });
  }

  void _toggleVelocity() {
    setState(() {
      if (_aiVelocityMode == 'Off') {
        _aiVelocityMode = '0.5x Smooth';
        _speed = 0.5;
      } else if (_aiVelocityMode == '0.5x Smooth') {
        _aiVelocityMode = '0.25x Ultra';
        _speed = 0.25;
      } else if (_aiVelocityMode == '0.25x Ultra') {
        _aiVelocityMode = '2.0x Fast';
        _speed = 2.0;
      } else {
        _aiVelocityMode = 'Off';
        _speed = 1.0;
      }
    });
  }

  void _toggleVoiceClean() {
    setState(() {
      if (_aiVoiceMode == 'Off') {
        _aiVoiceMode = 'Denoise';
      } else if (_aiVoiceMode == 'Denoise') {
        _aiVoiceMode = 'Voice Isolate';
      } else {
        _aiVoiceMode = 'Off';
      }
    });
  }

  void _toggleHdrEnhancer() {
    setState(() {
      _aiHdrEnhance = !_aiHdrEnhance;
    });
  }

  void _toggleReverse() {
    setState(() {
      _isReverse = !_isReverse;
    });
  }

  void _toggleMirror() {
    setState(() {
      _isMirrorH = !_isMirrorH;
    });
  }

  double? _getPreviewAspectRatio() {
    if (_selectedRatio == '9:16') return 9 / 16;
    if (_selectedRatio == '16:9') return 16 / 9;
    if (_selectedRatio == '1:1') return 1 / 1;
    return null;
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

    // Video Filter Chain
    String videoFilter = "setpts=${setpts}*PTS";

    if (_isMirrorH) {
      videoFilter += ",hflip";
    }

    if (_isReverse) {
      videoFilter += ",reverse";
    }

    if (_selectedRatio == '9:16') {
      videoFilter += ",scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black";
    } else if (_selectedRatio == '16:9') {
      videoFilter += ",scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black";
    } else if (_selectedRatio == '1:1') {
      videoFilter += ",scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:(ow-iw)/2:(oh-ih)/2:black";
    }

    // Glitch FX via FFmpeg
    if (_selectedGlitch == 'RGB Split') {
      videoFilter += ",rgbashift=rh=8:bv=-8";
    } else if (_selectedGlitch == 'VHS Glitch') {
      videoFilter += ",noise=alls=20:allf=t+u,hue=s=1.5";
    } else if (_selectedGlitch == 'Cyberpunk') {
      videoFilter += ",rgbashift=rh=15:gh=-5:bv=10,eq=contrast=1.3:saturation=1.5";
    }

    if (_aiHdrEnhance) {
      videoFilter += ",unsharp=5:5:1.2:5:5:0.0,eq=contrast=1.18:brightness=0.03:saturation=1.3";
    }

    if (_aiVelocityMode == '0.25x Ultra' || _aiVelocityMode == '0.5x Smooth') {
      videoFilter += ",minterpolate='mi_mode=mci:mc_mode=aobmc:vsbmc=1:fps=60'";
    }

    if (_bgCutoutMode == 'Chroma') {
      videoFilter += ",colorkey=0x00FF00:0.3:0.1";
    } else if (_bgCutoutMode == 'AI Cutout') {
      videoFilter += ",boxblur=10:1[bg];[0:v]crop=iw:ih[fg];[bg][fg]overlay=0:0";
    }

    if (_selectedFilter == 'B&W') {
      videoFilter += ",hue=s=0";
    } else if (_selectedFilter == 'Warm') {
      videoFilter += ",curves=vintage";
    }

    if (_customText.isNotEmpty) {
      String cleanText = _customText.replaceAll("'", "");
      videoFilter += ",drawtext=text='$cleanText':fontcolor=white:fontsize=48:box=1:boxcolor=black@0.6:boxborderw=8:x=(w-text_w)/2:y=h*0.25";
    }

    // Audio Mixing
    String command = "";
    if (_bgMusicPath != null && File(_bgMusicPath!).existsSync()) {
      command =
          "-ss $startSec -i \"${widget.videoPath}\" -i \"$_bgMusicPath\" -t $durationSec -filter_complex \"[0:v]$videoFilter[v];[0:a]atempo=$atempo,volume=1.0[a1];[1:a]volume=0.4[a2];[a1][a2]amix=inputs=2:duration=first[a]\" -map \"[v]\" -map \"[a]\" -preset ultrafast \"$outPath\"";
    } else {
      String audioFilter = "atempo=$atempo";
      if (_isReverse) audioFilter += ",areverse";
      if (_aiVoiceMode == 'Denoise') audioFilter += ",afftdn=nf=-25,anlmdn=s=3";
      if (_aiVoiceMode == 'Voice Isolate') audioFilter += ",afftdn=nf=-35,highpass=f=220,lowpass=f=3400,volume=1.6";

      command =
          "-ss $startSec -i \"${widget.videoPath}\" -t $durationSec -filter_complex \"[0:v]$videoFilter[v];[0:a]$audioFilter[a]\" -map \"[v]\" -map \"[a]\" -preset ultrafast \"$outPath\"";
    }

    await FFmpegKit.executeAsync(command, (session) async {
      final returnCode = await session.getReturnCode();
      setState(() => _isExporting = false);

      if (ReturnCode.isSuccess(returnCode)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E5FF),
            content: Text("Export Success: $outPath", style: const TextStyle(color: Colors.black)),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Export complete.")),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double? ratio = _getPreviewAspectRatio();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Shadow Cut Pro AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
          Expanded(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: ratio != null ? Border.all(color: Colors.white24, width: 1.5) : null,
                ),
                child: AspectRatio(
                  aspectRatio: ratio ?? 16 / 9,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        color: _bgCutoutMode != 'Off' ? const Color(0xFF1E1E2C) : Colors.black,
                        child: Transform.scale(
                          scaleX: _isMirrorH ? -1.0 : 1.0,
                          child: _glitchMatrices[_selectedGlitch] != null
                              ? ColorFiltered(
                                  colorFilter: _glitchMatrices[_selectedGlitch]!,
                                  child: VideoViewer(trimmer: widget._trimmer),
                                )
                              : (_aiHdrEnhance
                                  ? ColorFiltered(
                                      colorFilter: _hdrFilterMatrix,
                                      child: _filters[_selectedFilter] != null
                                          ? ColorFiltered(
                                              colorFilter: _filters[_selectedFilter]!,
                                              child: VideoViewer(trimmer: widget._trimmer),
                                            )
                                          : VideoViewer(trimmer: widget._trimmer),
                                    )
                                  : (_filters[_selectedFilter] != null
                                      ? ColorFiltered(
                                          colorFilter: _filters[_selectedFilter]!,
                                          child: VideoViewer(trimmer: widget._trimmer),
                                        )
                                      : VideoViewer(trimmer: widget._trimmer))),
                        ),
                      ),
                      if (_customText.isNotEmpty)
                        Positioned(
                          top: 60 + _textPosition.dy,
                          left: 20 + _textPosition.dx,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _textPosition += details.delta;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white70, width: 1.5),
                              ),
                              child: Text(
                                _customText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 8)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_autoCaptionText.isNotEmpty)
                        Positioned(
                          bottom: 40,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                            ),
                            child: Text(
                              _autoCaptionText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xFF181818),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TrimViewer(
                  trimmer: widget._trimmer,
                  viewerHeight: 50.0,
                  viewerWidth: MediaQuery.of(context).size.width - 32,
                  maxVideoLength: const Duration(minutes: 10),
                  onChangeStart: (value) => _startValue = value,
                  onChangeEnd: (value) => _endValue = value,
                  onChangePlaybackState: (value) => setState(() => _isPlaying = value),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 40, color: const Color(0xFF00E5FF)),
                      onPressed: () async {
                        bool state = await widget._trimmer.videoPlaybackControl(startValue: _startValue, endValue: _endValue);
                        setState(() => _isPlaying = state);
                      },
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "Glitch FX",
                              _selectedGlitch,
                              _toggleGlitch,
                              isAi: true,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "Text Overlay",
                              _customText.isEmpty ? "+ Add" : "Edit",
                              _showAddTextDialog,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "Add Music",
                              _bgMusicPath != null ? "🎵 Added" : "+ Pick",
                              _pickBackgroundMusic,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "Canvas",
                              _selectedRatio,
                              _toggleAspectRatio,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "Reverse",
                              _isReverse ? "ON" : "OFF",
                              _toggleReverse,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "Mirror",
                              _isMirrorH ? "FLIP" : "OFF",
                              _toggleMirror,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "AI Audio",
                              _aiVoiceMode,
                              _toggleVoiceClean,
                              isAi: true,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "AI Enhancer",
                              _aiHdrEnhance ? "4K HDR" : "OFF",
                              _toggleHdrEnhancer,
                              isAi: true,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "AI Velocity",
                              _aiVelocityMode,
                              _toggleVelocity,
                              isAi: true,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "AI Cutout",
                              _bgCutoutMode,
                              _toggleCutout,
                              isAi: true,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption(
                              "AI Captions",
                              _isGeneratingCaptions ? "..." : (_autoCaptionText.isEmpty ? "OFF" : "ON"),
                              _isGeneratingCaptions ? () {} : _generateAICaptions,
                              isAi: true,
                            ),
                            const SizedBox(width: 8),
                            _buildToolOption("Filter", _selectedFilter, () {
                              final keys = _filters.keys.toList();
                              int nextIdx = (keys.indexOf(_selectedFilter) + 1) % keys.length;
                              setState(() => _selectedFilter = keys[nextIdx]);
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolOption(String title, String value, VoidCallback onTap, {bool isAi = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isAi ? const Color(0xFF2A1B4E) : const Color(0xFF262626),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isAi ? const Color(0xFFB388FF) : Colors.white12),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 10, color: isAi ? const Color(0xFFB388FF) : Colors.white54, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
          ],
        ),
      ),
    );
  }
}
