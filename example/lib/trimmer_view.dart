import 'dart:io';
import 'dart:math' as math;
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

  // Masking Feature States
  String _maskType = 'None';
  double _maskAngle = 35.0;
  bool _showMaskControl = false;

  // Trending Effects States (Screenshot 3 - Tendencias)
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
    'Cámara en Mov.': const ColorFilter.matrix([
      1.2, 0, 0, 0, 10,
      0, 1.2, 0, 0, 10,
      0, 0, 1.2, 0, 10,
      0, 0, 0, 1, 0,
    ]),
    'Baile Mariposa': const ColorFilter.matrix([
      1.4, 0.1, 0.3, 0, 25,
      0.1, 1.1, 0.4, 0, -10,
      0.3, 0.1, 1.6, 0, 35,
      0, 0, 0, 1, 0,
    ]),
    'Enfoque Flash': const ColorFilter.matrix([
      1.5, 0, 0, 0, 40,
      0, 1.5, 0, 0, 40,
      0, 0, 1.5, 0, 40,
      0, 0, 0, 1, 0,
    ]),
  };

  // FX, Audio & AI States
  String _selectedMusicTitle = "";
  String? _bgMusicPath;
  String _selectedResolution = "1080P";
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

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // ---------------- TENDENCIAS / TRENDING EFFECTS SHEET (Screenshot 3) ----------------
  void _openTrendingEffectsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141417),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                children: [
                  // Top Category Tabs: Tendencias, Básico, Bling, Fiesta
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.block, color: Colors.white54, size: 20),
                            SizedBox(width: 14),
                            Text("Tendencias", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(width: 16),
                            Text("Básico", style: TextStyle(color: Colors.white54, fontSize: 14)),
                            SizedBox(width: 16),
                            Text("Bling", style: TextStyle(color: Colors.white54, fontSize: 14)),
                            SizedBox(width: 16),
                            Text("Fiesta", style: TextStyle(color: Colors.white54, fontSize: 14)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.check, color: Color(0xFF00E5FF), size: 24),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  // Grid of 3 columns with Effect Cards
                  Expanded(
                    child: GridView.count(
                      padding: const EdgeInsets.all(14),
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                      children: [
                        _buildEffectCard("Halo Desenfoque", const Color(0xFF3949AB), Icons.blur_on),
                        _buildEffectCard("Bordes Brillantes", const Color(0xFF8E24AA), Icons.auto_awesome),
                        _buildEffectCard("JVC Vintage", const Color(0xFF546E7A), Icons.videocam_outlined),
                        _buildEffectCard("Cámara en Mov.", const Color(0xFF43A047), Icons.vibration),
                        _buildEffectCard("Baile Mariposa", const Color(0xFFE53935), Icons.flutter_dash),
                        _buildEffectCard("Enfoque Flash", const Color(0xFFFB8C00), Icons.flash_on),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEffectCard(String title, Color color, IconData icon) {
    bool isSelected = _activeEffect == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeEffect = isSelected ? 'None' : title;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E5FF),
            content: Text("✨ Effect: $_activeEffect", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent, width: 2),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(icon, color: Colors.white70, size: 30)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(isSelected ? Icons.check_circle : Icons.arrow_downward_rounded, size: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10)),
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
        _maskType = 'Linear';
      } else if (_maskType == 'Linear') {
        _maskType = 'Circle';
      } else {
        _maskType = 'None';
        _showMaskControl = false;
      }
    });
  }

  void _openAddSoundModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141417),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.white, size: 24)),
                    const Expanded(child: Center(child: Text("Add sound", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildMusicTile("MaskOff Freestyle", "Müd & Seventeenbb", "01:00", const Color(0xFFE53935)),
                    _buildMusicTile("Modern city pop, fashion, Vlog", "Loquat Music", "03:48", const Color(0xFF1E88E5)),
                    _buildMusicTile("Drake style / HIPHOP beat(149)", "Burning Man", "02:45", const Color(0xFF8E24AA)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMusicTile(String title, String artist, String duration, Color coverColor) {
    return ListTile(
      leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: coverColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.music_note, color: Colors.white)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text("$artist • $duration", style: const TextStyle(color: Colors.white54, fontSize: 11)),
      trailing: GestureDetector(
        onTap: () {
          setState(() => _selectedMusicTitle = title);
          Navigator.pop(context);
        },
        child: const Icon(Icons.download_for_offline_outlined, color: Color(0xFF00E5FF), size: 24),
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
          decoration: const InputDecoration(hintText: "Enter text...", enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E5FF)))),
        ),
        actions: [
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

    // Dynamic Trending Effects Integration in FFmpeg
    if (_activeEffect == 'Halo Desenfoque') {
      videoFilter += ",gblur=sigma=10:steps=2";
    } else if (_activeEffect == 'Bordes Brillantes') {
      videoFilter += ",edgedetect=low=0.1:high=0.4";
    } else if (_activeEffect == 'JVC Vintage') {
      videoFilter += ",curves=vintage,noise=alls=15:allf=t";
    } else if (_activeEffect == 'Enfoque Flash') {
      videoFilter += ",eq=contrast=1.5:brightness=0.1:saturation=1.4";
    }

    if (_maskType == 'Circle') {
      videoFilter += ",geq=r='r(X,Y)':a='if(lte(hypot(X-W/2,Y-H/2),H/2.5),255,0)'";
    } else if (_maskType == 'Diagonal' || _maskType == 'Linear') {
      videoFilter += ",geq=r='r(X,Y)':a='if(lte(Y - X*tan(${_maskAngle * math.pi / 180}), H*0.2),255,0)'";
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
      backgroundColor: const Color(0xFF101012),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.school_outlined, color: Colors.white70, size: 20),
            SizedBox(width: 10),
            Icon(Icons.local_fire_department, color: Color(0xFFFF5252), size: 22),
          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
      body: Column(
        children: [
          // CapCut Video Viewport with Active Trending Effect Filter
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF24D2DB), width: 1.5)),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _trendingEffects[_activeEffect] != null
                        ? ColorFiltered(
                            colorFilter: _trendingEffects[_activeEffect]!,
                            child: VideoViewer(trimmer: widget._trimmer),
                          )
                        : VideoViewer(trimmer: widget._trimmer),
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
                    if (_customText.isNotEmpty)
                      Positioned(
                        top: 40 + _textPosition.dy,
                        left: 20 + _textPosition.dx,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                          child: Text(_customText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      inactiveColor: Colors.white24,
                      onChanged: (val) => setState(() => _maskAngle = val),
                    ),
                  ),
                  Text("${_maskAngle.toInt()}°", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.fullscreen, color: Colors.white70, size: 20),
                Row(
                  children: [
                    const Text("00:02", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    const Text(" / 00:15", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                      onPressed: () async {
                        bool state = await widget._trimmer.videoPlaybackControl(startValue: _startValue, endValue: _endValue);
                        setState(() => _isPlaying = state);
                      },
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Icon(Icons.diamond_outlined, color: Colors.white70, size: 18),
                    SizedBox(width: 14),
                    Icon(Icons.undo, color: Colors.white70, size: 18),
                    SizedBox(width: 14),
                    Icon(Icons.redo, color: Colors.white70, size: 18),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFF16161A),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Container(
                          width: 44,
                          height: 48,
                          decoration: BoxDecoration(color: const Color(0xFF222228), borderRadius: BorderRadius.circular(6)),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined, size: 14, color: Colors.white70),
                              SizedBox(height: 2),
                              Text("Cover", style: TextStyle(fontSize: 9, color: Colors.white70)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TrimViewer(
                            trimmer: widget._trimmer,
                            viewerHeight: 48.0,
                            viewerWidth: MediaQuery.of(context).size.width - 120,
                            maxVideoLength: const Duration(minutes: 10),
                            onChangeStart: (v) => _startValue = v,
                            onChangeEnd: (v) => _endValue = v,
                            onChangePlaybackState: (v) => setState(() => _isPlaying = v),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 12, left: 6),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: const Color(0xFF2A2A32), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    Container(width: 2, height: 60, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _openAddSoundModal,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    height: 28,
                    decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          _selectedMusicTitle.isNotEmpty ? "🎵 $_selectedMusicTitle" : "Add audio",
                          style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Toolbar (Effects button opens Screenshot 3 Tendencias Modal)
          Container(
            color: const Color(0xFF101012),
            height: 64,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildToolbarItem(Icons.arrow_back_ios, "", () => Navigator.pop(context), isArrow: true),
                  _buildToolbarItem(Icons.auto_awesome_outlined, "Effects", _openTrendingEffectsModal),
                  _buildToolbarItem(Icons.masks_outlined, "Mask", _toggleMaskType),
                  _buildToolbarItem(Icons.splitscreen_rounded, "Split", () {}),
                  _buildToolbarItem(Icons.speed_rounded, "Speed", () {
                    setState(() => _speed = _speed == 1.0 ? 2.0 : (_speed == 2.0 ? 0.5 : 1.0));
                  }),
                  _buildToolbarItem(Icons.delete_outline, "Delete", () {}),
                  _buildToolbarItem(Icons.mic_none_outlined, "Enhance voice", () {
                    setState(() => _aiVoiceMode = _aiVoiceMode == 'Off' ? 'Voice Isolate' : 'Off');
                  }),
                  _buildToolbarItem(Icons.text_fields_rounded, "Text", _showAddTextDialog),
                  _buildToolbarItem(Icons.subtitles_outlined, "AI Captions", _generateAICaptions),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarItem(IconData icon, String label, VoidCallback onTap, {bool isArrow = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isArrow ? 16 : 22, color: Colors.white),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ]
          ],
        ),
      ),
    );
  }
}
