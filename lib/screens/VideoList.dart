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
  bool _isSearching = false;
  bool _isListening = false;
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  @override
  void initState() {
    super.initState();
    fetchVideos(); // Charge les vidéos depuis Supabase
  }

  Future<void> fetchVideos() async {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('videos')
          .select();

      setState(() {
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

  void _filterVideos(String query) {
    setState(() {
      filteredVideos = query.isEmpty
          ? videos
          : videos
              .where((video) =>
                  video['title']!.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          _filterVideos(_searchController.text);
        });
      });
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text("Décryptages",
          style: TextStyle(color: Colors.white, fontSize: 18)),
      backgroundColor: Colors.blue,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              _searchController.clear();
              _filterVideos(""); // Réinitialise la recherche
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
              onChanged: _filterVideos,
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
          child: filteredVideos.isEmpty
              ? const Center(
                  child: Text(
                    "Aucune vidéo trouvée",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredVideos.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Image.network(
                          filteredVideos[index]['thumbnail']!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error, color: Colors.red);
                          },
                        ),
                        title: Text(
                          filteredVideos[index]['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.play_arrow, size: 30),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerPage(
                                videoPath: filteredVideos[index]['video_path']!,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
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
      appBar: AppBar(title: const Text('Décryptages')),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.error, color: Colors.red, size: 50),
                  Text('Erreur de chargement de la vidéo',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            )
          : Center(
              child: _controller.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(),
            ),
      floatingActionButton: _hasError
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
    );
  }
}
