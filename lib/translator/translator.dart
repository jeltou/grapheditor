import 'package:flutter/services.dart' as s;
import 'package:fores/debug/debug.dart';
import 'package:yaml/yaml.dart';

Translator? _instance;

Translator getTranslator() {
  if (_instance == null) {
    throw Exception("Translator not initilouzed");
  }
  return _instance!;
}

Future<void> initTranslator(String lang) async {
  _instance = Translator();
  await _instance?.initTranslator(lang);
}

class Translator {
  Map<String, String> translations = {};
  String defaultLang = "de_de";

  Future<void> initTranslator(String lang) async {
    try {
      final data = await s.rootBundle.loadString('assets/i18n/$lang.yaml');
      translations = Map<String, String>.from(loadYaml(data));
    } catch (e) {
      dPrint(e);
    }
  }

  String translate(String input, {bool replaceAll = true}) {
    if (replaceAll) {
      translations.forEach((search, replace) {
        if (input.contains(search)) {
          input = input.replaceAll(search, replace);
        }
      });
    } else {
      if (translations.containsKey(input)) {
        input = input.replaceAll(input, translations[input]!);
      }
    }
    return input;
  }
}
