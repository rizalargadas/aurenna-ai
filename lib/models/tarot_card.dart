class TarotCard {
  final int id;
  final String name;
  final String suit; // Major Arcana, Cups, Wands, Swords, Pentacles
  final String uprightMeaning;
  final String reversedMeaning;
  final String keywords;
  final String description;
  final int? number; // null for Major Arcana cards with special names

  const TarotCard({
    required this.id,
    required this.name,
    required this.suit,
    required this.uprightMeaning,
    required this.reversedMeaning,
    required this.keywords,
    required this.description,
    this.number,
  });

  // Check if card is Major Arcana
  bool get isMajorArcana => suit == 'Major Arcana';

  // Get full card name with number if applicable
  String get fullName {
    if (isMajorArcana) {
      return name;
    } else {
      return '$name of $suit';
    }
  }

  // Get the image path for this card
  String get imagePath => 'assets/img/cards/$id.png';

  // Get the cover image path
  static String get coverImagePath => 'assets/img/cards/cover.png';

  // Convert to JSON for storing in database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'suit': suit,
      'number': number,
      'upright_meaning': uprightMeaning,
      'reversed_meaning': reversedMeaning,
      'keywords': keywords,
      'description': description,
    };
  }

  // Create from JSON
  factory TarotCard.fromJson(Map<String, dynamic> json) {
    return TarotCard(
      id: json['id'],
      name: json['name'],
      suit: json['suit'],
      number: json['number'],
      uprightMeaning: json['upright_meaning'],
      reversedMeaning: json['reversed_meaning'],
      keywords: json['keywords'],
      description: json['description'],
    );
  }
}
