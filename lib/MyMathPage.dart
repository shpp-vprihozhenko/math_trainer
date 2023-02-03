import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:math_trainer/globals.dart';
import 'dart:math';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'IntToRusPropis.dart';
import 'about.dart';
import 'blink_mic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

IntToRusPropis itp = IntToRusPropis();
enum TtsState { playing, stopped, paused, continued }

class MyMathPage extends StatefulWidget {
  MyMathPage({Key? key}) : super(key: key);

  @override
  _MyMathPage createState() => _MyMathPage();
}

class _MyMathPage extends State<MyMathPage> {
  int mode = 0;

  int maxNum = 100;
  int multiplierForTable = 7;
  bool dynamicDifficult = false;
  String curDoing = '+-';
  String _curTaskMsg = 'Сколько будет 2 + 2 ?', _curTaskMsgTxt = '';
  int expectedRes = 0;
  int numOkAnswer = 0, numWrongAnswer = 0, numTotalAnswer = 0;
  int numOkLast5 = 0;
  bool showMic = false;
  int wrongCounter = 0;

  final List<TaskType> _tasksTypes = TaskType.getTaskTypes();
  List<DropdownMenuItem<TaskType>> _dropDownMenuTaskTypeItems = [];
  TaskType _selectedTaskType = TaskType('','');

  final textEditController = TextEditingController();
  final textEditControllerForMult = TextEditingController();

  late SpeechToText speech;
  String lastSttWords = '';
  String lastSttError = '';

  bool gotNonFinalResult = false;
  String waitingFor = '';
  String lastNonFinalRecognizedWords = '';


  late FlutterTts flutterTts;
  dynamic languages;
  String language = '';
  double volume = 1;
  double pitch = 1;
  double rate = 0.5;

  TtsState ttsState = TtsState.stopped;

  bool isProcessed = false;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  initState() {
    super.initState();

    initTTS();

    initSTT();

    _dropDownMenuTaskTypeItems = buildDropDownTaskTypeItems(_tasksTypes);
    _selectedTaskType = _tasksTypes[5];
    _prefs.then((SharedPreferences prefs) {
      setState(() {
        maxNum = (prefs.getInt('maxNum') ?? 100);
        multiplierForTable = (prefs.getInt('mult') ?? 7);
        int mode = (prefs.getInt('mode') ?? 5);
        _selectedTaskType = _tasksTypes[mode];
        dynamicDifficult = (prefs.getBool('dynDif') ?? false);
        rate = prefs.getDouble('rate') ?? 0.55;
      });
    });
  }

  List<DropdownMenuItem<TaskType>> buildDropDownTaskTypeItems(List<TaskType> tasksTypes) {
    List<DropdownMenuItem<TaskType>> items = [];
    for (TaskType tt in tasksTypes) {
      items.add(DropdownMenuItem(value: tt, child: Text(tt.name)));
    }
    return items;
  }

  isSupportedLanguageInList() {
    for (var lang in languages) {
      if (lang.toString().toUpperCase() == 'RU-RU') {
        return true;
      }
    }
    return false;
  }

