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

  final String firstCharacter = String.fromCharCode(trimmed.runes.first);
  final String normalized = firstCharacter.toUpperCase();

  if (normalized.codeUnitAt(0) >= 48 && normalized.codeUnitAt(0) <= 57) {
    return normalized;
  }

  if (normalized.codeUnitAt(0) >= 65 && normalized.codeUnitAt(0) <= 90) {
    return normalized;
  }

  if (_isVisibleUnicodeShortcut(firstCharacter)) {
    return firstCharacter;
  }

  return '#';
}

List<String> sortAsciiShortcutLabels(Iterable<String> labels) {
  final sortedLabels = labels.toSet().toList();

  int sortRank(String label) {
    if (label == '#') {
      return 0;
    }

    final String trimmed = label.trim();
    if (trimmed.isEmpty) {
      return 1000;
    }

    final String firstCharacter = String.fromCharCode(trimmed.runes.first);
    final String normalized = firstCharacter.toUpperCase();

    if (normalized.codeUnitAt(0) >= 48 && normalized.codeUnitAt(0) <= 57) {
      return 10 + (normalized.codeUnitAt(0) - 48);
    }

    if (normalized.codeUnitAt(0) >= 65 && normalized.codeUnitAt(0) <= 90) {
      return 100 + (normalized.codeUnitAt(0) - 65);
    }

    return 1000 + trimmed.runes.first;
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

bool _isVisibleUnicodeShortcut(String character) {
  final int rune = character.runes.first;

  if (rune <= 0x20) {
    return false;
  }

  if (rune >= 0x7F && rune <= 0xA0) {
    return false;
  }

  return true;
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
