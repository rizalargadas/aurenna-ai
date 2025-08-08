import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/tarot_card.dart';
import '../models/reading.dart';

class SimpleCardShuffle extends StatefulWidget {
  final VoidCallback? onShuffleComplete;
  final VoidCallback? onCardsRevealed;
  final List<DrawnCard>? drawnCards;
  final int cardCount;
  final bool showCardDetails; // Whether to show card names and positions
  final String? revealMessage; // Message to show during card reveal

  const SimpleCardShuffle({
    super.key,
    this.onShuffleComplete,
    this.onCardsRevealed,
    this.drawnCards,
    this.cardCount = 3, // Default to 3 cards
    this.showCardDetails = true, // Default to showing details
    this.revealMessage, // Optional reveal message
  });

  @override
  State<SimpleCardShuffle> createState() => _SimpleCardShuffleState();
}

class _SimpleCardShuffleState extends State<SimpleCardShuffle>
    with TickerProviderStateMixin {
  late AnimationController _shuffleController;
  late AnimationController _revealController;
  late AnimationController _cardRevealController;

  final int cardCount = 78;
  late List<CardAnimationData> _cards;
  List<int> _selectedCardIndices = [];

  bool _isShuffling = true;
  bool _cardsSelected = false;

  @override
  void initState() {
    super.initState();

    _shuffleController = AnimationController(
      duration: const Duration(
        milliseconds: 5000,
      ), // Longer shuffle for more dramatic effect
      vsync: this,
    );

    _revealController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Faster card movement
      vsync: this,
    );

    _cardRevealController = AnimationController(
      duration: const Duration(milliseconds: 600), // Quicker reveal
      vsync: this,
    );

    _initializeCards();
    _startAnimation();
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

    // Select random cards for the final reveal based on widget.cardCount
    final indices = List.generate(cardCount, (i) => i);
    indices.shuffle();
    _selectedCardIndices = indices.take(widget.cardCount).toList();
  }

  Future<void> _startAnimation() async {
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

      widget.onShuffleComplete?.call();

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
    // Reveal all cards instantly and wait 3 seconds before next phase
    if (!mounted) return;
    
    _cardRevealController.forward(from: 0);
    
    // Wait 3 seconds before moving to generation phase
    await Future.delayed(const Duration(milliseconds: 3000));
    
    // Now call onCardsRevealed to move to generation phase
    if (mounted) {
      widget.onCardsRevealed?.call();
    }
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    _revealController.dispose();
    _cardRevealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          
          // Reveal message at bottom during card reveal
          if (_cardsSelected && widget.revealMessage != null)
            _buildRevealMessage(),
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
    
    // Handle different card counts
    if (widget.cardCount <= 4) {
      // Row layout for 3-4 cards
      final maxCardWidth = (availableWidth - (widget.cardCount - 1) * 16) / widget.cardCount;
      final cardWidth = math.min(maxCardWidth, 100.0);

      return [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _selectedCardIndices.asMap().entries.map((entry) {
              final index = entry.key;

              final cardWidget = SizedBox(
                width: cardWidth,
                child: _buildCardFront(cardWidth, index),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: cardWidget,
              );
            }).toList(),
          ),
        ),
      ];
    } else {
      // Grid layout for more cards (like 12-card general reading)
      final crossAxisCount = widget.cardCount == 12 ? 3 : 4;
      final cardWidth = (availableWidth - (crossAxisCount + 1) * 8) / crossAxisCount;
      final finalCardWidth = math.min(cardWidth, 80.0);

      return [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cardCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: widget.showCardDetails ? 0.5 : 0.7,
              ),
              itemBuilder: (context, index) {
                return _buildCardFront(finalCardWidth, index);
              },
            ),
          ),
        ),
      ];
    }
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
    if (widget.drawnCards != null && position < widget.drawnCards!.length) {
      final drawnCard = widget.drawnCards![position];
      final cardHeight = width * 1.4; // Standard tarot card ratio

      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
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
                // Subtle mystical glow effect
                BoxShadow(
                  color: AurennaTheme.electricViolet.withValues(
                    alpha: 0.2,
                  ), // Reduced from 0.4
                  blurRadius: 12, // Reduced from 20
                  spreadRadius: 1, // Reduced from 3
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: AurennaTheme.cosmicPurple.withValues(
                    alpha: 0.3,
                  ), // Reduced from 0.6
                  blurRadius: 8, // Reduced from 15
                  spreadRadius: 0, // Reduced from 1
                  offset: const Offset(0, 1), // Reduced from 2
                ),
                // Soft depth shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), // Reduced from 0.3
                  blurRadius: 6, // Reduced from 8
                  offset: const Offset(0, 3), // Reduced from 4
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
          // Text labels below card (only if showCardDetails is true)
          if (widget.showCardDetails) ...[
            const SizedBox(height: 8),

            // Position name
            Text(
              drawnCard.positionName,
              style: TextStyle(
                color: AurennaTheme.crystalBlue,
                fontSize: width * 0.12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Card name
            SizedBox(
              width: width,
              child: Text(
                drawnCard.card.name.isNotEmpty
                    ? drawnCard.card.name
                    : 'Unknown Card',
                style: TextStyle(
                  color: AurennaTheme.textPrimary,
                  fontSize: width * 0.11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Reversed indicator if needed
            if (drawnCard.isReversed) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AurennaTheme.amberGlow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AurennaTheme.amberGlow.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Reversed',
                  style: TextStyle(
                    color: AurennaTheme.amberGlow,
                    fontSize: width * 0.08,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
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
  
  Widget _buildRevealMessage() {
    return Positioned(
      bottom: 80,
      left: 24,
      right: 24,
      child: SafeArea(
        child: Text(
          widget.revealMessage!,
          style: TextStyle(
            color: AurennaTheme.silverMist,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 10,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
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
