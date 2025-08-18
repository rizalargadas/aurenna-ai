import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../services/tarot_service.dart';
import '../../services/auth_service.dart';
import '../../services/error_handler.dart';
import '../../models/reading.dart';
import 'reading_result_screen.dart';
import '../../widgets/html_reading_widget.dart';
import '../../utils/share_reading.dart';

class CardOfTheDayScreen extends StatefulWidget {
  const CardOfTheDayScreen({super.key});

  @override
  State<CardOfTheDayScreen> createState() => _CardOfTheDayScreenState();
}

class _CardOfTheDayScreenState extends State<CardOfTheDayScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _glowController;
  late Animation<double> _cardAnimation;
  late Animation<double> _glowAnimation;

  bool _isLoading = false;
  bool _hasDrawnToday = false;
  DrawnCard? _todayCard;
  String? _todayReading;
  DateTime? _nextAvailableTime;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _checkDailyCardStatus();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _glowController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_hasDrawnToday && _nextAvailableTime != null) {
        setState(() {
          // This will trigger a rebuild and update the countdown
        });
        
        // Check if it's past midnight and they can draw again
        if (DateTime.now().isAfter(_nextAvailableTime!)) {
          _checkDailyCardStatus();
        }
      }
    });
  }

  Future<void> _checkDailyCardStatus() async {
    final tarotService = TarotService();
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final result = await tarotService.checkDailyCardStatus(authService.currentUser!.id);
      setState(() {
        _hasDrawnToday = result['hasDrawn'] as bool;
        if (_hasDrawnToday && result['card'] != null) {
          _todayCard = result['card'] as DrawnCard;
          _todayReading = result['interpretation'] as String?;
          _cardController.forward();
          
          // Calculate next available time (midnight)
          final now = DateTime.now();
          _nextAvailableTime = DateTime(now.year, now.month, now.day + 1);
        }
      });
    } catch (e) {
      debugPrint('Error checking daily card status: $e');
    }
  }

  String _getTimeUntilNextCard() {
    if (_nextAvailableTime == null) return '';
    
    final now = DateTime.now();
    final difference = _nextAvailableTime!.difference(now);
    
    if (difference.isNegative) {
      // Time has passed, they can draw again
      _checkDailyCardStatus();
      return '';
    }
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} and $minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  void _showCardReadingModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CardOfTheDayReadingScreen(
          card: _todayCard!,
          reading: _todayReading ?? 'Your daily card reading',
        ),
      ),
    );
  }

  // Debug function to reset daily card (remove in production)
  Future<void> _resetDailyCard() async {
    final prefs = await SharedPreferences.getInstance();
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser!.id;
    
    // Clear all daily card data
    await prefs.remove('daily_card_last_draw_$userId');
    await prefs.remove('daily_card_data_$userId');
    await prefs.remove('daily_card_interpretation_$userId');
    
    setState(() {
      _hasDrawnToday = false;
      _todayCard = null;
      _todayReading = null;
      _nextAvailableTime = null;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily card reset! You can draw again.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _drawDailyCard() async {
    if (_hasDrawnToday) {
      // Show sassy alert dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AurennaTheme.voidBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AurennaTheme.electricViolet.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: AurennaTheme.electricViolet,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⏰ Hold Up, Speed Racer!',
                    style: TextStyle(
                      color: AurennaTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'It\'s called Card of the DAY, not Card of the Hour, bestie! 💅',
                  style: TextStyle(
                    color: AurennaTheme.textPrimary,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The universe doesn\'t do instant replays. One cosmic download per 24 hours, that\'s the rules!',
                  style: TextStyle(
                    color: AurennaTheme.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AurennaTheme.cosmicPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AurennaTheme.cosmicPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: AurennaTheme.cosmicPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Come back in:',
                              style: TextStyle(
                                color: AurennaTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _getTimeUntilNextCard(),
                              style: TextStyle(
                                color: AurennaTheme.electricViolet,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AurennaTheme.electricViolet,
                        AurennaTheme.cosmicPurple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Fine, I\'ll Wait 🙄',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final tarotService = TarotService();
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Draw the card and get reading
      final result = await tarotService.getDailyCardReading(authService.currentUser!.id);
      
      if (result != null && mounted) {
        // Extract the interpretation and card from the result
        final interpretation = result['interpretation'] as String;
        final drawnCard = result['card'] as DrawnCard;
        
        // Navigate to result screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReadingResultScreen(
              question: 'Card of the Day',
              drawnCards: [drawnCard],
              reading: interpretation,
              isFromHistory: false,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Card of the Day Error: $e');
      if (mounted) {
        // Show user-friendly error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AurennaTheme.voidBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AurennaTheme.cosmicPurple.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            title: Text(
              ErrorHandler.getErrorTitle(e),
              style: TextStyle(
                color: AurennaTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Text(
                ErrorHandler.getUserFriendlyMessage(e),
                style: TextStyle(
                  color: AurennaTheme.textPrimary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Got It',
                  style: TextStyle(color: AurennaTheme.textSecondary),
                ),
              ),
              if (!ErrorHandler.isNetworkError(e)) // Only show retry for non-network errors
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _drawDailyCard();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AurennaTheme.cosmicPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _resetDailyCard, // Long press to reset for testing
          child: const Text('Card of the Day'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header text
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '🌅 Your Daily Cosmic Check-In',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AurennaTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _hasDrawnToday 
                    ? 'Here\'s your card for today. The universe has spoken.'
                    : 'Pull your daily card to see what the cosmos wants you to know today.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AurennaTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Show time until next card if already drawn
              if (_hasDrawnToday && _nextAvailableTime != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: IntrinsicWidth(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AurennaTheme.cosmicPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AurennaTheme.cosmicPurple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AurennaTheme.cosmicPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Next card in ${_getTimeUntilNextCard()}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AurennaTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Main card area
              Container(
                height: 350,
                alignment: Alignment.center,
                child: _hasDrawnToday && _todayCard != null
                    ? _buildTodayCard()
                    : _buildDrawCardArea(),
              ),

              // Bottom text
              if (!_hasDrawnToday) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AurennaTheme.electricViolet.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AurennaTheme.electricViolet,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can draw one card per day. Come back tomorrow for fresh cosmic guidance!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AurennaTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 200.0 : screenWidth * 0.5;
    final cardHeight = cardWidth * 1.5;
    
    return ScaleTransition(
      scale: _cardAnimation,
      child: GestureDetector(
        onTap: () {
          // Navigate to a simple reading display
          _showCardReadingModal();
        },
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              _todayCard!.card.imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawCardArea() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 200.0 : screenWidth * 0.5;
    final cardHeight = cardWidth * 1.5;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _isLoading ? null : _drawDailyCard,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AurennaTheme.electricViolet.withValues(alpha: _glowAnimation.value * 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Card cover image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/img/cards/cover.png',
                    width: cardWidth,
                    height: cardHeight,
                    fit: BoxFit.cover,
                  ),
                ),
                
                // Animated overlay with glow effect
                Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AurennaTheme.electricViolet.withValues(alpha: _glowAnimation.value * 0.2),
                        AurennaTheme.cosmicPurple.withValues(alpha: _glowAnimation.value * 0.15),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: AurennaTheme.electricViolet.withValues(alpha: _glowAnimation.value),
                      width: 2,
                    ),
                  ),
                ),
                
                // Loading indicator or call to action
                if (_isLoading)
                  Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AurennaTheme.electricViolet,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Drawing your card...',
                            style: TextStyle(
                              color: AurennaTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 40,
                          color: AurennaTheme.electricViolet.withValues(alpha: _glowAnimation.value),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to Draw',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AurennaTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardOfTheDayReadingScreen extends StatelessWidget {
  final DrawnCard card;
  final String reading;

  const _CardOfTheDayReadingScreen({
    required this.card,
    required this.reading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      appBar: AppBar(
        title: const Text('Card of the Day'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                await ShareReading.shareReadingResult(
                  question: 'Card of the Day',
                  drawnCards: [card],
                  reading: reading,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: AurennaTheme.crystalBlue,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AurennaTheme.electricViolet.withValues(alpha: 0.3),
                      AurennaTheme.cosmicPurple.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AurennaTheme.electricViolet.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      color: AurennaTheme.electricViolet,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Daily Guidance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AurennaTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Card display
                    Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          card.card.imagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      card.card.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AurennaTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (card.isReversed) ...[
                      const SizedBox(height: 4),
                      Text(
                        '(Reversed)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AurennaTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Reading container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AurennaTheme.mysticBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AurennaTheme.silverMist.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AurennaTheme.silverMist.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HtmlReadingWidget(
                      content: reading,
                      fallbackTextColor: 'silvermist',
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AurennaTheme.silverMist.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(
                      'Trust your intuition and let the wisdom guide your day.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AurennaTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Back to Home'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/reading-history');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('View Reading History'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  '✨ Trust the process, trust yourself ✨',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AurennaTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}