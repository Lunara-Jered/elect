import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final SpeechToText _speechToText = SpeechToText();

  List<Map<String, dynamic>> _faqList = [];
  List<Map<String, dynamic>> _filteredFaqList = [];
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _fetchFaq();
    _listenForAnswers();
  }

  /// 📌 Initialiser les notifications locales
  void _initNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    _notificationsPlugin.initialize(initializationSettings);
  }

  /// 📌 Afficher une notification
  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'faq_channel',
      'FAQ Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  /// 📌 Ajouter une question dans la base de données
  Future<void> _addQuestion() async {
    String question = _questionController.text.trim();
    if (question.isNotEmpty) {
      await supabase.from('faq').insert({'question': question, 'answer': null});
      _questionController.clear();
      _fetchFaq(); // Rafraîchir la liste après ajout
    }
  }

  /// 📌 Écouter les nouvelles réponses et envoyer une notification
  void _listenForAnswers() {
    supabase.from('faq').stream(primaryKey: ['id']).listen((data) {
      for (var row in data) {
        if (row['answer'] != null) {
          _showNotification("Nouvelle réponse !", row['answer']);
        }
      }
      _fetchFaq(); // Rafraîchir la liste en temps réel
    });
  }

  /// 📌 Récupérer les questions depuis Supabase
  Future<void> _fetchFaq() async {
    final List<Map<String, dynamic>> data = await supabase.from('faq').select();
    setState(() {
      _faqList = data;
      _filteredFaqList = data;
    });
  }

  /// 📌 Filtrer les questions en fonction de la recherche
  void _filterFaq(String query) {
    setState(() {
      _filteredFaqList = _faqList
          .where((faq) =>
              faq['question'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// 📌 Activer la recherche vocale
  Future<void> _startListening() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(onResult: (result) {
        _searchController.text = result.recognizedWords;
        _filterFaq(result.recognizedWords);
      });
    }
  }

  /// 📌 Arrêter la reconnaissance vocale
  void _stopListening() {
    setState(() => _isListening = false);
    _speechToText.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQ", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchFaq, // Rafraîchir les données
          ),
        ],
      ),
      body: Column(
        children: [
          // 📌 Barre de recherche avec reconnaissance vocale
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterFaq,
                    decoration: InputDecoration(
                      hintText: "Rechercher une question...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.blue),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
              ],
            ),
          ),

          // 📌 Champ pour poser une nouvelle question
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: "Posez votre question...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _addQuestion,
                ),
              ],
            ),
          ),

          // 📌 Liste des questions filtrées
          Expanded(
            child: _filteredFaqList.isEmpty
                ? const Center(child: Text("Aucune question trouvée"))
                : ListView.builder(
                    itemCount: _filteredFaqList.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqList[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ExpansionTile(
                          title: Text("❓ ${faq['question']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          children: [
                            if (faq['answer'] != null)
                              ListTile(
                                title: Text("💬 ${faq['answer']}"),
                                leading: const Icon(Icons.comment, color: Colors.blue),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
