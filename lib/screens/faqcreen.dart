import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _questionController = TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
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
      setState(() {}); // Rafraîchir l'affichage
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
    });
  }

  /// 📌 Récupérer les questions depuis Supabase
  Future<List<Map<String, dynamic>>> _fetchFaq() async {
    return await supabase.from('faq').select();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQ"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // 📌 Champ pour poser une question
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

          // 📌 Liste des questions et réponses
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFaq(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final faqList = snapshot.data!;
                return ListView.builder(
                  itemCount: faqList.length,
                  itemBuilder: (context, index) {
                    final faq = faqList[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
