import 'package:flutter/material.dart';
import '../model/message.dart';
import 'message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  }
}
