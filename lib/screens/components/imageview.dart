import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

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
