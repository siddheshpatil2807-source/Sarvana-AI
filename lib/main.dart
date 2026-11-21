
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SarvanaApp());
}

const String backendUrl = 'https://sarvana-ai.onrender.com';

// Temporary testing placeholder.
// Do not put your OpenAI API key here.
const String appToken = 'YOUR-APP-TOKEN';

class SarvanaApp extends StatelessWidget {
  const SarvanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sarvana AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF100D19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB58AFF),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final storage = SharedPreferencesAsync();
  final controller = TextEditingController();
  final scrollController = ScrollController();

  final characters = ['Hindavi', 'Kabir', 'Vivaan', 'Meher'];

  String character = 'Hindavi';
  List<Map<String, String>> messages = [];
  List<Map<String, String>> history = [];

  bool loading = false;
  bool loadingHistory = true;

  String storageKey(String name) => 'sarvana_chat_$name';

  Future<void> saveMessages() async {
    await storage.setString(
      storageKey(character),
      jsonEncode(messages),
    );
  }

  Future<void> loadMessages(String name) async {
    setState(() {
      loadingHistory = true;
      messages = [];
      history = [];
    });

    try {
      final saved = await storage.getString(storageKey(name));

      if (saved != null) {
        final decoded = jsonDecode(saved) as List;

        final loaded = decoded.map((item) {
          return Map<String, String>.from(item);
        }).toList();

        if (mounted && character == name) {
          setState(() {
            messages = loaded;
            history = loaded.where((item) {
              return item['role'] == 'user' ||
                  item['role'] == 'assistant';
            }).toList();
          });
        }
      }
    } catch (_) {
      // Ignore invalid old local data.
    }

    if (mounted) {
      setState(() => loadingHistory = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadMessages(character);
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty || loading || loadingHistory) return;

    if (appToken == 'YOUR-APP-TOKEN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App token setup is pending.')),
      );
      return;
    }

    controller.clear();

    final previousHistory =
        history.map((item) => Map<String, String>.from(item)).toList();

    setState(() {
      messages.add({'role': 'user', 'content': text});
      history.add({'role': 'user', 'content': text});
      loading = true;
    });

    await saveMessages();

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 40);

      final request = await client.postUrl(
        Uri.parse('$backendUrl/chat'),
      );

      request.headers.contentType = ContentType.json;
      request.headers.set('x-app-token', appToken);

      request.write(jsonEncode({
        'character': character,
        'message': text,
        'history': previousHistory.take(30).toList(),
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = jsonDecode(body);
      final reply = data['reply']?.toString() ?? 'No reply received.';

      if (!mounted) return;

      setState(() {
        messages.add({
          'role': 'assistant',
          'content': reply,
        });

        history.add({
          'role': 'assistant',
          'content': reply,
        });
      });

      await saveMessages();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection failed. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);

        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  Future<void> changeCharacter(String? value) async {
    if (value == null || loading) return;

    setState(() => character = value);
    await loadMessages(value);
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF21182F),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SARVANA AI',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Your AI companion',
                style: TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: character,
            dropdownColor: const Color(0xFF29213B),
            underline: const SizedBox(),
            items: characters.map((name) {
              return DropdownMenuItem(
                value: name,
                child: Text(name),
              );
            }).toList(),
            onChanged: changeCharacter,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite,
                                size: 45, color: Color(0xFFB58AFF)),
                            const SizedBox(height: 12),
                            Text('Start your story with $character'),
                            const SizedBox(height: 5),
                            const Text(
                              'Your conversations will be saved.',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final item = messages[index];
                          final isUser = item['role'] == 'user';

                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints:
                                  const BoxConstraints(maxWidth: 310),
                              margin: const EdgeInsets.symmetric(vertical: 7),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? const Color(0xFF7651B5)
                                    : const Color(0xFF292536),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(item['content'] ?? ''),
                            ),
                          );
                        },
                      ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Typing...'),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Message $character...',
                        filled: true,
                        fillColor: const Color(0xFF292536),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: loading ? null : sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

