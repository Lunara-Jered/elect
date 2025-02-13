import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';


class VideoListPage extends StatefulWidget {
  @override
  _VideoListPageState createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  List<Map<String, String>> videos = [];
  List<Map<String, String>> filteredVideos = [];
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _searchText = "";
  bool _isSearchVisible = false; // Gère la visibilité de la search bar

  @override
  void initState() {
    super.initState();
    fetchVideos(); // Charge les vidéos depuis Supabase
  }

  // Fonction pour récupérer les vidéos depuis Supabase
  Future<void> fetchVideos() async {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('videos')
          .select(); // Pas besoin de `.execute()`

      setState(() {
        // Vérifie que chaque élément est bien une Map<String, dynamic>
        videos = response.map((video) => {
              'title': video['title'] as String? ?? '',
              'thumbnail': video['thumbnail'] as String? ?? '',
              'video_path': video['video_path'] as String? ?? '',
            }).toList();

        filteredVideos = videos;
      });
    } catch (e) {
      print('Erreur de récupération des vidéos: $e');
    }
  }

  void searchVideos(String query) {
    setState(() {
      _searchText = query;
      filteredVideos = videos
          .where((video) => video['title']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        searchVideos(result.recognizedWords);
      });
    } else {
      print('Speech recognition not available');
    }
  }

  void stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                onChanged: searchVideos,
                decoration: InputDecoration(
                  labelText: 'Rechercher',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
              )
            : Text('Décryptages', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible; // Change l'état de la search bar
                if (!_isSearchVisible) {
                  _searchText = ""; // Réinitialiser le texte de recherche
                  filteredVideos = videos; // Réinitialiser la liste filtrée
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: filteredVideos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Image.network(
                    filteredVideos[index]['thumbnail']!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.error, color: Colors.red);
                    },
                  ),
                  title: Text(filteredVideos[index]['title']!),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerPage(videoPath: filteredVideos[index]['video_path']!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String videoPath;
  VideoPlayerPage({required this.videoPath});

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoPath)
      ..initialize().then((_) => setState(() {})).catchError((error) {
        setState(() {
          _hasError = true;
        });
        print('Erreur de chargement de la vidéo : $error');
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
      appBar: AppBar(title: Text('Décryptages')),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 50),
                  Text('Erreur de chargement de la vidéo', style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          : Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
                  : CircularProgressIndicator(),
            ),
      floatingActionButton: _hasError
          ? null
          : FloatingActionButton(
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

