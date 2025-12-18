import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final List<Message> messages = [];
  bool loading = false;

  Future<void> send() async {
    final text = controller.text;
    if (text.isEmpty) return;

    setState(() {
      messages.add(Message(text: text, isUser: true));
      loading = true;
    });

    controller.clear();

    final reply = await ChatService.sendMessage(text);

    setState(() {
      messages.add(Message(text: reply, isUser: false));
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fertilis Chatbot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, i) =>
                  ChatBubble(message: messages[i]),
            ),
          ),
          if (loading) const CircularProgressIndicator(),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration:
                      const InputDecoration(hintText: "Type here"),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: send,
              )
            ],
          ),
        ],
      ),
    );
  }
}
