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