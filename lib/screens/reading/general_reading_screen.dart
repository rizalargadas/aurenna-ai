import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/reading.dart';
import '../../models/tarot_card.dart';
import '../../services/auth_service.dart';
import '../../services/tarot_service.dart';
import '../../utils/reading_messages.dart';
import '../../utils/share_reading.dart';
import '../../widgets/mystical_loading.dart';
import '../../widgets/reading_animation_v1.dart';
import '../../widgets/html_reading_widget.dart';

class GeneralReadingScreen extends StatefulWidget {
  const GeneralReadingScreen({super.key});

  @override
  State<GeneralReadingScreen> createState() => _GeneralReadingScreenState();
}

class _GeneralReadingScreenState extends State<GeneralReadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _shuffleController;
  late AnimationController _revealController;
  late AnimationController _cardRevealController;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  bool _disposed = false;

  // Shuffling animation data
  final int cardCount = 78;
  late List<CardAnimationData> _cards;
  List<int> _selectedCardIndices = [];
  bool _isShuffling = true;
  bool _cardsSelected = false;
  int _currentRevealIndex = 0;

  List<DrawnCard> _drawnCards = [];
  String _aiReading = '';
  bool _isGenerating = false;
  bool _isComplete = false;
  String _errorMessage = '';
  int _currentStep = 0; // 0: shuffling, 1: cards revealed, 2: generating reading
  bool _shuffleStarted = false;
  
  // User input
  bool _showNameInput = true;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _userName = '';
  
  // Generation message selected once per session
  String _generationMessage = '';

  @override
  void initState() {
    super.initState();
    
    // Don't start animations yet - wait for user input
    _showNameInput = true;
    
    // Select generation message once for this session
    _generationMessage = ReadingMessages.getRandomGenerationMessage();
    
    // Floating animation controller
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Glow animation controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Shuffling animation controllers
    _shuffleController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );
    
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _cardRevealController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start continuous animations
    if (!_disposed) {
      _floatController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
    
    _initializeCards();
    // Don't start reading automatically - wait for user input
  }

  @override
  void dispose() {
    _disposed = true;
    
    // Stop all repeating animations first
    _floatController.stop();
    _glowController.stop();
    
    // Reset all controllers to ensure they're in a clean state
    _floatController.reset();
    _glowController.reset();
    _shuffleController.reset();
    _revealController.reset();
    _cardRevealController.reset();
    
    // Dispose all controllers
    _floatController.dispose();
    _glowController.dispose();
    _shuffleController.dispose();
    _revealController.dispose();
    _cardRevealController.dispose();
    _nameController.dispose();
    
    super.dispose();
  }

  void _initializeCards() {
    final random = math.Random();
    _cards = List.generate(cardCount, (index) {
      // Generate random starting positions from all screen edges
      final edge = random.nextInt(4); // 0: top, 1: right, 2: bottom, 3: left
      late Offset startPos;

      switch (edge) {
        case 0: // Top
          startPos = Offset(random.nextDouble(), -0.2);
          break;
        case 1: // Right
          startPos = Offset(1.2, random.nextDouble());
          break;
        case 2: // Bottom
          startPos = Offset(random.nextDouble(), 1.2);
          break;
        case 3: // Left
          startPos = Offset(-0.2, random.nextDouble());
          break;
      }

      // Random target positions in different directions
      final targetEdge = (edge + 2) % 4; // Opposite side
      late Offset endPos;

      switch (targetEdge) {
        case 0: // Top
          endPos = Offset(random.nextDouble(), -0.2);
          break;
        case 1: // Right
          endPos = Offset(1.2, random.nextDouble());
          break;
        case 2: // Bottom
          endPos = Offset(random.nextDouble(), 1.2);
          break;
        case 3: // Left
          endPos = Offset(-0.2, random.nextDouble());
          break;
      }

      return CardAnimationData(
        id: index,
        startPosition: startPos,
        endPosition: endPos,
        rotation: random.nextDouble() * math.pi * 4,
        delay: random.nextDouble() * 0.5,
        speed: 0.5 + random.nextDouble() * 0.5,
      );
    });

    // Select random cards for the final reveal (12 cards for general reading)
    final indices = List.generate(cardCount, (i) => i);
    indices.shuffle();
    _selectedCardIndices = indices.take(12).toList();
  }

  void _onShuffleComplete() {
    // Draw the 12 cards when shuffle completes
    _drawnCards = TarotService.drawTwelveCards();
    setState(() {});
  }

  void _onCardsRevealed() async {
    if (!mounted || _disposed) return;
    // Don't set step 1 here - it's already set in _revealCards
    
    // Move directly to generation phase
    setState(() => _currentStep = 2);

    try {
      // Generate AI reading with user's name
      _aiReading = await TarotService.generateGeneralReading(_drawnCards, userName: _userName);

      // Save reading to database
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId != null) {
        await TarotService.saveReading(
          userId: userId,
          question: 'Comprehensive General Reading for $_userName',
          drawnCards: _drawnCards,
          aiReading: _aiReading,
          authService: authService,
        );
      }

      // Stop animations before showing completed reading
      _floatController.stop();
      _glowController.stop();
      
      // Small delay to ensure animations are fully stopped
      await Future.delayed(const Duration(milliseconds: 100));

      setState(() {
        _isGenerating = false;
        _isComplete = true;
        _currentStep = 3; // Move to completed state
      });

    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Failed to generate reading: ${e.toString()}';
      });
    }
  }

  Future<void> _startGeneralReading() async {
    // Validate and save name first
    if (_showNameInput) {
      if (!_formKey.currentState!.validate()) return;
      
      setState(() {
        _userName = _nameController.text.trim();
        _showNameInput = false;
      });
      
      // Small delay for transition
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (!mounted || _disposed) return;
    setState(() {
      _isShuffling = true;
      _shuffleStarted = true;
      _errorMessage = '';
      _currentStep = 0;
    });
    _startShuffleAnimation();
  }

  Future<void> _startShuffleAnimation() async {
    // Start shuffling animation
    _shuffleController.repeat();

    // Wait for shuffle duration
    await Future.delayed(
      const Duration(milliseconds: 5000),
    ); // Match controller duration

    // Stop shuffling and move selected cards to center
    if (mounted) {
      setState(() {
        _isShuffling = false;
        _cardsSelected = true;
      });

      _onShuffleComplete();

      _shuffleController.stop();
      _revealController.forward();

      // Wait for cards to move to center
      await Future.delayed(
        const Duration(milliseconds: 1000),
      ); // Match controller duration

      // Start revealing cards one by one
      _revealCards();
    }
  }

  Future<void> _revealCards() async {
    for (int i = 0; i < 12; i++) {
      if (!mounted) return;

      setState(() {
        _currentRevealIndex = i;
      });

      _cardRevealController.forward(from: 0);
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Much faster reveal interval
    }

    // Show "Your cards have been revealed" immediately
    if (mounted) {
      setState(() => _currentStep = 1);
    }
    
    // Wait 3 seconds before moving to generation
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      _onCardsRevealed();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Comprehensive General Reading'),
        actions: [
          if (_isComplete)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                try {
                  await ShareReading.shareGeneralReading(
                    question: 'Comprehensive General Reading for $_userName',
                    drawnCards: _drawnCards,
                    reading: _aiReading,
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    
    if (_showNameInput) {
      return _buildNameInputScreen();
    }

    // For completed state, show reading directly without Stack constraints
    if (_currentStep == 3 || _isComplete) {
      return _buildCompleteReading();
    }
    
    // Use the reusable animation widget
    ReadingAnimationPhase phase;
    String? statusMessage;
    
    switch (_currentStep) {
      case 0:
        phase = ReadingAnimationPhase.shuffling;
        break;
      case 1:
        phase = ReadingAnimationPhase.revealing;
        statusMessage = ReadingMessages.getRandomCardRevealMessage();
        break;
      case 2:
        phase = ReadingAnimationPhase.generating;
        // No status message during generating phase - radial effect only
        statusMessage = null;
        break;
      default:
        phase = ReadingAnimationPhase.complete;
        break;
    }
    
    return ComprehensiveReadingAnimation(
      cardCount: 78,
      drawnCards: _drawnCards,
      phase: phase,
      statusMessage: statusMessage,
      generationMessage: _generationMessage,
      onShuffleComplete: _onShuffleComplete,
      onCardsRevealed: _onCardsRevealed,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AurennaTheme.electricViolet.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AurennaTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AurennaTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = '';
                });
                _startGeneralReading();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCompleteReading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AurennaTheme.crystalBlue.withValues(alpha: 0.3),
                  AurennaTheme.electricViolet.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AurennaTheme.electricViolet.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AurennaTheme.electricViolet,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Comprehensive General Reading',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AurennaTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Your Life Spread',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          _buildCardGrid(),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.auto_awesome,
                  color: AurennaTheme.electricViolet,
                  size: 20,
                ),
              ),
              Expanded(
                child: Divider(
                  color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'Your Cosmic Narrative',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Reading container without height constraints
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
              mainAxisSize: MainAxisSize.min, // Let column size to content
              children: [
                // Reading content - no constraints
                _buildFormattedReading(),
                const SizedBox(height: 16),
                Divider(color: AurennaTheme.silverMist.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  'This reading reflects the current energies in your life. Trust your intuition as you move forward.',
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
              '✨ May the universe guide your journey ✨',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AurennaTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card size based on screen width
        final crossAxisCount = 4; // Always 4 columns for 12 cards (3 rows x 4 cols)
        final horizontalSpacing = 8.0;
        final verticalSpacing = 4.0; // Reduced vertical spacing
        final cardWidth = (constraints.maxWidth - (crossAxisCount + 1) * horizontalSpacing) / crossAxisCount;
        final maxCardWidth = 85.0; // Bigger cards
        final finalCardWidth = cardWidth < maxCardWidth ? cardWidth : maxCardWidth;
        
        // Calculate proper aspect ratio to prevent overflow
        final cardHeight = finalCardWidth * 1.4;
        final totalItemHeight = cardHeight + 50; // Optimized for labels
        
        final aspectRatio = finalCardWidth / totalItemHeight;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: horizontalSpacing,
            mainAxisSpacing: verticalSpacing, // Minimal vertical spacing
            childAspectRatio: aspectRatio,
          ),
          itemCount: _drawnCards.length,
          itemBuilder: (context, index) {
            return _buildGeneralCard(_drawnCards[index], finalCardWidth);
          },
        );
      },
    );
  }

  Widget _buildGeneralCard(DrawnCard drawnCard, double cardWidth) {
    final borderColor = drawnCard.isReversed
        ? AurennaTheme.electricViolet
        : AurennaTheme.crystalBlue;
    final cardHeight = cardWidth * 1.4;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Position name
        Container(
          width: cardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: AurennaTheme.crystalBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            drawnCard.positionName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.crystalBlue,
              fontWeight: FontWeight.w600,
              fontSize: 9, // Bigger font size
              height: 1.0, // Even tighter line height
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 4),

        // Card container with exact dimensions
        Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Card image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Transform.rotate(
                  angle: drawnCard.isReversed ? 3.14159 : 0,
                  child: Image.asset(
                    drawnCard.card.imagePath,
                    width: cardWidth,
                    height: cardHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: AurennaTheme.mysticBlue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.all(4.0),
                        child: Center(
                          child: Text(
                            drawnCard.card.name,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AurennaTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Reversed indicator
              if (drawnCard.isReversed)
                Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AurennaTheme.electricViolet.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'R',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 5), // 5px spacing as requested

        // Card name (title)
        SizedBox(
          width: cardWidth,
          child: Text(
            drawnCard.card.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.textPrimary,
              fontSize: 8, // Slightly bigger card name
              fontWeight: FontWeight.w500,
              height: 1.1, // Tighter line height
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildShuffleAnimation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: screenWidth,
      height: screenHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background sparkles during shuffling
          if (_isShuffling) ..._buildBackgroundSparkles(),
          
          // Shuffling cards
          if (_isShuffling) ..._buildShufflingCards(),

          // Selected cards moving to center
          if (_cardsSelected) ..._buildSelectedCards(),
        ],
      ),
    );
  }

  List<Widget> _buildShufflingCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return _cards.map((card) {
      return AnimatedBuilder(
        animation: _shuffleController,
        builder: (context, child) {
          final progress = (_shuffleController.value + card.delay) % 1.0;

          // Interpolate position
          final currentPos = Offset.lerp(
            card.startPosition,
            card.endPosition,
            progress,
          )!;

          final x = currentPos.dx * screenWidth;
          final y = currentPos.dy * screenHeight;

          // Only show cards that are within screen bounds
          if (x < -100 ||
              x > screenWidth + 100 ||
              y < -100 ||
              y > screenHeight + 100) {
            return const SizedBox.shrink();
          }

          return Positioned(
            left: x,
            top: y,
            child: Transform.rotate(
              angle: card.rotation * progress,
              child: _buildCardBack(
                screenWidth * 0.18,
              ), // 3x bigger cards (was 0.06, now 0.18)
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildSelectedCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth * 0.9;
    
    // Grid layout for 12-card general reading
    final crossAxisCount = 4;
    final maxCardWidth = (availableWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
    final cardWidth = math.min(maxCardWidth, 100.0);

    return [
      Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.45, // Adjusted to prevent overflow
            ),
            itemBuilder: (context, index) {
              return Align(
                alignment: Alignment.topCenter, // Align each card to top of its grid cell
                child: _buildCardFront(cardWidth, index),
              );
            },
          ),
        ),
      ),
    ];
  }

  Widget _buildCardBack(double width) {
    return Container(
      width: width,
      height: width * 1.4, // Exact card dimensions
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          // Simple shadow for shuffling cards - no magical glow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // Cosmic Purple background exactly the size of the card
          color: AurennaTheme.cosmicPurple,
          width: width,
          height: width * 1.4,
          child: Image.asset(
            TarotCard.coverImagePath,
            fit: BoxFit.contain, // Use contain to prevent overflow
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AurennaTheme.cosmicPurple,
                child: Center(
                  child: Text(
                    '✦',
                    style: TextStyle(
                      fontSize: width * 0.3,
                      color: AurennaTheme.silverMist,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(double width, int position) {
    // If we have drawn cards, display them
    if (_drawnCards.isNotEmpty && position < _drawnCards.length) {
      final drawnCard = _drawnCards[position];
      final cardHeight = width * 1.4; // Standard tarot card ratio

      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start, // Align to top
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Card image with fixed size and Cosmic Purple background
          Container(
            width: width,
            height: cardHeight,
            decoration: BoxDecoration(
              color: AurennaTheme
                  .cosmicPurple, // Cosmic Purple background only for card
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                // Remove glow effects, keep only basic shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  // Cosmic Purple background
                  Container(color: AurennaTheme.cosmicPurple),
                  // Card image
                  Positioned.fill(
                    child: Transform.rotate(
                      angle: drawnCard.isReversed ? math.pi : 0,
                      child: Image.asset(
                        drawnCard.card.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AurennaTheme.cosmicPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  drawnCard.card.name,
                                  style: TextStyle(
                                    fontSize: width * 0.08,
                                    fontWeight: FontWeight.bold,
                                    color: AurennaTheme.silverMist,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Compact labels to prevent overflow
          const SizedBox(height: 2),
          Text(
            drawnCard.positionName,
            style: TextStyle(
              color: AurennaTheme.crystalBlue,
              fontSize: width * 0.08,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            drawnCard.card.name,
            style: TextStyle(
              color: AurennaTheme.textPrimary,
              fontSize: width * 0.07,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (drawnCard.isReversed)
            Text(
              '(R)',
              style: TextStyle(
                color: AurennaTheme.amberGlow,
                fontSize: width * 0.06,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
        ],
      );
    }

    // Fallback placeholder
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: AurennaTheme.mysticalGradient,
        boxShadow: [
          BoxShadow(
            color: AurennaTheme.electricViolet.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Card ${position + 1}',
            style: TextStyle(
              color: AurennaTheme.silverMist,
              fontSize: width * 0.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: width * 0.1),
          Icon(
            Icons.auto_awesome,
            color: AurennaTheme.amberGlow,
            size: width * 0.3,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNameInputScreen() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
              // Mystical header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AurennaTheme.cosmicPurple.withValues(alpha: 0.3),
                      AurennaTheme.electricViolet.withValues(alpha: 0.3),
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
                      Icons.auto_awesome,
                      color: AurennaTheme.electricViolet,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Comprehensive General Reading',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AurennaTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A complete view of your life\'s energy across 12 key areas',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AurennaTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Name input
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your name or initials',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AurennaTheme.crystalBlue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _startGeneralReading(),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'This helps personalize your cosmic narrative',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AurennaTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Start button
              ElevatedButton(
                onPressed: _startGeneralReading,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('Begin My Reading'),
              ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFormattedReading() {
    return HtmlReadingWidget(
      content: _aiReading,
      fallbackTextColor: 'silvermist',
    );
  }

  List<Widget> _buildBackgroundSparkles() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final random = math.Random();
    
    return List.generate(50, (index) {
      // Create fixed base positions for each sparkle
      final baseX = random.nextDouble() * screenWidth;
      final baseY = random.nextDouble() * screenHeight;
      
      return AnimatedBuilder(
        animation: _shuffleController,
        builder: (context, child) {
          // Much smaller, slower movement for galaxy effect
          final sparkleOffset = Offset(
            baseX + (math.sin((_shuffleController.value * 0.5 * math.pi) + index) * 8),
            baseY + (math.cos((_shuffleController.value * 0.3 * math.pi) + index) * 6),
          );
          
          // Gentler opacity changes
          final opacity = (math.sin((_shuffleController.value * 1.5 * math.pi) + index) + 1) / 2;
          
          return Positioned(
            left: sparkleOffset.dx,
            top: sparkleOffset.dy,
            child: Opacity(
              opacity: opacity * 0.4, // More subtle
              child: Container(
                width: 2 + (math.sin((_shuffleController.value * 2 * math.pi) + index) * 1),
                height: 2 + (math.sin((_shuffleController.value * 2 * math.pi) + index) * 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AurennaTheme.silverMist.withValues(alpha: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
  
  List<Widget> _buildCosmicBackground(double screenWidth, double screenHeight) {
    final random = math.Random();
    final List<Widget> stars = [];
    
    // Create multiple layers of stars
    for (int i = 0; i < 100; i++) {
      final size = random.nextDouble() * 3 + 1;
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      final delay = random.nextDouble() * 2; // Increased delay spread for more variety
      
      stars.add(
        Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              // Much slower, smoother twinkling (0.3x speed)
              final opacity = ((math.sin((_glowAnimation.value + delay) * math.pi * 0.6) + 1) / 2) * 0.6;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AurennaTheme.silverMist.withValues(alpha: opacity),
                  boxShadow: [
                    BoxShadow(
                      color: AurennaTheme.silverMist.withValues(alpha: opacity * 0.5),
                      blurRadius: size * 2,
                      spreadRadius: size * 0.5,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
    
    // Add some floating cosmic dust
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      final floatSpeed = 0.3 + random.nextDouble() * 0.2; // Variable slow speeds
      
      stars.add(
        Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              // Much slower, smoother floating (0.3x speed with variable speeds)
              final offsetY = math.sin(_floatAnimation.value * math.pi * floatSpeed) * 10;
              final offsetX = math.cos(_floatAnimation.value * math.pi * floatSpeed * 0.8) * 8;
              return Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AurennaTheme.cosmicPurple.withValues(alpha: 0.2),
                        AurennaTheme.electricViolet.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return stars;
  }
}

class CardAnimationData {
  final int id;
  final Offset startPosition;
  final Offset endPosition;
  final double rotation;
  final double delay;
  final double speed;

  CardAnimationData({
    required this.id,
    required this.startPosition,
    required this.endPosition,
    required this.rotation,
    required this.delay,
    required this.speed,
  });
}