import 'package:r_flutter/src/model/resources.dart';
import 'package:yaml/yaml.dart';

enum DocumentationStyle {
  /// Works in Android Studio
  html,

  /// Works in VSCode
  markdown,

  none
}

class Arguments {
  String pubspecFilename = 'pubspec.yaml';
  List<String> ignoreAssets = [];
  String outputFilename = 'assets.dart';
  String intlFilename;
  List<CustomAssetType> assetClasses;
  DocumentationStyle documentationStyle = DocumentationStyle.html;
}

T parseEnum<T>(String input, List<T> values) {
  for (var value in values) {
    final stringValue = '$value'.split('.').last;

    if (stringValue == input) {
      return value;
    }
  }

  return null;
}

Arguments parseYamlArguments(YamlMap yaml) {
  final arguments = Arguments();

  yaml = yaml["r_flutter"];
  if (yaml == null) {
    return arguments;
  }

  arguments.outputFilename = yaml["outputFilename"] ?? arguments.outputFilename;
  arguments.documentationStyle =
      parseEnum(yaml["documentationStyle"], DocumentationStyle.values) ??
          DocumentationStyle.html;

  final YamlList ignoreRaw = yaml['ignore'];
  arguments.ignoreAssets = ignoreRaw?.map((x) => x as String)?.toList() ?? [];
  arguments.intlFilename = yaml['intl'];

  final YamlMap assetClasses = yaml['asset_classes'];
  final classes = <CustomAssetType>[];
  for (var key in assetClasses?.keys ?? []) {
    final Object value = assetClasses[key];
    var import = CustomAssetType.defaultImport;
    String className;
    if (value is YamlMap) {
      className = value['class'];
      import = value['import'] ?? import;
    } else if (value is String) {
      className = value;
    } else {
      assert(false);
    }

    classes.add(CustomAssetType(className, key, import));
  }
  arguments.assetClasses = classes;

  return arguments;
}
