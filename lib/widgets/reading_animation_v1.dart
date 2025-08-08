import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/reading.dart';
import '../models/tarot_card.dart';
import '../utils/reading_messages.dart';
import 'mystical_loading.dart';

enum ReadingAnimationPhase {
  shuffling,
  revealing,
  generating,
  complete,
}

/// A reusable animation widget that handles the complete reading animation sequence
/// from shuffling to card reveal to the radial glow effect, used across all spreads
class ComprehensiveReadingAnimation extends StatefulWidget {
  final int cardCount;
  final List<DrawnCard> drawnCards;
  final VoidCallback? onShuffleComplete;
  final VoidCallback? onCardsRevealed;
  final String? statusMessage;
  final ReadingAnimationPhase phase;
  final String? generationMessage; // Fixed message for generation phase
  final Widget? overlayContent; // For custom overlay content during animation

  const ComprehensiveReadingAnimation({
    super.key,
    required this.cardCount,
    required this.drawnCards,
    this.onShuffleComplete,
    this.onCardsRevealed,
    this.statusMessage,
    this.phase = ReadingAnimationPhase.shuffling,
    this.generationMessage,
    this.overlayContent,
  });

  @override
  State<ComprehensiveReadingAnimation> createState() => _ComprehensiveReadingAnimationState();
}

