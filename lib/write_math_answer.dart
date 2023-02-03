import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:provider/provider.dart';
import 'about.dart';
import 'globals.dart';

class WriteMathAnswer extends StatefulWidget {
  final mode;

  const WriteMathAnswer({Key? key, this.mode}) : super(key: key);

  @override
  State<WriteMathAnswer> createState() => _WriteMathAnswerState();
}

enum TtsState { playing, stopped, paused, continued }
final String recognize_language = 'en-US';
final double glTtsVolume = 1.0, glTtsRate = 0.4;

class _WriteMathAnswerState extends State<WriteMathAnswer> {
  int num1=0, num2=0, num3=0, result=0, userAnswer=-1;
  String deal1='+', deal2='+';
  int maxNum = 100, attempt = 0;

  bool isModelDownloaded = false;

  var rng = Random();

  @override
  void initState() {
    super.initState();
    _initWorkspace();
  }

  _initWorkspace() async {
    await initGlTTS();
    _loadModel();
    if (!kDebugMode) {
      await speak('Привет!');
      await speak("Давай поиграем!");
      await speak("Я буду задавать тебе интересные задачки, а ты попробуй их решить.");
      await speak("Напиши ответ пальчиком в синем окошке.");
      await speak('Не бойся ошибиться, я всегда помогу тебе!');
      await speak('Дождись когда всё будет готово, и нажми ОК.');
    }
    _formTask();
  }

  _loadModel() async {
    print('_loadModel');
    final DigitalInkRecognizerModelManager2 _modelManager = DigitalInkRecognizerModelManager2();
    bool isDownloaded = await _modelManager.isModelDownloaded(recognize_language);

    print('model isDownloaded? $isDownloaded at ${DateTime.now()}');
    if (!isDownloaded) {
      print('no. loading...');
      await _modelManager.downloadModel(recognize_language);
      print('model isDownloaded at ${DateTime.now()}');
      setState(() {});
    }
    setState(() {
      isModelDownloaded = true;
      print('set isModelDownloaded=true at ${DateTime.now()}');
    });
  }

  _formTask(){
    if (widget.mode == 1) {
      maxNum = 10;
    } else  if (widget.mode == 2) {
      maxNum = 20;
    }
    userAnswer = -1; attempt = 0;
    do {
      num1 = rng.nextInt(maxNum);
      num2 = rng.nextInt(maxNum);
      num3 = rng.nextInt(maxNum);
      if (widget.mode <= 3) {
        num3 = 0;
      }
      deal1 = rng.nextInt(2)==0? '+':'-';
      if (widget.mode == 4) {
        if (deal1 == '-') {
          if (num1 < num2) {
            continue;
          }
        } else {
          if (num1 + num2 > maxNum) {
            continue;
          }
        }
      }
      deal2 = rng.nextInt(2)==0? '+':'-';
      result = num1 + (deal1=='+'?1:-1)*num2 + (deal2=='+'?1:-1)*num3;
      if (result >=0 && result <= maxNum) {
        break;
      }
    } while (true);
    setState(() {});
    String s = 'Сколько будет $num1 ${deal1=='+'?'+':'минус'}  ${itp.intToPropis(num2)} ${deal2=='+'?'+':'минус'} ${itp.intToPropis(num3)}';
    if (widget.mode <= 3) {
      s = 'Сколько будет $num1 ${deal1=='+'?'+':'минус'}  ${itp.intToPropis(num2)}';
    }
    speak(s);
  }

  _gotRecognizedResult(int recResult) async {
    print('_gotRecognizedResult $recResult');
    userAnswer = recResult;
    setState(() {});
    if (userAnswer == result) {
      //await speak('Правильно!');
      await speak(oks[rng.nextInt(oks.length)]);
      //await speak('Решаем дальше');
      _formTask();
    } else {
      await speak('Нет!');
      attempt++;
      if (attempt == 4) {
        await speak(wrongs[rng.nextInt(wrongs.length)]);
        await speak('$result');
        _formTask();
      } else {
        await speak(tries[rng.nextInt(tries.length)]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(
        children: [
          Expanded(child: Text('Напиши решение', textAlign: TextAlign.center,)),
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Сколько будет', textScaleFactor: 2.5,),
              const SizedBox(height: 12,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.mode < 4?
                  Text('$num1 $deal1 $num2 =', textScaleFactor: 2.5)
                  :
                  Text('$num1 $deal1 $num2 $deal2 $num3 =', textScaleFactor: 2.5),
                  const SizedBox(width: 12,),
                  Text('${userAnswer>-1? userAnswer:'?'}', textScaleFactor: 2.5,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: userAnswer == -1? Colors.blue
                                :
                            userAnswer == result?
                                Colors.green
                                :
                                Colors.red
                      ,
                    )
                  ),
                ],
              ),
            ],
          ),
          Expanded(
              child: Container(
                key: recContKey,
                width: double.infinity, height: double.infinity,
                color: Colors.lightBlueAccent[100],
                child: isModelDownloaded?
                  ChangeNotifierProvider(
                    create: (_) => DigitalInkRecognitionState(),
                    child: DigitalInkRecognitionPage(CBonRecognize: _gotRecognizedResult),
                  )
                    :
                  Text('OK')
                ,
              )
          )
        ],
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _formTask,
              child: Text('>')
          ),
        ],
      ),
    );
  }
}


