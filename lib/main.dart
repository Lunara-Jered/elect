import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:elect241/screens/pdfviewer.dart';
import 'package:elect241/screens/faqcreen.dart';
import 'package:elect241/screens/VideoList.dart';
import 'package:elect241/screens/feedscreen.dart';

void main() {
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
    const FAQScreen(),
    const PDFViewerSection(),
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
class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> stories = [
      {"image": "assets/brice.png", "name": "Joseph Lapensée ESINGONE","image": "assets/Brice.png", "video": "assets/video1.mp4"},
      {"image": "assets/murielle.png", "name": "Steeve ILAHOU", "video": "assets/video4.mp4"},
      {"image": "assets/seraphin.png", "name": "GNINGA CHANNING", "video": "assets/vid.mp4"},
    ];

    return SizedBox(
      height: 100, // Réduction de la taille des stories
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          var story = stories[index];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => StoryPopup(videoPath: story['video']),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30, // Réduction de la taille des avatars
                  backgroundImage: AssetImage(story['image']),
                ),
                const SizedBox(height: 5), // Espacement
                Text(
                  story['name'],
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
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
  final String videoPath;
  const StoryPopup({super.key, required this.videoPath});

  @override
  _StoryPopupState createState() => _StoryPopupState();
}

class _StoryPopupState extends State<StoryPopup> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
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
