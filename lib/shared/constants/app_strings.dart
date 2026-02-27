class AppStrings {
  AppStrings._();

  static const String appName = 'Muslim GPT';
  static const String appTagline = 'Your Islamic Knowledge Companion';

  // Chat
  static const String typeYourQuestion = 'Ask your Islamic question...';
  static const String send = 'Send';
  static const String thinking = 'Thinking...';
  static const String welcomeTitle = 'Assalamu Alaikum!';
  static const String welcomeSubtitle =
      'Ask me anything about Islam. I\'ll provide answers with proper Quran and Hadith citations.';

  // Suggested questions
  static const List<String> suggestedQuestions = [
    'Explain Ayat al-Kursi',
    'What are the Five Pillars of Islam?',
    'Hadith on patience',
    'How to perform Wudu?',
  ];

  // Home
  static const String conversations = 'Conversations';
  static const String newChat = 'New Chat';
  static const String noConversations = 'No conversations yet';
  static const String startChatPrompt = 'Tap + to start a new conversation';

  // Settings
  static const String settings = 'Settings';
  static const String apiKey = 'API Key';
  static const String apiKeyHint = 'Enter your OpenRouter API key';
  static const String language = 'Language';
  static const String english = 'English';
  static const String arabic = 'العربية';
  static const String about = 'About';

  // Citations
  static const String source = 'Source';
  static const String translation = 'Translation';
  static const String explanation = 'Explanation';
  static const String reference = 'Reference';

  // Errors
  static const String offTopicResponse =
      'I\'m sorry, I can only help with Islamic questions related to Quran, Hadith, Fiqh, and Islamic knowledge. Please ask an Islam-related question.';
  static const String errorGeneral = 'Something went wrong. Please try again.';
  static const String noApiKey = 'Please set your API key in Settings first.';
}
