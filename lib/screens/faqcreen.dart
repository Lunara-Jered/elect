import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Map<String, List<String>> _faqData = {}; // Stocke les questions et réponses

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadFAQData();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    _notificationsPlugin.initialize(settings);
  }

  Future<void> _showNotification(String question) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'faq_channel',
      'FAQ Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
        0, 'Nouvelle réponse', 'Une réponse a été ajoutée à "$question"', details);
  }

  Future<void> _loadFAQData() async {
  final response = await Supabase.instance.client.from('faq').select();

  if (response.isNotEmpty) {
    setState(() {
      _faqData.clear();
      for (var item in response) {
        // Vérifier si 'answer' est bien une liste
        if (item['answer'] is List) {
          _faqData[item['question']] =
              (item['answer'] as List).map((e) => e.toString()).toList();
        } else if (item['answer'] is String) {
          // Si c'est une chaîne, essayer de parser en JSON
          try {
            _faqData[item['question']] =
                (jsonDecode(item['answer']) as List).map((e) => e.toString()).toList();
          } catch (e) {
            _faqData[item['question']] = []; // Valeur par défaut si erreur
          }
        } else {
          _faqData[item['question']] = [];
        }
      }
    });
  } else {
    print('Erreur lors du chargement des FAQ');
  }
}


  Future<void> _addQuestion() async {
    String question = _questionController.text.trim();
    if (question.isNotEmpty && !_faqData.containsKey(question)) {
      final response = await Supabase.instance.client.from('faq').insert([
        {'question': question, 'answer': []}
      ]);

      if (!response.error) {
        setState(() {
          _faqData[question] = [];
        });
        _questionController.clear();
      } else {
        print("Erreur lors de l'ajout de la question");
      }
    }
  }

  Future<void> _addAnswer(String question) async {
    String answer = _answerController.text.trim();
    if (answer.isNotEmpty) {
      final updatedAnswers = [..._faqData[question]!, answer];

      final response = await Supabase.instance.client.from('faq').update({
        'answer': updatedAnswers
      }).eq('question', question);

      if (!response.error) {
        setState(() {
          _faqData[question] = updatedAnswers;
        });
        _answerController.clear();
        _showNotification(question);
      } else {
        print("Erreur lors de l'ajout de la réponse");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQ",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: "Posez votre question...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10),
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
          Expanded(
            child: ListView.builder(
              itemCount: _faqData.length,
              itemBuilder: (context, index) {
                String question = _faqData.keys.elementAt(index);
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  child: ExpansionTile(
                    title: Text("❓ $question",
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      ..._faqData[question]!.map((answer) => ListTile(
                            title: Text("💬 $answer"),
                            leading:
                                const Icon(Icons.comment, color: Colors.blue),
                          )),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _answerController,
                                decoration: InputDecoration(
                                  hintText: "Votre réponse...",
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.green),
                              onPressed: () {
                                _addAnswer(question);
                              },
                            ),
                          ],
                        ),
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
