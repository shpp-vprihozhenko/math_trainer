import 'package:flutter/material.dart';
import 'package:math_trainer/chooseModeForWriteSolution.dart';
import 'MyMathPage.dart';
import 'about.dart';
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
      appBar: AppBar(title: Row(
        children: [
          Expanded(child: Text('Математика', textAlign: TextAlign.center,)),
          IconButton(
              onPressed: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const About())
                );
              },
              icon: const Icon(Icons.help, size: 30,)
          ),
        ],
      ),),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChooseModeForWriteSolution()));
                },
                child: Text('Напиши решение', textScaleFactor: 2,)
            ),
          ],
        ),
      ),
    );
  }
}
