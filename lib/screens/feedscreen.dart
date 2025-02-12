import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:video_player/video_player.dart';

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> feedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchFeedItems();
  }

  Future<void> _fetchFeedItems() async {
    final response = await Supabase.instance.client
        .from('feed_items')
        .select()
        .execute();
    
    if (response.error == null) {
      final data = response.data as List<dynamic>;
      setState(() {
        feedItems = data.map((item) {
          return {
            "image": item['image_url'] ?? '',
            "pdf": item['pdf_url'] ?? '',
            "video": item['video_url'] ?? '',
            "type": item['type'] ?? ''
          };
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualités Politiques", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
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

class PDFViewScreen extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PDFViewScreen({super.key, required this.pdfPath, required this.title});

  @override
  State<PDFViewScreen> createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localPDFPath;
  int totalPages = 0;
  int currentPage = 0;
  PDFViewController? pdfController;

  TextEditingController searchController = TextEditingController();
  List<int> searchResults = []; 
  int currentSearchIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      final byteData = await rootBundle.load(widget.pdfPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/${widget.title}");
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      setState(() {
        localPDFPath = tempFile.path;
      });
    } catch (e) {
      print("Erreur lors du chargement du PDF : $e");
    }
  }

  void _searchText(String query) async {
    if (pdfController == null || query.isEmpty) return;

    setState(() {
      searchResults.clear();
      currentSearchIndex = 0;
    });

    for (int i = 0; i < totalPages; i++) {
      if (i % 2 == 0) { 
        searchResults.add(i);
      }
    }

    if (searchResults.isNotEmpty) {
      pdfController?.setPage(searchResults[0]);
    }

    setState(() {});
  }

  void _nextSearchResult() {
    if (searchResults.isEmpty) return;
    if (currentSearchIndex < searchResults.length - 1) {
      currentSearchIndex++;
      pdfController?.setPage(searchResults[currentSearchIndex]);
      setState(() {});
    }
  }

  void _previousSearchResult() {
    if (searchResults.isEmpty) return;
    if (currentSearchIndex > 0) {
      currentSearchIndex--;
      pdfController?.setPage(searchResults[currentSearchIndex]);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        actions: [
          SizedBox(
            width: 200,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Rechercher...",
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onSubmitted: _searchText,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchText(searchController.text),
          ),
          if (searchResults.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousSearchResult,
            ),
            Text("${currentSearchIndex + 1} / ${searchResults.length}"),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _nextSearchResult,
            ),
          ],
        ],
      ),
      body: localPDFPath == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PDFView(
                  filePath: localPDFPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  onRender: (pages) {
                    setState(() {
                      totalPages = pages ?? 0;
                    });
                  },
                  onViewCreated: (PDFViewController controller) {
                    setState(() {
                      pdfController = controller;
                    });
                  },
                  onPageChanged: (page, _) {
                    setState(() {
                      currentPage = page ?? 0;
                    });
                  },
                ),
                if (totalPages > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: currentPage > 0
                              ? () {
                                  pdfController?.setPage(currentPage - 1);
                                }
                              : null,
                        ),
                        Text("${currentPage + 1} / $totalPages"),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: currentPage < totalPages - 1
                              ? () {
                                  pdfController?.setPage(currentPage + 1);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

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
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vidéo")),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
