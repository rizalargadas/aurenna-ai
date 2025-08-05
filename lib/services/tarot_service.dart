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
4. Be warm, frank, and funny — like the no-filter bestie who's also psychic.
5. Be kind but clear if any energy feels off or conflicted. Call it out with love.
6. Wrap it up with a powerful summary that leaves them feeling more confident, seen, and ready to take on life.

FORMAT:
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
      throw Exception('Error generating general reading: $e');
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
