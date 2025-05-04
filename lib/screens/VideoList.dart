import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoListPage extends StatefulWidget {
  @override
  _VideoListPageState createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  List<Map<String, String>> videos = [];
  List<Map<String, String>> filteredVideos = [];
  bool _isSearching = false;
  bool _isLoading = false;
  bool _isListening = false;
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  String searchQuery = "";
  
  final Map<String, VideoPlayerController> _preloadedControllers = {};

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    setState(() => _isLoading = true);
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

      _preloadVideos();
    } catch (e) {
      print('Erreur de récupération des vidéos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _preloadVideos() {
    for (var video in videos) {
      final path = video['video_path']!;
      if (!_preloadedControllers.containsKey(path)) {
        final controller = VideoPlayerController.network(path);
        _preloadedControllers[path] = controller;
        controller.initialize().then((_) {
          print('Vidéo pré-chargée: $path');
        }).catchError((e) {
          print('Erreur pré-chargement: $e');
          _preloadedControllers.remove(path);
        });
      }
    }
  }

  @override
  void dispose() {
    _preloadedControllers.values.forEach((controller) {
      controller.pause();
      controller.dispose();
    });
    _preloadedControllers.clear();
    _searchController.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: _isSearching
            ? TextField(
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
              )
            : const Text('Décryptages',
                style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchController.clear();
                _filterVideos("");
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredVideos.length,
                    itemBuilder: (context, index) {
                      final video = filteredVideos[index];
                      return ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: video['thumbnail']!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, color: Colors.red),
                        ),
                        title: Text(video['title']!),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerPage(
                                videoPath: video['video_path']!,
                                preloadedController: _preloadedControllers[video['video_path']],
                              ),
                            ),
                          ).then((_) {
                            // Cette callback est exécutée quand on revient de la page
                            if (_preloadedControllers.containsKey(video['video_path'])) {
                              _preloadedControllers[video['video_path']]?.pause();
                            }
                          });
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
  final VideoPlayerController? preloadedController;

  VideoPlayerPage({required this.videoPath, this.preloadedController});

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _hasError = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.preloadedController != null && 
          widget.preloadedController!.value.isInitialized) {
        _controller = widget.preloadedController!;
        setState(() => _isInitializing = false);
      } else {
        _controller = VideoPlayerController.network(widget.videoPath)
          ..setLooping(true);
        
        await _controller.initialize();
      }
      
      await _controller.play();
    } catch (error) {
      print('Erreur de chargement vidéo: $error');
      setState(() {
        _hasError = true;
        _isInitializing = false;
      });
    }
    
    if (!_hasError) {
      setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    // Toujours mettre en pause avant de disposer
    _controller.pause();
    
    // Ne disposer que si ce n'est pas un contrôleur pré-chargé
    if (widget.preloadedController == null) {
      _controller.dispose();
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Décryptages')),
      body: _hasError
          ? _buildErrorWidget()
          : _isInitializing
              ? _buildLoadingWidget()
              : _buildVideoPlayer(),
      floatingActionButton: _hasError || _isInitializing
          ? null
          : FloatingActionButton(
              onPressed: _togglePlayPause,
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error, color: Colors.red, size: 50),
          Text('Erreur de chargement de la vidéo',
              style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }
}
