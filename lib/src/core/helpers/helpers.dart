import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Color calculateTextColor(Color background) {
  return background.computeLuminance() >= 0.5 ? Colors.black : Colors.white;
}

String? extractAsciiShortcutLabel(String value) {
  final String trimmed = value.trimLeft();
  if (trimmed.isEmpty) {
    return null;
  }

  final int codeUnit = trimmed.codeUnitAt(0);

  if (codeUnit >= 48 && codeUnit <= 57) {
    return String.fromCharCode(codeUnit);
  }

  if (codeUnit >= 65 && codeUnit <= 90) {
    return String.fromCharCode(codeUnit);
  }

  if (codeUnit >= 97 && codeUnit <= 122) {
    return String.fromCharCode(codeUnit - 32);
  }

  return '#';
}

List<String> sortAsciiShortcutLabels(Iterable<String> labels) {
  final sortedLabels = labels.toSet().toList();

  int sortRank(String label) {
    if (label == '#') {
      return 1000;
    }

    final int codeUnit = label.codeUnitAt(0);
    if (codeUnit >= 48 && codeUnit <= 57) {
      return codeUnit - 48;
    }

    if (codeUnit >= 65 && codeUnit <= 90) {
      return 100 + (codeUnit - 65);
    }

    return 1000;
  }

  sortedLabels.sort((first, second) {
    final int rankComparison = sortRank(first).compareTo(sortRank(second));
    if (rankComparison != 0) {
      return rankComparison;
    }

    return first.compareTo(second);
  });

  return sortedLabels;
}

Future<void> shareSong(
    BuildContext context, String songPath, String songName) async {
  List<XFile> files = [];
  // convert song to xfile
  final songFile = XFile(songPath);
  files.add(songFile);
  await Share.shareXFiles(
    files,
    text: songName,
  );
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}
