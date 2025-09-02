 import 'package:chatapp/Pages/ChatPage.dart';
import 'package:flutter/material.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this, initialIndex: 1); // default to CHATS
  }

  @override
  void dispose() {
    _controller.dispose(); // Always dispose controllers to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Clone'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              print(value);
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: "New group",
                  child: Text("New group"),
                ),
                const PopupMenuItem(
                  value: "New broadcast", 
                  child: Text("New broadcast"),
                ),
                const PopupMenuItem(
                  value: "WhatsApp Web", 
                  child: Text("WhatsApp Web"),
                ),
                const PopupMenuItem(
                  value: "Starred messages", 
                  child: Text("Starred messages"),
                ),
                const PopupMenuItem(
                  value: "Settings", 
                  child: Text("Settings"),
                ),
              ];
            },
          )
        ],
        bottom: TabBar(
          controller: _controller,
          indicatorColor: Colors.white,
           
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt)),
            Tab(text: 'CHATS'),
            Tab(text: 'STATUS'),
            Tab(text: 'CALLS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: const [
          Center(child: Text("Camera")),
          ChatPage(),
          Center(child: Text("Status")),
          Center(child: Text("Calls")),
        ],
      ),
    );
  }
}
