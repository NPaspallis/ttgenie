enum MessageType {
  error,
  warning;

  @override
  String toString() => name;
}

class Message {

  static const String noUrl = '';

  final MessageType type;
  final String shortText;
  final String fullText;
  final String url;

  Message(this.type, this.shortText, this.fullText, {this.url = noUrl});

  bool get hasUrl => url != noUrl;

  String toBadgeHtml() {
    return '<span class="$type"><div class="tooltip">${type == MessageType.error ? "&#9888; Conflict: $shortText" : "&#9888; Warning: $shortText"}<span class="tooltiptext">$fullText</span></div></span>';
  }
}
