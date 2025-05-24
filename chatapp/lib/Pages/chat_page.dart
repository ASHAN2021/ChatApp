import 'package:chatapp/CustomUI/custom_card.dart';
import 'package:chatapp/Model/chat_model.dart';
import 'package:chatapp/Screens/select_contact.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatModel> chats = [
    ChatModel(
      name: 'John Doe',
      icon: 'assets/groups.svg',
      isGroup: false,
      currentMessage: 'Hello, how are you?',
      time: '18.04',
    ),
    ChatModel(
      name: 'Jane Smith',
      icon: 'assets/groups.svg',
      isGroup: false,
      currentMessage: 'Let\'s catch up later.',
      time: '17.30',
    ),
    ChatModel(
      name: 'Group Chat',
      icon: 'assets/groups.svg',
      isGroup: true,
      currentMessage: 'Welcome!',
      time: '16.45',
    ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelectContact()),
          );
        },
        backgroundColor: const Color(0xff128C7E),
        child: const Icon(Icons.chat),
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          return CustomCard(chatModel: chats[index]);
        },
      ),
    );
  }
}
