import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TrimmerView extends StatefulWidget {
  final File videoFile;
  const TrimmerView(this.videoFile, {super.key});

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  double _startValue = 0.0;
  double _endValue = 1.0;
  bool _isExporting = false;
  
  String _customText = "";
  Offset _textPosition = const Offset(0, 0);

  double _videoScale = 1.0;
  bool _isKeyframeActive = false;

  String _maskType = 'None';
  double _maskAngle = 35.0;
  bool _showMaskControl = false;
  String _activeEffect = 'None';

  final Map<String, ColorFilter?> _trendingEffects = {
    'None': null,
    'Halo Desenfoque': const ColorFilter.matrix([
      1.1, 0.2, 0, 0, 15,
      0.1, 1.1, 0, 0, 15,
      0, 0.1, 1.2, 0, 20,
      0, 0, 0, 1, 0,
    ]),
    'Bordes Brillantes': const ColorFilter.matrix([
      1.6, 0, 0.2, 0, 30,
      0, 1.4, 0.2, 0, 30,
      0.2, 0, 1.8, 0, 45,
      0, 0, 0, 1, 0,
    ]),
    'JVC Vintage': const ColorFilter.matrix([
      0.9, 0.1, 0.1, 0, -10,
      0.1, 1.0, 0.1, 0, 0,
      0.1, 0.1, 0.7, 0, -20,
      0, 0, 0, 1, 0,
    ]),
  };

  String _selectedMusicTitle = "";
  String _selectedResolution = "1080P";
  double _speed = 1.0;
  String _autoCaptionText = "";
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _endValue = _controller.value.duration.inMilliseconds.toDouble();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addOrRemoveKeyframe() {
    setState(() {
      _isKeyframeActive = !_isKeyframeActive;
      _videoScale = _isKeyframeActive ? 1.25 : 1.0;
    });
  }

  void _openTrendingEffectsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141417),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tendencias", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.check, color: Color(0xFF00E5FF)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEffectBtn("Halo Desenfoque"),
                    _buildEffectBtn("Bordes Brillantes"),
                    _buildEffectBtn("JVC Vintage"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEffectBtn(String name) {
    return GestureDetector(
      onTap: () {
        setState(() => _activeEffect = _activeEffect == name ? 'None' : name);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF222228),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _activeEffect == name ? const Color(0xFF00E5FF) : Colors.transparent, width: 2),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  void _toggleMaskType() {
    setState(() {
      _showMaskControl = true;
      if (_maskType == 'None') {
        _maskType = 'Diagonal';
      } else if (_maskType == 'Diagonal') {
        _maskType = 'Circle';
      } else {
        _maskType = 'None';
        _showMaskControl = false;
      }
    });
  }

  Future<void> _exportVideo() async {
    setState(() => _isExporting = true);
    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/ShadowCut_${DateTime.now().millisecondsSinceEpoch}.mp4';
    await widget.videoFile.copy(outPath);
    setState(() => _isExporting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF00E5FF),
          content: Text("Export Success: $outPath", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101012),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 11),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFF222228), borderRadius: BorderRadius.circular(6)),
            child: Row(
              children: [
                Text(_selectedResolution, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 10, bottom: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF24D2DB),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isExporting ? null : _exportVideo,
              child: _isExporting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("Export", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          )
        ],
      ),
      body: _isInitialized
          ? Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF24D2DB), width: 1.5)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: _videoScale,
                            child: _trendingEffects[_activeEffect] != null
                                ? ColorFiltered(
                                    colorFilter: _trendingEffects[_activeEffect]!,
                                    child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
                                  )
                                : AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
                          ),
                          if (_maskType != 'None')
                            Transform.rotate(
                              angle: _maskAngle * (math.pi / 180),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.amberAccent, width: 2.0),
                                  borderRadius: _maskType == 'Circle' ? BorderRadius.circular(200) : BorderRadius.zero,
                                ),
                                width: _maskType == 'Circle' ? 180 : double.infinity,
                                height: _maskType == 'Circle' ? 180 : 120,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showMaskControl)
                  Container(
                    color: const Color(0xFF141418),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Text("Rotate", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: _maskAngle,
                            min: -180.0,
                            max: 180.0,
                            activeColor: const Color(0xFF00E5FF),
                            onChanged: (val) => setState(() => _maskAngle = val),
                          ),
                        ),
                        Text("${_maskAngle.toInt()}°", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying ? _controller.pause() : _controller.play();
                          });
                        },
                      ),
                      GestureDetector(
                        onTap: _addOrRemoveKeyframe,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: _isKeyframeActive ? const Color(0xFF00E5FF) : Colors.transparent, shape: BoxShape.circle),
                          child: Icon(Icons.diamond_outlined, color: _isKeyframeActive ? Colors.black : Colors.white70, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFF16161A),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: RangeSlider(
                    values: RangeValues(_startValue, _endValue),
                    min: 0.0,
                    max: _controller.value.duration.inMilliseconds.toDouble(),
                    activeColor: const Color(0xFF00E5FF),
                    inactiveColor: Colors.white24,
                    onChanged: (vals) {
                      setState(() {
                        _startValue = vals.start;
                        _endValue = vals.end;
                      });
                      _controller.seekTo(Duration(milliseconds: vals.start.toInt()));
                    },
                  ),
                ),
                Container(
                  color: const Color(0xFF101012),
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: const Icon(Icons.auto_awesome_outlined, color: Colors.white), onPressed: _openTrendingEffectsModal),
                      IconButton(icon: const Icon(Icons.masks_outlined, color: Colors.white), onPressed: _toggleMaskType),
                      IconButton(
                        icon: const Icon(Icons.speed_rounded, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _speed = _speed == 1.0 ? 2.0 : (_speed == 2.0 ? 0.5 : 1.0);
                            _controller.setPlaybackSpeed(_speed);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))),
    );
  }
}
