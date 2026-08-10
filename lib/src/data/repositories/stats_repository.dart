import 'package:hive/hive.dart';
import 'package:music/src/data/services/hive_box.dart';

class PlayEvent {
  final String songId;
  final DateTime playedAt;
  final Duration listened;

  PlayEvent({
    required this.songId,
    required this.playedAt,
    required this.listened,
  });
}

class StatsRepository {
  final Box<dynamic> _box = Hive.box(HiveBox.boxName);

  static const int _maxHistoryEntries = 2000;

  Map<String, int> _readCounters(String key) {
    final Map<dynamic, dynamic> raw = Map<dynamic, dynamic>.from(
      _box.get(key, defaultValue: {}) as Map,
    );

    return raw.map((id, value) => MapEntry(id.toString(), value as int));
  }

  Map<String, int> get playCounts => _readCounters(HiveBox.playCountsKey);

  Map<String, int> get listeningTimes =>
      _readCounters(HiveBox.listeningTimeKey);

  int playCountOf(String songId) => playCounts[songId] ?? 0;

  Duration listeningTimeOf(String songId) =>
      Duration(milliseconds: listeningTimes[songId] ?? 0);

  Future<void> incrementPlayCount(String songId) async {
    final Map<String, int> counts = playCounts;
    counts[songId] = (counts[songId] ?? 0) + 1;
    await _box.put(HiveBox.playCountsKey, counts);
  }

  Future<void> addListeningTime(String songId, Duration listened) async {
    final Map<String, int> times = listeningTimes;
    times[songId] = (times[songId] ?? 0) + listened.inMilliseconds;
    await _box.put(HiveBox.listeningTimeKey, times);

    final List<dynamic> history = List<dynamic>.from(
      _box.get(HiveBox.playHistoryKey, defaultValue: <dynamic>[]) as List,
    );

    history.add({
      'id': songId,
      'at': DateTime.now().millisecondsSinceEpoch,
      'ms': listened.inMilliseconds,
    });

    if (history.length > _maxHistoryEntries) {
      history.removeRange(0, history.length - _maxHistoryEntries);
    }

    await _box.put(HiveBox.playHistoryKey, history);
  }

  List<PlayEvent> history({DateTime? since}) {
    final List<dynamic> raw = List<dynamic>.from(
      _box.get(HiveBox.playHistoryKey, defaultValue: <dynamic>[]) as List,
    );

    final List<PlayEvent> events = [];

    for (final dynamic entry in raw) {
      final Map<dynamic, dynamic> item = Map<dynamic, dynamic>.from(entry as Map);
      final DateTime at = DateTime.fromMillisecondsSinceEpoch(item['at'] as int);

      if (since != null && at.isBefore(since)) {
        continue;
      }

      events.add(
        PlayEvent(
          songId: item['id'].toString(),
          playedAt: at,
          listened: Duration(milliseconds: item['ms'] as int),
        ),
      );
    }

    return events;
  }

  Duration totalListeningTime({DateTime? since}) {
    if (since == null) {
      final int total = listeningTimes.values.fold(0, (sum, ms) => sum + ms);
      return Duration(milliseconds: total);
    }

    final int total = history(since: since).fold(
      0,
      (sum, event) => sum + event.listened.inMilliseconds,
    );

    return Duration(milliseconds: total);
  }

  int playsSince(DateTime since) => history(since: since).length;
}
