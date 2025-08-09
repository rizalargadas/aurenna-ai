import 'package:share_plus/share_plus.dart';
import '../models/reading.dart';

class ShareReading {
  /// Shares a tarot reading with formatted text
  static Future<void> shareReading({
    required String question,
    required List<DrawnCard> drawnCards,
    required String reading,
    String? readingType,
  }) async {
    final buffer = StringBuffer();
    
    // Header with app branding
    buffer.writeln('🔮 ✨ Aurenna AI Tarot Reading ✨ 🔮');
    buffer.writeln();
    
    // Reading type if provided
    if (readingType != null && readingType.isNotEmpty) {
      buffer.writeln('📖 Reading Type: $readingType');
      buffer.writeln();
    }
    
    // Question section
    buffer.writeln('🤔 Your Question:');
    buffer.writeln('"$question"');
    buffer.writeln();
    
    // Cards section
    buffer.writeln('🃏 Your Cards:');
    for (int i = 0; i < drawnCards.length; i++) {
      final card = drawnCards[i];
      final position = i + 1;
      final reversedText = card.isReversed ? ' (Reversed)' : '';
      
      if (drawnCards.length <= 3) {
        // For 3-card spreads, show position names
        buffer.writeln('$position. ${card.positionName}: ${card.card.name}$reversedText');
      } else {
        // For larger spreads, just number them
        buffer.writeln('$position. ${card.card.name}$reversedText');
      }
    }
    buffer.writeln();
    
    // Reading section
    buffer.writeln('🌟 Your Reading:');
    buffer.writeln(reading);
    buffer.writeln();
    
    // Footer
    buffer.writeln('✨ May the cards guide your path ✨');
    buffer.writeln();
    buffer.writeln('Generated with Aurenna AI Tarot 🔮');
    
    try {
      await Share.share(
        buffer.toString(),
        subject: 'My Tarot Reading - ${readingType ?? 'Personal Guidance'}',
      );
    } catch (e) {
      // If sharing fails, we can handle it gracefully
      throw Exception('Unable to share reading. Please try again.');
    }
  }
  
  /// Shares a simple reading result (for ReadingResultScreen)
  static Future<void> shareReadingResult({
    required String question,
    required List<DrawnCard> drawnCards,
    required String reading,
  }) async {
    return shareReading(
      question: question,
      drawnCards: drawnCards,
      reading: reading,
      readingType: _getReadingTypeFromCards(drawnCards),
    );
  }
  
  /// Shares a love compatibility reading
  static Future<void> shareLoveReading({
    required String person1,
    required String person2,
    required List<DrawnCard> drawnCards,
    required String reading,
  }) async {
    final question = 'Love compatibility between $person1 and $person2';
    return shareReading(
      question: question,
      drawnCards: drawnCards,
      reading: reading,
      readingType: 'Love Compatibility Reading',
    );
  }
  
  /// Shares a situationship reading
  static Future<void> shareSituationshipReading({
    required String person1,
    required String person2,
    required List<DrawnCard> drawnCards,
    required String reading,
  }) async {
    final question = 'Situationship guidance for $person1 and $person2';
    return shareReading(
      question: question,
      drawnCards: drawnCards,
      reading: reading,
      readingType: 'Situationship Reading',
    );
  }
  
  /// Shares a relationship decision reading
  static Future<void> shareRelationshipDecisionReading({
    required String person1,
    required String person2,
    required List<DrawnCard> drawnCards,
    required String reading,
  }) async {
    final question = 'Relationship decision for $person1 and $person2';
    return shareReading(
      question: question,
      drawnCards: drawnCards,
      reading: reading,
      readingType: 'Relationship Decision Reading',
    );
  }
  
  /// Shares a career reading
  static Future<void> shareCareerReading({
    required String name,
    required String currentJob,
    required List<DrawnCard> drawnCards,
    required String reading,
  }) async {
    final jobInfo = currentJob.isNotEmpty ? ' ($currentJob)' : '';
    final question = 'Career guidance for $name$jobInfo';
    return shareReading(
      question: question,
      drawnCards: drawnCards,
      reading: reading,
      readingType: 'Career Reading',
    );
  }
  
  /// Shares a general reading
  static Future<void> shareGeneralReading({
    required String question,
    required List<DrawnCard> drawnCards,
    required String reading,
  }) async {
    return shareReading(
      question: question,
      drawnCards: drawnCards,
      reading: reading,
      readingType: 'Comprehensive General Reading',
    );
  }
  
  /// Shares a past life reading
  static Future<void> sharePastLifeReading({
    required String userName,
    required List<DrawnCard> drawnCards,
    required String reading,
  }) async {
    final question = userName.isNotEmpty 
        ? 'Past Life Reading for $userName' 
        : 'Past Life Reading';
    return shareReading(
      question: question,
      drawnCards: drawnCards,
      reading: reading,
      readingType: 'Past Life Reading - Soul Journey',
    );
  }
  
  /// Shares a career reading
  static Future<void> shareCareerReading({
    required String userName,
    required List<DrawnCard> drawnCards,
    required String reading,
  }) async {
    final question = userName.isNotEmpty 
        ? 'Career Reading for $userName' 
        : 'Career Reading';
    return shareReading(
      question: question,
      drawnCards: drawnCards,
      reading: reading,
      readingType: 'Career Reading - Professional Guidance',
    );
  }
  
  /// Determines reading type based on number of cards
  static String _getReadingTypeFromCards(List<DrawnCard> cards) {
    switch (cards.length) {
      case 1:
        return 'Single Card Reading';
      case 3:
        return 'Three-Card Reading';
      case 5:
        return cards.first.readingType == ReadingType.career 
            ? 'Career Reading' 
            : 'Five-Card Reading';
      case 12:
        return 'Comprehensive Reading';
      default:
        return 'Tarot Reading';
    }
  }
}