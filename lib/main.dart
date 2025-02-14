import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:elect241/screens/pdfviewer.dart';
import 'package:elect241/screens/faqcreen.dart';
import 'package:elect241/screens/VideoList.dart';
import 'package:elect241/screens/feedscreen.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://leuxlvlrpumzmgkyqtfd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxldXhsdmxycHVtem1na3lxdGZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkzNjI4MjcsImV4cCI6MjA1NDkzODgyN30.JNSdrlOvmPRKBNE3J1bucZOWrqIkA3zteGnPu1Wgzkw',
  );

  runApp(const Elect241App());
}


class Elect241App extends StatelessWidget {
  const Elect241App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    FeedScreen(),
    VideoListPage(),
    FAQScreen(),
    PDFViewerSection(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.white,
        title: Image.asset("assets/banner.png", height: 40),
      ),
      body: Column(
        children: [
          const StorySection(), // Ajout de la section stories sous l'AppBar
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({super.key, required this.currentIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.image_aspect_ratio), label: "Actualités"),
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Décryptages"),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "FAQ"),
        BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: "Lois Électorales"),
      ],
      onTap: onItemTapped,
    );
  }
} 


class StorySection extends StatefulWidget {
  const StorySection({super.key});

  @override
  _StorySectionState createState() => _StorySectionState();
}

class _StorySectionState extends State<StorySection> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> stories = [];

  @override
  void initState() {
    super.initState();
    fetchStories();
  }

  Future<void> fetchStories() async {
    final response = await supabase.from('stories').select();
    List<Map<String, dynamic>> allStories = List<Map<String, dynamic>>.from(response);

    // 🔹 Ne garder que les vidéos
    setState(() {
      stories = allStories.where((story) {
        String mediaUrl = story['mediaUrl'] ?? '';
        return mediaUrl.endsWith('.mp4'); // Filtrer uniquement les vidéos
      }).toList();
    });
  }

  void _showStoryPopup(String mediaUrl) {
    if (mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune vidéo disponible pour cette story.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StoryPopup(mediaUrl: mediaUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          var story = stories[index];
          String mediaUrl = story['mediaUrl'] ?? '';

          return GestureDetector(
            onTap: () => _showStoryPopup(mediaUrl),
            child: Container(
              width: 95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 60,
                    child: Text(
                      story['name'] ?? '',
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 📌 Popup amélioré pour LIRE UNIQUEMENT LES VIDÉOS
class StoryPopup extends StatefulWidget {
  final String mediaUrl;

  const StoryPopup({super.key, required this.mediaUrl});

  @override
  _StoryPopupState createState() => _StoryPopupState();
}

class _StoryPopupState extends State<StoryPopup> {
  late VideoPlayerController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    print("📹 Chargement de la vidéo : ${widget.mediaUrl}");

    _controller = VideoPlayerController.network(widget.mediaUrl)
      ..initialize().then((_) {
        print("✅ Vidéo chargée avec succès");
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        _controller.play();
      }).catchError((error) {
        print("❌ Erreur de chargement vidéo : $error");
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Impossible de charger la vidéo."),
                )
              : Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        child: Icon(
                          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

