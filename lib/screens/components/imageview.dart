import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf_text/pdf_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  FlutterTts flutterTts = FlutterTts();
  String extractedText = "";

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

      _extractTextFromPDF(tempFile.path);
    } catch (e) {
      print("Erreur lors du chargement du PDF : $e");
    }
  }

  Future<void> _extractTextFromPDF(String path) async {
    try {
      PDFDoc doc = await PDFDoc.fromFile(File(path));
      String text = await doc.text;
      setState(() {
        extractedText = text;
      });
    } catch (e) {
      print("Erreur lors de l'extraction du texte : $e");
    }
  }

  Future<void> _speakText() async {
    if (extractedText.isNotEmpty) {
      await flutterTts.speak(extractedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: _speakText,
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
