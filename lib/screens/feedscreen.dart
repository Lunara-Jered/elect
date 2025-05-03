import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> feedItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = false;
  String searchQuery = "";
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  
  // Cache pour les PDFs et vidéos
  final Map<String, String> _pdfCache = {};
  final Map<String, VideoPlayerController> _videoCache = {};
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _fetchFeedItems();
    _cacheManager.emptyCache(); // Nettoie le cache au démarrage
  }

  Future<void> _fetchFeedItems() async {
    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('feed_items')
          .select()
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        setState(() {
          feedItems = response.map((item) => {
            "image": item['image_url'] ?? '',
            "pdf": item['pdf_url'] ?? '',
            "video": item['video_url'] ?? '',
            "type": item['type'] ?? '',
            "title": item['title'] ?? '',
            "id": item['id'] ?? '',
          }).toList();
          filteredItems = List.from(feedItems);
        });
        
        // Pré-charge les médias en arrière-plan
        _preloadMedia();
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

  // Pré-charge les PDFs et vidéos
  void _preloadMedia() async {
    for (var item in feedItems) {
      if (item["type"] == 'pdf' && item["pdf"] != '') {
        _downloadAndCachePDF(item["pdf"], item["id"]);
      } else if (item["type"] == 'video' && item["video"] != '') {
        _preloadVideo(item["video"], item["id"]);
      }
    }
  }

  Future<void> _downloadAndCachePDF(String url, String id) async {
    if (_pdfCache.containsKey(id)) return;
    
    try {
      final file = await _cacheManager.getSingleFile(url);
      _pdfCache[id] = file.path;
      print("PDF pré-chargé: $id");
    } catch (e) {
      print("Erreur pré-chargement PDF: $e");
    }
  }

  void _preloadVideo(String url, String id) {
    if (_videoCache.containsKey(id)) return;
    
    final controller = VideoPlayerController.network(url);
    _videoCache[id] = controller;
    
    controller.initialize().then((_) {
      print("Vidéo pré-chargée: $id");
    }).catchError((e) {
      print("Erreur pré-chargement vidéo: $e");
      _videoCache.remove(id);
    });
  }

  @override
  void dispose() {
    // Nettoie les contrôleurs vidéo
    _videoCache.values.forEach((controller) => controller.dispose());
    _videoCache.clear();
    speech.stop();
    super.dispose();
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

  void _startListening() async {
    bool available = await speech.initialize(
      onStatus: (status) {
        if (status == "notListening") {
          setState(() => isListening = false);
        }
      },
      onError: (error) {
        print("Erreur Speech: $error");
      },
    );

    if (available) {
      setState(() => isListening = true);
      speech.listen(
        onResult: (result) {
          setState(() {
            searchQuery = result.recognizedWords;
            _searchItems(searchQuery);
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualités Politiques", 
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _searchItems,
                    decoration: InputDecoration(
                      hintText: "Rechercher...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: Colors.blue),
                  onPressed: _startListening,
                ),
              ],
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
                          return MediaItem(
                            item: item,
                            pdfCache: _pdfCache,
                            videoCache: _videoCache,
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

class MediaItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, String> pdfCache;
  final Map<String, VideoPlayerController> videoCache;

  const MediaItem({
    required this.item,
    required this.pdfCache,
    required this.videoCache,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () {
          if (item["type"] == 'pdf') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PDFViewScreen(
                  pdfPath: item["pdf"],
                  cachedPath: pdfCache[item["id"]],
                  title: item["title"] ?? "Actualités Politiques",
                ),
              ),
            );
          } else if (item["type"] == 'video') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  videoPath: item["video"],
                  preloadedController: videoCache[item["id"]],
                ),
              ),
            );
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: item["image"],
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              height: 180,
              color: Colors.grey,
              child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class PDFViewScreen extends StatefulWidget {
  final String pdfPath;
  final String? cachedPath;
  final String title;

  const PDFViewScreen({
    required this.pdfPath,
    this.cachedPath,
    required this.title,
  });

  @override
  _PDFViewScreenState createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localFilePath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    // Utilise le cache si disponible
    if (widget.cachedPath != null && File(widget.cachedPath!).existsSync()) {
      setState(() {
        localFilePath = widget.cachedPath;
        isLoading = false;
      });
      return;
    }

    // Télécharge le PDF si nécessaire
    if (widget.pdfPath.startsWith("http")) {
      try {
        final tempDir = await getTemporaryDirectory();
        final filePath = "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf";
        await Dio().download(widget.pdfPath, filePath);
        setState(() {
          localFilePath = filePath;
          isLoading = false;
        });
      } catch (e) {
        print("Erreur de téléchargement du PDF : $e");
        setState(() => isLoading = false);
      }
    } else {
      setState(() {
        localFilePath = widget.pdfPath;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : localFilePath == null
              ? Center(child: Text("Impossible de charger le PDF"))
              : PDFView(
                  filePath: localFilePath!,
                  enableSwipe: true,
                  pageSnap: true,
                  autoSpacing: true,
                ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final VideoPlayerController? preloadedController;

  const VideoPlayerScreen({
    required this.videoPath,
    this.preloadedController,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Utilise le contrôleur pré-chargé s'il existe
      if (widget.preloadedController != null && 
          widget.preloadedController!.value.isInitialized) {
        _controller = widget.preloadedController!;
        setState(() => isLoading = false);
      } else {
        _controller = VideoPlayerController.network(widget.videoPath)
          ..setLooping(true);
        
        await _controller.initialize();
        setState(() => isLoading = false);
      }
      
      await _controller.play();
    } catch (error) {
      print('Erreur de chargement vidéo : $error');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Ne pas disposer si c'est un contrôleur pré-chargé
    if (widget.preloadedController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Actualités Politiques")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      Text('Erreur de chargement de la vidéo'),
                    ],
                  ),
                )
              : AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
