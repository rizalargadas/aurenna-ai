import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../models/tarot_card.dart';

enum ShufflePhase {
  initial,
  split,
  riffle,
  bridge,
  complete,
}

enum ShuffleStyle {
  riffle,
  bridge,
  manual,
}

class AdvancedCardShuffle extends StatefulWidget {
  final int cardCount;
  final double shuffleSpeed;
  final double shuffleDepth;
  final double rotationVariance;
  final ShuffleStyle shuffleStyle;
  final VoidCallback? onComplete;
  final bool enableHaptics;
  final bool enableSounds;
  final bool enableMotionBlur;
  final bool enable3DEffects;

  const AdvancedCardShuffle({
    super.key,
    this.cardCount = 10,
    this.shuffleSpeed = 1.0,
    this.shuffleDepth = 30.0,
    this.rotationVariance = 6.0,
    this.shuffleStyle = ShuffleStyle.bridge,
    this.onComplete,
    this.enableHaptics = true,
    this.enableSounds = false,
    this.enableMotionBlur = true,
    this.enable3DEffects = true,
  });

  @override
  State<AdvancedCardShuffle> createState() => _AdvancedCardShuffleState();
}

class _AdvancedCardShuffleState extends State<AdvancedCardShuffle>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _splitController;
  late AnimationController _riffleController;
  late AnimationController _bridgeController;
  late AnimationController _glowController;

  late List<CardAnimationData> _cards;
  ShufflePhase _currentPhase = ShufflePhase.initial;
  bool _disposed = false;

  // Animation durations (affected by shuffleSpeed)
  late Duration _splitDuration;
  late Duration _riffleDuration;
  late Duration _bridgeDuration;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCards();
    _startShuffleSequence();
  }

  void _initializeAnimations() {
    final speedMultiplier = 1.0 / widget.shuffleSpeed;
    
    _splitDuration = Duration(milliseconds: (2000 * speedMultiplier).round()); // Much longer
    _riffleDuration = Duration(milliseconds: (4000 * speedMultiplier).round()); // Much longer
    _bridgeDuration = Duration(milliseconds: (2000 * speedMultiplier).round()); // Much longer

    _mainController = AnimationController(
      duration: Duration(
        milliseconds: (_splitDuration.inMilliseconds +
                _riffleDuration.inMilliseconds +
                _bridgeDuration.inMilliseconds)
            .round(),
      ),
      vsync: this,
    );

    _splitController = AnimationController(
      duration: _splitDuration,
      vsync: this,
    );

    _riffleController = AnimationController(
      duration: _riffleDuration,
      vsync: this,
    );

    _bridgeController = AnimationController(
      duration: _bridgeDuration,
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _initializeCards() {
    final random = math.Random();
    _cards = List.generate(widget.cardCount, (index) {
      return CardAnimationData(
        id: index,
        initialPosition: Offset.zero,
        targetPosition: Offset.zero,
        rotation: 0.0,
        rotationVariance: (random.nextDouble() - 0.5) * widget.rotationVariance * math.pi / 180,
        isLeftHalf: index < widget.cardCount ~/ 2,
        stackOrder: _generateShuffledOrder(index),
        delay: index * 0.02, // Faster delay for 78 cards (20ms between cards)
        zIndex: widget.cardCount - index, // Higher index = lower Z
      );
    });
  }

  int _generateShuffledOrder(int originalIndex) {
    // Create realistic interleaving pattern
    if (originalIndex < widget.cardCount ~/ 2) {
      return originalIndex * 2; // Left half gets even positions
    } else {
      return ((originalIndex - widget.cardCount ~/ 2) * 2) + 1; // Right half gets odd positions
    }
  }

  Future<void> _startShuffleSequence() async {
    if (_disposed) return;

    // Phase 1: Split
    setState(() => _currentPhase = ShufflePhase.split);
    _splitController.forward();
    await Future.delayed(_splitDuration);

    if (_disposed) return;

    // Haptic feedback for split
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }

    // Phase 2: Riffle
    setState(() => _currentPhase = ShufflePhase.riffle);
    _riffleController.forward();
    await Future.delayed(_riffleDuration);

    if (_disposed) return;

    // Haptic feedback for riffle completion
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }

    // Phase 3: Bridge (if style includes bridge)
    if (widget.shuffleStyle == ShuffleStyle.bridge) {
      setState(() => _currentPhase = ShufflePhase.bridge);
      _bridgeController.forward();
      await Future.delayed(_bridgeDuration);

      if (_disposed) return;

      // Final haptic feedback
      if (widget.enableHaptics) {
        HapticFeedback.lightImpact();
      }
    }

    // Complete
    setState(() => _currentPhase = ShufflePhase.complete);
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    _mainController.dispose();
    _splitController.dispose();
    _riffleController.dispose();
    _bridgeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen epic animation - use entire screen space
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return SizedBox(
      width: screenWidth,
      height: screenHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background mystical effect
          if (widget.enable3DEffects) _buildMysticalBackground(),
          
          // Animated cards with proper Z-indexing
          ..._buildAnimatedCards(),
          
          // Foreground particle effects
          if (widget.enableMotionBlur) _buildParticleEffects(),
        ],
      ),
    );
  }

  Widget _buildMysticalBackground() {
    // Minimal background - no glow effects during shuffling
    return const SizedBox.shrink();
  }

  Widget _buildParticleEffects() {
    if (_currentPhase != ShufflePhase.riffle) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _riffleController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return Stack(
          children: List.generate(36, (index) { // More particles for 78 cards
            final progress = _riffleController.value;
            final particleProgress = ((progress - (index * 0.02)).clamp(0.0, 1.0)); // Faster stagger
            
            // Create particles across entire screen space
            final startX = (index % 9) * screenWidth * 0.12; // 9 columns
            final startY = (index ~/ 9) * screenHeight * 0.25; // 4 rows
            
            return Positioned(
              left: startX + (particleProgress * screenWidth * 0.7) + (math.sin(particleProgress * math.pi * 3) * 60),
              top: startY + (math.cos(particleProgress * math.pi * 2) * screenHeight * 0.12),
              child: Opacity(
                opacity: (particleProgress * (1 - particleProgress) * 4).clamp(0.0, 1.0),
                child: Container(
                  width: 8, // Bigger particles for bigger cards
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index % 3 == 0 
                        ? AurennaTheme.electricViolet 
                        : index % 3 == 1 
                            ? AurennaTheme.cosmicPurple 
                            : AurennaTheme.mysticBlue,
                    boxShadow: [
                      BoxShadow(
                        color: (index % 3 == 0 
                            ? AurennaTheme.electricViolet 
                            : index % 3 == 1 
                                ? AurennaTheme.cosmicPurple 
                                : AurennaTheme.mysticBlue).withValues(alpha: 0.8),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  List<Widget> _buildAnimatedCards() {
    // Sort cards by Z-index for proper layering
    final sortedCards = List<CardAnimationData>.from(_cards);
    sortedCards.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return sortedCards.map((cardData) {
      return AnimatedBuilder(
        animation: Listenable.merge([
          _splitController,
          _riffleController,
          _bridgeController,
          _glowController,
        ]),
        builder: (context, child) {
          if (!mounted || _disposed) return const SizedBox.shrink();
          
          final position = _calculateCardPosition(cardData);
          final rotation = _calculateCardRotation(cardData);
          final scale = _calculateCardScale(cardData);
          final opacity = _calculateCardOpacity(cardData);
          final transform = _calculate3DTransform(cardData);

          // Don't render cards if they're invisible
          if (opacity <= 0.0) return const SizedBox.shrink();

          return Positioned(
            left: position.dx,
            top: position.dy,
            child: Transform(
              transform: transform,
              alignment: Alignment.center,
              child: Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: rotation,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: _buildCard(cardData),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Matrix4 _calculate3DTransform(CardAnimationData cardData) {
    if (!widget.enable3DEffects) return Matrix4.identity();
    
    final matrix = Matrix4.identity();
    
    switch (_currentPhase) {
      case ShufflePhase.split:
        final progress = _splitController.value;
        final perspective = 0.001;
        matrix.setEntry(3, 2, perspective);
        
        final rotationY = cardData.isLeftHalf ? -0.2 * progress : 0.2 * progress;
        matrix.rotateY(rotationY);
        break;
        
      case ShufflePhase.riffle:
        final progress = _riffleController.value;
        final cardProgress = ((progress - cardData.delay).clamp(0.0, 1.0));
        
        // Add slight 3D rotation during flight
        final perspective = 0.001;
        matrix.setEntry(3, 2, perspective);
        matrix.rotateX(cardProgress * 0.3 * math.sin(cardProgress * math.pi));
        break;
        
      case ShufflePhase.bridge:
        final progress = _bridgeController.value;
        final perspective = 0.001;
        matrix.setEntry(3, 2, perspective);
        
        // Bridge arch effect
        final archRotation = 0.3 * math.sin(progress * math.pi);
        matrix.rotateX(archRotation);
        break;
        
      default:
        break;
    }
    
    return matrix;
  }

  Offset _calculateCardPosition(CardAnimationData cardData) {
    // Truly random positioning from anywhere around screen perimeter
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final centerX = screenWidth * 0.5;
    final centerY = screenHeight * 0.4;
    final cardWidth = screenWidth * 0.3; // Updated to match 2x bigger cards
    
    // Generate completely random initial position around screen perimeter
    final random = math.Random(cardData.id * 12345); // Unique seed per card
    final perimeterPosition = random.nextDouble(); // 0.0 to 1.0 around perimeter
    late Offset initialPos;
    
    // Map perimeter position to actual screen coordinates
    if (perimeterPosition < 0.25) {
      // Top edge (including corners)
      final x = (perimeterPosition / 0.25) * screenWidth;
      initialPos = Offset(x, -cardWidth * 2);
    } else if (perimeterPosition < 0.5) {
      // Right edge
      final y = ((perimeterPosition - 0.25) / 0.25) * screenHeight;
      initialPos = Offset(screenWidth + cardWidth * 2, y);
    } else if (perimeterPosition < 0.75) {
      // Bottom edge
      final x = ((perimeterPosition - 0.5) / 0.25) * screenWidth;
      initialPos = Offset(x, screenHeight + cardWidth * 2);
    } else {
      // Left edge
      final y = ((perimeterPosition - 0.75) / 0.25) * screenHeight;
      initialPos = Offset(-cardWidth * 2, y);
    }
    
    // Add some extra randomness to make it even more chaotic
    final randomOffsetX = (random.nextDouble() - 0.5) * screenWidth * 0.3;
    final randomOffsetY = (random.nextDouble() - 0.5) * screenHeight * 0.3;
    initialPos = Offset(
      initialPos.dx + randomOffsetX, 
      initialPos.dy + randomOffsetY
    );
    
    switch (_currentPhase) {
      case ShufflePhase.initial:
        // Start completely off-screen in random positions
        return initialPos;

      case ShufflePhase.split:
        final progress = _splitController.value;
        final curve = Curves.easeInOutQuart.transform(progress);
        
        // Cards slowly move toward screen but still spread out
        final midwayX = initialPos.dx + ((centerX - initialPos.dx) * curve * 0.4);
        final midwayY = initialPos.dy + ((centerY - initialPos.dy) * curve * 0.4);
        
        // Add swirling motion
        final swirl = progress * math.pi * 2;
        final swirlRadius = 100 * (1 - progress);
        
        return Offset(
          midwayX + math.cos(swirl + cardData.id) * swirlRadius,
          midwayY + math.sin(swirl + cardData.id) * swirlRadius
        );

      case ShufflePhase.riffle:
        final progress = _riffleController.value;
        final cardProgress = ((progress - cardData.delay).clamp(0.0, 1.0));
        final curve = Curves.easeInOutCubic.transform(cardProgress);
        
        // Final target position in center - tighter stacking for 78 cards
        final targetX = centerX + (cardData.stackOrder * cardWidth * 0.008) - (widget.cardCount * cardWidth * 0.004);
        final targetY = centerY + (cardData.stackOrder * cardWidth * 0.006);
        
        // Create dramatic spiral trajectory
        final spiralTurns = 2.0; // Number of spirals
        final spiralAngle = cardProgress * spiralTurns * math.pi * 2;
        final spiralRadius = (1 - cardProgress) * math.min(screenWidth, screenHeight) * 0.3;
        
        // Base movement from initial to target
        final baseX = initialPos.dx + ((targetX - initialPos.dx) * curve);
        final baseY = initialPos.dy + ((targetY - initialPos.dy) * curve);
        
        // Add spiral motion
        final currentX = baseX + math.cos(spiralAngle + cardData.id) * spiralRadius;
        final currentY = baseY + math.sin(spiralAngle + cardData.id) * spiralRadius;
        
        return Offset(currentX, currentY);

      case ShufflePhase.bridge:
        final progress = _bridgeController.value;
        final springCurve = Curves.elasticOut.transform(progress);
        
        final baseX = centerX + (cardData.stackOrder * cardWidth * 0.008) - (widget.cardCount * cardWidth * 0.004);
        final baseY = centerY + (cardData.stackOrder * cardWidth * 0.006);
        
        // Final settling with elastic bounce
        final archHeight = screenHeight * 0.05 * math.sin(math.pi * (1 - springCurve));
        final currentY = baseY - archHeight;
        
        return Offset(baseX, currentY);

      case ShufflePhase.complete:
        final finalX = centerX + (cardData.stackOrder * cardWidth * 0.008) - (widget.cardCount * cardWidth * 0.004);
        final finalY = centerY + (cardData.stackOrder * cardWidth * 0.006);
        return Offset(finalX, finalY);
    }
  }

  double _calculateCardRotation(CardAnimationData cardData) {
    final random = math.Random(cardData.id * 54321);
    
    switch (_currentPhase) {
      case ShufflePhase.initial:
        return (random.nextDouble() - 0.5) * math.pi * 2; // Completely random initial rotation

      case ShufflePhase.split:
        final progress = _splitController.value;
        // Wild spinning as cards fly out
        final spinSpeed = 3.0 + (random.nextDouble() * 4.0); // Random spin speed
        final chaosRotation = progress * spinSpeed * math.pi * 2;
        return cardData.rotationVariance + chaosRotation;

      case ShufflePhase.riffle:
        final progress = _riffleController.value;
        final cardProgress = ((progress - cardData.delay).clamp(0.0, 1.0));
        
        // Intense tumbling during spiral flight
        final tumbleSpeed = 4.0 + (random.nextDouble() * 6.0);
        final tumbleRotation = cardProgress * tumbleSpeed * math.pi * 2;
        
        // Add wobble effect
        final wobble = math.sin(cardProgress * math.pi * 8) * 0.5;
        
        return cardData.rotationVariance + tumbleRotation + wobble;

      case ShufflePhase.bridge:
        final progress = _bridgeController.value;
        // Settling rotation with some final spins
        final settleRotation = (1 - progress) * math.pi;
        return cardData.rotationVariance * 0.1 + settleRotation;

      case ShufflePhase.complete:
        return cardData.rotationVariance * 0.02; // Nearly straight
    }
  }

  double _calculateCardScale(CardAnimationData cardData) {
    switch (_currentPhase) {
      case ShufflePhase.riffle:
        final progress = _riffleController.value;
        final cardProgress = ((progress - cardData.delay).clamp(0.0, 1.0));
        // Enhanced scale animation for depth perception
        return 0.9 + (0.1 * math.sin(cardProgress * math.pi));

      case ShufflePhase.bridge:
        final progress = _bridgeController.value;
        // Slight compression during bridge
        return 1.0 - (0.05 * math.sin(progress * math.pi));

      default:
        return 1.0;
    }
  }

  double _calculateCardOpacity(CardAnimationData cardData) {
    switch (_currentPhase) {
      case ShufflePhase.riffle:
        final progress = _riffleController.value;
        final cardProgress = ((progress - cardData.delay).clamp(0.0, 1.0));
        // Motion blur simulation
        if (widget.enableMotionBlur) {
          return 0.8 + (0.2 * cardProgress);
        }
        return 1.0;

      case ShufflePhase.bridge:
        final progress = _bridgeController.value;
        // Fade out quickly during bridge phase
        return (1.0 - progress).clamp(0.0, 1.0);

      case ShufflePhase.complete:
        // Completely invisible when complete
        return 0.0;

      default:
        return 1.0;
    }
  }

  Widget _buildCard(CardAnimationData cardData) {
    // Epic full-screen cards - 2x bigger and optimized for 78 cards
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.3; // 2x bigger (was 0.15, now 0.3)
    final cardHeight = cardWidth * 1.4; // Maintain tarot card aspect ratio
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        color: AurennaTheme.cosmicPurple, // Solid purple background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(2), // Small padding to prevent cutoff
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              TarotCard.coverImagePath,
              fit: BoxFit.contain, // Changed from cover to contain to prevent cutoff
              width: cardWidth - 4,
              height: cardHeight - 4,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: AurennaTheme.cosmicPurple, // Solid purple fallback
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CardAnimationData {
  final int id;
  final Offset initialPosition;
  final Offset targetPosition;
  final double rotation;
  final double rotationVariance;
  final bool isLeftHalf;
  final int stackOrder;
  final double delay;
  final int zIndex;

  CardAnimationData({
    required this.id,
    required this.initialPosition,
    required this.targetPosition,
    required this.rotation,
    required this.rotationVariance,
    required this.isLeftHalf,
    required this.stackOrder,
    required this.delay,
    required this.zIndex,
  });
}