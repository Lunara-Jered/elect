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
    FAQPage(),
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

  @override
  void initState() {
    super.initState();
    fetchStories();
  }

  Future<void> fetchStories() async {
    final response = await supabase.from('stories').select();
    setState(() {
      stories = List<Map<String, dynamic>>.from(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // Ajuste la hauteur de la section des stories
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          var story = stories[index];
          return Container(
            width: 80, // Largeur fixe pour chaque story
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
    );
  }
}




// 📌 Popup Video Story
class StoryPopup extends StatefulWidget {
  final String videoUrl;
  const StoryPopup({super.key, required this.videoUrl});

  @override
  _StoryPopupState createState() => _StoryPopupState();
}

class _StoryPopupState extends State<StoryPopup> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
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
      content: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const CircularProgressIndicator(),
    );
  }
}
