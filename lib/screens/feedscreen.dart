import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
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

// Ajoutez ici les classes PDFViewScreen et VideoPlayerScreen si nécessaire.
