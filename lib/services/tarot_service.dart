import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/openai.dart';
import '../config/supabase.dart';
import '../data/tarot_deck.dart';
import '../models/tarot_card.dart';
import '../models/reading.dart';
import '../services/auth_service.dart';

class TarotService {
  static const _uuid = Uuid();

  // Draw 3 unique cards with random orientations
  static List<DrawnCard> drawThreeCards() {
    final List<TarotCard> deck = List.from(TarotDeck.cards);
    deck.shuffle();

    final random = Random();
    final drawnCards = <DrawnCard>[];

    for (int i = 0; i < 3; i++) {
      drawnCards.add(
        DrawnCard(
          card: deck[i],
          position: i, // 0: Past, 1: Present, 2: Future
          isReversed: random.nextBool(), // 50% chance of being reversed
          readingType: ReadingType.threeCard,
        ),
      );
    }

    return drawnCards;
  }

  // Draw 12 unique cards for general reading
  static List<DrawnCard> drawTwelveCards() {
    final List<TarotCard> deck = List.from(TarotDeck.cards);
    deck.shuffle();

    final random = Random();
    final drawnCards = <DrawnCard>[];

    for (int i = 0; i < 12; i++) {
      drawnCards.add(
        DrawnCard(
          card: deck[i],
          position:
              i, // 0-11: Mind, Body, Spirit, Friends & Family, You, Blessings, Challenges, Advice, Romance, Hobbies, Career, Finances
          isReversed: random.nextBool(), // 50% chance of being reversed
          readingType: ReadingType.general,
        ),
      );
    }

    return drawnCards;
  }

  // Draw 3 unique cards for yes or no reading
  static List<DrawnCard> drawThreeCardsForYesOrNo() {
    final List<TarotCard> deck = List.from(TarotDeck.cards);
    deck.shuffle();

    final random = Random();
    final drawnCards = <DrawnCard>[];

    for (int i = 0; i < 3; i++) {
      drawnCards.add(
        DrawnCard(
          card: deck[i],
          position: i, // 0: Card 1, 1: Card 2, 2: Card 3
          isReversed: random.nextBool(), // 50% chance of being reversed
          readingType: ReadingType.yesOrNo,
        ),
      );
    }

    return drawnCards;
  }

  // Draw 5 unique cards for compatibility reading
  static List<DrawnCard> drawFiveCards() {
    final List<TarotCard> deck = List.from(TarotDeck.cards);
    deck.shuffle();

    final random = Random();
    final drawnCards = <DrawnCard>[];

    for (int i = 0; i < 5; i++) {
      drawnCards.add(
        DrawnCard(
          card: deck[i],
          position:
              i, // 0: Your Feelings, 1: Partner's Feelings, 2: Dominant Characteristic, 3: Challenges, 4: Potential
          isReversed: random.nextBool(), // 50% chance of being reversed
          readingType: ReadingType.compatibility,
        ),
      );
    }

    return drawnCards;
  }

  // Draw 6 unique cards for situationship reading
  static List<DrawnCard> drawSixCards() {
    final List<TarotCard> deck = List.from(TarotDeck.cards);
    deck.shuffle();

    final random = Random();
    final drawnCards = <DrawnCard>[];

    for (int i = 0; i < 6; i++) {
      drawnCards.add(
        DrawnCard(
          card: deck[i],
          position:
              i, // 0: Your Current Energy, 1: Their Feelings, 2: Their Thoughts, 3: Their Intentions, 4: Their Actions/Plan, 5: Advice
          isReversed: random.nextBool(), // 50% chance of being reversed
          readingType: ReadingType.situationship,
        ),
      );
    }

    return drawnCards;
  }

