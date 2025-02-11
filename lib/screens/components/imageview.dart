import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class PDFViewScreen extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PDFViewScreen({super.key, required this.pdfPath, required this.title});

  @override
  State<PDFViewScreen> createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localPDFPath;
  PdfViewerController pdfController = PdfViewerController();
  TextEditingController searchController = TextEditingController();
  List<MatchedItem> searchResults = [];
  int currentSearchIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      final byteData = await rootBundle.load(widget.pdfPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/${widget.title}");
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      setState(() {
        localPDFPath = tempFile.path;
      });
    } catch (e) {
      print("Erreur lors du chargement du PDF : $e");
    }
  }

  void _searchText(String query) async {
    if (query.isEmpty || pdfController == null) return;

    final result = await pdfController.searchText(query);
    setState(() {
      searchResults = result;
      currentSearchIndex = 0;
    });

    if (searchResults.isNotEmpty) {
      pdfController.jumpToTextInstance(searchResults[0]);
    }
  }

  void _nextSearchResult() {
    if (searchResults.isEmpty) return;
    if (currentSearchIndex < searchResults.length - 1) {
      currentSearchIndex++;
      pdfController.jumpToTextInstance(searchResults[currentSearchIndex]);
      setState(() {});
    }
  }

  void _previousSearchResult() {
    if (searchResults.isEmpty) return;
    if (currentSearchIndex > 0) {
      currentSearchIndex--;
      pdfController.jumpToTextInstance(searchResults[currentSearchIndex]);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          SizedBox(
            width: 200,
            child: TextField(
              controller: searchController,
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
            onPressed: () => _searchText(searchController.text),
          ),
          if (searchResults.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousSearchResult,
            ),
            Text("${currentSearchIndex + 1} / ${searchResults.length}"),
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
      body: localPDFPath == null
          ? const Center(child: CircularProgressIndicator())
          : SfPdfViewer.file(
              File(localPDFPath!),
              controller: pdfController,
              canShowScrollHead: true,
              canShowPaginationDialog: true,
            ),
    );
  }
}
