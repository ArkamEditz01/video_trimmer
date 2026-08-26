import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'trimmer_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShadowCutApp());
}

class ShadowCutApp extends StatelessWidget {
  const ShadowCutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shadow Cut',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121214),
        primaryColor: const Color(0xFF00E5FF),
      ),
      home: const LoginScreen(),
    );
  }
}

// ---------------- 1. CAPCUT LOGIN SCREEN ----------------
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.content_cut_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "ShadowCut",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "All-in-one AI Video Editor",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const Spacer(),
              _buildLoginButton(
                icon: Icons.g_mobiledata_rounded,
                text: "Continue with Google",
                bgColor: const Color(0xFFF2F3F5),
                textColor: Colors.black,
                onTap: () => _goToHome(context),
              ),
              const SizedBox(height: 12),
              _buildLoginButton(
                icon: Icons.facebook,
                text: "Sign in with Facebook",
                bgColor: const Color(0xFF1877F2),
                textColor: Colors.white,
                onTap: () => _goToHome(context),
              ),
              const SizedBox(height: 12),
              _buildLoginButton(
                icon: Icons.person_outline,
                text: "Guest Mode / Skip",
                bgColor: Colors.black,
                textColor: Colors.white,
                onTap: () => _goToHome(context),
              ),
              const Spacer(),
              const Text(
                "By signing in, you agree to Terms of Service & Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const CapCutHomeScreen()),
    );
  }

  Widget _buildLoginButton({
    required IconData icon,
    required String text,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        icon: Icon(icon, size: 22, color: textColor),
        label: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
        onPressed: onTap,
      ),
    );
  }
}

// ---------------- 2. CAPCUT MAIN HOME DASHBOARD ----------------
class CapCutHomeScreen extends StatefulWidget {
  const CapCutHomeScreen({super.key});

  @override
  State<CapCutHomeScreen> createState() => _CapCutHomeScreenState();
}

class _CapCutHomeScreenState extends State<CapCutHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;

  void _pickVideo() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final trimmer = Trimmer();
        await trimmer.loadVideo(videoFile: file);

        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TrimmerView(trimmer, file.path),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading video: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("ShadowCut", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text("PRO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          IconButton(icon: const Icon(Icons.search, size: 24), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings_outlined, size: 24), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Top Quick AI Feature Tiles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopAction(Icons.auto_stories_rounded, "Script to video"),
                _buildTopAction(Icons.campaign_outlined, "Smart Ads"),
                _buildTopAction(Icons.photo_filter_rounded, "Photo editor"),
                _buildTopAction(Icons.translate_rounded, "AI Captions"),
              ],
            ),
            const SizedBox(height: 20),
            // Big CapCut New Project Button
            GestureDetector(
              onTap: _isLoading ? null : _pickVideo,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00D2FF).withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.add_box_rounded, size: 38, color: Colors.white),
                    const SizedBox(width: 14),
                    Text(
                      _isLoading ? "Opening Media..." : "New project",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Recent Projects Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Projects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1C1C24), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_queue, size: 16, color: Color(0xFF00E5FF)),
                      SizedBox(width: 6),
                      Text("Cloud Space", style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Project Grid Sample
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_outline_rounded, color: Colors.white.withOpacity(0.5), size: 32),
                        const SizedBox(height: 8),
                        Text("Draft #0${index + 1}", style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      // CapCut Exact Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121216),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        currentIndex: _currentIndex,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.content_cut_rounded), label: "Edit"),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_customize_outlined), label: "Templates"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: "Inbox"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: "Me"),
        ],
      ),
    );
  }

  Widget _buildTopAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F26),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