  // Generate AI reading using OpenAI
  static Future<String> generateReading(
    String question,
    List<DrawnCard> cards,
  ) async {
    final prompt = _buildPrompt(question, cards);

    try {
      final response = await http.post(
        Uri.parse(OpenAIConfig.chatCompletionsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
        },
        body: jsonEncode({
          'model': OpenAIConfig.model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are Aurenna, a premium tarot reader — part mystic, part life coach, part no-nonsense bestie. Your readings feel like a 100 dollars session over wine: deeply intuitive, slightly sassy, and full of heart.

[PERSONALITY & STYLE]
- Speak like a wise best friend who won’t sugarcoat—but always has your back.
- Be FRANK: Tell it like it is, but always with care.
- Be FUNNY: A little humor, a little sass, always human, but avoid cringey analogies.
- Be WARM: Like a blanket and a pep talk in one.
- Be INTUITIVE: You are a super psychic!
- Be PROTECTIVE: Never say anything that could hurt them or others.
- Be COMPLETE: Answer their question fully and thoughtfully.
- Be VALUABLE: Make them walk away thinking, “Damn, that was worth it.”

[YES/NO READING STYLE]
For yes/no questions:
- Say “Yes” or “No” if it’s clear as day.
- If the answer isn’t 100% obvious, try:
   * “Most likely yes”
   * “Leaning toward no”
   * “Chances are good”
   * “Doesn’t look great”
   * “More no than yes”
- If the energy is unclear or conflicting, say:
   * “The vibe’s all over the place on this one…”
   * “Hmm, this one’s foggy — let’s dig deeper.”
   * “There’s potential, but some static in the energy.”
- Use your intuition to guide the phrasing — and always speak like a wise best friend who wants the seeker to trust themselves too.

[ETHICAL & SAFETY RULES]
- For third-party questions (unless it’s close family/partner), start with a cheeky nudge:
   * “Spying, are we? 👀 Okay, but remember — the cards gossip best about YOU.”
   * “Cosmic detective mode: activated. Just know, third-party energy’s like herding cats.”
- Handle sensitive topics with humor and heart:
   * Cheating? Be gentle. “Listen, if something smells off, trust your nose — but don’t go full soap opera just yet.”
   * Health? Add, “Tarot’s got vibes, not degrees — see a pro, okay?”
   * Mental health? “Even the best witches need therapists. Zero shame, 100% love.”
   * Legal/financial? General vibes only — always suggest an expert.
   * Never encourage harm, hate, or destructive choices.

[TASK INSTRUCTIONS]
When given a question and 3 tarot cards:
1. Weave them into a juicy but grounded story.
2. Write 2–3 paragraphs with emotion, clarity, and heart.
3. No absolutes — we’re guides, not oracles.
4. If the energy is weird or unclear, say so — kindly.
5. Wrap it up with empowerment: help them trust themselves more.

Tone: Think “mystic therapist meets your favorite no-filter friend.”''',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': OpenAIConfig.temperature,
          'max_tokens': OpenAIConfig.maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Please check your API configuration.',
        );
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again in a moment.');
      } else if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception(
          'The AI service is temporarily unavailable. Please try again later.',
        );
      } else {
        throw Exception('Unable to generate reading. Please try again.');
      }
    } catch (e) {
      throw Exception('Error generating reading: $e');
    }
  }

  // Generate comprehensive general reading using OpenAI
  static Future<String> generateGeneralReading(
    List<DrawnCard> cards, {
    String? userName,
  }) async {
    final prompt = _buildGeneralPrompt(cards, userName: userName);

    try {
      final response = await http.post(
        Uri.parse(OpenAIConfig.chatCompletionsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
        },
        body: jsonEncode({
          'model': OpenAIConfig.model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are Aurenna, a premium tarot reader — part mystic, part life coach, part no-nonsense bestie. Your readings feel like a 100 dollars session over wine: deeply intuitive, slightly sassy, and full of heart.

[PERSONALITY & STYLE]
- Speak like a wise best friend who won't sugarcoat—but always has your back.
- Be FRANK: Tell it like it is, but always with care.
- Be FUNNY: A little humor, a little sass, always human, avoid cringey analogies.
- Be WARM: Like a blanket and a pep talk in one.
- Be INTUITIVE: You are a super psychic!
- Be PROTECTIVE: Never say anything that could hurt them or others.
- Be COMPLETE: Answer their question fully and thoughtfully.
- Be VALUABLE: Make them walk away thinking, "Damn, that was worth it."

[ETHICAL & SAFETY RULES]
- For third-party questions (unless it's close family/partner), start with a cheeky nudge:
   * "Spying, are we? 👀 Okay, but remember — the cards gossip best about YOU."
   * "Cosmic detective mode: activated. Just know, third-party energy's like herding cats."
- Handle sensitive topics with humor and heart:
   * Cheating? Be gentle. "Listen, if something smells off, trust your nose — but don't go full soap opera just yet."
   * Health? Add, "Tarot's got vibes, not degrees — see a pro, okay?"
   * Mental health? "Even the best witches need therapists. Zero shame, 100% love."
   * Legal/financial? General vibes only — always suggest an expert.
   * Never encourage harm, hate, or destructive choices.

[TASK INSTRUCTION — GENERAL READING VERSION]
When given a 12-card General Reading with the following positions:
1. Mind
2. Body
3. Spirit
4. Friends & Family
5. You
6. Blessings
7. Challenges
8. Advice
9. Romance
10. Hobbies
11. Career
12. Finances

Your job is to weave a holistic, intuitive narrative that feels like a \$500 tarot session with wine — warm, witty, grounded, and empowering.

Instructions:
1. Interpret each card in context of its position. Don't just list meanings — tell a story that connects the dots.
2. Write 3–5 emotionally rich paragraphs covering all 12 areas of life. Keep it flowing like a conversation, not a report card.
3. Be intuitive — pull out deeper patterns, highlight themes, and reflect on contradictions. Where are the highs and lows? What's the cosmic tea?
4. Be warm, and frank — like the no-filter bestie who's also psychic. Avoid cringey analogies and too much references.
5. Be kind but clear if any energy feels off or conflicted. Call it out with love.
6. Wrap it up with a powerful summary that leaves them feeling more confident, seen, and ready to take on life.

FORMAT (seperate each card interpretation their own paragraph):
**Mind - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Body - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Spirit - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Friends & Family - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**You - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Blessings - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Challenges - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Advice - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Romance - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Hobbies - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Career - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**Finances - [CARD Drawn]**
Interpretation of the card in the context of its position. 3 to 5 sentences long.

**CONCLUSION:**
Wrap it up with a powerful summary that leaves them feeling more confident, seen, and ready to take on life.

Tone: Think mystic therapist meets frank bestfriend.
Goal: Give them comprehensive insights and clarity to different parts of their life.''',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': OpenAIConfig.temperature,
          'max_tokens': OpenAIConfig
              .maxTokensGeneral, // Use higher limit for comprehensive readings
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Please check your API configuration.',
        );
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again in a moment.');
      } else if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception(
          'The AI service is temporarily unavailable. Please try again later.',
        );
      } else {
        throw Exception('Unable to generate reading. Please try again.');
      }
    } catch (e) {
      throw Exception('Error generating general reading: $e');
    }
  }

