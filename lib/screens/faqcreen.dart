import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final Map<String, List<String>> _faqData = {}; // Stocke les questions et réponses

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings settings = InitializationSettings(android: androidSettings);
    _notificationsPlugin.initialize(settings);
  }

  Future<void> _showNotification(String question) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'faq_channel', 'FAQ Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, 'Nouvelle réponse', 'Une réponse a été ajoutée à "$question"', details);
  }

  void _addQuestion() {
    String question = _questionController.text.trim();
    if (question.isNotEmpty) {
      setState(() {
        _faqData[question] = [];
      });
      _questionController.clear();
    }
  }

  void _addAnswer(String question, String answer) {
    if (answer.isNotEmpty) {
      setState(() {
        _faqData[question]?.add(answer);
      });
      _showNotification(question);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQ", style: TextStyle(color: Colors.white, fontSize: 18)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
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
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ExpansionTile(
                    title: Text("❓ $question", style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      ..._faqData[question]!.map((answer) => ListTile(
                            title: Text("💬 $answer"),
                            leading: const Icon(Icons.comment, color: Colors.blue),
                          )),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Votre réponse...",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onSubmitted: (value) => _addAnswer(question, value),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.green),
                              onPressed: () {
                                _addAnswer(question, _questionController.text);
                                _questionController.clear();
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
