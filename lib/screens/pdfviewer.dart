import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
  final _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _fetchPDFFilesFromDatabase();
  }

  Future<void> _fetchPDFFilesFromDatabase() async {
    try {
      setState(() => _isLoading = true);

      final response = await Supabase.instance.client
          .from('pdf_files')
          .select('name, file_url, updated_at')
          .order('updated_at', ascending: false);

      if (response.isNotEmpty) {
        final files = response.map((item) => {
          'name': item['name'] as String,
          'url': item['file_url'] as String,
          'updated_at': item['updated_at'] as String,
        }).toList();

        setState(() {
          _pdfFiles = files;
          _filteredFiles = _pdfFiles;
        });

        _preloadPDFs();
      }
    } catch (e) {
      print("Erreur lors de la récupération des PDFs: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _preloadPDFs() async {
    for (var file in _pdfFiles) {
      try {
        await _cacheManager.getFileFromCache(file['url']!);
      } catch (e) {
        print("Erreur pré-chargement PDF ${file['name']}: $e");
      }
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
                        child: Text("Aucun fichier PDF trouvé", 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    : ListView.builder(
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = _filteredFiles[index];
                          return _PDFListItem(
                            fileName: file['name']!,
                            fileUrl: file['url']!,
                            onTap: () => _openPDF(context, file['url']!, file['name']!),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchPDFFilesFromDatabase,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _openPDF(BuildContext context, String url, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewScreen(pdfUrl: url, pdfName: name),
      ),
    );
  }
}

class _PDFListItem extends StatelessWidget {
  final String fileName;
  final String fileUrl;
  final VoidCallback onTap;

  const _PDFListItem({
    required this.fileName,
    required this.fileUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}

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
  final _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      // Vérifie d'abord le cache
      final fileInfo = await _cacheManager.getFileFromCache(widget.pdfUrl);
      
      if (fileInfo != null) {
        setState(() {
          localPath = fileInfo.file.path;
          isLoading = false;
        });
        return;
      }

      // Télécharge si pas dans le cache
      final newFileInfo = await _cacheManager.downloadFile(widget.pdfUrl);
      setState(() {
        localPath = newFileInfo.file.path;
        isLoading = false;
      });
    } catch (e) {
      print("Erreur chargement PDF: $e");
      setState(() => isLoading = false);
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
          : localPath == null
              ? const Center(child: Text("Impossible de charger le PDF"))
              : PDFView(
                  filePath: localPath,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  pageSnap: true,
                  onRender: (_) => setState(() => isLoading = false),
                  onError: (error) => print("Erreur PDF: $error"),
                  onPageError: (page, error) => print('Erreur page $page: $error'),
                ),
    );
  }
}
