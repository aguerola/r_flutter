import 'dart:io';

import 'package:r_flutter/builder.dart';
import 'package:r_flutter/src/arguments.dart';
import 'package:r_flutter/src/generator/generator.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import '../bin/generate.dart' as bin;

import 'current_directory.dart';

void main() {
  test('test example', () {
    final contents = processPubspec('pubspec.yaml', 'example');
    expect(contents, isNotNull);
  });

  test('test asset classes', () {
    final contents = processPubspec('pubspec_asset_classes.yaml');
    expect(contents, contains('SvgFile'));
    expect(contents, contains('TxtFile'));
  });

  test('test simple', () {
    final contents = processPubspec('pubspec_simple.yaml');
    expect(contents, contains('svg.svg'));
  });

  test('test manual', () {
    setCurrentDirectory('example');
    bin.main([]);

    final generated = File('assets.dart');
    final content = generated.readAsStringSync();
    expect(content, contains('SvgFile'));
    generated.deleteSync();
  });
}

Arguments loadPubspec(String name, String currentDirectory) {
  setCurrentDirectory(currentDirectory);
  final yaml = loadYaml(File(name).readAsStringSync());
  final args = parseYamlArguments(yaml);
  args.pubspecFilename = name;
  return args;
}

String processPubspec(String name, [String currentDirectory = 'test']) {
  final arguments = loadPubspec(name, currentDirectory);
  final res = parseResources(arguments);
  final contents = generateFile(res, arguments);
  return contents;
}
