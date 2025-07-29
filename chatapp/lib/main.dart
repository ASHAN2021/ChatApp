import 'package:camera/camera.dart';
import 'package:chatapp/Screens/welcome_screen.dart';
import 'package:chatapp/Services/database_service.dart';
import 'package:flutter/material.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force complete database reset to fix isRead column issue
  print('🔄 Forcing complete database reset...');
  await DatabaseService.forceCompleteReset();

  cameras = await availableCameras();
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
      home: WelcomeScreen(),
    );
  }
}