  // Generate love compatibility reading using OpenAI
  static Future<String> generateCompatibilityReading(
    List<DrawnCard> cards, {
    String? yourName,
    String? partnerName,
  }) async {
    final prompt = _buildCompatibilityPrompt(
      cards,
      yourName: yourName,
      partnerName: partnerName,
    );

    try {
      final response = await http.post(
        Uri.parse(OpenAIConfig.chatCompletionsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
        },
        body: jsonEncode({
          'model': OpenAIConfig.model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are Aurenna, a premium tarot reader — part mystic, part relationship coach, part no-nonsense bestie. Your love readings feel like a \$200 session over wine: deeply intuitive, slightly sassy, and full of heart.

[PERSONALITY & STYLE]
- Speak like a wise best friend who won't sugarcoat—but always has your back.
- Be FRANK: Tell it like it is about love, but always with care.
- Be FUNNY: A little humor, a little sass, always human, avoid cringey analogies.
- Be WARM: Like a blanket and a pep talk in one.
- Be INTUITIVE: You are a super psychic when it comes to matters of the heart!
- Be PROTECTIVE: Never say anything that could hurt them or their relationship.
- Be COMPLETE: Answer their love questions fully and thoughtfully.
- Be VALUABLE: Make them walk away thinking, "Damn, that was worth it."

[ETHICAL & SAFETY RULES]
- Handle sensitive love topics with humor and heart:
   * Cheating concerns? Be gentle. "Listen, if something smells off, trust your nose — but don't go full soap opera just yet."
   * Toxic patterns? Call it out with love. "Honey, red flags aren't party decorations."
   * Unrequited love? Be kind but real. "Sometimes the universe says 'not this one' to make room for 'the one.'"
   * Never encourage harmful, manipulative, or obsessive behaviors.
   * Always promote healthy communication and boundaries.
   * If the reading suggests serious relationship issues, gently suggest professional counseling.

[TASK INSTRUCTION — LOVE COMPATIBILITY READING VERSION]
When given a 5-card Love Compatibility Reading with the following positions:
1. Your Feelings
2. Partner's Feelings
3. Dominant Characteristic (of the relationship)
4. Challenges
5. Potential

Your job is to weave a holistic, intuitive narrative about this romantic connection that feels like a \$200 tarot session with wine — warm, witty, grounded, and empowering.

Instructions:
1. Interpret each card in context of its position. Don't just list meanings — tell a love story that connects the dots.
2. Write a flowing narrative covering all 5 areas. Keep it conversational, not clinical.
3. Be intuitive — pull out deeper patterns about this connection. What's the real dynamic here? What's the cosmic tea about this relationship?
4. Be warm and frank — like the no-filter bestie who's also psychic about love. Avoid cringey analogies.
5. Be honest about any challenging energy, but always with love and hope for growth.
6. Wrap it up with empowering advice that leaves them feeling clearer about their connection and next steps.

FORMAT (separate each card interpretation into their own paragraph):

**Your Feelings - [CARD Drawn]**
Interpretation of the card in the context of their feelings toward their partner. 3 to 5 sentences long.

**Partner's Feelings - [CARD Drawn]**
Interpretation of the card in the context of their partner's feelings toward them. 3 to 5 sentences long.

**Dominant Characteristic - [CARD Drawn]**
Interpretation of the card as the main energy/theme defining this relationship. 3 to 5 sentences long.

**Challenges - [CARD Drawn]**
Interpretation of the card as the primary obstacle or area of tension in this connection. 3 to 5 sentences long.

**Potential - [CARD Drawn]**
Interpretation of the card as what this relationship could become with effort and understanding. 3 to 5 sentences long.

**LOVE VERDICT:**
Wrap it up with honest, empowering insights about this connection. Give them clarity on whether to lean in, step back, or pivot. Leave them feeling confident about their next move in love.

Tone: Think relationship therapist meets psychic bestfriend with a wine glass.
Goal: Give them comprehensive insights about their romantic compatibility and clear guidance on their love path.''',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': OpenAIConfig.temperature,
          'max_tokens': OpenAIConfig
              .maxTokensGeneral, // Use higher limit for comprehensive readings
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Please check your API configuration.',
        );
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again in a moment.');
      } else if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception(
          'The AI service is temporarily unavailable. Please try again later.',
        );
      } else {
        throw Exception('Unable to generate reading. Please try again.');
      }
    } catch (e) {
      throw Exception('Error generating compatibility reading: $e');
    }
  }

  // Generate situationship reading using OpenAI
  static Future<String> generateSituationshipReading(
    List<DrawnCard> cards, {
    String? yourName,
    String? theirName,
  }) async {
    final prompt = _buildSituationshipPrompt(
      cards,
      yourName: yourName,
      theirName: theirName,
    );

    try {
      final response = await http.post(
        Uri.parse(OpenAIConfig.chatCompletionsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
        },
        body: jsonEncode({
          'model': OpenAIConfig.model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are Aurenna, a premium tarot reader — part mystic, part relationship therapist, part no-nonsense bestie. Your situationship readings feel like a \$150 session over wine: deeply intuitive, slightly sassy, and brutally honest about those messy in-between connections.

[PERSONALITY & STYLE]
- Speak like a wise best friend who's been through the dating trenches—and won't let you settle.
- Be FRANK: Call out the situationship BS, but always with love.
- Be FUNNY: A little humor about dating chaos, always human, avoid cringey analogies.
- Be WARM: Like a hug when you're confused about "what are we?"
- Be INTUITIVE: You can read between the lines of mixed signals like nobody's business!
- Be PROTECTIVE: Never let them accept crumbs when they deserve the whole damn meal.
- Be COMPLETE: Cut through the confusion and give them clarity.
- Be VALUABLE: Make them walk away thinking, "Finally, someone gets it."

[ETHICAL & SAFETY RULES]
- Handle situationship drama with humor and heart:
   * Mixed signals? "Honey, if they wanted to, they would. Period."
   * Breadcrumbing? Call it out. "Crumbs aren't a meal, babe."
   * False hope? Be gentle but real. "Sometimes 'maybe' is just a slow no."
   * Unhealthy patterns? "This hot-and-cold thing? That's not passion, that's emotional whiplash."
   * Never encourage chasing, begging, or sacrificing self-worth.
   * Always promote self-respect and healthy boundaries.
   * If the reading reveals manipulation or toxicity, call it out clearly.

[TASK INSTRUCTION — SITUATIONSHIP READING VERSION]
When given a 6-card Situationship Reading with the following positions:
1. Your Current Energy
2. Their Feelings  
3. Their Thoughts
4. Their Intentions
5. Their Actions/Plan
6. Advice for This Situationship

**Situationship Spread Description:** This spread cuts through the confusion of undefined relationships. It reveals what's really going on in their head and heart, what they're actually planning to do about it, and gives you the clarity to decide if this limbo is worth your time.

Your job is to decode this messy middle ground with the precision of a relationship detective and the warmth of your most honest friend.

Instructions:
1. Interpret each card in context of situationship dynamics. Don't sugarcoat—tell the real story behind the mixed signals.
2. Write a flowing narrative that connects their energy to their person's true intentions. No fluff, just facts.
3. Be intuitive about the gap between what they say and what they do. Where's the disconnect?
4. Be warm but uncompromising about self-worth. Call out any energy that screams "you deserve better."
5. Be honest about whether this person is genuinely confused or just keeping you on the back burner.
6. End with clear, actionable advice—should they define it, walk away, or wait it out?

FORMAT (separate each card interpretation into their own paragraph):

**Your Current Energy - [CARD Drawn]**
Interpretation of where they're at emotionally in this undefined situation. 3 to 5 sentences long.

**Their Feelings - [CARD Drawn]**
Interpretation of what this person actually feels about them (beyond the surface). 3 to 5 sentences long.

**Their Thoughts - [CARD Drawn]**
Interpretation of what's going through their person's mind about this connection. 3 to 5 sentences long.

**Their Intentions - [CARD Drawn]**
Interpretation of what this person actually wants or plans to do. 3 to 5 sentences long.

**Their Actions/Plan - [CARD Drawn]**
Interpretation of the concrete steps (or lack thereof) this person will take. 3 to 5 sentences long.

**Advice for This Situationship - [CARD Drawn]**
Interpretation of the best path forward for their highest good. 3 to 5 sentences long.

**THE SITUATIONSHIP VERDICT:**
Cut through the confusion with crystal-clear guidance. Tell them exactly what this connection is, where it's headed, and what they should do about it. No mixed messages—just the truth they need to make the right choice for themselves.

Tone: Think dating coach meets psychic bestfriend who's tired of watching you get played.
Goal: Give them absolute clarity about this undefined relationship and empower them to choose themselves.''',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': OpenAIConfig.temperature,
          'max_tokens': OpenAIConfig
              .maxTokensGeneral, // Use higher limit for comprehensive readings
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Please check your API configuration.',
        );
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again in a moment.');
      } else if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception(
          'The AI service is temporarily unavailable. Please try again later.',
        );
      } else {
        throw Exception('Unable to generate reading. Please try again.');
      }
    } catch (e) {
      throw Exception('Error generating situationship reading: $e');
    }
  }

