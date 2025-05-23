import 'package:chatapp/Screens/home_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'OpenSans',
        primaryColor: Color(0xff075E54),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xff128C7E),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
