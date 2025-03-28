import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PDFViewerSection extends StatefulWidget {
  const PDFViewerSection({super.key});

  @override
  State<PDFViewerSection> createState() => _PDFViewerSectionState();
}

class _PDFViewerSectionState extends State<PDFViewerSection> {
  List<Map<String, String>> _pdfFiles = [];
  List<Map<String, String>> _filteredFiles = [];
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isListening = false;
  late stt.SpeechToText _speech;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _fetchPDFFilesFromDatabase();
  }

  Future<void> _fetchPDFFilesFromDatabase() async {
    try {
      setState(() => _isLoading = true);

      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('pdf_files')
          .select('name, file_url');

      if (response.isNotEmpty) {
        final List<Map<String, String>> fetchedFiles = response
            .map((item) => {'name': item['name'] as String, 'url': item['file_url'] as String})
            .toList();

        setState(() {
          _pdfFiles = fetchedFiles;
          _filteredFiles = _pdfFiles;
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération des PDFs: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterFiles(String query) {
    setState(() {
      _filteredFiles = query.isEmpty
          ? _pdfFiles
          : _pdfFiles
              .where((file) => file['name']!.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
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

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lois électorales", style: TextStyle(color: Colors.white, fontSize: 18)),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? const Center(
                        child: Text("Aucun fichier PDF trouvé", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    : ListView.builder(
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          String fileName = _filteredFiles[index]['name']!;
                          String fileUrl = _filteredFiles[index]['url']!;
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PDFViewScreen(pdfUrl: fileUrl, pdfName: fileName),
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

// 📌 Écran pour afficher un PDF
class PDFViewScreen extends StatefulWidget {
  final String pdfUrl;
  final String pdfName;

  const PDFViewScreen({super.key, required this.pdfUrl, required this.pdfName});

  @override
  _PDFViewScreenState createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePDF();
  }

  Future<void> _downloadAndSavePDF() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/${widget.pdfName}.pdf");
        await file.writeAsBytes(response.bodyBytes, flush: true);

        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } else {
        print("Erreur lors du téléchargement: ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfName, style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : PDFView(
              filePath: localPath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: false,
              pageSnap: false,
              pageFling: false,
              fitPolicy: FitPolicy.BOTH, // 📌 Améliore la netteté du PDF
              onRender: (pages) {
                setState(() {
                  isLoading = false;
                });
              },
              onError: (error) => print("Erreur: $error"),
              onPageError: (page, error) => print('Erreur sur la page $page: $error'),
            ),
    );
  }
}
