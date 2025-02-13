import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FAQPage extends StatefulWidget {
  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, List<String>> _faqData = {};

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadFAQData();
    _listenForUpdates();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    _notificationsPlugin.initialize(settings);
  }

  void _showNotification(String question) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'faq_channel', 'FAQ Notifications',
      importance: Importance.high, priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(0, 'Nouvelle réponse ajoutée', 'À la question : $question', details);
  }

  void _listenForUpdates() {
    _supabase.from('faq').stream(primaryKey: ['id']).listen((data) {
      _loadFAQData();
    });
  }

  Future<void> _loadFAQData() async {
    final response = await _supabase.from('faq').select();
    if (response.isNotEmpty) {
      setState(() {
        _faqData.clear();
        for (var item in response) {
          try {
            _faqData[item['question']] = (jsonDecode(item['answer']) as List).map((e) => e.toString()).toList();
          } catch (e) {
            _faqData[item['question']] = [];
          }
        }
      });
    }
  }

  Future<void> _addQuestion() async {
    String question = _questionController.text.trim();
    if (question.isNotEmpty && !_faqData.containsKey(question)) {
      final response = await _supabase.from('faq').insert([
        {'question': question, 'answer': jsonEncode([])}
      ]);
      if (response != null) {
        _questionController.clear();
      }
    }
  }

  Future<void> _addAnswer(String question) async {
    String answer = _answerController.text.trim();
    if (answer.isNotEmpty) {
      final response = await _supabase.from('faq').select().eq('question', question).single();
      if (response != null) {
        List<dynamic> existingAnswers = jsonDecode(response['answer']);
        existingAnswers.add(answer);

        final updateResponse = await _supabase.from('faq').update({
          'answer': jsonEncode(existingAnswers)
        }).eq('question', question);

        if (updateResponse != null) {
          _answerController.clear();
          _showNotification(question);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FAQ App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: InputDecoration(labelText: 'Posez une question'),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: _addQuestion, child: Text('Ajouter Question')),
            Expanded(
              child: ListView.builder(
                itemCount: _faqData.keys.length,
                itemBuilder: (context, index) {
                  String question = _faqData.keys.elementAt(index);
                  return Card(
                    child: ExpansionTile(
                      title: Text(question, style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        for (String answer in _faqData[question]!)
                          ListTile(title: Text(answer)),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: _answerController,
                                decoration: InputDecoration(labelText: 'Ajouter une réponse'),
                              ),
                              SizedBox(height: 5),
                              ElevatedButton(
                                onPressed: () => _addAnswer(question),
                                child: Text('Ajouter Réponse'),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
