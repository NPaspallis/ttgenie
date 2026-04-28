import 'package:flutter/foundation.dart';

class TimetableViewEntry implements Comparable<TimetableViewEntry> {
  final String type;
  final String group;
  final String programme;
  final bool distanceLearning;
  final String name;
  final List<String> values;

  TimetableViewEntry({
    required this.type,
    required this.group,
    required this.programme,
    required this.distanceLearning,
    required this.name,
    required this.values,
  });

  @override
  int compareTo(TimetableViewEntry other) => name.compareTo(other.name);

  @override
  String toString() {
    return 'TimetableViewEntry{'
        'type: $type, '
        'group: $group, '
        'programme: $programme, '
        'distanceLearning: $distanceLearning, '
        'name: $name, '
        'values: $values'
        '}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimetableViewEntry) return false;

    return other.distanceLearning == distanceLearning &&
        other.type == type &&
        other.group == group &&
        other.programme == programme &&
        other.name == name &&
        listEquals(other.values, values);
  }

  @override
  int get hashCode => Object.hash(
    type,
    group,
    programme,
    distanceLearning,
    name,
    Object.hashAll(values),
  );
}