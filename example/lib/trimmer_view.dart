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

  // ---------------- CAPCUT "ADD SOUND" BOTTOM SHEET (Screenshot 1) ----------------
  void _openAddSoundModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141417),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: Column(
                children: [
                  // Top Header with X and Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Add sound",
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222228),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 12),
                          Icon(Icons.search, color: Colors.white38, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              style: TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Search songs or artists",
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Cards Grid (VLOG, Spring, LOVE, TRAVEL, POP, SALE)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.0,
                              children: [
                                _buildCategoryCard("VLOG", const [Color(0xFF8E9EAB), Color(0xFFEEF2F3)]),
                                _buildCategoryCard("🌱 Spring", const [Color(0xFF56AB2F), Color(0xFFA8E063)]),
                                _buildCategoryCard("LOVE", const [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
                                _buildCategoryCard("TRAVEL", const [Color(0xFF2193B0), Color(0xFF6DD5ED)]),
                                _buildCategoryCard("POP", const [Color(0xFF4A00E0), Color(0xFF8E2DE2)]),
                                _buildCategoryCard("SALE", const [Color(0xFFF12711), Color(0xFFF5AF19)]),
                              ],
                            ),
                          ),
                          // Sub Tabs: TikTok, Folder (Device file), Flame (Trending), Bookmark
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                const Icon(Icons.music_note_rounded, color: Colors.white38, size: 22),
                                GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(context);
                                    _pickDeviceAudio();
                                  },
                                  child: const Icon(Icons.folder_open_rounded, color: Colors.white70, size: 24),
                                ),
                                const Icon(Icons.local_fire_department, color: Color(0xFF00E5FF), size: 26),
                                const Icon(Icons.bookmark_border_rounded, color: Colors.white38, size: 22),
                              ],
                            ),
                          ),
                          const Divider(color: Colors.white12, thickness: 1),
                          // Recommended Songs Header
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              "Recommended",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Music List
                          _buildMusicTile("MaskOff Freestyle", "Müd & Seventeenbb", "01:00", const Color(0xFFE53935)),
                          _buildMusicTile("Modern city pop, fashion, Vlog", "Loquat Music", "03:48", const Color(0xFF1E88E5)),
                          _buildMusicTile("Drake style / HIPHOP beat(149)", "Burning Man", "02:45", const Color(0xFF8E24AA)),
                          _buildMusicTile("Acoustic Chill Vibes", "Summer Beats", "02:15", const Color(0xFF43A047)),
                          const SizedBox(height: 20),
                        ],
                      ),
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

  Widget _buildCategoryCard(String title, List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
        ),
      ),
    );
  }

  Widget _buildMusicTile(String title, String artist, String duration, Color coverColor) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: coverColor, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.music_note, color: Colors.white, size: 24),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text("$artist • $duration", style: const TextStyle(color: Colors.white54, fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_border, color: Colors.white54, size: 20),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () {
              setState(() => _selectedMusicTitle = title);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF00E5FF),
                  content: Text("🎵 Added: $title", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              );
            },
            child: const Icon(Icons.download_for_offline_outlined, color: Color(0xFF00E5FF), size: 24),
          ),
        ],
      ),
    );
  }

  void _pickDeviceAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _bgMusicPath = result.files.single.path;
        _selectedMusicTitle = result.files.single.name;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF00E5FF),
            content: Text("🎵 Audio Loaded: $_selectedMusicTitle", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        );
      }
    }
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
            hintText: "Enter text...",
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

    if (_selectedResolution == "1080P") {
      videoFilter += ",scale=1080:-2";
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

  // ---------------- 2. CAPCUT MAIN EDITOR SCREEN (Screenshot 2) ----------------
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
          // 1080P Dropdown
          Container(
            margin: const EdgeInsets.symmetric(vertical: 11),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF222228),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Text(_selectedResolution, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Cyan Export Button
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
          // CapCut Video Viewport with Cyan Border
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF24D2DB), width: 2.0),
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
          // Center Timecode and Play Controls
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
          // Multi-Track Timeline (White playhead, Cover icon, Clip strip, + Add audio)
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
                        // Cover Tile
                        Container(
                          width: 44,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF222228),
                            borderRadius: BorderRadius.circular(6),
                          ),
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
                        // Trimmer Video Strip
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
                        // Plus (+) Add Clip Button
                        Container(
                          margin: const EdgeInsets.only(right: 12, left: 6),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: const Color(0xFF2A2A32), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                    // White Playhead Needle Center Line
                    Container(width: 2, height: 60, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                // CapCut "+ Add audio" Row (Opens Screenshot 1 Music Screen)
                GestureDetector(
                  onTap: _openAddSoundModal,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(4),
                    ),
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
          // CapCut Bottom Toolbar (Screenshot 2: Split, Speed, Animations, Effects, Delete, Enhance voice)
          Container(
            color: const Color(0xFF101012),
            height: 64,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildToolbarItem(Icons.arrow_back_ios, "", () => Navigator.pop(context), isArrow: true),
                  _buildToolbarItem(Icons.splitscreen_rounded, "Split", () {}),
                  _buildToolbarItem(Icons.speed_rounded, "Speed", () {
                    setState(() => _speed = _speed == 1.0 ? 2.0 : (_speed == 2.0 ? 0.5 : 1.0));
                  }),
                  _buildToolbarItem(Icons.play_circle_outline, "Animations", () {}),
                  _buildToolbarItem(Icons.auto_awesome_outlined, "Effects", () {
                    final keys = _filters.keys.toList();
                    setState(() => _selectedFilter = keys[(keys.indexOf(_selectedFilter) + 1) % keys.length]);
                  }),
                  _buildToolbarItem(Icons.delete_outline, "Delete", () {}),
                  _buildToolbarItem(Icons.mic_none_outlined, "Enhance voice", () {
                    setState(() => _aiVoiceMode = _aiVoiceMode == 'Off' ? 'Voice Isolate' : 'Off');
                  }),
                  _buildToolbarItem(Icons.text_fields_rounded, "Text", _showAddTextDialog),
                  _buildToolbarItem(Icons.subtitles_outlined, "AI Captions", _generateAICaptions),
                  _buildToolbarItem(Icons.hdr_on_outlined, "4K HDR", () {
                    setState(() => _aiHdrEnhance = !_aiHdrEnhance);
                  }),
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
