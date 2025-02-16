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

  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// 🔄 Rafraîchit automatiquement l'application lorsque la base de données change
  void _setupRealtimeListener() {
    for (var table in ['stories', 'videos', 'faq', 'feed_items', 'pdf_files']) {
      supabase
          .from(table)
          .stream(primaryKey: ['id'])
          .listen((event) {
        print("🔄 Mise à jour détectée dans $table");
        setState(() {}); // Rafraîchir l'application
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    final List<Map<String, dynamic>> results = [];

    // 🔍 Recherche dans les 5 tables
    final stories = await supabase.from('stories').select().ilike('name', '%$query%');
    final videos = await supabase.from('videos').select().ilike('title', '%$query%');
    final faqs = await supabase.from('faq').select().ilike('question', '%$query%');
    final feedItems = await supabase.from('feed_items').select().ilike('content', '%$query%');
    final pdfs = await supabase.from('pdf_files').select().ilike('title', '%$query%');

    // Ajout des résultats avec indication du type
    results.addAll(stories.map((e) => {...e, 'type': 'story'}));
    results.addAll(videos.map((e) => {...e, 'type': 'video'}));
    results.addAll(faqs.map((e) => {...e, 'type': 'faq'}));
    results.addAll(feedItems.map((e) => {...e, 'type': 'feed_item'}));
    results.addAll(pdfs.map((e) => {...e, 'type': 'pdf'}));

    setState(() {
      searchResults = results;
    });
  }

  void _openResult(Map<String, dynamic> result) {
    switch (result['type']) {
      case 'story':
        _showStoryPopup(result['mediaUrl']);
        break;
      case 'video':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(videoPath: result['url']),
          ),
        );
        break;
      case 'faq':
      case 'feed_item':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result['type'] == 'faq' ? result['question'] : "Actualité"),
            content: Text(result['type'] == 'faq' ? result['answer'] : result['content']),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("Fermer"))
            ],
          ),
        );
        break;
      case 'pdf':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewSection(),
          ),
        );
        break;
    }
  }

  void _showStoryPopup(String mediaUrl) {
    if (mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun média disponible pour cette story.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StoryPopup(mediaUrl: mediaUrl), // ✅ Correction ici
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.white,
        title: Image.asset("assets/banner.png", height: 40),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.black),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DataSearch(_performSearch, searchResults, _openResult),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const StorySection(),
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

class DataSearch extends SearchDelegate<String> {
  final Function(String) onSearch;
  final List<Map<String, dynamic>> results;
  final Function(Map<String, dynamic>) onResultTap;

  DataSearch(this.onSearch, this.results, this.onResultTap);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = "",
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, ""),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          title: Text(item['name'] ?? item['title'] ?? item['question'] ?? "Résultat"),
          subtitle: Text(item['type'].toUpperCase()),
          onTap: () => onResultTap(item),
        );
      },
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
    setState(() {
      stories = List<Map<String, dynamic>>.from(response);
    });
  }

  void _showStoryPopup(String mediaUrl) {
    if (mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun média disponible pour cette story.")),
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
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          var story = stories[index];
          String imageUrl = story['imageUrl'] ?? '';
          String mediaUrl = story['mediaUrl'] ?? '';
          String name = story['name'] ?? 'Sans nom';
          bool isVideo = mediaUrl.endsWith('.mp4');

          return GestureDetector(
            onTap: () => _showStoryPopup(mediaUrl),
            child: Container(
              width: 95,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(imageUrl),
                    child: isVideo
                        ? const Icon(Icons.play_circle_fill, color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 60,
                    child: Text(
                      name,
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

// 📌 Popup qui affiche les images et vidéos
class StoryPopup extends StatefulWidget {
  final String mediaUrl;

  const StoryPopup({super.key, required this.mediaUrl});

  @override
  _StoryPopupState createState() => _StoryPopupState();
}

class _StoryPopupState extends State<StoryPopup> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    print("📹 Chargement de la vidéo : ${widget.mediaUrl}");

    _controller = VideoPlayerController.network(widget.mediaUrl)
      ..initialize().then((_) {
        print("✅ Vidéo chargée avec succès");
        setState(() {});
        _controller.play();
      }).catchError((error) {
        print("❌ Erreur de chargement vidéo : $error");
        setState(() {
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
      backgroundColor: Colors.black, // Fond noir pour un effet immersif
      content: Stack(
        alignment: Alignment.center,
        children: [
          if (_hasError)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Impossible de charger la vidéo.",
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          else if (!_controller.value.isInitialized)
            const Center(child: CircularProgressIndicator())
          else
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),

          // Bouton "Fermer"
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Bouton Play/Pause
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

