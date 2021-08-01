import 'package:cosecheros/shared/constants.dart';
import 'package:cosecheros/shared/extensions.dart';
import 'package:flutter/widgets.dart';

class FormUrl {
  String href;
  int min;

  FormUrl.fromMap(Map map) {
    href = map['href'];
    min = map['min'] as int;
  }
}

class FormSpec {
  Color color;
  String label;
  List<FormUrl> urls;
  Map<String, bool> users;

  FormSpec.fromMap(Map map) {
    print("FormSpec: map: $map");

    color = HexColor.fromHex(map['color'] ?? '#FF2196F3');
    label = map['label'];

    final unparsedUrls = map['urls'];
    urls = unparsedUrls is List
        ? unparsedUrls.map((e) => FormUrl.fromMap(e)).toList()
        : List.empty();

    // users = Map<String, bool>.from(map['users']);
  }

  /*
   * Busca la mejor url del formulario.
   * Tiene en cuenta la version minima requerida por el formulario
   * y la version actual de la app.
   *
   * El algoritmo es el siguiente:
   *
   * Supongamos que la versión de la app es la 5
   *
   * 1. Hay alguna url cuya versión requerida sea 5?
   * 2. Si es si, la devuelvo
   * 2. Si hay muchas, elijo la última. Ya que
   *    como firebase sólo permite agregar items al final,
   *     la última siempre va a ser la más nueva.
   * 3. Si no hay, pregunto por 4, y repito 2.
   * 4. Itero hasta la 1, si no se encontró ninguna,
   *    devuelvo null.
   *
   * Ejemplos
   * urls = [ {a, 2}, {b, 2}, {c, 3}, {d, 4}, {e, 2}, {f, 4} ]
   *
   * buildNumber = 5
   * min = 5? -> []
   * min = 4? -> [d, f] -> return f
   *
   * buildNumber = 3
   * min = 3? -> [c] -> return c
   *
   * buildNumber = 1
   * min = 1? -> [] -> return null
   */
  String getUrl() {
    for (int v = Constants.buildVersion; 0 < v; v--) {
      final a = urls.where((e) => e.min == v);
      if (a.isNotEmpty) {
        return a.last.href;
      }
    }
    return null;
  }
}
