import 'package:flutter/material.dart';
import 'MyMathPage.dart';
import 'write_math_answer.dart';

enum TtsState { playing, stopped, paused, continued }

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math trainer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Математика'),),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyMathPage()));
                },
                child: Text('Ответь решение', textScaleFactor: 2,)
            ),
            SizedBox(height: 20,),
            ElevatedButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => WriteMathAnswer()));
                },
                child: Text('Напиши решение', textScaleFactor: 2,)
            ),
          ],
        ),
      ),
    );
  }
}
