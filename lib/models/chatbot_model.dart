class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class AIResponse {
  final String message;
  final List<String>? suggestions;
  final String disclaimer;

  AIResponse({
    required this.message,
    this.suggestions,
    required this.disclaimer,
  });
}
