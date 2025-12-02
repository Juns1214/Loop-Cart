import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/chatbot",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  // Controllers
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State variables
  final List<Map<String, String>> _messages = [];
  final List<Map<String, String>> _conversationHistory = [];
  bool _isTyping = false;

  // 🔑 API Configuration
  static const String _apiKey = "AIzaSyDZ60GnSE7rb0s1K7-E4deXR0So5DkkdMs";
  static const String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  Future<String> loadSystemPrompt() async {
    return await rootBundle.loadString('assets/data/System_Prompt.txt');
  }

  // 🌿 System Context
  static String _systemContext = "";

  @override
  void initState() {
    super.initState();
    _loadSystemContext();
  }

  Future<void> _loadSystemContext() async {
    _systemContext = await loadSystemPrompt();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 📨 Send message to Gemini API
  Future<void> _sendMessage(String userInput) async {
    // Validate input
    if (userInput.trim().isEmpty) return;

    final userMessage = userInput.trim();
    final timestamp = _getCurrentTime();

    // Add user message to UI
    setState(() {
      _messages.add({"role": "user", "text": userMessage, "time": timestamp});
      _isTyping = true;
    });

    // Scroll to bottom
    _scrollToBottom();

    // Add to conversation history
    _conversationHistory.add({"role": "user", "text": userMessage});

    try {
      final botReply = await _callGeminiAPI(userMessage);

      // Add bot response to conversation history
      _conversationHistory.add({"role": "bot", "text": botReply});

      setState(() {
        _messages.add({
          "role": "bot",
          "text": botReply,
          "time": _getCurrentTime(),
        });
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "bot",
          "text": "Sorry, I couldn't process your request. Please try again.",
          "time": _getCurrentTime(),
        });
      });
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  // 🌐 Call Gemini API
  Future<String> _callGeminiAPI(String userInput) async {
    // Build conversation context
    final conversationText = _buildConversationContext(userInput);

    final response = await http.post(
      Uri.parse("$_apiUrl?key=$_apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": conversationText},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      if (reply == null || reply.isEmpty) {
        throw Exception("Empty response from API");
      }

      return reply.trim();
    } else if (response.statusCode == 400) {
      throw Exception("Invalid API key or request format");
    } else if (response.statusCode == 429) {
      throw Exception("Rate limit exceeded. Please wait a moment.");
    } else {
      throw Exception("API Error: ${response.statusCode}");
    }
  }

  // 🔄 Build conversation context with history
  String _buildConversationContext(String currentInput) {
    final buffer = StringBuffer();
    buffer.writeln(_systemContext);
    buffer.writeln();

    // Add last 5 conversation turns for context (to save tokens)
    final recentHistory = _conversationHistory.length > 10
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : _conversationHistory;

    for (var msg in recentHistory) {
      if (msg["role"] == "user") {
        buffer.writeln("User: ${msg['text']}");
      } else {
        buffer.writeln("Assistant: ${msg['text']}");
      }
    }

    buffer.writeln("User: $currentInput");
    buffer.write("Assistant:");

    return buffer.toString();
  }

  // 📅 Get current time formatted
  String _getCurrentTime() {
    return DateFormat('hh:mm a').format(DateTime.now());
  }

  // 📜 Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ⚠️ Show error snackbar
  void _showErrorSnackBar(String error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 💬 Chat bubble widget
  Widget _buildChatBubble(Map<String, String> msg) {
    final isUser = msg["role"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[400] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isUser
                ? const Radius.circular(14)
                : const Radius.circular(0),
            bottomRight: isUser
                ? const Radius.circular(0)
                : const Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg["text"] ?? "",
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg["time"] ?? "",
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 Input field widget
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Ask me about Green Coins...",
                border: InputBorder.none,
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  _controller.clear();
                  _sendMessage(text);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () {
              final text = _controller.text;
              if (text.trim().isNotEmpty) {
                _controller.clear();
                _sendMessage(text);
              }
            },
          ),
        ],
      ),
    );
  }

  // 💭 Typing indicator widget
  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text("GreenBot is typing... 💬"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.energy_savings_leaf, color: Colors.green),
            ),
            SizedBox(width: 10),
            Text("GreenCycle Chatbot 🌱"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Start a conversation with GreenBot!",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildChatBubble(_messages[index]);
                    },
                  ),
          ),

          // Typing indicator
          if (_isTyping) _buildTypingIndicator(),

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }
}
