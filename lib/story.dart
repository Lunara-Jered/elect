import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const Elect241App());
}

class Elect241App extends StatelessWidget {
  const Elect241App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
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
    const PDFViewerSection(),
    VideoScreen(),
    const FAQScreen(),
    const FeedScreen(),
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
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
        BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: "Lois Électorales"),
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Décryptages"),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: "FAQ"),
        BottomNavigationBarItem(icon: Icon(Icons.image_aspect_ratio), label: "Actualités"),
      ],
      onTap: onItemTapped,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  final List<String> videoPaths = [
  'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4', // Test URL
];


  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
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
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _questionController = TextEditingController();
  final Map<String, List<String>> _faqData = {}; // Stocke les questions et réponses

  void _addQuestion() {
    String question = _questionController.text.trim();
    if (question.isNotEmpty) {
      setState(() {
        _faqData[question] = [];
      });
      _questionController.clear();
    }
  }

  void _addAnswer(String question, String answer) {
    if (answer.isNotEmpty) {
      setState(() {
        _faqData[question]?.add(answer);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40), // 📌 Réduction de la hauteur de l'AppBar
        child: AppBar(
          title: const Text("Feed", style: TextStyle(color: Colors.white, fontSize: 18)),
          backgroundColor: Colors.blue,
        ),
      ),
      body: Column(
        children: [
          // 📌 Champ pour poser une question
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: "Posez votre question...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _addQuestion,
                ),
              ],
            ),
          ),

          // 📌 Liste des questions et réponses
          Expanded(
            child: ListView.builder(
              itemCount: _faqData.length,
              itemBuilder: (context, index) {
                String question = _faqData.keys.elementAt(index);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ExpansionTile(
                    title: Text(
                      "❓ $question",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      // 📌 Liste des réponses
                      ..._faqData[question]!.map((answer) => ListTile(
                            title: Text("💬 $answer"),
                            leading: const Icon(Icons.comment, color: Colors.blue),
                          )),

                      // 📌 Champ pour répondre
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Votre réponse...",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onSubmitted: (value) => _addAnswer(question, value),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.green),
                              onPressed: () {
                                _addAnswer(question, _questionController.text);
                                _questionController.clear();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PDFViewerSection extends StatefulWidget {
  const PDFViewerSection({super.key});

  @override
  State<PDFViewerSection> createState() => _PDFViewerSectionState();
}

class _PDFViewerSectionState extends State<PDFViewerSection> {
  List<String> _pdfFiles = [];
  List<String> _filteredFiles = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    getFiles();  // Charge les fichiers PDF au démarrage
  }

  /// 📌 Charge les fichiers PDF depuis les assets
  Future<void> getFiles() async {
    try {
      // Charge la liste des fichiers déclarés dans `pubspec.yaml`
      String manifestContent = await rootBundle.loadString('AssetManifest.json');
      Map<String, dynamic> manifestMap = json.decode(manifestContent);

      List<String> assetPaths = manifestMap.keys
          .where((String key) => key.endsWith('.pdf'))  // Filtre uniquement les PDF
          .toList();

      setState(() {
        _pdfFiles = assetPaths;
        _filteredFiles = _pdfFiles;
      });
    } catch (e) {
      print("Erreur lors de la récupération des fichiers : $e");
    }
  }

  /// 📌 Filtre les fichiers en fonction de la recherche
  void _filterFiles(String query) {
    setState(() {
      _filteredFiles = query.isEmpty
          ? _pdfFiles
          : _pdfFiles.where((file) => path.basename(file).toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
     appBar: PreferredSize(
  preferredSize: const Size.fromHeight(40), // 📌 Réduction de la hauteur de l'AppBar
  child: AppBar(
    title: !_isSearching
        ? const Text("Lois électorales", style: TextStyle(color: Colors.white, fontSize: 18))
        : TextField(
            decoration: const InputDecoration(
              hintText: "Rechercher un PDF...",
              border: InputBorder.none,
            ),
            onChanged: _filterFiles,
          ),
    backgroundColor: Colors.blue,
    elevation: 0,
    actions: [
      IconButton(
        onPressed: () {
          setState(() {
            _isSearching = !_isSearching;
            _filteredFiles = _pdfFiles;
          });
        },
        icon: Icon(_isSearching ? Icons.cancel : Icons.search),
      )
    ],
  ),
),

      body: _filteredFiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredFiles.length,
              itemBuilder: (context, index) {
                String filePath = _filteredFiles[index];
                String fileName = path.basename(filePath);
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.yellow, size: 30),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PDFViewScreen(pdfPath: filePath, pdfName: fileName),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: getFiles,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 📌 Liste des images et leurs PDF associés
    List<Map<String, String>> feedItems = [
      {"image": "assets/images/election.png", "pdf": "assets/pdfs/date.pdf"},
      {"image": "assets/images/elect.png", "pdf": "assets/pdfs/elect.pdf"},
      {"image": "assets/images/all.png", "pdf": "assets/pdfs/elect.pdf"},
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40), // 📌 Réduction de la hauteur de l'AppBar
        child: AppBar(
          title: const Text("Feed", style: TextStyle(color: Colors.white, fontSize: 18)),
          backgroundColor: Colors.blue,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView.builder(
          itemCount: feedItems.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15), // 📌 Espacement entre les images
              child: GestureDetector(
                onTap: () {
                  // 📌 Navigation vers la page PDF
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PDFViewScreen(
                        pdfPath: feedItems[index]["pdf"]!,
                        title: "Document PDF",
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 150, // 📌 Hauteur du conteneur pour l'image
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    feedItems[index]["image"]!,
                    width: double.infinity, // 📌 Largeur adaptable
                    height: 150, // 📌 Hauteur fixe pour uniformiser
                    fit: BoxFit.cover, // 📌 Remplissage optimal sans distorsion
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  String? videoPath;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final tempDir = await getTemporaryDirectory();
    final tempVideoFile = File("${tempDir.path}/video.mp4");

    if (!await tempVideoFile.exists()) {
      final byteData = await rootBundle.load("assets/vid/video.mp4");
      await tempVideoFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    }

    setState(() {
      videoPath = tempVideoFile.path;
      _controller = VideoPlayerController.file(tempVideoFile)
        ..initialize().then((_) {
          print("Vidéo chargée : ${_controller.value.size}"); // 🔥 Vérifier si la vidéo est bien chargée
          setState(() {});
          _controller.play();
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
    return Scaffold(
      appBar: AppBar(title: const Text("Lecture Vidéo")),
      body: videoPath == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SizedBox(
                height: 300, // 🔥 Définit une hauteur pour éviter une vidéo invisible
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio > 0
                      ? _controller.value.aspectRatio
                      : 16 / 9, // 🔥 Si `0.0`, utiliser 16:9
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
    );
  }
}

class PDFViewScreen extends StatefulWidget {
  final String pdfPath; // 📌 Ex: "assets/pdfs/document.pdf"
  final String pdfName; // 📌 Ex: "document.pdf"

  const PDFViewScreen({super.key, required this.pdfPath, required this.pdfName});

  @override
  State<PDFViewScreen> createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localPDFPath; // 📌 Stocke le chemin du PDF copié

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  /// 📌 Copie le fichier des assets vers un dossier temporaire pour pouvoir l'afficher
  Future<void> _loadPDF() async {
    try {
      // 📌 Charge le fichier PDF depuis les assets
      final byteData = await rootBundle.load(widget.pdfPath);
      
      // 📌 Récupère un dossier temporaire
      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/${widget.pdfName}");
      
      // 📌 Écrit les données du fichier
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      setState(() {
        localPDFPath = tempFile.path;
      });
    } catch (e) {
      print("Erreur lors du chargement du PDF : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfName),
        backgroundColor: Colors.blue,
      ),
      body: localPDFPath == null
          ? const Center(child: CircularProgressIndicator()) // 📌 Affiche un loader le temps que le fichier soit copié
          : PDFView(
              filePath: localPDFPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
            ),
    );
  }
}

class PDFViewScreen extends StatefulWidget {
  final String pdfPath; // 📌 Ex: "assets/pdfs/document.pdf"
  final String title; // 📌 Ex: "document.pdf"

  const PDFViewScreen({super.key, required this.pdfPath, required this.title});

  @override
  State<PDFViewScreen> createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localPDFPath; // 📌 Stocke le chemin du PDF copié

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  /// 📌 Copie le fichier des assets vers un dossier temporaire pour pouvoir l'afficher
  Future<void> _loadPDF() async {
    try {
      // 📌 Charge le fichier PDF depuis les assets
      final byteData = await rootBundle.load(widget.pdfPath);
      
      // 📌 Récupère un dossier temporaire
      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/${widget.title}");
      
      // 📌 Écrit les données du fichier
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      setState(() {
        localPDFPath = tempFile.path;
      });
    } catch (e) {
      print("Erreur lors du chargement du PDF : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
      ),
      body: localPDFPath == null
          ? const Center(child: CircularProgressIndicator()) // 📌 Affiche un loader le temps que le fichier soit copié
          : PDFView(
              filePath: localPDFPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
            ),
    );
  }
}
// 📌 Section des Stories
class StorySection extends StatelessWidget {
  const StorySection({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> stories = [
      {"image": "assets/brice.png", "name": "Brice OLIGUI NGUEMA"},
      {"image": "assets/murielle.png", "name": "Murielle MINKOUE"},
      {"image": "assets/seraphin.png", "name": "Séraphin Moundounga"},
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          var story = stories[index];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => StoryPopup(story['image']),
              );
            },
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(story['image']),
                ),
                Text(story['name'], style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 📌 Popup Story
class StoryPopup extends StatelessWidget {
  final String media;
  const StoryPopup(this.media, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Image.asset(media, fit: BoxFit.cover),
    );
  }
}
