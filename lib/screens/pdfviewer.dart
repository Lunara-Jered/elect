import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:elect241/screens/components/pdfview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';

class PDFViewerSection extends StatefulWidget {
  const PDFViewerSection({super.key});

  @override
  State<PDFViewerSection> createState() => _PDFViewerSectionState();
}

class _PDFViewerSectionState extends State<PDFViewerSection> {
  List<String> _pdfFiles = [];
  List<String> _filteredFiles = [];
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isListening = false;
  late stt.SpeechToText _speech;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _fetchPDFFilesFromDatabase(); // Get PDF files from Supabase
  }

  // 📌 Charge les fichiers PDF depuis Supabase
 Future<void> _fetchPDFFilesFromDatabase() async {
  try {
    setState(() => _isLoading = true);

    final List<Map<String, dynamic>> response = await Supabase.instance.client
        .from('pdf_files') // Nom correct de la table
        .select('file_url'); // Nom correct de la colonne

    // ✅ Vérifier si des données existent
    if (response.isNotEmpty) {
      final List<String> fetchedFiles = response.map((item) => item['file_url'] as String).toList();
      setState(() {
        _pdfFiles = fetchedFiles;
        _filteredFiles = _pdfFiles;
      });
    } else {
      print('Aucun fichier trouvé dans la base de données.');
    }
  } catch (e) {
    print("Erreur lors de la récupération des PDFs: $e");
  } finally {
    setState(() => _isLoading = false);
  }
}

  // 📌 Filtre les fichiers en fonction de la recherche
  void _filterFiles(String query) {
    setState(() {
      _filteredFiles = query.isEmpty
          ? _pdfFiles
          : _pdfFiles
              .where((file) =>
                  path.basename(file).toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  // 📌 Démarre la reconnaissance vocale
  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print("Status: $status"),
      onError: (error) => print("Error: $error"),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
            _filterFiles(_searchController.text);
          });
        },
      );
    }
  }

  // 📌 Arrête la reconnaissance vocale
  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lois électorales",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _filteredFiles = _pdfFiles;
                _searchController.clear();
              });
            },
            icon: Icon(_isSearching ? Icons.cancel : Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          // Champ de recherche en haut de la liste
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterFiles,
                decoration: InputDecoration(
                  labelText: 'Rechercher',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),

          // Liste des fichiers PDF
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun fichier PDF trouvé",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          String filePath = _filteredFiles[index];
                          String fileName = path.basename(filePath);
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(fileName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              leading: const Icon(Icons.picture_as_pdf,
                                  color: Colors.red, size: 30),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewScreen(
                                        pdfPath: filePath, pdfName: fileName),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _fetchPDFFilesFromDatabase()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
