import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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
  int totalPages = 0;
  int currentPage = 0;
  PDFViewController? pdfController;

  // Recherche
  TextEditingController searchController = TextEditingController();
  List<int> searchResults = []; // Liste des pages contenant le mot
  int currentSearchIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  /// 📌 Copie le fichier PDF dans un dossier temporaire
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

  /// 📌 Fonction de recherche dans le PDF (simulée, car PDFView ne supporte pas nativement la recherche)
  void _searchText(String query) async {
    if (pdfController == null || query.isEmpty) return;

    // Réinitialise la recherche
    setState(() {
      searchResults.clear();
      currentSearchIndex = 0;
    });

    // Simule une recherche (Flutter PDFView ne permet pas encore de chercher dans le texte)
    // Ici, on suppose que chaque mot-clé peut être trouvé sur n'importe quelle page au hasard (à adapter selon ton besoin)
    for (int i = 0; i < totalPages; i++) {
      if (i % 2 == 0) { // Exemple : On simule la présence du mot une page sur deux
        searchResults.add(i);
      }
    }

    // Déplace l'utilisateur vers le premier résultat
    if (searchResults.isNotEmpty) {
      pdfController?.setPage(searchResults[0]);
    }

    setState(() {});
  }

  /// 📌 Passe au résultat suivant
  void _nextSearchResult() {
    if (searchResults.isEmpty) return;
    if (currentSearchIndex < searchResults.length - 1) {
      currentSearchIndex++;
      pdfController?.setPage(searchResults[currentSearchIndex]);
      setState(() {});
    }
  }

  /// 📌 Passe au résultat précédent
  void _previousSearchResult() {
    if (searchResults.isEmpty) return;
    if (currentSearchIndex > 0) {
      currentSearchIndex--;
      pdfController?.setPage(searchResults[currentSearchIndex]);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
        actions: [
          // 📌 Barre de recherche
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
        ],
      ),
      body: localPDFPath == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PDFView(
                  filePath: localPDFPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  onRender: (pages) {
                    setState(() {
                      totalPages = pages ?? 0;
                    });
                  },
                  onViewCreated: (PDFViewController controller) {
                    setState(() {
                      pdfController = controller;
                    });
                  },
                  onPageChanged: (page, _) {
                    setState(() {
                      currentPage = page ?? 0;
                    });
                  },
                ),

                // 📌 Navigation des pages
                if (totalPages > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: currentPage > 0
                              ? () {
                                  pdfController?.setPage(currentPage - 1);
                                }
                              : null,
                        ),
                        Text("${currentPage + 1} / $totalPages"),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: currentPage < totalPages - 1
                              ? () {
                                  pdfController?.setPage(currentPage + 1);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
