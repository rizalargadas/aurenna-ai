class ErrorHandler {
  // Convert technical errors to user-friendly messages
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network/Connection errors
    if (errorString.contains('socketexception') || 
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('no address associated with hostname')) {
      return '''📱 Looks like you're offline, bestie!
      
The cosmic vibes need internet to flow properly. Check your WiFi or mobile data and try again when you're connected! ✨''';
    }
    
    // Timeout errors
    if (errorString.contains('timeout') || 
        errorString.contains('connection timeout')) {
      return '''⏰ The universe is taking its sweet time...
      
Your connection seems slow right now. Give it a moment and try again! Sometimes the cosmos needs a little patience. 🌟''';
    }
    
    // API/Server errors
    if (errorString.contains('401')) {
      return '''🔐 Oops! There's an authentication hiccup.
      
Try refreshing the app or contact support if this keeps happening. We're on it! 💜''';
    }
    
    if (errorString.contains('429')) {
      return '''🚦 Whoa there, speed demon!
      
You're asking for readings faster than the universe can deliver. Take a breather and try again in a few minutes! ⚡''';
    }
    
    if (errorString.contains('500') || errorString.contains('503') || errorString.contains('502')) {
      return '''🌩️ The cosmic servers are having a moment...
      
Our mystical backend is temporarily overwhelmed. Try again in a few minutes while we get the energy flowing again! 🔮''';
    }
    
    // OpenAI specific errors
    if (errorString.contains('openai') || errorString.contains('api')) {
      return '''✨ The AI spirits are temporarily unavailable...
      
Our mystical reading engine needs a quick recharge. Try again in a moment - Aurenna will be back with your cosmic truth! 🔮''';
    }
    
    // Database/Supabase errors
    if (errorString.contains('database') || errorString.contains('supabase')) {
      return '''📚 Our cosmic library is having a moment...
      
The database spirits are taking a quick break. Your reading will be ready shortly - try again in a moment! 🌙''';
    }
    
    // Daily card specific errors
    if (errorString.contains('daily card') || errorString.contains('already drawn')) {
      return '''🌅 You've already pulled your daily cosmic wisdom!
      
The universe speaks once per day, bestie. Come back tomorrow for fresh guidance! ⏰''';
    }
    
    // Generic fallback with personality
    return '''🔮 The cosmic connection hit a snag...
    
Something unexpected happened while channeling your reading. Take a deep breath and try again - the universe just needs a moment to realign! ✨

(If this keeps happening, check your internet connection or try again later!)''';
  }
  
  // Check if error is likely network-related
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') || 
           errorString.contains('failed host lookup') ||
           errorString.contains('network is unreachable') ||
           errorString.contains('connection refused') ||
           errorString.contains('clientexception') ||
           errorString.contains('no address associated with hostname');
  }
  
  // Get a short title for error dialogs
  static String getErrorTitle(dynamic error) {
    if (isNetworkError(error)) {
      return '📱 No Internet Connection';
    }
    
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout')) {
      return '⏰ Connection Timeout';
    }
    
    if (errorString.contains('429')) {
      return '🚦 Slow Down There!';
    }
    
    if (errorString.contains('500') || errorString.contains('503')) {
      return '🌩️ Server Issues';
    }
    
    return '🔮 Cosmic Hiccup';
  }
}