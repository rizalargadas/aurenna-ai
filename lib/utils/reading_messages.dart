import 'dart:math';

class ReadingMessages {
  static final _random = Random();
  
  // Card reveal messages (shown when cards are revealed)
  static const List<String> cardRevealMessages = [
    "The cards await your energy...",
    "Your sacred spread is ready...",
    "The cosmic stage is set...",
    "The gateway opens...",
    "Your cards have chosen you...",
    "Your reading awaits...",
    "The cards have gathered...",
  ];
  
  // Generation phase messages (shown in the center of radial effect)
  static const List<String> generationMessages = [
    "Channeling universal wisdom...",
    "Opening channels to the infinite...",
    "Tuning into cosmic frequencies...",
    "Channeling the universe's voice...",
    "Connecting to universal consciousness...",
    "Receiving whispers from infinity...",
    "Receiving transmissions from beyond...",
    "Opening portals to cosmic truth...",
  ];
  
  /// Returns a random card reveal message
  static String getRandomCardRevealMessage() {
    return cardRevealMessages[_random.nextInt(cardRevealMessages.length)];
  }
  
  /// Returns a random generation phase message
  static String getRandomGenerationMessage() {
    return generationMessages[_random.nextInt(generationMessages.length)];
  }
}