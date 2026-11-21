
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const SarvanaApp());
}

const String backendUrl =
    'https://YOUR-RENDER-SERVICE.onrender.com';

const String appToken = 'YOUR-APP-TOKEN';

class SarvanaApp extends StatelessWidget {
  const SarvanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sarvana AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF10101A),
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
  final controller = TextEditingController();
  final scrollController = ScrollController();

  final characters = ['Hindavi', 'Kabir', 'Vivaan', 'Meher'];
  String character = 'Hindavi';

  final List<Map<String, String>> messages = [];
  final List<Map<String, String>> history = [];

  bool loading = false;

  Future<void> sendMessage() async {
    final text = controller.text.trim();

    if (text.isEmpty || loading) return;

    if (backendUrl.contains('YOUR-RENDER') ||
        appToken == 'YOUR-APP-TOKEN') {
      setState(() {
        messages.add({
          'role': 'assistant',
          'content': 'Please configure your Render URL and app token.'
        });
      });
      return;
    }

    controller.clear();

    setState(() {
      messages.add({'role': 'user', 'content': text});
      loading = true;
    });

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      final uri = Uri.parse('$backendUrl/chat');
      final request = await client.postUrl(uri);

      request.headers.contentType = ContentType.json;
      request.headers.set('x-app-token', appToken);

      request.write(jsonEncode({
        'character': character,
        'message': text,
        'history': history,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(body);
      final reply = data['reply']?.toString() ?? 'No reply received.';

      history.add({'role': 'user', 'content': text});
      history.add({'role': 'assistant', 'content': reply});

      if (history.length > 40) {
        history.removeRange(0, history.length - 40);
      }

      if (mounted) {
        setState(() {
          messages.add({'role': 'assistant', 'content': reply});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add({
            'role': 'assistant',
            'content': 'Connection failed. Please try again.'
          });
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SARVANA AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF191526),
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
            onChanged: loading ? null : (value) {
              if (value == null) return;
              setState(() {
                character = value;
                messages.clear();
                history.clear();
              });
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message['role'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    margin: const EdgeInsets.symmetric(vertical: 7),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF7651B5)
                          : const Color(0xFF292536),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(message['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Sarvana is typing...'),
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
