import 'package:chatapp/CustomUI/button_card.dart';
import 'package:chatapp/Model/chat_model.dart';
import 'package:chatapp/Screens/home_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  ChatModel? sourceChat;
  List<ChatModel> chats = [
    ChatModel(
      id: '1',
      name: 'John Doe',
      lastMessage: 'Hello, how are you?',
      lastMessageTime: DateTime.now(),
      isGroup: false,
      currentMessage: 'Hello, how are you?',
      time: '18.04',
    ),
    ChatModel(
      id: '2',
      name: 'Jane Smith',
      lastMessage: 'Let\'s catch up later.',
      lastMessageTime: DateTime.now(),
      isGroup: false,
      currentMessage: 'Let\'s catch up later.',
      time: '17.30',
    ),
    // ChatModel(
    //   name: 'Group Chat',
    //   icon: 'assets/groups.svg',
    //   isGroup: true,
    //   currentMessage: 'Welcome!',
    //   time: '16.45',
    // ),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            sourceChat = chats.removeAt(index);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (builder) =>
                    HomeScreen(chatmodels: chats, sourceChat: sourceChat),
              ),
            );
          },
          child: ButtonCard(name: chats[index].name, icon: Icons.person),
        ),
      ),
    );
  }
}
