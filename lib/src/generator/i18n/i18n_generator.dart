import 'package:r_flutter/src/arguments.dart';
import 'package:r_flutter/src/generator/i18n/i18n_generator_utils.dart';
import 'package:r_flutter/src/model/dart_class.dart';
import 'package:r_flutter/src/model/i18n.dart';

///
/// ```dart
/// class I18n {
///  final I18nLookup _lookup;
///
///  I18n(this._lookup);
///
///  static Locale _locale;
///
///  static Locale get currentLocale => _locale;
///
///  /// add custom locale lookup which will be called first
///  static I18nLookup customLookup;
///
///  static const I18nDelegate delegate = I18nDelegate();
///
///  static I18n of(BuildContext context) => Localizations.of<I18n>(context, I18n);
///
///  static List<Locale> get supportedLocales {
///    return const <Locale>[
///      Locale("en"),
///      Locale("de"),
///      Locale("pl"),
///      Locale("de", "AT")
///    ];
///  }
///
///  String get hello {
///    return customLookup?.hello ?? _lookup.hello;
///  }
///
///  String getString(String key, [Map<String, String> placeholders]) {
///    switch (key) {
///      case I18nKeys.hello:
///        return hello;
///    }
///    return null;
///  }
///}
/// ```
///
DartClass generateI18nClass(I18nLocales i18n, Arguments arg) {
  StringBuffer classString = StringBuffer("""class I18n {
  final I18nLookup _lookup;

  I18n(this._lookup);

  static Locale _locale;

  static Locale get currentLocale => _locale;

  /// add custom locale lookup which will be called first
  static I18nLookup customLookup;

  static const I18nDelegate delegate = I18nDelegate();

  static I18n of(BuildContext context) => Localizations.of<I18n>(context, I18n);

""");

  classString.writeln(_generateSupportedLocales(i18n));
  classString.write(_generateAccessorMethods(i18n, arg));
  classString.write(_generateGetStringMethod(i18n));

  classString.writeln("}");
  return DartClass(code: classString.toString());
}

String _generateSupportedLocales(I18nLocales i18n) {
  StringBuffer code =
      StringBuffer("""  static List<Locale> get supportedLocales {
    return const <Locale>[
""");

  List<Locale> locales = i18n.locales
      .map((it) => it.locale)
      .where((it) => it != i18n.defaultLocale)
      .toList();

  code.write(
      "      Locale(\"${i18n.defaultLocale.toString().split("_").join(", ")}\")");
  for (var locale in locales) {
    String localeParameters = locale.toString().split("_").join("\", \"");
    code.write(",\n      Locale(\"${localeParameters}\")");
  }
  code.write("\n");
  code.writeln("    ];");
  code.writeln("  }");
  return code.toString();
}

String _generateAccessorMethods(I18nLocales i18n, Arguments args) {
  String code = "";

  List<I18nString> values = i18n.defaultValues.strings;

  for (var value in values) {
    String methodCall = _stringValueMethodName(value);
    code += _generateAccessorMethodComment(i18n, value, args);
    code += generateMethod(
            name: value.escapedKey,
            parameters: value.placeholders,
            code:
                "    return customLookup?.${methodCall} ?? _lookup.${methodCall};") +
        "\n";
  }

  return code;
}

String _generateAccessorMethodComment(
    I18nLocales i18n, I18nString string, Arguments args) {
  switch (args.documentationStyle) {
    case DocumentationStyle.html:
      return _generateAccessorMethodCommentHtml(i18n, string);
    case DocumentationStyle.markdown:
      return _generateAccessorMethodCommentMarkdown(i18n, string);
    case DocumentationStyle.none:
      return '';
  }

  return '';
}

/// Returns localizations of given string key.
Iterable<MapEntry<String, String>> getValues(
    I18nLocales i18n, I18nString string) sync* {
  final locales = i18n.locales.toList()
    ..sort((item1, item2) =>
        item1.locale.toString().compareTo(item2.locale.toString()))
    ..remove(i18n.defaultValues)
    ..insert(0, i18n.defaultValues);

  for (var item in locales) {
    String localeString = item.locale.toString();
    final translation = item.strings
        .firstWhere((it) => it.key == string.key, orElse: () => null);

    String value;

    if (translation != null) {
      value = escapeStringLiteral(translation.value);
    }

    yield MapEntry(localeString, value);
  }
}

String _generateAccessorMethodCommentMarkdown(
    I18nLocales i18n, I18nString string) {
  StringBuffer code = StringBuffer();

  final values = getValues(i18n, string).toList();
  final first = values.removeAt(0);

  code.writeln("  /// |||");
  code.writeln('  /// ---|---');
  code.writeln('  /// __${first.key}__ | ${first.value}');
  for (var item in values) {
    code.writeln('  /// ${item.key} | ${item.value ?? '⚠'}');
  }

  return code.toString();
}

String _generateAccessorMethodCommentHtml(I18nLocales i18n, I18nString string) {
  StringBuffer code = StringBuffer();
  code
    ..writeln("  ///")
    ..writeln("  /// <table style=\"width:100%\">")
    ..writeln("  ///   <tr>")
    ..writeln("  ///     <th>Locale</th>")
    ..writeln("  ///     <th>Translation</th>")
    ..writeln("  ///   </tr>");

  final values = getValues(i18n, string);

  for (var item in values) {
    code
      ..writeln("  ///   <tr>")
      ..writeln("  ///     <td style=\"width:60px;\">${item.key}</td>");

    if (item.value == null) {
      code.writeln("  ///     <td><font color=\"yellow\">⚠</font></td>");
    } else {
      code.writeln("  ///     <td>\"${item.value}\"</td>");
    }
    code.writeln("  ///   </tr>");
  }
  code.writeln("  ///  </table>");
  code.writeln("  ///");
  return code.toString();
}

String _stringValueMethodName(I18nString value) {
  if (value.placeholders.isEmpty) {
    return value.escapedKey;
  } else {
    return "${value.escapedKey}(${value.placeholders.join(", ")})";
  }
}

String _generateGetStringMethod(I18nLocales i18n) {
  StringBuffer code = StringBuffer();
  code
    ..writeln(
        "  String getString(String key, [Map<String, String> placeholders]) {")
    ..writeln("    switch (key) {");

  List<I18nString> values = i18n.defaultValues.strings;

  for (var value in values) {
    String methodName;
    if (value.placeholders.isEmpty) {
      methodName = value.escapedKey;
    } else {
      methodName = "${value.escapedKey}(";
      for (var placeholder in value.placeholders) {
        if (!methodName.endsWith("(")) {
          methodName += ", ";
        }
        methodName += "placeholders[\"$placeholder\"]";
      }
      methodName += ")";
    }

    code
      ..writeln("      case I18nKeys.${value.escapedKey}:")
      ..writeln("        return ${methodName};");
  }

  code..writeln("    }")..writeln("    return null;")..writeln("  }");
  return code.toString();
}