class DigitalInkRecognitionPage extends StatefulWidget {
  var CBonRecognize;

  DigitalInkRecognitionPage({Key? key, this.CBonRecognize}) : super(key: key);

  @override
  _DigitalInkRecognitionPageState createState() =>
      _DigitalInkRecognitionPageState();
}

class _DigitalInkRecognitionPageState extends State<DigitalInkRecognitionPage> {
  bool isCurrentLanguageInstalled = false;

  late final DigitalInkRecognizer2 _digitalInkRecognizer = DigitalInkRecognizer2(languageCode: recognize_language);
  final Ink2 _ink = Ink2();
  List<StrokePoint2> _points = [];
  double topShift = 0;

  @override
  void initState() {
    super.initState();
    RenderBox box = recContKey.currentContext!.findRenderObject() as RenderBox;
    Offset position = box.localToGlobal(Offset.zero); //this is global position
    topShift = position.dy;
  }

  @override
  void dispose() {
    _digitalInkRecognizer.close();
    super.dispose();
  }

  void _clearPad() {
    setState(() {
      _ink.strokes.clear();
      _points.clear();
    });
  }

  Future<void> _startRecognition() async {
    try {
      final candidates = await _digitalInkRecognizer.recognize(_ink);
      String answer = '';
      answer = candidates.first.text;
      answer = answer.replaceAll('g', '9').replaceAll('o', '0');
      setState(() {});
      print('res $answer');
      int intAnswer = -1;
      try {
        intAnswer = int.parse(answer);
      } catch(e) {};
      print('got intAnswer $intAnswer');
      if (intAnswer > -1) {
        widget.CBonRecognize(intAnswer);
      } else {
        showAlertPage(context, 'Не понял. Попробуй ещё ращ');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
    _clearPad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (DragStartDetails details) {
                _ink.strokes.add(Stroke2());
              },
              onPanUpdate: (DragUpdateDetails details) {
                setState(() {
                  final RenderObject? object = context.findRenderObject();
                  final localPosition = (object as RenderBox?)
                      ?.globalToLocal(details.localPosition);
                  if (localPosition != null) {
                    _points = List.from(_points)
                      ..add(StrokePoint2(
                        x: localPosition.dx,
                        y: localPosition.dy+topShift,
                        t: DateTime.now().millisecondsSinceEpoch,
                      ));
                  }
                  if (_ink.strokes.isNotEmpty) {
                    _ink.strokes.last.points = _points.toList();
                  }
                });
              },
              onPanEnd: (DragEndDetails details) {
                _points.clear();
                setState(() {});
              },
              child: CustomPaint(
                painter: Signature(ink: _ink),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text('OK'),
        onPressed: _startRecognition,
      ),
    );
  }
}

class DigitalInkRecognitionState extends ChangeNotifier {
  List<List<Offset>> _writings = [];
  List<RecognitionCandidate2> _data = [];
  bool isProcessing = false;

  List<List<Offset>> get writings => _writings;
  List<RecognitionCandidate2> get data => _data;
  bool get isNotProcessing => !isProcessing;
  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;

  List<Offset> _writing = [];

  void reset() {
    _writings = [];
    notifyListeners();
  }

  void startWriting(Offset point) {
    _writing = [point];
    _writings.add(_writing);
    notifyListeners();
  }

  void writePoint(Offset point) {
    if (_writings.isNotEmpty) {
      _writings[_writings.length - 1].add(point);
      notifyListeners();
    }
  }

  void stopWriting() {
    _writing = [];
    notifyListeners();
  }

  void startProcessing() {
    isProcessing = true;
    notifyListeners();
  }

  void stopProcessing() {
    isProcessing = false;
    notifyListeners();
  }

  set data(List<RecognitionCandidate2> data) {
    _data = data;
    notifyListeners();
  }

  @override
  String toString() {
    return isNotEmpty ? _data.first.text : '';
  }

  String toCompleteString() {
    return _data.first.text.toLowerCase();
  }
}

class Signature extends CustomPainter {
  Ink2 ink;

