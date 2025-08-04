import 'tarot_card.dart';
import '../data/tarot_deck.dart';

class Reading {
  final String id;
  final String userId;
  final String question;
  final List<DrawnCard>
  drawnCards; // Cards with their positions and orientations
  final String aiReading;
  final DateTime createdAt;

  const Reading({
    required this.id,
    required this.userId,
    required this.question,
    required this.drawnCards,
    required this.aiReading,
    required this.createdAt,
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
    };
  }

  // Create from database JSON
  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'],
      userId: json['user_id'],
      question: json['question'],
      drawnCards: (json['cards'] as List)
          .map((cardJson) => DrawnCard.fromJson(cardJson))
          .toList(),
      aiReading: json['ai_reading'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Represents a card that was drawn with its position and orientation
class DrawnCard {
  final TarotCard card;
  final int position; // 0: Past, 1: Present, 2: Future
  final bool isReversed;

  const DrawnCard({
    required this.card,
    required this.position,
    required this.isReversed,
  });

  String get positionName {
    switch (position) {
      case 0:
        return 'Past';
      case 1:
        return 'Present';
      case 2:
        return 'Future';
      default:
        return 'Unknown';
    }
  }

  String get meaning => isReversed ? card.reversedMeaning : card.uprightMeaning;

  Map<String, dynamic> toJson() {
    return {
      'card_id': card.id,
      'position': position,
      'is_reversed': isReversed,
    };
  }

  factory DrawnCard.fromJson(Map<String, dynamic> json) {
    // Import TarotDeck to get the actual card
    final card = TarotDeck.getCardById(json['card_id']);
    return DrawnCard(
      card: card,
      position: json['position'],
      isReversed: json['is_reversed'],
    );
  }
}