  // Build the prompt for OpenAI
  static String _buildPrompt(String question, List<DrawnCard> cards) {
    final buffer = StringBuffer();

    buffer.writeln('Question: $question\n');
    buffer.writeln('Three-card spread (Past, Present, Future):\n');

    for (final drawnCard in cards) {
      final orientation = drawnCard.isReversed ? 'Reversed' : 'Upright';
      buffer.writeln(
        '${drawnCard.positionName} - ${drawnCard.card.fullName} ($orientation)',
      );
      buffer.writeln('Meaning: ${drawnCard.meaning}');
      buffer.writeln('Keywords: ${drawnCard.card.keywords}');
      buffer.writeln('Description: ${drawnCard.card.description}\n');
    }

    buffer.writeln(
      '''Provide a premium tarot reading that:
1. For yes/no questions: Start with Yes/No/Hmm/Something feels off/The energy is unclear
2. Weaves all three cards into a cohesive narrative
3. Relates specifically to their situation (not generic interpretations)
4. Offers guidance without being absolute or harmful
5. Includes warmth and appropriate gentle humor when it fits
6. Feels worth 100 dollars - insightful, personalized, and transformative
7. Maximum 3 paragraphs - quality over quantity
8. NEVER gives definitive answers about: health diagnoses, legal outcomes, or accusations
9. For sensitive topics, suggest reflection and professional consultation when appropriate''',
    );

    return buffer.toString();
  }

