import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';

class About extends StatelessWidget {
  const About({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О программе'),),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text('Не спеши и не суетись!', textAlign: TextAlign.center, textScaleFactor: 1.25,),
              const SizedBox(height: 12,),
              const Text('Нажми на микрофончик, если тебе надо подумать'),
              const SizedBox(height: 12,),
              const Text('Затем нажми ещё раз, чтобы дать ответ'),
              const SizedBox(height: 12,),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: "Кнопка ",
                      style: TextStyle(color: Colors.black, fontSize: 16,)
                    ),
                    WidgetSpan(
                      child: Icon(Icons.arrow_forward_ios),
                    ),
                    TextSpan(text: " переключает на следующую задачу, если эта слишком сложная",
                        style: TextStyle(color: Colors.black, fontSize: 16,),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12,),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: "Кнопка ",
                        style: TextStyle(color: Colors.black, fontSize: 16,)
                    ),
                    WidgetSpan(
                      child: Icon(Icons.repeat),
                    ),
                    TextSpan(text: " позволяет прослушать задание ещё раз",
                      style: TextStyle(color: Colors.black, fontSize: 16,),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12,),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(text: "Перейди в настройки ",
                        style: TextStyle(color: Colors.black, fontSize: 16,)
                    ),
                    WidgetSpan(
                      child: Icon(Icons.settings),
                    ),
                    TextSpan(text: " и уменьши Максимум числа если тебе тяжело",
                      style: TextStyle(color: Colors.black, fontSize: 16,),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24,),
              const Text('Вроде и всё. Терпения и успехов!', textAlign: TextAlign.center,),
              const SizedBox(height: 24,),
              const Text('Эту программу придумал и разработал программист', textAlign: TextAlign.center,),
              const SizedBox(height: 12,),
              const Text('Прихоженко Владимир Анатольевич', textAlign: TextAlign.center),
              const SizedBox(height: 12,),
              Image.asset('assets/images/v1.jpg', height: 309,),
              const SizedBox(height: 20,),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Замечания и предложения присылайте мне', textAlign: TextAlign.center),
              ),
              const SizedBox(height: 6,),
              Container(
                color: Colors.yellow[100],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: (){
                      FlutterClipboard.copy('vprihogenko@gmail.com').then(( value ) => print('copied'));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скопировал!'),));
                    },
                    child: const Text('vprihogenko@gmail.com', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, ),)
                  ),
                ),
              ),
              const SizedBox(height: 24,),
            ],
          ),
        ),
      ),
    );
  }
}
