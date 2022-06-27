import 'dart:math';

class TaskType {
  String id;
  String name;

  TaskType(this.id, this.name);

  static List<TaskType> getTaskTypes() {
    return <TaskType>[
      TaskType('+', 'Сложение'),
      TaskType('-', 'Вычитание'),
      TaskType('+-', 'Сложение и вычитание'),
      TaskType('*/', 'Умножение и деление'),
      TaskType('+-*/', 'Все простые действия'),
      TaskType('+-з', 'Задачи и примеры на + -'),
      TaskType('+-*/з', 'Задачи и примеры на + - * /'),
      TaskType('з', 'Задачи отдельно'),
      TaskType('ту', 'Таблица умножения'),
      TaskType('тд', 'Таблица деления'),
      TaskType('туд', 'Таблица умножения и деления'),
    ];
  }
}

List <String> oks = ['Окей!', "Супер", "Молодец", "Так держать!", "Умница"];
List <String> wrongs = ["Неправильно. Будет", "Увы. Правильный ответ", "Нееет. Правильный ответ",
  "Не совсем. Будет"];
List <String> tries = ['А если подумать?', "Подумай ещё", "Попробуй ещё раз",
  "Почти. Следующая попытка", "Внимательней!"];

String getOk () {
  Random rng = Random();
  return oks[rng.nextInt(oks.length)];
}

String getWrong () {
  Random rng = Random();
  return wrongs[rng.nextInt(wrongs.length)];
}

String getTry () {
  Random rng = Random();
  return tries[rng.nextInt(tries.length)];
}

/*
тест
плеймаркет + аппстор
укр. версия
англ. версия

el-GR, ko-KR, id-ID, it-IT, sk-SK, th-TH, fr-FR, zh-CN, fr-CA, en-IN, es-MX,
en-GB, he-IL, nl-BE, hu-HU, ar-SA, nl-NL, zh-TW, de-DE, pt-BR, ja-JP, pt-PT,
tr-TR, no-NO, en-IE, da-DK, hi-IN, es-ES, cs-CZ, ro-RO, en-AU, fi-FI, en-ZA,
pl-PL, sv-SE, en-US, ru-RU, zh-HK
*/