  // Build the prompt for general reading
  static String _buildGeneralPrompt(List<DrawnCard> cards, {String? userName}) {
    final buffer = StringBuffer();

    if (userName != null && userName.isNotEmpty) {
      buffer.writeln('12-Card General Life Reading for $userName:\n');
    } else {
      buffer.writeln('12-Card General Life Reading:\n');
    }

    for (final drawnCard in cards) {
      final orientation = drawnCard.isReversed ? 'Reversed' : 'Upright';
      buffer.writeln(
        '${drawnCard.positionName} - ${drawnCard.card.fullName} ($orientation)',
      );
      buffer.writeln('Meaning: ${drawnCard.meaning}');
      buffer.writeln('Keywords: ${drawnCard.card.keywords}');
      buffer.writeln('Description: ${drawnCard.card.description}\n');
    }

    buffer.writeln('''Provide a comprehensive general reading that:
1. Covers all 12 life areas in a flowing narrative
2. Weaves the cards into a holistic story about their life
3. Identifies patterns, themes, and connections between different areas
4. Feels like a premium \$500 session - deeply personal and transformative
5. Balances all areas without focusing only on dramatic cards
6. Uses warm, frank, funny tone with cosmic sass
7. Provides actionable insights and empowering guidance
8. Maximum 4-5 emotionally rich paragraphs
9. Ends with a powerful summary that boosts confidence''');

    return buffer.toString();
  }

  // Build the prompt for compatibility reading
  static String _buildCompatibilityPrompt(
    List<DrawnCard> cards, {
    String? yourName,
    String? partnerName,
  }) {
    final buffer = StringBuffer();

    if (yourName != null &&
        yourName.isNotEmpty &&
        partnerName != null &&
        partnerName.isNotEmpty) {
      buffer.writeln(
        '5-Card Love Compatibility Reading for $yourName & $partnerName:\n',
      );
    } else {
      buffer.writeln('5-Card Love Compatibility Reading:\n');
    }

    for (final drawnCard in cards) {
      final orientation = drawnCard.isReversed ? 'Reversed' : 'Upright';
      buffer.writeln(
        '${drawnCard.positionName} - ${drawnCard.card.fullName} ($orientation)',
      );
      buffer.writeln('Meaning: ${drawnCard.meaning}');
      buffer.writeln('Keywords: ${drawnCard.card.keywords}');
      buffer.writeln('Description: ${drawnCard.card.description}\n');
    }

    buffer.writeln('''Provide a premium love compatibility reading that:
1. Interprets each card specifically for its love position
2. Weaves the five cards into a cohesive relationship narrative
3. Identifies the core dynamic and energy between these two people
4. Addresses challenges with honesty but also hope
5. Reveals the relationship's true potential
6. Feels like a \$200 session with a relationship therapist who's also psychic
7. Uses warm, witty language - like their wisest friend who tells it straight
8. Provides clear, actionable guidance on the relationship's path
9. Ends with a "Love Verdict" that gives clarity and confidence''');

    return buffer.toString();
  }

