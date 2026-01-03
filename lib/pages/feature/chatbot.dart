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
  static const String _apiKey = "AIzaSyDZ60GnSE7rb0s1K7-E4deXR0So5DkkdMs";
  static const String _apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

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
          _messages.add({"role": "bot", "text": reply, "time": DateFormat('hh:mm a').format(DateTime.now())});
          _history.add({"role": "bot", "text": reply});
        });
      }
    } catch (e) {
      if (mounted) _showError("Couldn't reach GreenBot. Please check your connection.");
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  Future<String> _fetchGeminiResponse(String userInput) async {
    final recentHistory = _history.length > 10 ? _history.sublist(_history.length - 10) : _history;

    final buffer = StringBuffer();
    buffer.writeln(_systemContext);
    for (var msg in recentHistory) {
      buffer.writeln("${msg['role'] == 'user' ? 'User' : 'Assistant'}: ${msg['text']}");
    }
    buffer.writeln("User: $userInput\nAssistant:");

    final response = await http.post(
      Uri.parse("$_apiUrl?key=$_apiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"contents": [{"parts": [{"text": buffer.toString()}]}]}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"]?.trim() ?? "I'm speechless!";
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
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600)), backgroundColor: const Color(0xFFD32F2F)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF212121), size: 22), onPressed: () => Navigator.pop(context)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('GreenAssistant', style: TextStyle(fontFamily: 'Roboto', color: Color(0xFF1B5E20), fontWeight: FontWeight.w800, fontSize: 20)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE0E0E0), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _ChatBubble(text: msg['text'] ?? '', time: msg['time'] ?? '', isUser: msg['role'] == 'user');
                    },
                  ),
          ),
          if (_isTyping) _TypingIndicator(),
          _InputArea(controller: _controller, onSend: _handleSendMessage),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 56, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 24),
          const Text("Hello! I'm GreenBot.", style: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
          const SizedBox(height: 8),
          const Text('Ask me anything about sustainability!', style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF424242))),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10, top: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF66BB6A), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32))),
                  ),
                  const SizedBox(width: 10),
                  const Text('Thinking...', style: TextStyle(fontFamily: 'Roboto', color: Color(0xFF1B5E20), fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputArea({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontFamily: 'Roboto', color: Color(0xFF212121), fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Ask about recycling, products...",
                hintStyle: const TextStyle(fontFamily: 'Roboto', color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500, fontSize: 15),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              onPressed: onSend,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text, time;
  final bool isUser;

  const _ChatBubble({required this.text, required this.time, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isUser 
              ? const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)])
              : null,
          color: isUser ? null : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFF66BB6A), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: isUser ? Colors.white : const Color(0xFF212121),
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: isUser ? Colors.white.withOpacity(0.9) : const Color(0xFF616161),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}