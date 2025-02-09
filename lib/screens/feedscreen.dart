import 'package:flutter/material.dart';
import 'package:elect241/screens/components/imageview.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, String>> feedItems = [
    {"image": "assets/images/election.png", "pdf": "assets/pdfs/date.pdf"},
    {"image": "assets/images/elect.jpeg", "pdf": "assets/pdfs/date.pdf"},
    {"image": "assets/images/elect.png", "pdf": "assets/pdfs/elect.pdf"},
    {"image": "assets/images/all.png", "pdf": "assets/pdfs/elect.pdf"},
    // Suppression de l'élément vidéo
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Actualités Politiques", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView.builder(
          itemCount: feedItems.length,
          itemBuilder: (context, index) {
            final item = feedItems[index];
            return ImageItem(imagePath: item["image"]!, pdfPath: item["pdf"]!);
          },
        ),
      ),
    );
  }
}

// 📌 Widget pour afficher une image cliquable vers un PDF
class ImageItem extends StatelessWidget {
  final String imagePath;
  final String pdfPath;

  const ImageItem({required this.imagePath, required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewScreen(pdfPath: pdfPath, title: "Document PDF"),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imagePath,
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 180,
                color: Colors.grey,
                child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}
