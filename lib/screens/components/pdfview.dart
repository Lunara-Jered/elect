import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdf_text/pdf_text.dart';

class PDFViewScreen extends StatefulWidget {
  final String pdfPath;
  final String pdfName;

  const PDFViewScreen({super.key, required this.pdfPath, required this.pdfName});

  @override
  State<PDFViewScreen> createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localPDFPath;
  bool _isLoading = true;
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();
  int? _searchPage;
  String _pdfText = '';
  List<String> _pageTexts = [];
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      final byteData = await rootBundle.load(widget.pdfPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/${widget.pdfName}");
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      // Extraire le texte par page
      await _extractTextFromPDF(tempFile);

      setState(() {
        localPDFPath = tempFile.path;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement du PDF : $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Extraire le texte par page
  Future<void> _extractTextFromPDF(File file) async {
    PDFDoc doc = await PDFDoc.fromFile(file);
    _totalPages = await doc.countPages;
    for (var i = 0; i < _totalPages; i++) {
      String pageText = await doc.pageAt(i).then((page) => page.text);
      _pageTexts.add(pageText);  // Stocke le texte de chaque page
    }
  }

  // Recherche dans le texte extrait du PDF
  void _searchInPDF(String query) {
    int foundPage = -1;
    for (int i = 0; i < _pageTexts.length; i++) {
      if (_pageTexts[i].contains(query)) {
        foundPage = i;
        break;
      }
    }

    if (foundPage != -1) {
      setState(() {
        _searchPage = foundPage;
      });
      print("Mot trouvé à la page : $foundPage");
    } else {
      print("Mot non trouvé.");
    }
  }

  Future<void> _speakText(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfName),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => _speakText("Lecture du document en cours..."),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : localPDFPath == null
              ? const Center(child: Text("Erreur lors du chargement du fichier"))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: "Rechercher dans le PDF",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () {
                              _searchInPDF(_searchController.text);
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PDFView(
                        filePath: localPDFPath!,
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: true,
                        pageFling: true,
                        pageIndex: _searchPage ?? 0, // Naviguer vers la page recherchée
                      ),
                    ),
                  ],
                ),
    );
  }
}
