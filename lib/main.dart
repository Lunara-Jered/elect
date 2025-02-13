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

// 📌 Section des Stories avec Vidéos 
class StorySection extends StatefulWidget {
  const StorySection({super.key});

  @override
  _StorySectionState createState() => _StorySectionState();
}

class _StorySectionState extends State<StorySection> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> stories = [];
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.25);
    fetchStories();
  }

  Future<void> fetchStories() async {
    final response = await supabase.from('stories').select();
    print("Stories récupérées: $response"); // Debugging pour voir les données

    if (response != null && response.isNotEmpty) {
      if (mounted) {
        setState(() {
          stories = List<Map<String, dynamic>>.from(response);
        });
        startAutoScroll(); // Lancer le défilement SEULEMENT si des stories existent
      }
    }
  }

  void startAutoScroll() {
    if (stories.isEmpty) return; // Ne pas démarrer si pas de stories

    _timer?.cancel(); // Annuler le timer précédent avant d’en créer un nouveau
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) { // Augmenter la durée
      if (_currentIndex < stories.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      if (mounted) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0), // Ajoute un espace en haut
    child: SizedBox(
      height: 100, // Ajuste la hauteur de la section des stories
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          var story = stories[index];
          return Container(
            width: 80, // Largeur fixe pour chaque story
            margin: const EdgeInsets.symmetric(horizontal: 5), // Espacement entre stories
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(story['imageUrl'] ?? ''),
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
          );
        },
      ),
    ),
  );
}




// 📌 Popup Video Story
class StoryPopup extends StatefulWidget {
  final List<String> mediaUrls;
  const StoryPopup({super.key, required this.mediaUrls});

  @override
  _StoryPopupState createState() => _StoryPopupState();
}

class _StoryPopupState extends State<StoryPopup> {
  late PageController _pageController;
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.mediaUrls.isNotEmpty) {
      _initializeMedia(widget.mediaUrls[_currentIndex]);
      startAutoScroll();
    }
  }

  void _initializeMedia(String url) {
    if (url.endsWith('.mp4')) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.network(url)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.play();
          }
        });
    }
  }

  void startAutoScroll() {
    if (widget.mediaUrls.length <= 1) return; // Pas besoin de défiler s'il y a une seule image/vidéo

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < widget.mediaUrls.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
      if (mounted) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
      _initializeMedia(widget.mediaUrls[_currentIndex]);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: SizedBox(
        height: 400,
        width: 300,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.mediaUrls.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            _initializeMedia(widget.mediaUrls[_currentIndex]);
          },
          itemBuilder: (context, index) {
            String url = widget.mediaUrls[index];
            return url.endsWith('.mp4')
                ? (_videoController != null && _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const Center(child: CircularProgressIndicator()))
                : Image.network(url, fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}

