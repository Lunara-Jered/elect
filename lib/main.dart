import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:elect/screens/pdfviewer.dart';
import 'package:elect/screens/faqcreen.dart';
import 'package:elect/screens/VideoList.dart';
import 'package:elect/screens/feedscreen.dart';
import 'package:video_player/video_player.dart';
import 'package:country_flags/country_flags.dart';
import 'package:elect/country/cameroun/camer.dart';
import 'package:elect/country/civ/main.dart';
import 'package:elect/country/congobrazza/main.dart';

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
      home: const CountrySelectionPage(),
       routes: {
        '/gabon': (context) => const MainScreen(),
        '/cameroun': (context) => const CamerScreen(),
         '/congo': (context) => const BrazzaScreen(),
         '/civ': (context) => const CivScreen(),
        // ... ajoutez toutes vos routes
      },
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
  void _preloadVideo(String url) {
    if (url.endsWith('.mp4')) {
      final controller = VideoPlayerController.network(url);
      controller.initialize().then((_) => controller.dispose());
    }
  }
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
    
    // Pré-charger les vidéos
    for (var story in stories) {
      _preloadVideo(story['mediaUrl'] ?? '');
    }
  }
void _showStoryPopup(String mediaUrl) {
  if (mediaUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Aucun média disponible")),
    );
    return;
  }

  Navigator.push(context, MaterialPageRoute(
    builder: (_) => StoryLoadingScreen(mediaUrl: mediaUrl),
  ));
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
// Complete StoryPopup implementation
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
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.network(widget.mediaUrl)
        ..setLooping(true);
      await _controller.initialize();
      await _controller.play();
    } catch (e) {
      print("Video error: $e");
      setState(() {
        _hasError = true;
      });
    }
  }

  Widget _buildErrorWidget() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Text(
        "Impossible de charger le média.",
        style: TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildVideoWidget() {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
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
      backgroundColor: Colors.black,
      content: Stack(
        alignment: Alignment.center,
        children: [
          if (_hasError)
            _buildErrorWidget()
          else if (!_controller.value.isInitialized)
            const Center(child: CircularProgressIndicator())
          else
            _buildVideoWidget(),

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

// Correct StoryLoadingScreen implementation
class StoryLoadingScreen extends StatefulWidget {
  final String mediaUrl;
  
  const StoryLoadingScreen({super.key, required this.mediaUrl});

  @override
  _StoryLoadingScreenState createState() => _StoryLoadingScreenState();
}

class _StoryLoadingScreenState extends State<StoryLoadingScreen> {
  late VideoPlayerController _controller;
  bool _hasError = false;

  Future<void> _initializeMedia() async {
    try {
      _controller = VideoPlayerController.network(widget.mediaUrl)
        ..setLooping(true);
      await _controller.initialize();
      await _controller.play();
    } catch (e) {
      print("Media error: $e");
      setState(() {
        _hasError = true;
      });
    }
  }

  Widget _buildErrorWidget() {
    return const Center(
      child: Text(
        "Failed to load media",
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildMediaViewer() {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _initializeMedia(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_hasError) return _buildErrorWidget();
            return _buildMediaViewer();
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}


class CountrySelectionPage extends StatefulWidget {
  const CountrySelectionPage({super.key});

  @override
  State<CountrySelectionPage> createState() => _CountrySelectionPageState();
}

class _CountrySelectionPageState extends State<CountrySelectionPage> {
  final List<Map<String, dynamic>> africanFrenchCountries = const [

     {
      'name': 'Cameroun', 
      'code': 'CM', 
      'dialCode': '+237',
      'route': '/cameroun', 
    },
    {
      'name': 'Congo', 
      'code': 'CG', 
      'dialCode': '+242',
      'route': '/congo', 
    },
    {
      'name': "Côte d'Ivoire", 
      'code': 'CI', 
      'dialCode': '+225',
      'route': '/civ', 
    },
    {
     'name': 'Gabon', 
     'code': 'GA', 
     'dialCode': '+241',
     'route': '/gabon', 
    },
  ];

  List<Map<String, dynamic>> filteredCountries = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCountries = List.from(africanFrenchCountries);
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredCountries = africanFrenchCountries.where((country) {
        return country['name'].toString().toLowerCase().contains(query) ||
               country['dialCode'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  void _navigateToCountryPage(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 100.0, // Réduit la hauteur pour un logo
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Image.asset(
              'assets/banner.png', // Utilisez votre logo ici
              height: 50, // Taille du logo
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => 
                const Text('Mon App'), // Fallback textuel
            ),
            background: Container(color: Colors.white), // Fond uni
            collapseMode: CollapseMode.parallax,
          ),
          backgroundColor: Colors.white,
          elevation: 0, // Supprime l'ombre
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100], // Fond légèrement gris
                hintText: 'Rechercher un pays...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none, // Pas de bordure
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final country = filteredCountries[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: CountryFlag.fromCountryCode(
                      country['code'],
                      height: 30,
                      width: 40,
                    ),
                    title: Text(
                      country['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Code: ${country['dialCode']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward,
                      color: Colors.blue[700],
                    ),
                    onTap: () => _navigateToCountryPage(context, country['route']),
                  ),
                ),
              );
            },
            childCount: filteredCountries.length,
          ),
        ),
      ],
    ),
  );
}
}
