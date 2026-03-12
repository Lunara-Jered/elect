// lib/services/pdf_search_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class PDFSearchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Rechercher dans les PDFs
  Future<List<Map<String, dynamic>>> searchPDFs(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _supabase
          .rpc('search_pdfs', params: {'search_query': query});

      if (response == null || response.isEmpty) return [];

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur recherche: $e');
      return [];
    }
  }

  // Mettre à jour le contenu d'un PDF (après extraction)
  Future<void> updatePDFContent(int pdfId, String content) async {
    await _supabase
        .from('pdf_files')
        .update({'content': content, 'last_indexed': DateTime.now().toIso8601String()})
        .eq('id', pdfId);
  }
}
