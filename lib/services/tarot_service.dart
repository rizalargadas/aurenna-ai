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
- Be FUNNY: A little humor, a little sass, always human, add some Gen-Z slangs when applicable.
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

      await SupabaseConfig.client.from('readings').insert({
        'id': readingId,
        'user_id': userId,
        'question': question,
        'cards': drawnCards.map((dc) => dc.toJson()).toList(),
        'ai_reading': aiReading,
        'created_at': DateTime.now().toIso8601String(),
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

  // Delete a specific reading
  static Future<void> deleteReading(String readingId, String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('readings')
          .delete()
          .eq('id', readingId)
          .eq('user_id', userId); // Ensure user can only delete their own readings

      if (response == null) {
        throw Exception('Failed to delete reading');
      }
    } catch (e) {
      throw Exception('Failed to delete reading: $e');
    }
  }
}
