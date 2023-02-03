import 'package:flutter/material.dart';
import 'about.dart';
import 'write_math_answer.dart';

class ChooseModeForWriteSolution extends StatelessWidget {
  const ChooseModeForWriteSolution({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          Expanded(child: Text('Выберите сложность', textAlign: TextAlign.center,)),
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
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(32),
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ElevatedButton(
                      onPressed: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) => WriteMathAnswer(mode: 1)));
                      },
                      child: Text('1й класс, до 10')
                    ),
                    ElevatedButton(
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => WriteMathAnswer(mode: 2)));
                        },
                        child: Text('1й класс, до 20')
                    ),
                    ElevatedButton(
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => WriteMathAnswer(mode: 3)));
                        },
                        child: Text('2й класс, до 100, 1 действие')
                    ),
                    ElevatedButton(
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => WriteMathAnswer(mode: 4)));
                        },
                        child: Text('2й класс, до 100, 2 действия')
                    ),
                    ElevatedButton(
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => WriteMathAnswer(mode: 5)));
                        },
                        child: Text('2й класс, до 100, 2 действия, иногда надо менять местами числа',
                          textAlign: TextAlign.center,
                        )
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
