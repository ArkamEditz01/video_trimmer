import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'trimmer_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Trimmer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Trimmer _trimmer = Trimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Trimmer"),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text("LOAD VIDEO"),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.video,
              allowCompression: false,
            );
            if (result != null && result.files.single.path != null) {
              File file = File(result.files.single.path!);
              await _trimmer.loadVideo(videoFile: file);
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  return TrimmerView(_trimmer);
                }),
              );
            }
          },
        ),
      ),
    );
  }
}
