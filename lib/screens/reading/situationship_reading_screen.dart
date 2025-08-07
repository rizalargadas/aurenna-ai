import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/reading.dart';
import '../../models/tarot_card.dart';
import '../../services/auth_service.dart';
import '../../services/tarot_service.dart';
import '../../widgets/mystical_loading.dart';

class SituationshipReadingScreen extends StatefulWidget {
  const SituationshipReadingScreen({super.key});

  @override
  State<SituationshipReadingScreen> createState() => _SituationshipReadingScreenState();
}

class _SituationshipReadingScreenState extends State<SituationshipReadingScreen>
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
  final _yourNameController = TextEditingController();
  final _theirNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _yourName = '';
  String _theirName = '';

  @override
  void initState() {
    super.initState();
    
    // Don't start animations yet - wait for user input
    _showNameInput = true;
    
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
    _yourNameController.dispose();
    _theirNameController.dispose();
    
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

    // Select random cards for the final reveal (6 cards for situationship reading)
    final indices = List.generate(cardCount, (i) => i);
    indices.shuffle();
    _selectedCardIndices = indices.take(6).toList();
  }

  void _onShuffleComplete() {
    // Draw the 6 cards when shuffle completes
    _drawnCards = TarotService.drawSixCards();
    setState(() {});
  }

  void _onCardsRevealed() async {
    if (!mounted || _disposed) return;
    
    // Move directly to generation phase
    setState(() => _currentStep = 2);

    try {
      // Generate AI reading with both names
      _aiReading = await TarotService.generateSituationshipReading(
        _drawnCards, 
        yourName: _yourName, 
        theirName: _theirName
      );

      // Save reading to database
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId != null) {
        await TarotService.saveReading(
          userId: userId,
          question: 'Situationship Reading: $_yourName about $_theirName',
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

  Future<void> _startSituationshipReading() async {
    // Validate and save names first
    if (_showNameInput) {
      if (!_formKey.currentState!.validate()) return;
      
      setState(() {
        _yourName = _yourNameController.text.trim();
        _theirName = _theirNameController.text.trim();
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
    for (int i = 0; i < 6; i++) {
      if (!mounted) return;

      setState(() {
        _currentRevealIndex = i;
      });

      _cardRevealController.forward(from: 0);
      await Future.delayed(
        const Duration(milliseconds: 200),
      ); // Fast reveal interval
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

  String _getStatusText() {
    switch (_currentStep) {
      case 0:
        return ''; // Remove shuffling text
      case 1:
        return 'The situationship cards have been drawn';
      case 2:
        return 'Aurenna is cutting through the BS...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      appBar: AppBar(
        title: const Text('Situationship Reading'),
        actions: [
          if (_isComplete)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Sharing coming soon! ✨',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AurennaTheme.crystalBlue,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
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
    
    // For animation states, use Stack
    return Stack(
      children: [
        // Full-screen animation layer
        Positioned.fill(
          child: _buildAnimatedContent(),
        ),
        
        // UI overlay at bottom (only show during card reveal and generating)
        if (_currentStep == 1 || _currentStep == 2)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AurennaTheme.voidBlack.withOpacity(0.9),
                      AurennaTheme.voidBlack.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status text - no background container
                    if (_getStatusText().isNotEmpty)
                      Text(
                        _getStatusText(),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AurennaTheme.silverMist,
                          fontSize: 24,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
              color: AurennaTheme.electricViolet.withOpacity(0.5),
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
                _startSituationshipReading();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedContent() {
    // Return empty container if we haven't started yet
    if (!_shuffleStarted) {
      return Container(color: AurennaTheme.voidBlack);
    }
    
    if (_currentStep == 0 && _shuffleStarted) {
      // Shuffling animation
      return _buildShuffleAnimation();
    } else if (_currentStep == 1) {
      // Cards are still being revealed
      return _buildShuffleAnimation();
    } else if (_currentStep == 2) {
      // Situationship-themed cosmic animation with dramatic effect
      return ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              
              return AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  if (!mounted || _disposed) return const SizedBox.shrink();
                  
                  return Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none, // Allow overflow
                    children: [
                      // Dramatic background - moody and intense
                      ..._buildDramaticBackground(screenWidth, screenHeight),
                      
                      // Swirling confusion effect - represents mixed signals
                      Container(
                        width: screenWidth * 3.0,
                        height: screenHeight * 3.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.0,
                            colors: [
                              AurennaTheme.electricViolet.withOpacity((_glowAnimation.value * 0.4).clamp(0.0, 1.0)),
                              AurennaTheme.crystalBlue.withOpacity((_glowAnimation.value * 0.35).clamp(0.0, 1.0)),
                              AurennaTheme.mysticBlue.withOpacity((_glowAnimation.value * 0.25).clamp(0.0, 1.0)),
                              AurennaTheme.voidBlack.withOpacity((_glowAnimation.value * 0.15).clamp(0.0, 1.0)),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                          ),
                        ),
                      ),
                      
                      // Secondary confused energy layer
                      Transform.rotate(
                        angle: _glowAnimation.value * math.pi * 2, // Slowly rotating confusion
                        child: Container(
                          width: screenWidth * 2.0,
                          height: screenHeight * 2.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AurennaTheme.electricViolet.withOpacity((_glowAnimation.value * 0.3).clamp(0.0, 1.0)),
                                AurennaTheme.mysticBlue.withOpacity((_glowAnimation.value * 0.2).clamp(0.0, 1.0)),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      
                      // Core mystical loading with situationship theme
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AurennaTheme.electricViolet.withOpacity((_glowAnimation.value * 0.8).clamp(0.0, 1.0)),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                            BoxShadow(
                              color: AurennaTheme.crystalBlue.withOpacity((_glowAnimation.value * 0.6).clamp(0.0, 1.0)),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const MysticalLoading(
                          message: 'Cutting through the BS...',
                          size: 80,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );
    } else {
      // Default empty container
      return Container(color: AurennaTheme.voidBlack);
    }
  }

  Widget _buildCompleteReading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AurennaTheme.electricViolet.withOpacity(0.3),
                  AurennaTheme.crystalBlue.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AurennaTheme.electricViolet.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.psychology,
                  color: AurennaTheme.electricViolet,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Situationship Reading',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AurennaTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '$_yourName about $_theirName',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AurennaTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Your Situationship Spread',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          _buildCardGrid(),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AurennaTheme.electricViolet.withOpacity(0.3),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.psychology,
                  color: AurennaTheme.electricViolet,
                  size: 20,
                ),
              ),
              Expanded(
                child: Divider(
                  color: AurennaTheme.electricViolet.withOpacity(0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'The Truth About This Connection',
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
                color: AurennaTheme.silverMist.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AurennaTheme.silverMist.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reading content - no constraints
                _buildFormattedReading(),
                const SizedBox(height: 16),
                Divider(color: AurennaTheme.silverMist.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  'Remember: You deserve clarity, not confusion. Trust what the cards reveal and choose yourself.',
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
              '🔮 Clarity over confusion, always 🔮',
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
        // For 6 cards, use a 3x2 grid layout
        final cardWidth = constraints.maxWidth > 400 ? 85.0 : 75.0;
        
        return Column(
          children: [
            // Top row - 3 cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSituationshipCard(_drawnCards[0], cardWidth), // Your Current Energy
                _buildSituationshipCard(_drawnCards[1], cardWidth), // Their Feelings
                _buildSituationshipCard(_drawnCards[2], cardWidth), // Their Thoughts
              ],
            ),
            const SizedBox(height: 20),
            // Bottom row - 3 cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSituationshipCard(_drawnCards[3], cardWidth), // Their Intentions
                _buildSituationshipCard(_drawnCards[4], cardWidth), // Their Actions/Plan
                _buildSituationshipCard(_drawnCards[5], cardWidth), // Advice
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSituationshipCard(DrawnCard drawnCard, double cardWidth) {
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
            color: AurennaTheme.electricViolet.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            drawnCard.positionName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.electricViolet,
              fontWeight: FontWeight.w600,
              fontSize: 9,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
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
                color: borderColor.withOpacity(0.2),
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
                        color: AurennaTheme.electricViolet.withOpacity(0.9),
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

        const SizedBox(height: 8),

        // Card name
        SizedBox(
          width: cardWidth,
          child: Text(
            drawnCard.card.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.textPrimary,
              fontSize: 8,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSelectedCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = math.min(screenWidth * 0.9 / 3.5, 75.0);

    return [
      Center( // Center the entire card group vertically and horizontally
        child: Container(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use same sizing logic as completed reading
              final cardWidth = constraints.maxWidth > 400 ? 85.0 : 75.0;
              
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row - 3 cards (exactly like _buildCardGrid)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCardFrontAligned(cardWidth, 0), // Your Current Energy
                      _buildCardFrontAligned(cardWidth, 1), // Their Feelings
                      _buildCardFrontAligned(cardWidth, 2), // Their Thoughts
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bottom row - 3 cards (exactly like _buildCardGrid)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCardFrontAligned(cardWidth, 3), // Their Intentions
                      _buildCardFrontAligned(cardWidth, 4), // Their Actions/Plan
                      _buildCardFrontAligned(cardWidth, 5), // Advice
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ];
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
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildCardBack(double width) {
    return Container(
      width: width,
      height: width * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: AurennaTheme.cosmicPurple,
          width: width,
          height: width * 1.4,
          child: Image.asset(
            TarotCard.coverImagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AurennaTheme.cosmicPurple,
                child: Center(
                  child: Text(
                    '🔮',
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

  // Card display method for reveal animation - matches _buildSituationshipCard exactly
  Widget _buildCardFrontAligned(double cardWidth, int position) {
    if (_drawnCards.isNotEmpty && position < _drawnCards.length) {
      final drawnCard = _drawnCards[position];
      final borderColor = drawnCard.isReversed
          ? AurennaTheme.electricViolet
          : AurennaTheme.crystalBlue;
      final cardHeight = cardWidth * 1.4;

      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Position name (exactly like _buildSituationshipCard)
          Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AurennaTheme.electricViolet.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              drawnCard.positionName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AurennaTheme.electricViolet,
                fontWeight: FontWeight.w600,
                fontSize: 9,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 4),

          // Card container (exactly like _buildSituationshipCard)
          Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withOpacity(0.2),
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
                          color: AurennaTheme.electricViolet.withOpacity(0.9),
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

          const SizedBox(height: 8),

          // Card name (exactly like _buildSituationshipCard)
          SizedBox(
            width: cardWidth,
            child: Text(
              drawnCard.card.name,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AurennaTheme.textPrimary,
                fontSize: 8,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Placeholder card (fallback)
    return Container(
      width: cardWidth,
      height: cardWidth * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AurennaTheme.electricViolet.withOpacity(0.3),
            AurennaTheme.crystalBlue.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AurennaTheme.electricViolet.withOpacity(0.5),
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
              fontSize: cardWidth * 0.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: cardWidth * 0.1),
          Icon(
            Icons.psychology,
            color: AurennaTheme.electricViolet,
            size: cardWidth * 0.3,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNameInputScreen() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Mystical header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AurennaTheme.electricViolet.withOpacity(0.3),
                      AurennaTheme.crystalBlue.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AurennaTheme.electricViolet.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: AurennaTheme.electricViolet,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Situationship Reading',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AurennaTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cut through the confusion and get crystal clear answers about that messy "what are we?" situation',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AurennaTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Your name input
              TextFormField(
                controller: _yourNameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your name',
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
              ),
              
              const SizedBox(height: 24),
              
              // Their name input
              TextFormField(
                controller: _theirNameController,
                decoration: InputDecoration(
                  labelText: 'Their Name',
                  hintText: 'Enter their name or initials',
                  prefixIcon: Icon(
                    Icons.psychology_outlined,
                    color: AurennaTheme.electricViolet,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter their name';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _startSituationshipReading(),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Get the truth about what\'s really going on in their head and heart',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AurennaTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Start button
              ElevatedButton.icon(
                onPressed: _startSituationshipReading,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  backgroundColor: AurennaTheme.electricViolet,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.psychology),
                label: const Text('Cut Through The BS'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFormattedReading() {
    // Parse the reading to format bold headers
    final List<TextSpan> spans = [];
    final lines = _aiReading.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Check if line starts with ** and contains a card position
      if (line.startsWith('**') && line.contains(' - ')) {
        // Extract the text between ** markers
        final match = RegExp(r'\*\*(.+?)\*\*').firstMatch(line);
        if (match != null) {
          final boldText = match.group(1) ?? '';
          // Add the bold header
          spans.add(TextSpan(
            text: boldText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: AurennaTheme.silverMist,
              fontWeight: FontWeight.bold,
            ),
          ));
          // Add the rest of the line after **
          final restOfLine = line.substring(match.end);
          if (restOfLine.isNotEmpty) {
            spans.add(TextSpan(
              text: restOfLine,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: AurennaTheme.silverMist,
              ),
            ));
          }
          spans.add(TextSpan(text: '\n'));
        } else {
          // Fallback if regex doesn't match
          spans.add(TextSpan(
            text: line + '\n',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: AurennaTheme.silverMist,
            ),
          ));
        }
      } else if (line == '**THE SITUATIONSHIP VERDICT:**') {
        // Handle situationship verdict header
        spans.add(TextSpan(
          text: 'THE SITUATIONSHIP VERDICT:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: AurennaTheme.silverMist,
            fontWeight: FontWeight.bold,
          ),
        ));
        spans.add(TextSpan(text: '\n'));
      } else {
        // Regular line
        spans.add(TextSpan(
          text: line + '\n',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: AurennaTheme.silverMist,
          ),
        ));
      }
    }
    
    // Return SelectableText directly - it will size to its content
    return SelectableText.rich(
      TextSpan(children: spans),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: AurennaTheme.silverMist,
      ),
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
              opacity: opacity * 0.4,
              child: Container(
                width: 2 + (math.sin((_shuffleController.value * 2 * math.pi) + index) * 1),
                height: 2 + (math.sin((_shuffleController.value * 2 * math.pi) + index) * 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AurennaTheme.silverMist.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: AurennaTheme.electricViolet.withOpacity(0.3),
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
  
  // Dramatic background for situationship reading - moody and intense
  List<Widget> _buildDramaticBackground(double screenWidth, double screenHeight) {
    final random = math.Random();
    final List<Widget> elements = [];
    
    // Create question marks floating around - representing confusion
    for (int i = 0; i < 20; i++) {
      final size = random.nextDouble() * 30 + 15;
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      final delay = random.nextDouble() * 2;
      
      elements.add(
        Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              final opacity = ((math.sin((_glowAnimation.value + delay) * math.pi * 0.4) + 1) / 2) * 0.3;
              final scale = 0.8 + (math.sin((_glowAnimation.value + delay) * math.pi) * 0.3);
              return Transform.scale(
                scale: scale,
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: size,
                    color: AurennaTheme.electricViolet.withOpacity(opacity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    // Add broken hearts - representing relationship confusion
    for (int i = 0; i < 15; i++) {
      final size = random.nextDouble() * 25 + 12;
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      final delay = random.nextDouble() * 2;
      
      elements.add(
        Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              final opacity = ((math.sin((_glowAnimation.value + delay) * math.pi * 0.3) + 1) / 2) * 0.4;
              final rotation = math.sin((_glowAnimation.value + delay) * math.pi * 0.2) * 0.5;
              return Transform.rotate(
                angle: rotation,
                child: Text(
                  '💔',
                  style: TextStyle(
                    fontSize: size,
                    color: AurennaTheme.crystalBlue.withOpacity(opacity),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    // Add regular stars for mystical background
    for (int i = 0; i < 60; i++) {
      final size = random.nextDouble() * 3 + 1;
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      final delay = random.nextDouble() * 2;
      
      elements.add(
        Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              final opacity = ((math.sin((_glowAnimation.value + delay) * math.pi * 0.6) + 1) / 2) * 0.5;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AurennaTheme.silverMist.withOpacity(opacity),
                  boxShadow: [
                    BoxShadow(
                      color: AurennaTheme.silverMist.withOpacity(opacity * 0.5),
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
    
    return elements;
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