  Signature({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    canvas.drawColor(Colors.teal[100]!, BlendMode.multiply);

    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(Offset(p1.x.toDouble(), p1.y.toDouble()),
            Offset(p2.x.toDouble(), p2.y.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => true;
}

class DigitalInkRecognizer2 {
  static const MethodChannel _channel =
  MethodChannel('google_mlkit_digital_ink_recognizer');

  /// Refers to language that is being processed.
  //  Note that model should be a BCP 47 language tag from https://developers.google.com/ml-kit/vision/digital-ink-recognition/base-models?hl=en#text
  //  Visit this site [https://tools.ietf.org/html/bcp47] to learn more.
  final String languageCode;

  /// Instance id.
  final id = DateTime.now().microsecondsSinceEpoch.toString();

  /// Constructor to create an instance of [DigitalInkRecognizer2].
  DigitalInkRecognizer2({required this.languageCode});

  /// Performs a recognition of the text written on screen.
  /// It takes an instance of [Ink2] which refers to the user input as a list of [Stroke2].
  Future<List<RecognitionCandidate2>> recognize(Ink2 ink,
      {DigitalInkRecognitionContext2? context}) async {
    final result = await _channel
        .invokeMethod('vision#startDigitalInkRecognizer', <String, dynamic>{
      'id': id,
      'ink': ink.toJson(),
      'context': context?._isValid == true ? context?.toJson() : null,
      'model': languageCode,
    });

    final List<RecognitionCandidate2> candidates = <RecognitionCandidate2>[];
    for (final dynamic json in result) {
      final candidate = RecognitionCandidate2.fromJson(json);
      candidates.add(candidate);
    }

    return candidates;
  }

  /// Closes the recognizer and releases its resources.
  Future<void> close() =>
      _channel.invokeMethod('vision#closeDigitalInkRecognizer', {'id': id});
}

/// Information about the context in which an ink has been drawn.
/// Pass this object to a [DigitalInkRecognizer2] alongside an [Ink2] to improve the recognition quality.
class DigitalInkRecognitionContext2 {
  /// Characters immediately before the position where the recognized text should be inserted.
  final String? preContext;

  /// Size of the writing area.
  final WritingArea? writingArea;

  /// Constructor to create an instance of [DigitalInkRecognitionContext2].
  DigitalInkRecognitionContext2({this.preContext, this.writingArea});

  bool get _isValid => preContext != null || writingArea != null;

  /// Returns a json representation of an instance of [WritingArea].
  Map<String, dynamic> toJson() => {
    'preContext': preContext,
    'writingArea': writingArea?.toJson(),
  };
}

/// The writing area is the area on the screen where the user can draw an ink.
class WritingArea {
  /// Writing area width, in the same units as used in [StrokePoint2].
  final double width;

  /// Writing area height, in the same units as used in [StrokePoint2].
  final double height;

  /// Constructor to create an instance of [WritingArea].
  WritingArea({required this.width, required this.height});

  /// Returns a json representation of an instance of [WritingArea].
  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
  };
}

/// Represents the user input as a collection of [Stroke2] and serves as input for the handwriting recognition task.
class Ink2 {
  /// List of strokes composing the ink.
  List<Stroke2> strokes = [];

  /// Returns a json representation of an instance of [Ink2].
  Map<String, dynamic> toJson() => {
    'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
  };
}

/// Represents a sequence of touch points between a pen (resp. touch) down and pen (resp. touch) up event.
class Stroke2 {
  /// List of touch points as [Point].
  List<StrokePoint2> points = [];

  /// Returns a json representation of an instance of [Stroke2].
  Map<String, dynamic> toJson() => {
    'points': points.map((point) => point.toJson()).toList(),
  };
}

/// A single touch point from the user.
class StrokePoint2 {
  /// Horizontal coordinate. Increases to the right.
  final double x;

  /// Vertical coordinate. Increases downward.
  final double y;

  /// Time when the point was recorded, in milliseconds.
  final int t;

  /// Constructor to create an instance of [StrokePoint2].
  StrokePoint2({required this.x, required this.y, required this.t});

  /// Returns a json representation of an instance of [StrokePoint2].
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    't': t,
  };
}

/// A subclass of [ModelManager] that manages [DigitalInkRecognitionModel] required to process the image.
class DigitalInkRecognizerModelManager2 extends ModelManager {
  /// Constructor to create an instance of [DigitalInkRecognizerModelManager2].
  DigitalInkRecognizerModelManager2()
      : super(
      channel: DigitalInkRecognizer2._channel,
      method: 'vision#manageInkModels');
}

/// Individual recognition candidate.
class RecognitionCandidate2 {
  /// The textual representation of this candidate.
  final String text;

  /// Score of the candidate. Values may be positive or negative.
  ///
  /// More likely candidates get lower values. This value is populated only for models that support it.
  /// Scores are meant to be used to reject candidates whose score is above a threshold.
  /// A particular threshold value for a given application will stay valid after a model update.
  final double score;

  /// Constructor to create an instance of [RecognitionCandidate2].
  RecognitionCandidate2({required this.text, required this.score});

  /// Returns an instance of [RecognitionCandidate2] from a given [json].
  factory RecognitionCandidate2.fromJson(Map<dynamic, dynamic> json) =>
      RecognitionCandidate2(
        text: json['text'],
        score: json['score'],
      );
}
