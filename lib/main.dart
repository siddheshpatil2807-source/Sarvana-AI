
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
void main() {
  runApp(const SarvanaApp());
}

class SarvanaApp extends StatefulWidget {
  const SarvanaApp({super.key});

  @override
  State<SarvanaApp> createState() => _SarvanaAppState();
}

class _SarvanaAppState extends State<SarvanaApp> {
  ThemeMode themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('sarvana_theme') ?? 'dark';
    if (!mounted) return;
    setState(() {
      themeMode = saved == 'light'
          ? ThemeMode.light
          : saved == 'system'
              ? ThemeMode.system
              : ThemeMode.dark;
    });
  }

  Future<void> changeTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'sarvana_theme',
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.system
              ? 'system'
              : 'dark',
    );
    setState(() => themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sarvana AI',
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008F70),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A884),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B141A),
        useMaterial3: true,
      ),
      home: ChatScreen(
        themeMode: themeMode,
        onThemeChanged: changeTheme,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const ChatScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('hindavi_chat');
    if (saved != null) {
      messages = List<Map<String, dynamic>>.from(
        (jsonDecode(saved) as List).map(
          (item) => Map<String, dynamic>.from(item),
        ),
      );
    }
    if (mounted) setState(() => loading = false);
    scrollToBottom();
  }

  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hindavi_chat', jsonEncode(messages));
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    setState(() {
      messages.add({
        'text': text,
        'mine': true,
        'time': DateTime.now().toIso8601String(),
      });
    });

    await saveMessages();
    scrollToBottom();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Message saved. AI connection will be enabled after secure setup.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String timeLabel(dynamic value) {
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final incoming = dark
        ? const Color(0xFF202C33)
        : Colors.white;
    final outgoing = dark
        ? const Color(0xFF005C4B)
        : const Color(0xFFD9FDD3);

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 21,
              backgroundColor: Color(0xFF008F70),
              child: Text(
                'H',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hindavi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Sarvana AI Companion',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice calling coming soon')),
              );
            },
          ),
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.more_vert),
            onSelected: widget.onThemeChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ThemeMode.light,
                child: Text('Light mode'),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark mode'),
              ),
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text('System default'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            color: dark
                ? const Color(0xFF182229)
                : const Color(0xFFE4F3EC),
            child: const Text(
              'Demo mode • Secure AI connection pending',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(
                              radius: 36,
                              backgroundColor: Color(0xFF008F70),
                              child: Text(
                                'H',
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Start a conversation with Hindavi',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Your story begins here.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final item = messages[index];
                          final mine = item['mine'] == true;

                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.78,
                              ),
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                12, 9, 9, 6,
                              ),
                              decoration: BoxDecoration(
                                color: mine ? outgoing : incoming,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(mine ? 12 : 2),
                                  bottomRight: Radius.circular(mine ? 2 : 12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item['text']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeLabel(item['time']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 7,
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emoji picker coming soon'),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message Hindavi...',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attachments coming soon'),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF00A884),
                    ),
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


