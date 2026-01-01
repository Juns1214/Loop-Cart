import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  // --- Configuration ---
  static const String _apiKey = "AIzaSyDZ60GnSE7rb0s1K7-E4deXR0So5DkkdMs";
  static const String _apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  // --- State & Controllers ---
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _messages = [];
  final List<Map<String, String>> _history = [];
  
  bool _isTyping = false;
  String _systemContext = "";

  @override
  void initState() {
    super.initState();
    _loadSystemPrompt();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSystemPrompt() async {
    try {
      _systemContext = await rootBundle.loadString('assets/data/System_Prompt.txt');
    } catch (e) {
      _systemContext = "You are GreenBot, a helpful sustainability assistant.";
    }
  }

  // --- Logic ---

  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    final timestamp = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      _messages.add({"role": "user", "text": text, "time": timestamp});
      _isTyping = true;
    });

    _scrollToBottom();
    _history.add({"role": "user", "text": text});

    try {
      final reply = await _fetchGeminiResponse(text);
      
      if (mounted) {
        setState(() {
          _messages.add({
            "role": "bot",
            "text": reply,
            "time": DateFormat('hh:mm a').format(DateTime.now()),
          });
          _history.add({"role": "bot", "text": reply});
        });
      }
    } catch (e) {
      if (mounted) {
        _showError("Couldn't reach GreenBot. Please check your connection.");
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  Future<String> _fetchGeminiResponse(String userInput) async {
    // Limit history to last 10 turns to save tokens/bandwidth
    final recentHistory = _history.length > 10 
        ? _history.sublist(_history.length - 10) 
        : _history;

    final buffer = StringBuffer();
    buffer.writeln(_systemContext);
    for (var msg in recentHistory) {
      buffer.writeln("${msg['role'] == 'user' ? 'User' : 'Assistant'}: ${msg['text']}");
    }
    buffer.writeln("User: $userInput\nAssistant:");

    final response = await http.post(
      Uri.parse("$_apiUrl?key=$_apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [{"parts": [{"text": buffer.toString()}]}],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"]?.trim() ?? 
             "I'm speechless!";
    }
    throw Exception("API Error: ${response.statusCode}");
  }

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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // --- UI Layout ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, color: Color(0xFF388E3C)),
            SizedBox(width: 8),
            Text(
              "GreenAssistant",
              style: TextStyle(
                color: Color(0xFF1B5E20), // Dark Green for high contrast
                fontWeight: FontWeight.bold,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _ChatBubble(
                        text: msg['text'] ?? '',
                        time: msg['time'] ?? '',
                        isUser: msg['role'] == 'user',
                      );
                    },
                  ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, size: 64, color: Color(0xFF388E3C)),
          ),
          const SizedBox(height: 16),
          const Text(
            "Hello! I'm GreenBot.",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ask me anything about sustainability!",
            style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10, top: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "GreenBot is thinking...",
          style: TextStyle(
            color: const Color(0xFF388E3C),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.black87), // Dark text for typing
              decoration: InputDecoration(
                hintText: "Ask about recycling...",
                hintStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _handleSendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF388E3C), // App Green
            radius: 24,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _handleSendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Internal Widget: Chat Bubble ---
// Kept in the same file as requested to reduce file count
class _ChatBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isUser;

  const _ChatBubble({
    required this.text,
    required this.time,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final userColor = const Color(0xFF388E3C); // App Green
    final botColor = const Color(0xFFF1F8E9); // Very light eco-green

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? userColor : botColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          // Subtle shadow for depth
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF1B5E20), // Dark Green text for bot
                fontSize: 16,
                height: 1.4,
                fontWeight: isUser ? FontWeight.bold : FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                color: isUser ? Colors.white.withOpacity(0.9) : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}