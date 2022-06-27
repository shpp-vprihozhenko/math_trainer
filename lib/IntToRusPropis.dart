class IntToRusPropis {
  List groups = [], names = [];

  IntToRusPropis() {
    groups = []..length = 10;

    groups[0] = []..length = 10;
    groups[1] = []..length = 10;
    groups[2] = []..length = 10;
    groups[3] = []..length = 10;
    groups[4] = []..length = 10;

    groups[9] = []..length = 10;

    groups[1][9] = 'тысяч';
    groups[1][1] = 'тысяча';
    groups[1][2] = 'тысячи';
    groups[1][3] = 'тысячи';
    groups[1][4] = 'тысячи';

    groups[2][9] = 'миллионов';
    groups[2][1] = 'миллион';
    groups[2][2] = 'миллиона';
    groups[2][3] = 'миллиона';
    groups[2][4] = 'миллиона';

    groups[3][1] = 'миллиард';
    groups[3][2] = 'миллиарда';
    groups[3][3] = 'миллиарда';
    groups[3][4] = 'миллиарда';

    groups[4][1] = 'триллион';
    groups[4][2] = 'триллиона';
    groups[4][3] = 'триллиона';
    groups[4][4] = 'триллиона';

    names = []..length = 901;

    names[1] = 'один';
    names[2] = 'два';
    names[3] = 'три';
    names[4] = 'четыре';
    names[5] = 'пять';
    names[6] = 'шесть';
    names[7] = 'семь';
    names[8] = 'восемь';
    names[9] = 'девять';
    names[10] = 'десять';
    names[11] = 'одиннадцать';
    names[12] = 'двенадцать';
    names[13] = 'тринадцать';
    names[14] = 'четырнадцать';
    names[15] = 'пятнадцать';
    names[16] = 'шестнадцать';
    names[17] = 'семнадцать';
    names[18] = 'восемнадцать';
    names[19] = 'девятнадцать';
    names[20] = 'двадцать';
    names[30] = 'тридцать';
    names[40] = 'сорок';
    names[50] = 'пятьдесят';
    names[60] = 'шестьдесят';
    names[70] = 'семьдесят';
    names[80] = 'восемьдесят';
    names[90] = 'девяносто';
    names[100] = 'сто';
    names[200] = 'двести';
    names[300] = 'триста';
    names[400] = 'четыреста';
    names[500] = 'пятьсот';
    names[600] = 'шестьсот';
    names[700] = 'семьсот';
    names[800] = 'восемьсот';
    names[900] = 'девятьсот';
  }

  String intToPropis(int x) {
    if (x == 0) {
      return 'ноль';
    }
    var r = '';
    var i, j;

    var y = x.floor();

    var t = []..length = 5;

    for (i = 0; i <= 4; i++) {
      t[i] = y % 1000;
      y = (y / 1000).floor();
    }

    var d = []..length = 5;

    for (i = 0; i <= 4; i++) {
      d[i] = []..length = 101;
      d[i][0] = t[i] % 10; // единицы
      d[i][10] = t[i] % 100 - d[i][0]; // десятки
      d[i][100] = t[i] - d[i][10] - d[i][0]; // сотни
      d[i][11] = t[i] % 100; // две правых цифры в виде числа
    }

    for (i = 4; i >= 0; i--) {
      if (t[i] > 0) {
        if (names[d[i][100]] != null) r += ' ' + names[d[i][100]];

        if (names[d[i][11]] != null) {
          r += ' ' + names[d[i][11]];
        } else {
          if (names[d[i][10]] != null) r += ' ' + names[d[i][10]];
          if (names[d[i][0]] != null) r += ' ' + names[d[i][0]];
        }

        if (names[d[i][11]] != null) // если существует числительное
          j = d[i][11];
        else
          j = d[i][0];

        if (i > 0) {
          if (groups[i][j] != null) {
            r += ' ' + groups[i][j];
          } else {
            r += ' ' + groups[i][9];
          }
        }
      }
    }

    r = r.replaceAll('сорок', '40');

    return r;
  }
}
