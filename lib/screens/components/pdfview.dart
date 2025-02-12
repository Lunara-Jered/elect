import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


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
  int _currentSearchIndex = 0;
  List<int> _searchResults = [];
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      final response = await Supabase.instance.client
          .storage
          .from('pdf_files') // Nom de votre bucket
          .download(widget.pdfPath); // Utilisez le chemin du fichier depuis Supabase

      if (response.error != null) {
        print("Erreur de téléchargement : ${response.error!.message}");
        setState(() => _isLoading = false);
        return;
      }

      final byteData = response.data!;
      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/${widget.pdfName}");

      await tempFile.writeAsBytes(byteData, flush: true);

      setState(() {
        localPDFPath = tempFile.path;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur lors du chargement du PDF : $e");
      setState(() => _isLoading = false);
    }
  }


  void _searchText(String query) {
    if (query.isEmpty) return;
    // Search functionality could be added here if needed
  }

  void _nextSearchResult() {
    if (_searchResults.isEmpty || _pdfViewController == null) return;

    if (_currentSearchIndex < _searchResults.length - 1) {
      _currentSearchIndex++;
      _pdfViewController!.setPage(_searchResults[_currentSearchIndex]);
      setState(() {});
    }
  }

  void _previousSearchResult() {
    if (_searchResults.isEmpty || _pdfViewController == null) return;

    if (_currentSearchIndex > 0) {
      _currentSearchIndex--;
      _pdfViewController!.setPage(_searchResults[_currentSearchIndex]);
      setState(() {});
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
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher...",
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onSubmitted: _searchText,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchText(_searchController.text),
          ),
          if (_searchResults.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousSearchResult,
            ),
            Text("${_currentSearchIndex + 1} / ${_searchResults.length}"),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _nextSearchResult,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () => _speakText("Je suis en création..."),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : localPDFPath == null
              ? const Center(child: Text("Erreur lors du chargement du fichier"))
              : PDFView(
                  filePath: localPDFPath!,
                  enableSwipe: true,
                  swipeHorizontal: true,
                  autoSpacing: true,
                  pageFling: true,
                  onViewCreated: (PDFViewController controller) {
                    _pdfViewController = controller;
                  },
                ),
    );
  }
}
