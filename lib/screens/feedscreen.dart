import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> feedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchFeedItems();
  }

  Future<void> _fetchFeedItems() async {
    try {
      final response = await Supabase.instance.client.from('feed_items').select();
      if (response.isNotEmpty) {
        setState(() {
          feedItems = response.map((item) => {
            "image": item['image_url'] ?? '',
            "pdf": item['pdf_url'] ?? '',
            "video": item['video_url'] ?? '',
            "type": item['type'] ?? ''
          }).toList();
        });
      }
    } catch (e) {
      print("Erreur de récupération des données : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualités Politiques", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
      ),
      body: feedItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView.builder(
                itemCount: feedItems.length,
                itemBuilder: (context, index) {
                  final item = feedItems[index];
                  return ImageItem(
                    imagePath: item["image"]!,
                    pdfPath: item["pdf"]!,
                    videoPath: item["video"]!,
                    type: item["type"]!,
                  );
                },
              ),
            ),
    );
  }
}

class ImageItem extends StatelessWidget {
  final String imagePath;
  final String pdfPath;
  final String videoPath;
  final String type;

  const ImageItem({required this.imagePath, required this.pdfPath, required this.videoPath, required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () {
          if (type == 'pdf') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewScreen(pdfPath: pdfPath, title: "Document PDF"),
              ),
            );
          } else if (type == 'video') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(videoPath: videoPath),
              ),
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imagePath,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 180,
                color: Colors.grey,
                child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class PDFViewScreen extends StatelessWidget {
  final String pdfPath;
  final String title;

  const PDFViewScreen({required this.pdfPath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PDFView(
        filePath: pdfPath,
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoPath)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lecture Vidéo")),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
