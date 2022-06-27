import 'package:flutter/material.dart';
import 'MyMathPage.dart';

enum TtsState { playing, stopped, paused, continued }

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Интерактивный тренажер',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyMathPage(),
    );
  }
}
