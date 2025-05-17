import 'package:flutter/material.dart';
import 'package:frontend/choose_screen.dart';
import 'package:frontend/producer_screen.dart' show HostScreen;
import 'package:frontend/landing.dart';
import 'socket_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    SocketService();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ChooseScreen(),
    );
  }
}