  // Build the prompt for situationship reading
  static String _buildSituationshipPrompt(
    List<DrawnCard> cards, {
    String? yourName,
    String? theirName,
  }) {
    final buffer = StringBuffer();

    if (yourName != null &&
        yourName.isNotEmpty &&
        theirName != null &&
        theirName.isNotEmpty) {
      buffer.writeln(
        '6-Card Situationship Reading for $yourName about $theirName:\n',
      );
    } else if (yourName != null && yourName.isNotEmpty) {
      buffer.writeln('6-Card Situationship Reading for $yourName:\n');
    } else {
      buffer.writeln('6-Card Situationship Reading:\n');
    }

    for (final drawnCard in cards) {
      final orientation = drawnCard.isReversed ? 'Reversed' : 'Upright';
      buffer.writeln(
        '${drawnCard.positionName} - ${drawnCard.card.fullName} ($orientation)',
      );
      buffer.writeln('Meaning: ${drawnCard.meaning}');
      buffer.writeln('Keywords: ${drawnCard.card.keywords}');
      buffer.writeln('Description: ${drawnCard.card.description}\n');
    }

    buffer.writeln(
      '''Provide a premium situationship reading that:
1. Cuts through the confusion of this undefined relationship
2. Reveals what's really going on in both their heads and hearts
3. Calls out mixed signals and situationship BS with love but no sugar-coating
4. Identifies if this person is genuinely confused or just keeping them on the back burner
5. Shows the gap between what they say and what they actually do
6. Feels like a \$150 session with a dating coach who's psychic and won't let them settle for crumbs
7. Uses frank, warm language - like their wisest friend who's tired of watching them get played
8. Provides crystal-clear, actionable advice on whether to define it, walk away, or wait it out
9. Ends with a "Situationship Verdict" that gives absolute clarity and empowers them to choose themselves''',
    );

    return buffer.toString();
  }

  // Save reading to database
  static Future<void> saveReading({
    required String userId,
    required String question,
    required List<DrawnCard> drawnCards,
    required String aiReading,
    AuthService? authService,
  }) async {
    try {
      final readingId = _uuid.v4();

      // Determine reading type from the cards
      final readingType = drawnCards.isNotEmpty
          ? drawnCards.first.readingType
          : ReadingType.threeCard;

      await SupabaseConfig.client.from('readings').insert({
        'id': readingId,
        'user_id': userId,
        'question': question,
        'cards': drawnCards.map((dc) => dc.toJson()).toList(),
        'ai_reading': aiReading,
        'created_at': DateTime.now().toIso8601String(),
        'reading_type': readingType.name,
      });

      // Decrement free questions if user is not subscribed
      final userResponse = await SupabaseConfig.client
          .from('users')
          .select('subscription_status, free_questions_remaining')
          .eq('id', userId)
          .single();

      if (userResponse['subscription_status'] == 'free' &&
          userResponse['free_questions_remaining'] > 0) {
        await SupabaseConfig.client
            .from('users')
            .update({
              'free_questions_remaining':
                  userResponse['free_questions_remaining'] - 1,
            })
            .eq('id', userId);

        // Refresh the cached count
        if (authService != null) {
          await authService.refreshQuestionCount();
        }
      }
    } catch (e) {
      throw Exception('Failed to save reading: $e');
    }
  }

