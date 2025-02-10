import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

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
                    Expanded(
                      child: PDFView(
                        filePath: localPDFPath!,
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: true,
                        pageFling: true,
                        defaultPage: _searchPage ?? 0, // Correction ici
                      ),
                    ),
                  ],
                ),
    );
  }
}