class _ComprehensiveReadingAnimationState extends State<ComprehensiveReadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _shuffleController;
  late AnimationController _revealController;
  late AnimationController _cardRevealController;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  bool _disposed = false;

  // Animation data
  late List<CardAnimationData> _cards;
  List<int> _selectedCardIndices = [];
  bool _isShuffling = true;
  bool _cardsSelected = false;
  int _currentRevealIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCards();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
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
  }

  void _initializeCards() {
    final random = math.Random();
    _cards = List.generate(widget.cardCount, (index) {
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

    // Select random cards for the final reveal
    final indices = List.generate(widget.cardCount, (i) => i);
    indices.shuffle();
    _selectedCardIndices = indices.take(widget.drawnCards.length).toList();
  }

  Future<void> _startAnimationSequence() async {
    // Phase 1: Shuffling
    await _startShuffleAnimation();
    
    // Phase 2: Card reveal
    if (widget.phase == ReadingAnimationPhase.revealing || 
        widget.phase == ReadingAnimationPhase.generating ||
        widget.phase == ReadingAnimationPhase.complete) {
      await _revealCardsSequence();
    }
  }

  Future<void> _startShuffleAnimation() async {
    if (_disposed) return;
    
    // Start shuffling animation
    _shuffleController.repeat();

    // Wait for shuffle duration
    await Future.delayed(const Duration(milliseconds: 5000));

    // Stop shuffling and move selected cards to center
    if (mounted && !_disposed) {
      setState(() {
        _isShuffling = false;
        _cardsSelected = true;
      });

      widget.onShuffleComplete?.call();
      _shuffleController.stop();
      _revealController.forward();

      // Wait for cards to move to center
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  Future<void> _revealCardsSequence() async {
    if (_disposed) return;

    // Start revealing cards one by one
    for (int i = 0; i < widget.drawnCards.length; i++) {
      if (!mounted || _disposed) return;

      setState(() {
        _currentRevealIndex = i;
      });

      _cardRevealController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Cards revealed - callback
    if (mounted && !_disposed) {
      widget.onCardsRevealed?.call();
    }
    
    // Wait before moving to generation phase
    await Future.delayed(const Duration(seconds: 3));
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
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen animation layer
        Positioned.fill(
          child: _buildAnimationContent(),
        ),
        
        // Status overlay
        if (widget.statusMessage != null && widget.statusMessage!.isNotEmpty)
          _buildStatusOverlay(),
        
        // Custom overlay content
        if (widget.overlayContent != null)
          widget.overlayContent!,
      ],
    );
  }

  Widget _buildAnimationContent() {
    switch (widget.phase) {
      case ReadingAnimationPhase.shuffling:
        return _buildShuffleAnimation();
      case ReadingAnimationPhase.revealing:
        return _buildShuffleAnimation(); // Still showing cards
      case ReadingAnimationPhase.generating:
        return _buildCosmicGeneratingAnimation();
      case ReadingAnimationPhase.complete:
        return Container(color: AurennaTheme.voidBlack);
    }
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

  Widget _buildCosmicGeneratingAnimation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        if (!mounted || _disposed) return const SizedBox.shrink();
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // Animated starfield background
            ..._buildCosmicBackground(screenWidth, screenHeight),
            
            // Massive background gradient that extends beyond screen
            Container(
              width: screenWidth * 2.5, // 2.5x screen width
              height: screenHeight * 2.0, // 2x screen height
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    AurennaTheme.electricViolet.withOpacity((_glowAnimation.value * 0.4).clamp(0.0, 1.0)),
                    AurennaTheme.cosmicPurple.withOpacity((_glowAnimation.value * 0.35).clamp(0.0, 1.0)),
                    AurennaTheme.mysticBlue.withOpacity((_glowAnimation.value * 0.25).clamp(0.0, 1.0)),
                    AurennaTheme.crystalBlue.withOpacity((_glowAnimation.value * 0.15).clamp(0.0, 1.0)),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                ),
              ),
            ),
            
            // Secondary pulsing layer
            Container(
              width: screenWidth * 1.8,
              height: screenHeight * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AurennaTheme.electricViolet.withOpacity((_glowAnimation.value * 0.3).clamp(0.0, 1.0)),
                    AurennaTheme.amberGlow.withOpacity((_glowAnimation.value * 0.2).clamp(0.0, 1.0)),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Core mystical loading with enhanced glow
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
                    color: AurennaTheme.cosmicPurple.withOpacity((_glowAnimation.value * 0.6).clamp(0.0, 1.0)),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: MysticalLoading(
                message: widget.generationMessage ?? 'Channeling universal wisdom...', // Fixed message per session
                size: 80,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusOverlay() {
    // Only show status overlay during revealing phase
    // Hide it during generating phase to avoid duplicate text
    if (widget.phase == ReadingAnimationPhase.generating) {
      return const SizedBox.shrink();
    }
    
    return AnimatedPositioned(
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
          child: Text(
            widget.statusMessage!,
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
        ),
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
              child: _buildCardBack(screenWidth * 0.18), // 3x bigger cards
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildSelectedCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth * 0.9;
    
    // Special layout for 5 cards (3-2 arrangement)
    if (widget.drawnCards.length == 5) {
      return [_build5CardLayout(availableWidth)];
    }
    
    // Dynamic grid layout for other card counts
    int crossAxisCount;
    if (widget.drawnCards.length <= 3) {
      crossAxisCount = widget.drawnCards.length;
    } else if (widget.drawnCards.length <= 8) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 4; // For 12-card spreads
    }
    
    final maxCardWidth = (availableWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
    final cardWidth = math.min(maxCardWidth, 100.0);

    return [
      Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.drawnCards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.45, // Adjusted to prevent overflow
            ),
            itemBuilder: (context, index) {
              return Align(
                alignment: Alignment.topCenter,
                child: _buildCardFront(cardWidth, index),
              );
            },
          ),
        ),
      ),
    ];
  }
  
  Widget _build5CardLayout(double availableWidth) {
    // Calculate card size for 3-2 layout - bigger cards
    final cardWidth = math.min((availableWidth - 32) / 3, 110.0); // Increased from 100 to 110
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row - 3 cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCardFront(cardWidth, 0),
                const SizedBox(width: 8),
                _buildCardFront(cardWidth, 1),
                const SizedBox(width: 8),
                _buildCardFront(cardWidth, 2),
              ],
            ),
            const SizedBox(height: 16), // Increased spacing
            // Second row - 2 cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCardFront(cardWidth, 3),
                const SizedBox(width: 8),
                _buildCardFront(cardWidth, 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(double width) {
    return Container(
      width: width,
      height: width * 1.4, // Exact card dimensions
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
    if (position < widget.drawnCards.length) {
      final drawnCard = widget.drawnCards[position];
      final cardHeight = width * 1.4;

      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Card image with fixed size and Cosmic Purple background
          Container(
            width: width,
            height: cardHeight,
            decoration: BoxDecoration(
              color: AurennaTheme.cosmicPurple,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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

  List<Widget> _buildBackgroundSparkles() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final random = math.Random();
    
    return List.generate(50, (index) {
      final baseX = random.nextDouble() * screenWidth;
      final baseY = random.nextDouble() * screenHeight;
      
      return AnimatedBuilder(
        animation: _shuffleController,
        builder: (context, child) {
          final sparkleOffset = Offset(
            baseX + (math.sin((_shuffleController.value * 0.5 * math.pi) + index) * 8),
            baseY + (math.cos((_shuffleController.value * 0.3 * math.pi) + index) * 6),
          );
          
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
  
  List<Widget> _buildCosmicBackground(double screenWidth, double screenHeight) {
    final random = math.Random();
    final List<Widget> stars = [];
    
    // Create multiple layers of stars
    for (int i = 0; i < 100; i++) {
      final size = random.nextDouble() * 3 + 1;
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      final delay = random.nextDouble() * 2;
      
      stars.add(
        Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              final opacity = ((math.sin((_glowAnimation.value + delay) * math.pi * 0.6) + 1) / 2) * 0.6;
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
    
    // Add some floating cosmic dust
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * screenWidth;
      final y = random.nextDouble() * screenHeight;
      final floatSpeed = 0.3 + random.nextDouble() * 0.2;
      
      stars.add(
        Positioned(
          left: x,
          top: y,
          child: AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
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
                        AurennaTheme.cosmicPurple.withOpacity(0.2),
                        AurennaTheme.electricViolet.withOpacity(0.05),
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