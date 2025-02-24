import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> feedItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isListening = false;
  String searchQuery = "";
  stt.SpeechToText speech = stt.SpeechToText();
  late stt.SpeechToText _speech;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFeedItems();
  }

  Future<void> _fetchFeedItems() async {
    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client.from('feed_items').select();
      if (response.isNotEmpty) {
        setState(() {
          feedItems = response.map((item) => {
            "image": item['image_url'] ?? '',
            "pdf": item['pdf_url'] ?? '',
            "video": item['video_url'] ?? '',
            "type": item['type'] ?? '',
            "title": item['title'] ?? '',
          }).toList();
          filteredItems = List.from(feedItems);
        });
      }
    } catch (e) {
      print("Erreur de récupération des données : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des données")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _searchItems(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredItems = feedItems.where((item) {
        final title = item["title"]?.toLowerCase() ?? "";
        return title.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print("Status: $status"),
      onError: (error) => print("Error: $error"),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
            _searchItems(_searchController.text);
          });
        },
      );
    }
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualités Politiques", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
      ), elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
               _searchItems = filteredItems;
                _searchController.clear();
              });
            },
            icon: Icon(_isSearching ? Icons.cancel : Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
           if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: _searchItems,
                decoration: InputDecoration(
                  labelText: 'Rechercher',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItems.isEmpty
                    ? const Center(child: Text("Aucun contenu trouvé"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(10.0),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ImageItem(
                            imagePath: item["image"]!,
                            pdfPath: item["pdf"]!,
                            videoPath: item["video"]!,
                            type: item["type"]!,
                          );
                        },
                      ),
          ),
        ],
      ),        

      floatingActionButton: FloatingActionButton(
        onPressed: _fetchFeedItems,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh, color: Colors.white),
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
                builder: (context) => PDFViewScreen(pdfPath: pdfPath, title: "Actualités Politiques"),
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


class PDFViewScreen extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PDFViewScreen({required this.pdfPath, required this.title});

  @override
  _PDFViewScreenState createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localFilePath;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    if (widget.pdfPath.startsWith("http")) {
      try {
        final tempDir = await getTemporaryDirectory();
        final filePath = "${tempDir.path}/document.pdf";
        await Dio().download(widget.pdfPath, filePath);
        setState(() {
          localFilePath = filePath;
        });
      } catch (e) {
        print("Erreur de téléchargement du PDF : $e");
      }
    } else {
      setState(() {
        localFilePath = widget.pdfPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: localFilePath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: localFilePath!,
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
      appBar: AppBar(title: const Text("Actualités Politiques")),
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
