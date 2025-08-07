import 'tarot_card.dart';
import '../data/tarot_deck.dart';

enum ReadingType {
  threeCard,
  general,
  compatibility,
  situationship,
}

class Reading {
  final String id;
  final String userId;
  final String question;
  final List<DrawnCard> drawnCards; // Cards with their positions and orientations
  final String aiReading;
  final DateTime createdAt;
  final ReadingType readingType;

  const Reading({
    required this.id,
    required this.userId,
    required this.question,
    required this.drawnCards,
    required this.aiReading,
    required this.createdAt,
    required this.readingType,
  });

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question': question,
      'cards': drawnCards.map((dc) => dc.toJson()).toList(),
      'ai_reading': aiReading,
      'created_at': createdAt.toIso8601String(),
      'reading_type': readingType.name,
    };
  }

  // Create from database JSON
  factory Reading.fromJson(Map<String, dynamic> json) {
    final readingTypeStr = json['reading_type'] ?? 'threeCard';
    final readingType = ReadingType.values.firstWhere(
      (e) => e.name == readingTypeStr,
      orElse: () => ReadingType.threeCard,
    );
    
    return Reading(
      id: json['id'],
      userId: json['user_id'],
      question: json['question'],
      drawnCards: (json['cards'] as List)
          .map((cardJson) => DrawnCard.fromJson(cardJson, readingType))
          .toList(),
      aiReading: json['ai_reading'],
      createdAt: DateTime.parse(json['created_at']),
      readingType: readingType,
    );
  }
}

// Represents a card that was drawn with its position and orientation
class DrawnCard {
  final TarotCard card;
  final int position;
  final bool isReversed;
  final ReadingType readingType;

  const DrawnCard({
    required this.card,
    required this.position,
    required this.isReversed,
    required this.readingType,
  });

  String get positionName {
    if (readingType == ReadingType.general) {
      switch (position) {
        case 0: return 'Mind';
        case 1: return 'Body';
        case 2: return 'Spirit';
        case 3: return 'Friends & Family';
        case 4: return 'You';
        case 5: return 'Blessings';
        case 6: return 'Challenges';
        case 7: return 'Advice';
        case 8: return 'Romance';
        case 9: return 'Hobbies';
        case 10: return 'Career';
        case 11: return 'Finances';
        default: return 'Unknown';
      }
    } else if (readingType == ReadingType.compatibility) {
      switch (position) {
        case 0: return 'Your Feelings';
        case 1: return 'Partner\'s Feelings';
        case 2: return 'Dominant Characteristic';
        case 3: return 'Challenges';
        case 4: return 'Potential';
        default: return 'Unknown';
      }
    } else if (readingType == ReadingType.situationship) {
      switch (position) {
        case 0: return 'Your Current Energy';
        case 1: return 'Their Feelings';
        case 2: return 'Their Thoughts';
        case 3: return 'Their Intentions';
        case 4: return 'Their Actions/Plan';
        case 5: return 'Advice for This Situationship';
        default: return 'Unknown';
      }
    } else {
      // Three card reading
      switch (position) {
        case 0: return 'Past';
        case 1: return 'Present';
        case 2: return 'Future';
        default: return 'Unknown';
      }
    }
  }

  String get meaning => isReversed ? card.reversedMeaning : card.uprightMeaning;

  Map<String, dynamic> toJson() {
    return {
      'card_id': card.id,
      'position': position,
      'is_reversed': isReversed,
      'reading_type': readingType.name,
    };
  }

  factory DrawnCard.fromJson(Map<String, dynamic> json, [ReadingType? readingType]) {
    // Import TarotDeck to get the actual card
    final card = TarotDeck.getCardById(json['card_id']);
    final cardReadingType = readingType ?? 
        (json['reading_type'] != null 
            ? ReadingType.values.firstWhere(
                (e) => e.name == json['reading_type'],
                orElse: () => ReadingType.threeCard,
              )
            : ReadingType.threeCard);
    
    return DrawnCard(
      card: card,
      position: json['position'],
      isReversed: json['is_reversed'],
      readingType: cardReadingType,
    );
  }
}
