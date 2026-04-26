import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TimetableView extends StatelessWidget {
  final String html;

  const TimetableView({super.key, required this.html});

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
        initialData: InAppWebViewInitialData(data: html),
        onReceivedError: (controller, request, error) {
          debugPrint('InAppWebView error: $error');
        },
        onConsoleMessage: (controller, consoleMessage) {
          debugPrint('InAppWebView console message: $consoleMessage');
        },
    );
  }
}

class TimetableViewEntry {
  final String type;
  final String programme;
  final bool distanceLearning;
  final String name;
  final List<String> values;

  TimetableViewEntry({
    required this.type,
    required this.programme,
    required this.distanceLearning,
    required this.name,
    required this.values,
  });

  @override
  String toString() {
    return 'TimetableViewEntry{'
        'type: $type, '
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
        other.programme == programme &&
        other.name == name &&
        listEquals(other.values, values);
  }

  @override
  int get hashCode => Object.hash(
        type,
        programme,
        distanceLearning,
        name,
        Object.hashAll(values),
      );
}