  Future _setSpeakParameters() async {
    await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
      IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
    ]);

    // ru-RU uk-UA en-US
    await flutterTts.setLanguage('ru-RU');
    //
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    print('volume $volume rate $rate pitch $pitch');
  }

  bool get isIOS => !kIsWeb && Platform.isIOS;

  Future _speak(_newVoiceText) async {
    // await flutterTts.setVolume(volume);
    // await flutterTts.setSpeechRate(rate);
    // await flutterTts.setPitch(pitch);

    if (speech.isListening) {
      print('cancel listening');
      await speech.cancel();
    }

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        print('speak $_newVoiceText');
        await flutterTts.speak(_newVoiceText!);
      }
    }
  }

  initTTS() async {
    flutterTts = FlutterTts();

    await flutterTts.awaitSpeakCompletion(true);

    flutterTts.setStartHandler(() {
      print("Playing");
    });

    flutterTts.setCompletionHandler(() {
      print("Complete");
    });

    if (isIOS) {
      flutterTts.setPauseHandler(() {
        setState(() {
          print("Paused");
          ttsState = TtsState.paused;
        });
      });

      flutterTts.setContinueHandler(() {
        setState(() {
          print("Continued");
          ttsState = TtsState.continued;
        });
      });
    }

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });

    _setSpeakParameters();
  }

  Future<dynamic> _getLanguages() => flutterTts.getLanguages;

  Future<dynamic> _getEngines() => flutterTts.getEngines;

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  checkPermission() async {
    var status = await Permission.microphone.status;
    print('got mic permis status $status');
    if (status.isDenied || status.isRestricted || status == PermissionStatus.denied) {
      print('grant');
      if (await Permission.microphone.request().isGranted) {
        print('granted');
      }
    }
  }

  void initSTT() async {
    speech = SpeechToText();

    await checkPermission();

    bool hasSpeech = await speech.initialize(onError: errorListener, onStatus: statusListener);

    if (hasSpeech) {
      print('has speech');
      //var _localeNames = await speech.locales();
      //_localeNames.forEach((element) => print(element.localeId));
      var systemLocale = await speech.systemLocale();
      var currentLocaleId = systemLocale?.localeId ;
    }

    if (!hasSpeech) {
      return;
    }
  }

  void errorListener(SpeechRecognitionError error) {
    print("Received MATH error status: $error, listening: ${speech.isListening}");
    setState(() {
      showMic = false;
      lastSttWords = '-';
    });
    //displaySttDialog();
  }

  void statusListener(String status) {
    if (status == 'notListening' || status == 'available') {
      setState(() { showMic = false; });
    } else if (status == 'listening') {
      // ok
    } else if (status == 'done') {
      setState(() { showMic = false; });
    } else {
      showAlertPage("Received strange Stt status: $status, listening: ${speech.isListening}");
    }
  }

  _formCurTask(int startTask, int finTask) {
    print('\n_formCurTask $startTask $finTask');
    var rng = Random();
    int nA = rng.nextInt(maxNum);
    int nB = rng.nextInt(maxNum);
    int nRes = rng.nextInt(maxNum);

    int actionInt = startTask;
    if (finTask > startTask) {
        actionInt += rng.nextInt(finTask - startTask + 1);
        if (finTask == 8) {
          if (actionInt == 3) {
            actionInt = 1;
          } else if (actionInt == 4) {
            actionInt = 2;
          }
        }
    }

    String actionTxt='', action='';

    if (actionInt == 1) {
      actionTxt = 'плюс';
      action = '+';
      if (nA > nRes) {
        int n = nA;
        nRes = nA;
        nA = n;
      }
      nB = nRes - nA;
    } else if (actionInt == 2) {
      actionTxt = 'минус';
      action = '-';
      if (nA > nB) {
        nRes = nA - nB;
      } else {
        nRes = nB - nA;
        nA = nB;
        nB = nA - nRes;
      }
    } else if (actionInt == 3) {
      actionTxt = 'умножить на';
      action = '*';
      nA = rng.nextInt(maxNum ~/ 10);
      if (nA > nRes) {
        int n = nA;
        nA = nRes;
        nRes = n;
      }
      if (nA == 0) {
        nA = 1;
      }
      nB = nRes ~/ nA;
      nRes = nA * nB;
    } else if (actionInt == 4) {
      actionTxt = 'разделить на';
      action = '/';
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA > nB) {
        nRes = (nA / nB).round();
        nA = nRes * nB;
      } else {
        if (nA == 0) {
          nA = 1;
        }
        nRes = (nB / nA).round();
        nB = nA;
        nA = nB * nRes;
      }
    } else if (actionInt == 5) {
      if (nA < nB) {
        nRes = nB - nA;
        nA = nB;
        nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'На сколько $nA больше чем $nB?';
      actionTxt =
          'На сколько ${itp.intToPropis(nA)} больше чем ${itp.intToPropis(nB)}?';
    } else if (actionInt == 6) {
      if (nA < nB) {
        nRes = nB - nA;
        nA = nB;
        nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'На сколько $nB меньше чем $nA?';
      actionTxt =
          'На сколько ${itp.intToPropis(nB)} меньше чем ${itp.intToPropis(nA)}?';
    } else if (actionInt == 7) {
      if (nA < nB) {
        nRes = nB - nA;
        nA = nB;
        nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'Сколько надо отнять от $nA, чтобы получить $nB?';
      actionTxt =
          'Сколько надо отнять от ${itp.intToPropis(nA)}, чтобы получить ${itp.intToPropis(nB)}?';
    } else if (actionInt == 8) {
      if (nA < nB) {
        nRes = nB - nA;
        nA = nB;
        nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'Сколько надо прибавить к $nB, чтобы получить $nA?';
      actionTxt =
          'Сколько надо прибавить к ${itp.intToPropis(nB)}, чтобы получить ${itp.intToPropis(nA)}?';
    } else if (actionInt == 9) {
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA < nB) {
        if (nA == 0) {
          nA = 1;
        }
        nRes = nB ~/ nA;
        if (nRes == 0) {
          nRes = 1;
        }
        nA = nB;
        nB = nA ~/ nRes;
      } else {
        if (nB == 0) {
          nB = 1;
        }
        nRes = nA ~/ nB;
        nA = nB * nRes;
      }
      action = 'Во сколько раз $nB меньше чем $nA?';
      actionTxt =
          'Во сколько раз ${itp.intToPropis(nB)} меньше чем ${itp.intToPropis(nA)}?';
    } else if (actionInt == 10) {
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA < nB) {
        if (nA == 0) {
          nA = 1;
        }
        nRes = nB ~/ nA;
        nA = nB;
        if (nRes == 0) {
          nRes = 1;
        }
        nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB;
        nA = nB * nRes;
      }
      action = 'Во сколько раз $nA больше чем $nB?';
      actionTxt =
          'Во сколько раз ${itp.intToPropis(nA)} больше чем ${itp.intToPropis(nB)}?';
    } else if (actionInt == 11) {
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA < nB) {
        if (nA == 0) {
          nA = 1;
        }
        nRes = nB ~/ nA;
        nA = nB;
        if (nRes == 0) {
          nRes = 1;
        }
        nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB;
        nA = nB * nRes;
      }
      action =
          'Машина проехала $nA километр${restOfNum(nA)} за $nB час${restOfNum(nB)}. С какой скоростью ехала машина?';
      actionTxt =
          'Машина проехала ${itp.intToPropis(nA)} километр${restOfNum(nA)} за ${itp.intToPropis(nB)} час${restOfNum(nB)}. С какой скоростью ехала машина?';
    } else if (actionInt == 12) {
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA < nB) {
        if (nA == 0) {
          nA = 1;
        }
        nRes = nB ~/ nA;
        nA = nB;
        if (nRes == 0) {
          nRes = 1;
        }
        nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB;
        nA = nB * nRes;
      }
      action =
          'За сколько времени поезд проедет $nA километр${restOfNum(nA)} если его скорость $nB километр${restOfNum(nB)} в час?';
      actionTxt =
          'За сколько времени поезд проедет ${itp.intToPropis(nA)} километр${restOfNum(nA)} если его скорость ${itp.intToPropis(nB)} километр${restOfNum(nB)} в час?';
    } else if (actionInt == 13) {
      nA = rng.nextInt(maxNum ~/ 10)+1;
      if (nA == 0) {
        nA = 1;
      }
      if (nA > nRes) {
        int n = nA;
        nA = nRes;
        nRes = n;
      }
      if (nA == 0) {
        nA = 1;
      }
      nB = nRes ~/ nA;
      nRes = nA * nB;
      action =
          'Какое расстояние пролетел вертолёт за $nB час${restOfNum(nB)}, если его скорость $nA километр${restOfNum(nA)} в час?';
      actionTxt =
          'Какое расстояние пролетел вертолёт за ${itp.intToPropis(nB)} час${restOfNum(nB)}, если его скорость ${itp.intToPropis(nA)} километр${restOfNum(nA)} в час?';
    } else if (actionInt == 14) {
      nA = multiplierForTable;
      if (nA == 0) {
        nA = 1;
      }
      if (nA > nRes) {
        nRes = nA;
      }
      nB = nRes ~/ nA;
      nRes = nA * nB;
      action = 'Сколько будет $nA * $nB ?';
      actionTxt =
          'Сколько будет ${itp.intToPropis(nA)} умножить на ${itp.intToPropis(nB)}?';
    } else if (actionInt == 15) {
      nB = multiplierForTable;
      if (nA < nRes) {
        nA = nRes;
      }
      nRes = nA ~/ nB;
      nA = nB * nRes;
      action = 'Сколько будет $nA / $nB ?';
      actionTxt =
          'Сколько будет ${itp.intToPropis(nA)} разделить на ${itp.intToPropis(nB)}?';
    }

    expectedRes = nRes;

    if (actionInt <= 4) {
      setState(() {
        _curTaskMsg = "Сколько будет $nA $action $nB ?";
        _curTaskMsgTxt = "Сколько будет ${itp.intToPropis(nA)} $actionTxt ${itp.intToPropis(nB)} ?";
      });
    } else {
      setState(() {
        _curTaskMsg = action;
        _curTaskMsgTxt = actionTxt;
      });
    }
  }

  String restOfNum(int num) {
    if (num > 4 && num < 21) {
     return 'ов';
    }
    int lastD = num%10;
    String res = '';
    if (lastD > 4 || lastD == 0) {
      res = 'ов';
    } else if (lastD > 1) {
      res = 'a';
    }
    return res;
  }

  void _startMathLoop() async {
    _savePref();
    await flutterTts.setSpeechRate(rate);
    _mainMathLoop();
  }

  _savePref() async {
    final SharedPreferences prefs = await _prefs;
    prefs.setInt("maxNum", maxNum);
    prefs.setInt("mult", multiplierForTable);
    prefs.setInt("mode", findCurTaskTypeNumber());
    prefs.setBool("dynDif", dynamicDifficult);
    prefs.setDouble("rate", rate);
  }

  void _mainMathLoop() async {
    try {
      if (_selectedTaskType.id == '+') {
        _formCurTask(1, 1);
      } else if (_selectedTaskType.id == '-') {
        _formCurTask(2, 2);
      } else if (_selectedTaskType.id == '+-') {
        _formCurTask(1, 2);
      } else if (_selectedTaskType.id == '*/') {
        _formCurTask(3, 4);
      } else if (_selectedTaskType.id == '+-*/') {
        _formCurTask(1, 4);
      } else if (_selectedTaskType.id == '+-з') {
        _formCurTask(1, 8);
      } else if (_selectedTaskType.id == '+-*/з') {
        _formCurTask(1, 13);
      } else if (_selectedTaskType.id == 'з') {
        _formCurTask(5, 13);
      } else if (_selectedTaskType.id == 'ту') {
        _formCurTask(14, 14);
      } else if (_selectedTaskType.id == 'тд') {
        _formCurTask(15, 15);
      } else if (_selectedTaskType.id == 'туд') {
        _formCurTask(14, 15);
      } else {
        _formCurTask(1, 13);
      }
    } catch (err) {
      setState(() {
        lastSttWords = 'task form err $err';
        _mainMathLoop();
      });
    }

    if (speech.isListening) {
      print('cancel speech listening');
      await speech.stop();
    }
    await flutterTts.stop();
    await _speak(_curTaskMsgTxt);
    startListening();
  }

  repeatTask() async {
    await flutterTts.stop();
    await _speak(_curTaskMsgTxt);
    startListening();
  }

  void startListening() async {
    if (speech.isListening) {
      print('stop speech into startListening');
      await speech.stop();
    }
    setState(() {
      showMic = true;
    });
    lastSttError = "";
    speech.listen(
      onResult: resultListener,
      listenFor: const Duration(seconds: 20),
      pauseFor: Duration(seconds: 4),
      localeId: 'ru_RU', // en_US uk_UA
      //onSoundLevelChange: _levelChange,
      // cancelOnError: true,
      partialResults: true,
      onDevice: false,
      listenMode: ListenMode.deviceDefault,
      // sampleRate: 44100,
    );
  }

  void resultListener(SpeechRecognitionResult result) async {
    if (!result.finalResult && isProcessed) {
      return;
    }
    String recognizedWords = result.recognizedWords.toString();
    analyzeResults(recognizedWords, result.finalResult);

    if (result.finalResult) {
      print('\n got final result $result \n');
      setState(() {
        lastSttWords = recognizedWords;
        showMic = false;
      });
    } else {
      if (result.alternates.isNotEmpty) {
        setState(() {
          lastSttWords = result.alternates[0].recognizedWords;
        });
      }
      print('\n got non-final result $result \n');
      lastNonFinalRecognizedWords = recognizedWords;
      if (waitingFor != _curTaskMsgTxt) {
        waitingFor = _curTaskMsgTxt;
        //Future.delayed(const Duration(seconds: 3), _checkIfLongPause);
      }
    }
  }

  bool _isNumeric(String str) {
    if (str == '') {
      return false;
    }
    return double.tryParse(str) != null;
  }

  analyzeResults(String recognizedWords, bool finalResult) async {
    print('analyzing $finalResult');
    var wordsList = recognizedWords.split(' ');
    int answerRes = -1;
    for (var i = 0; i < wordsList.length; i++) {
      String word = wordsList[i].toLowerCase();
      print('analyze word $word'); // Восемь
      word = word.replaceAll('четыре', '4');
      word = word.replaceAll('восемь', '8');
      word = word.replaceAll('девять', '9');
      word = word.replaceAll('десять', '10');
      word = word.replaceAll('шесть', '6');
      word = word.replaceAll('пять', '5');
      word = word.replaceAll('семь', '7');
      word = word.replaceAll('ноль', '0');
      word = word.replaceAll('один', '1');
      word = word.replaceAll('два', '2');
      word = word.replaceAll('три', '3');
      word = word.replaceAll(':00', '');
      print('after replace $word');
      if (_isNumeric(word)) {
        print('isNumeric');
        answerRes = int.parse(word);
        print('answerRes $answerRes');
        break;
      }
    }
    print('res answ $answerRes');
    if (answerRes == -1) {
      if (!finalResult) {
        return;
      }
      await _speak('Повтори пожалуйста.');
      startListening();
      return;
    }
    if (answerRes == expectedRes) {
      if (!finalResult) {
        await speech.stop();
        setState(() {});
      }
      numOkLast5++;
      setState(() {
        if (dynamicDifficult && numOkLast5 == 5) {
          maxNum = (maxNum * 1.05 + 1).toInt();
          numOkLast5--;
        }
        numOkAnswer++;
        numTotalAnswer++;
      });
      await _speak(getOk());
      wrongCounter = 0;
    } else {
      if (!finalResult) {
        return;
      }
      wrongCounter++;
      if (wrongCounter < 2) {
        await _speak(getTry());
        startListening();
        return;
      }
      numOkLast5--;
      setState(() {
        if (dynamicDifficult && numOkLast5 == -1) {
          maxNum = (maxNum * 0.95 - 1).toInt();
          numOkLast5 = 0;
        }
        numWrongAnswer++;
        numTotalAnswer++;
      });
      await _speak('${getWrong()} $expectedRes');
    }
    _mainMathLoop();
  }

  void displaySttDialog() async {
    await flutterTts.stop();
    await speech.stop();
    var result  = await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20,),
            const Text("Я тебя не понял...", textScaleFactor: 1.3,),
            const SizedBox(height: 12,),
            const Text("Повторим?", textScaleFactor: 1.5,),
            const SizedBox(height: 30,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: ElevatedButton(
                      child: const Text('Да', style: TextStyle(color: Colors.white),),
                      onPressed: () {
                        Navigator.pop(context, true);
                      }),
                ),
                const SizedBox(width: 40,),
                Container(
                  width: 70, height: 70,
                  decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.all(Radius.circular(50))
                  ),
                  child: ElevatedButton(
                      child: const Text('Нет', style: TextStyle(color: Colors.white),),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result == null) {
      return;
    }
    startListening();
  }

  showAlertPage(String msg) {
    showAboutDialog(
      context: context,
      applicationName: 'Alert',
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Center(child: Text(msg))
        )
      ],
    );
  }

  void onChangeDropdownItem(value) {
    setState(() {
      _selectedTaskType = value;
    });
  }

  int findCurTaskTypeNumber() {
    for (int i = 0; i < _tasksTypes.length; i++) {
      if (_tasksTypes[i] == _selectedTaskType) {
        return i;
      }
    }
    return 5;
  }

  Widget myFlatBtn(String s, cb) {
    return ElevatedButton(
      onPressed: () {
        cb();
      },
      child: Text(s, style: const TextStyle(fontSize: 16.0),),
    );
  }

  Widget taskPageW(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
            children: [
              const Expanded(child: Text('Реши задачу')),
              IconButton(
                  onPressed: () async {
                    speech.stop();
                    flutterTts.stop();
                    setState(() { mode = 0; });
                  },
                  icon: const Icon(Icons.settings, size: 28,)
              )
            ],
          )
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  _curTaskMsg,
                  style: const TextStyle(fontSize: 22.0),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: (){
                  if (speech.isListening) {
                    speech.stop();
                    showMic = false;
                    setState((){});
                  } else {
                    startListening();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    color: showMic? Colors.green : Colors.black12,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                      speech.isListening?
                      BlinkWidget(
                        children: <Widget>[
                          Icon(
                            Icons.mic,
                            size: 50,
                            color: speech.isListening ? Colors.green : Colors.transparent,
                          ),
                          const Icon(Icons.mic, size: 50, color: Colors.transparent),
                        ],
                      )
                          :
                      const Icon(Icons.mic, size: 50, color: Colors.grey)
                      ,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: Text('Последний ответ: $lastSttWords',
                      style: const TextStyle(fontSize: 20.0), textAlign: TextAlign.center,),
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              Text('Всего ответов: $numTotalAnswer',
                  style: const TextStyle(fontSize: 20.0)),
              const SizedBox(height: 10,),
              Text('Правильных ответов: $numOkAnswer',
                  style: const TextStyle(fontSize: 20.0)),
              const SizedBox(height: 10,),
              Text('Неправильных ответов: $numWrongAnswer',
                  style: const TextStyle(fontSize: 20.0)),
            ],
          ),
          const SizedBox(height: 20,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ClipOval(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.blue,
                  child: IconButton(
                    onPressed: (){ repeatTask(); },
                    icon: const Icon(Icons.repeat, size: 33, color: Colors.white,),
                  ),
                ),
              ),
              ClipOval(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.blue,
                  child: IconButton(
                    onPressed: (){ _mainMathLoop(); },
                    icon: const Icon(Icons.arrow_forward_ios, size: 35, color: Colors.white,),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20,),
        ],
      ),
    );
  }

  Widget startMathMenuW(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          const Expanded(child: Text('Ответь решение')),
          IconButton(
              onPressed: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const About())
                );
              },
              icon: const Icon(Icons.help, size: 30,)
          ),
        ],
      )),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('assets/images/math.png'),
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.2), BlendMode.dstATop),
            ),
          ),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              const SizedBox(height: 30,),
              Row(
                children: const [
                  SizedBox(width: 15,),
                  Expanded(child: Text('Когда будешь готов - нажми', textScaleFactor: 3, textAlign: TextAlign.center)),
                  SizedBox(width: 15,),
                ],
              ),
              const SizedBox(height: 30,),
              Container(
                width: double.infinity, height: 100,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        mode = 1;
                      });
                      _startMathLoop();
                    },
                    child: const Text(
                      "СТАРТ",
                      style: TextStyle(fontSize: 30.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30,),
              Container(
                padding: const EdgeInsets.all(15),
                color: Colors.lightBlue[100],
                child: Column(children: <Widget>[
                  const Text('настройки Тренера:',
                      textScaleFactor: 1.4, textAlign: TextAlign.center),
                  const SizedBox(height: 10,),
                  Container(
                    color: Colors.white60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        DropdownButton(
                            value: _selectedTaskType,
                            items: _dropDownMenuTaskTypeItems,
                            onChanged: onChangeDropdownItem
                        ),
                      ],
                    ),
                  ),
                  TextField(
                      controller: textEditController
                        ..text = maxNum.toString(),
                      autocorrect: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          prefix: Text('Максимум числа: '),
                          //labelStyle: ,
                          hintText: 'Максимум:'),
                      onSubmitted: (String value) async {
                        if (_isNumeric(value)) {
                          setState(() {
                            maxNum = int.parse(value);
                          });
                        }
                      }),
                  Row(
                    children: <Widget>[
                      const Text('Динамическая сложность:', textScaleFactor: 1.1),
                      Switch(
                          value: dynamicDifficult,
                          onChanged: (newVal) {
                            setState(() {
                              dynamicDifficult = newVal;
                            });
                          })
                    ],
                  ),
                  TextField(
                      controller: textEditControllerForMult
                        ..text = multiplierForTable.toString(),
                      autocorrect: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          prefix: Text('Множитель (умножение): '),
                          hintText: 'Множитель для таблицы умножения:'),
                      onSubmitted: (String value) async {
                        if (_isNumeric(value)) {
                          setState(() {
                            multiplierForTable = int.parse(value);
                          });
                        }
                      }),
                  const SizedBox(height: 12,),
                  Text('Скорость речи: ${(rate*100).toStringAsFixed(0)}% '),
                  Slider(value: rate,
                      onChanged: (newVal) {
                        rate = newVal;
                        setState((){});
                      }
                  ),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (mode == 0) {
      return startMathMenuW(context);
    } else {
      return taskPageW(context);
    }
  }

}
