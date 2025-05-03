import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PDFViewerSection extends StatefulWidget {
  const PDFViewerSection({super.key});

  @override
  State<PDFViewerSection> createState() => _PDFViewerSectionState();
}

class _PDFViewerSectionState extends State<PDFViewerSection> {
  List<Map<String, dynamic>> _pdfFiles = [];
  List<Map<String, dynamic>> _filteredFiles = [];
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isListening = false;
  late stt.SpeechToText _speech;
  final TextEditingController _searchController = TextEditingController();
  final _cacheManager = DefaultCacheManager();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _fetchPDFFilesFromDatabase();
  }

  Future<void> _fetchPDFFilesFromDatabase() async {
    try {
      setState(() => _isLoading = true);

      final response = await _supabase
          .from('pdf_files')
          .select('id, name, file_url') // Retiré updated_at
          .order('name', ascending: true); // Tri par nom à la place

      if (response != null && response.isNotEmpty) {
        final files = response.map((item) => {
          'id': item['id'].toString(),
          'name': item['name']?.toString() ?? 'Sans nom',
          'url': item['file_url']?.toString() ?? '',
          // Retiré updated_at
        }).toList();

        setState(() {
          _pdfFiles = files;
          _filteredFiles = List.from(_pdfFiles);
        });

        await _preloadPDFs();
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération des PDFs: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _preloadPDFs() async {
    try {
      await Future.wait(_pdfFiles.map((file) async {
        try {
          final url = file['url'] as String;
          if (url.isNotEmpty) {
            await _cacheManager.getFileFromCache(url);
          }
        } catch (e) {
          debugPrint("Erreur pré-chargement PDF: $e");
        }
      }));
    } catch (e) {
      debugPrint("Erreur lors du pré-chargement: $e");
    }
  }

  void _filterFiles(String query) {
    setState(() {
      _filteredFiles = query.isEmpty
          ? List.from(_pdfFiles)
          : _pdfFiles.where((file) => 
              file['name'].toString().toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  // ... (le reste du code reste inchangé jusqu'à la méthode build)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lois électorales"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterFiles('');
                }
              });
            },
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
                decoration: InputDecoration(
                  labelText: 'Rechercher',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _filterFiles,
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? const Center(child: Text("Aucun PDF disponible"))
                    : ListView.builder(
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          final file = _filteredFiles[index];
                          return ListTile(
                            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                            title: Text(file['name']),
                            onTap: () => _openPDF(context, file['url'], file['name']),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: _fetchPDFFilesFromDatabase,
      ),
    );
  }

  // ... (le reste du code reste inchangé)
}

class PDFViewScreen extends StatefulWidget {
  final String pdfUrl;
  final String pdfName;

  const PDFViewScreen({super.key, required this.pdfUrl, required this.pdfName});

  @override
  State<PDFViewScreen> createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _error;
  final _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    try {
      debugPrint("Début du chargement du PDF: ${widget.pdfUrl}");
      
      final cachedFile = await _cacheManager.getFileFromCache(widget.pdfUrl);
      if (cachedFile != null) {
        debugPrint("PDF trouvé dans le cache");
        setState(() {
          _localPath = cachedFile.file.path;
          _isLoading = false;
        });
        return;
      }

      debugPrint("Téléchargement du PDF...");
      final newFile = await _cacheManager.downloadFile(widget.pdfUrl);
      setState(() {
        _localPath = newFile.file.path;
        _isLoading = false;
      });
      debugPrint("PDF téléchargé avec succès");
      
    } catch (e) {
      debugPrint("Erreur de chargement du PDF: $e");
      setState(() {
        _error = "Impossible de charger le PDF";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfName),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    
    if (_localPath == null) {
      return const Center(child: Text("Fichier PDF introuvable"));
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      pageSnap: true,
      onError: (error) {
        debugPrint("Erreur PDF: $error");
        setState(() => _error = "Erreur d'affichage du PDF");
      },
      onPageError: (page, error) {
        debugPrint("Erreur page $page: $error");
      },
      onRender: (_) => setState(() => _isLoading = false),
    );
  }
}
