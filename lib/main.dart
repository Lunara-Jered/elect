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
      home: const CountrySelectionPage(),
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

import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pays Francophones',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CountrySelectionPage(),
    );
  }
}

class CountrySelectionPage extends StatefulWidget {
  const CountrySelectionPage({super.key});

  @override
  State<CountrySelectionPage> createState() => _CountrySelectionPageState();
}

class _CountrySelectionPageState extends State<CountrySelectionPage> {
  final List<Map<String, String>> africanFrenchCountries = const [
    {'name': 'Algérie', 'code': 'DZ', 'dialCode': '+213'},
    {'name': 'Bénin', 'code': 'BJ', 'dialCode': '+229'},
    {'name': 'Burkina Faso', 'code': 'BF', 'dialCode': '+226'},
    {'name': 'Burundi', 'code': 'BI', 'dialCode': '+257'},
    {'name': 'Cameroun', 'code': 'CM', 'dialCode': '+237'},
    {'name': 'Comores', 'code': 'KM', 'dialCode': '+269'},
    {'name': 'Congo', 'code': 'CG', 'dialCode': '+242'},
    {'name': "Côte d'Ivoire", 'code': 'CI', 'dialCode': '+225'},
    {'name': 'Djibouti', 'code': 'DJ', 'dialCode': '+253'},
    {'name': 'Gabon', 'code': 'GA', 'dialCode': '+241'},
    {'name': 'Guinée', 'code': 'GN', 'dialCode': '+224'},
    {'name': 'Guinée équatoriale', 'code': 'GQ', 'dialCode': '+240'},
    {'name': 'Madagascar', 'code': 'MG', 'dialCode': '+261'},
    {'name': 'Mali', 'code': 'ML', 'dialCode': '+223'},
    {'name': 'Maroc', 'code': 'MA', 'dialCode': '+212'},
    {'name': 'Mauritanie', 'code': 'MR', 'dialCode': '+222'},
    {'name': 'Niger', 'code': 'NE', 'dialCode': '+227'},
    {'name': 'République centrafricaine', 'code': 'CF', 'dialCode': '+236'},
    {'name': 'République démocratique du Congo', 'code': 'CD', 'dialCode': '+243'},
    {'name': 'Rwanda', 'code': 'RW', 'dialCode': '+250'},
    {'name': 'Sénégal', 'code': 'SN', 'dialCode': '+221'},
    {'name': 'Seychelles', 'code': 'SC', 'dialCode': '+248'},
    {'name': 'Tchad', 'code': 'TD', 'dialCode': '+235'},
    {'name': 'Togo', 'code': 'TG', 'dialCode': '+228'},
    {'name': 'Tunisie', 'code': 'TN', 'dialCode': '+216'},
  ];

  List<Map<String, String>> filteredCountries = [];
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
        return country['name']!.toLowerCase().contains(query) ||
               country['dialCode']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _navigateToCountryPage(BuildContext context, String countryName, String countryCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CountryDetailPage(
          countryName: countryName,
          countryCode: countryCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                'assets/banner.png', // Remplacez par votre image
                fit: BoxFit.cover,
              ),
            ),
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un pays...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final country = filteredCountries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CountryFlag.fromCountryCode(
                      country['code']!,
                      height: 30,
                      width: 40,
                    ),
                    title: Text(
                      country['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Code: ${country['dialCode']}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _navigateToCountryPage(
                      context,
                      country['name']!,
                      country['code']!,
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

class CountryDetailPage extends StatelessWidget {
  final String countryName;
  final String countryCode;

  const CountryDetailPage({
    super.key,
    required this.countryName,
    required this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(countryName),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CountryFlag.fromCountryCode(
              countryCode,
              height: 100,
              width: 150,
            ),
            const SizedBox(height: 20),
            Text(
              countryName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
