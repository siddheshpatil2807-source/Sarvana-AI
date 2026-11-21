
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    if (mounted) {
      setState(() => themeMode = mode);
    }
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
        onThemeChanged: changeTheme,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;

  const ChatScreen({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final ImagePicker picker = ImagePicker();

  List<Map<String, dynamic>> messages = [];

  String? profileImagePath;
  String? wallpaperImagePath;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMessages();
    loadCustomImages();
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

    if (mounted) {
      setState(() => loading = false);
    }

    scrollToBottom();
  }

  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hindavi_chat', jsonEncode(messages));
  }

  Future<void> loadCustomImages() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      profileImagePath = prefs.getString('hindavi_dp');
      wallpaperImagePath = prefs.getString('hindavi_wallpaper');
    });
  }

  Future<String> saveSelectedImage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();

    final extension = image.path.contains('.')
        ? image.path.split('.').last
        : 'jpg';

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.$extension';

    final savedFile = await File(image.path).copy(
      '${directory.path}/$fileName',
    );

    return savedFile.path;
  }

  Future<void> changeProfilePhoto() async {
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      final path = await saveSelectedImage(image);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('hindavi_dp', path);

      if (!mounted) return;

      setState(() {
        profileImagePath = path;
      });

      showMessage('Hindavi DP updated!');
    } catch (e) {
      showMessage('Unable to change DP. Please try again.');
    }
  }

  Future<void> changeWallpaper() async {
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) return;

      final path = await saveSelectedImage(image);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('hindavi_wallpaper', path);

      if (!mounted) return;

      setState(() {
        wallpaperImagePath = path;
      });

      showMessage('Chat wallpaper updated!');
    } catch (e) {
      showMessage('Unable to change wallpaper. Please try again.');
    }
  }

  Future<void> resetWallpaper() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('hindavi_wallpaper');

    if (!mounted) return;

    setState(() {
      wallpaperImagePath = null;
    });

    showMessage('Default wallpaper restored.');
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

    showMessage('Message saved. AI connection is still pending.');
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

  Widget hindaviAvatar(double radius) {
    final hasImage = profileImagePath != null &&
        File(profileImagePath!).existsSync();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF008F70),
      backgroundImage:
          hasImage ? FileImage(File(profileImagePath!)) : null,
      child: hasImage
          ? null
          : Text(
              'H',
              style: TextStyle(
                color: Colors.white,
                fontSize: radius,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget chatWallpaper({required Widget child}) {
    final hasWallpaper = wallpaperImagePath != null &&
        File(wallpaperImagePath!).existsSync();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        image: hasWallpaper
            ? DecorationImage(
                image: FileImage(File(wallpaperImagePath!)),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.20),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: child,
    );
  }

  Future<void> handleMenu(String value) async {
    switch (value) {
      case 'dp':
        await changeProfilePhoto();
        break;

      case 'wallpaper':
        await changeWallpaper();
        break;

      case 'reset':
        await resetWallpaper();
        break;

      case 'light':
        widget.onThemeChanged(ThemeMode.light);
        break;

      case 'dark':
        widget.onThemeChanged(ThemeMode.dark);
        break;

      case 'system':
        widget.onThemeChanged(ThemeMode.system);
        break;
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
            GestureDetector(
              onTap: changeProfilePhoto,
              child: hindaviAvatar(21),
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
              showMessage('Voice calling coming soon');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'dp',
                child: ListTile(
                  leading: Icon(Icons.account_circle_outlined),
                  title: Text('Change profile photo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'wallpaper',
                child: ListTile(
                  leading: Icon(Icons.wallpaper),
                  title: Text('Change chat wallpaper'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Reset wallpaper'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'light',
                child: Text('Light mode'),
              ),
              PopupMenuItem(
                value: 'dark',
                child: Text('Dark mode'),
              ),
              PopupMenuItem(
                value: 'system',
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
                : chatWallpaper(
                    child: messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                hindaviAvatar(36),
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
                                        MediaQuery.of(context).size.width *
                                            0.78,
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
                                      bottomLeft: Radius.circular(
                                          mine ? 12 : 2),
                                      bottomRight: Radius.circular(
                                          mine ? 2 : 12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item['text']?.toString() ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ),
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
                      showMessage('Emoji picker coming soon');
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
                        fillColor:
                            Theme.of(context).colorScheme.surface,
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
                      showMessage('Attachments coming soon');
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



