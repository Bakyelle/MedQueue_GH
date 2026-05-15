import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chatbot_model.dart';

class ChatbotService extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Mock AI responses
  static final Map<String, AIResponse> mockResponses = {
    'headache': AIResponse(
      message:
          'I understand you have a headache. Common causes include stress, dehydration, or lack of sleep.\n\nSuggested first aid:\n• Rest in a quiet, dark room\n• Drink plenty of water\n• Apply a cold/warm compress\n• Take over-the-counter pain relief if needed\n\nSee a doctor if the pain persists or worsens.',
      suggestions: ['More about headaches', 'When to see a doctor', 'Common triggers'],
      disclaimer: 'This is educational information only. Always consult a healthcare professional for proper diagnosis.',
    ),
    'fever': AIResponse(
      message:
          'A fever is your body\'s response to infection. Normal body temperature is 98.6°F (37°C), and a fever is typically 100.4°F (38°C) or higher.\n\nSuggested first aid:\n• Stay hydrated\n• Rest well\n• Use fever-reducing medications if needed\n• Wear light clothing\n• Monitor your temperature regularly',
      suggestions: ['Fever medications', 'When it\'s serious', 'Temperature tracking'],
      disclaimer: 'This is educational information only. Always consult a healthcare professional for proper diagnosis.',
    ),
    'cold': AIResponse(
      message:
          'Common cold is usually caused by viruses and typically goes away on its own within 7-10 days.\n\nSuggested first aid:\n• Get plenty of rest\n• Stay hydrated\n• Use saline nasal drops\n• Gargle with warm salt water\n• Eat vitamin C rich foods\n• Use honey for cough relief (adults and children over 1 year)',
      suggestions: ['Cold prevention', 'Cough remedies', 'When to get help'],
      disclaimer: 'This is educational information only. Always consult a healthcare professional for proper diagnosis.',
    ),
    'default': AIResponse(
      message:
          'Thank you for reaching out. I can provide basic health information and first-aid guidance.\n\nFor specific symptoms, please describe them, and I\'ll provide relevant information. However, please remember that I cannot diagnose conditions.\n\nIf you experience severe symptoms, please call emergency services or visit a hospital immediately.',
      suggestions: ['Common symptoms', 'First aid basics', 'When to see a doctor'],
      disclaimer: 'This is educational information only. Always consult a healthcare professional for proper diagnosis.',
    ),
  };

  // Send message to chatbot
  Future<void> sendMessage(String userMessage) async {
    // Add user message
    _messages.add(
      ChatMessage(
        id: Uuid().v4(),
        content: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Get mock response based on keywords
      String responseKey = 'default';
      final lowerMessage = userMessage.toLowerCase();

      if (lowerMessage.contains('headache') || lowerMessage.contains('head pain')) {
        responseKey = 'headache';
      } else if (lowerMessage.contains('fever') || lowerMessage.contains('temperature')) {
        responseKey = 'fever';
      } else if (lowerMessage.contains('cold') || lowerMessage.contains('cough') || lowerMessage.contains('flu')) {
        responseKey = 'cold';
      }

      final response = mockResponses[responseKey]!;

      // Add bot message
      _messages.add(
        ChatMessage(
          id: Uuid().v4(),
          content: response.message,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get response: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear chat history
  void clearMessages() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