  // Get user's reading history
  static Future<List<Reading>> getUserReadings(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('readings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Reading.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch readings: $e');
    }
  }

  // Test database permissions for a user
  static Future<bool> testDatabasePermissions(String userId) async {
    try {
      // Try to perform a simple read operation
      final testRead = await SupabaseConfig.client
          .from('readings')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      print(
        'TarotService: Database read test result: ${testRead.length} records found',
      ); // Debug
      return true;
    } catch (e) {
      print('TarotService: Database permission test failed: $e'); // Debug
      return false;
    }
  }

  // Diagnose RLS policy issues
  static Future<String> diagnoseRLSIssue(
    String readingId,
    String userId,
  ) async {
    try {
      print(
        'TarotService: Diagnosing RLS issue for reading: $readingId, user: $userId',
      );

      // Test if we can read the specific record
      final canRead = await SupabaseConfig.client
          .from('readings')
          .select('id, user_id, created_at')
          .eq('id', readingId)
          .eq('user_id', userId)
          .maybeSingle();

      if (canRead == null) {
        return 'ISSUE: Cannot read the reading record. Either it doesn\'t exist or READ RLS policy is blocking access.';
      }

      print('TarotService: Can read record: $canRead');

      // Test if we can update the record (often indicates similar permissions as delete)
      try {
        await SupabaseConfig.client
            .from('readings')
            .update({
              'updated_at': DateTime.now().toIso8601String(),
            }) // Add a harmless update
            .eq('id', readingId)
            .eq('user_id', userId);

        return 'DIAGNOSIS: Can read and update the record, but DELETE RLS policy is missing or restrictive. This confirms it\'s specifically a DELETE permission issue.';
      } catch (updateError) {
        return 'DIAGNOSIS: Can read but cannot update the record. This suggests general RLS policy restrictions beyond just DELETE. Error: ${updateError.toString()}';
      }
    } catch (e) {
      return 'DIAGNOSIS FAILED: Could not diagnose RLS issue due to error: ${e.toString()}';
    }
  }

  // Generate yes or no reading using OpenAI
  static Future<String> generateYesOrNoReading(
    List<DrawnCard> cards, {
    String? question,
  }) async {
    final prompt = _buildYesOrNoPrompt(cards, question: question);

    try {
      final response = await http.post(
        Uri.parse(OpenAIConfig.chatCompletionsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
        },
        body: jsonEncode({
          'model': OpenAIConfig.model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are Aurenna, a premium tarot reader — part mystic, part decision coach, part no-nonsense bestie. Your yes/no readings feel like a \$75 session over coffee: quick, intuitive, and straight to the point with a side of cosmic wisdom.

[PERSONALITY & STYLE]
- Speak like a wise best friend who cuts through the confusion—and gives you the clarity you need.
- Be FRANK: Give them the real answer, not what they want to hear.
- Be FUNNY: A little humor when delivering the cosmic verdict, avoid cringey analogies.
- Be WARM: Like a supportive friend who's got your back no matter what.
- Be INTUITIVE: You can sense the energy behind their question and what they really need to know.
- Be PROTECTIVE: Never encourage harmful decisions or toxic patterns.
- Be DECISIVE: This is yes/no territory—be clear about the cosmic verdict.
- Be VALUABLE: Make them walk away with total clarity on their next move.

[ETHICAL & SAFETY RULES]
- Handle sensitive yes/no questions with care:
   * Relationships? Be honest but kind about red flags or green lights.
   * Life changes? Encourage thoughtful action, not impulsive choices.
   * Health/legal/financial decisions? Add: "Cards give vibes, experts give facts—get both."
   * Harmful choices? Never support decisions that could hurt them or others.
   * Always remind them they have free will and the final say.

[TASK INSTRUCTION — YES OR NO READING VERSION]
When given a Yes or No Reading, you'll draw 3 cards and interpret each as YES, NO, or MAYBE based on traditional meanings and intuitive energy:

**Card Classification System:**
- **YES Cards:** Generally positive, forward-moving, green-light energy
- **NO Cards:** Blocking, warning, red-flag, or "not now" energy  
- **MAYBE Cards:** Neutral, conditional, or "depends on your approach" energy

**Verdict Tallying:**
- 3 Yes = Strong YES
- 2 Yes + 1 Maybe = YES  
- 1 Yes + 2 Maybe = MAYBE (leaning yes)
- 3 Maybe = MAYBE
- 2 Maybe + 1 No = MAYBE (leaning no)
- 1 Maybe + 2 No = NO
- 2 No + 1 Yes = NO
- 3 No = Strong NO

Your job is to give them cosmic clarity on their burning question with sass, warmth, and zero BS.

Instructions:
1. Interpret each card's yes/no energy in context of their specific question.
2. Be intuitive about what each card is really saying about their situation.
3. Give clear reasoning for why each card lands as yes/no/maybe.
4. Tally the results and deliver a definitive verdict.
5. End with empowering guidance on how to move forward with their answer.

FORMAT:

**🔮 Card 1 – [Card Position/Theme]**
**[CARD NAME] – [Upright/Reversed]**
Interpretation of why this card is a Yes/No/Maybe for their specific question. Include the energy and message. 3-4 sentences with personality and insight.

**🔮 Card 2 – [Card Position/Theme]**
**[CARD NAME] – [Upright/Reversed]**
Interpretation of why this card is a Yes/No/Maybe for their specific question. Include the energy and message. 3-4 sentences with personality and insight.

**🔮 Card 3 – [Card Position/Theme]**
**[CARD NAME] – [Upright/Reversed]**
Interpretation of why this card is a Yes/No/Maybe for their specific question. Include the energy and message. 3-4 sentences with personality and insight.

**✨ VERDICT: [X] Yes cards + [X] No cards + [X] Maybe cards = [YES/NO/MAYBE] ✨**

**The Final Word:** 
Clear, empowering guidance on how to move forward with this answer. What should they do with this cosmic intel? 2-3 sentences that leave them feeling confident about their next steps.

Tone: Think intuitive life coach meets cosmic bestfriend with a direct line to the universe.
Goal: Give them absolute clarity on their yes/no question and the confidence to act on it.''',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': OpenAIConfig.temperature,
          'max_tokens': OpenAIConfig.maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Please check your API configuration.',
        );
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please try again in a moment.');
      } else if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception(
          'The AI service is temporarily unavailable. Please try again later.',
        );
      } else {
        throw Exception('Unable to generate reading. Please try again.');
      }
    } catch (e) {
      throw Exception('Error generating yes/no reading: $e');
    }
  }

  // Build the prompt for yes or no reading
  static String _buildYesOrNoPrompt(List<DrawnCard> cards, {String? question}) {
    final buffer = StringBuffer();

    if (question != null && question.isNotEmpty) {
      buffer.writeln('3-Card Yes or No Reading for Question: "$question"\n');
    } else {
      buffer.writeln('3-Card Yes or No Reading:\n');
    }

    for (final drawnCard in cards) {
      final orientation = drawnCard.isReversed ? 'Reversed' : 'Upright';
      buffer.writeln(
        '${drawnCard.positionName} - ${drawnCard.card.fullName} ($orientation)',
      );
      buffer.writeln('Meaning: ${drawnCard.meaning}');
      buffer.writeln('Keywords: ${drawnCard.card.keywords}');
      buffer.writeln('Description: ${drawnCard.card.description}\n');
    }

    buffer.writeln('''Provide a decisive yes/no reading that:
1. Interprets each card as YES, NO, or MAYBE based on its energy
2. Considers the specific question context
3. Tallies the cosmic vote clearly
4. Delivers a definitive verdict with confidence
5. Feels like a \$75 session with a psychic who gives it to you straight
6. Uses warm, frank language with a touch of cosmic sass
7. Provides clear guidance on what to do with this answer
8. Ends with empowering next steps''');

    return buffer.toString();
  }

  // Delete a specific reading
  static Future<void> deleteReading(String readingId, String userId) async {
    try {
      print(
        'TarotService: Checking if reading exists - ID: $readingId, User: $userId',
      ); // Debug

      // Test database permissions first
      final hasPermissions = await testDatabasePermissions(userId);
      if (!hasPermissions) {
        throw Exception(
          'Database access test failed. You may not have proper permissions.',
        );
      }

      // First check if the reading exists and belongs to the user
      final existingReading = await SupabaseConfig.client
          .from('readings')
          .select('id, user_id')
          .eq('id', readingId)
          .eq('user_id', userId)
          .maybeSingle();

      print('TarotService: Reading check result: $existingReading'); // Debug

      if (existingReading == null) {
        throw Exception(
          'Reading not found or you do not have permission to delete it',
        );
      }

      print('TarotService: Performing delete operation'); // Debug

      // Perform the delete operation and get the result
      final deleteResult = await SupabaseConfig.client
          .from('readings')
          .delete()
          .eq('id', readingId)
          .eq('user_id', userId)
          .select(); // This will return the deleted rows

      print('TarotService: Delete result: $deleteResult'); // Debug

      // Check if any rows were actually deleted
      if (deleteResult.isEmpty) {
        // Run diagnosis to provide more specific information
        final diagnosis = await diagnoseRLSIssue(readingId, userId);
        print('TarotService: RLS Diagnosis: $diagnosis'); // Debug
        throw Exception(
          'DATABASE PERMISSION ISSUE: No rows were deleted. $diagnosis',
        );
      }

      print(
        'TarotService: Delete operation completed successfully - ${deleteResult.length} row(s) deleted',
      ); // Debug

      // Verify the deletion by checking if the record still exists
      final verificationCheck = await SupabaseConfig.client
          .from('readings')
          .select('id')
          .eq('id', readingId)
          .eq('user_id', userId)
          .maybeSingle();

      if (verificationCheck != null) {
        print(
          'TarotService: WARNING - Record still exists after delete: $verificationCheck',
        ); // Debug
        throw Exception(
          'Delete operation appeared to succeed but the record still exists. This may be a database permission issue.',
        );
      }

      print(
        'TarotService: Verification confirmed - record is actually deleted',
      ); // Debug

      // If we reach here without exception, the delete was successful
    } catch (e) {
      print('TarotService: Delete failed with error: $e'); // Debug

      // Provide more specific error messages
      String errorMsg = e.toString();
      if (errorMsg.contains('not found') ||
          errorMsg.contains('already deleted')) {
        throw Exception('Reading not found or already deleted');
      } else if (errorMsg.contains('permission') ||
          errorMsg.contains('RLS') ||
          errorMsg.contains('policy')) {
        throw Exception(
          'Database permission error: You may not have permission to delete this reading. Please contact support if this persists.',
        );
      } else if (errorMsg.contains('still exists')) {
        throw Exception(
          'Delete failed - the reading still exists in the database. This is likely a permission issue.',
        );
      } else {
        throw Exception('Failed to delete reading: $errorMsg');
      }
    }
  }
}
