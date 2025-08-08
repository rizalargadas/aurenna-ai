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

class RealisticCardShuffle extends StatefulWidget {
  final int cardCount;
  final double shuffleSpeed;
  final double shuffleDepth;
  final double rotationVariance;
  final ShuffleStyle shuffleStyle;
  final VoidCallback? onComplete;
  final bool enableHaptics;
  final bool enableSounds;

  const RealisticCardShuffle({
    super.key,
    this.cardCount = 8,
    this.shuffleSpeed = 1.0,
    this.shuffleDepth = 30.0,
    this.rotationVariance = 6.0,
    this.shuffleStyle = ShuffleStyle.riffle,
    this.onComplete,
    this.enableHaptics = true,
    this.enableSounds = false,
  });

  @override
  State<RealisticCardShuffle> createState() => _RealisticCardShuffleState();
}

class _RealisticCardShuffleState extends State<RealisticCardShuffle>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _splitController;
  late AnimationController _riffleController;
  late AnimationController _bridgeController;

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
    
    _splitDuration = Duration(milliseconds: (800 * speedMultiplier).round());
    _riffleDuration = Duration(milliseconds: (1200 * speedMultiplier).round());
    _bridgeDuration = Duration(milliseconds: (600 * speedMultiplier).round());

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
        stackOrder: index,
        delay: index * 0.05, // 50ms delay between cards
      );
    });
  }

  Future<void> _startShuffleSequence() async {
    if (_disposed) return;

    // Phase 1: Split
    setState(() => _currentPhase = ShufflePhase.split);
    _splitController.forward();
    await Future.delayed(_splitDuration);

    if (_disposed) return;

    // Phase 2: Riffle
    setState(() => _currentPhase = ShufflePhase.riffle);
    _riffleController.forward();
    await Future.delayed(_riffleDuration);

    if (_disposed) return;

    // Phase 3: Bridge (if style includes bridge)
    if (widget.shuffleStyle == ShuffleStyle.bridge) {
      setState(() => _currentPhase = ShufflePhase.bridge);
      _bridgeController.forward();
      await Future.delayed(_bridgeDuration);
    }

    if (_disposed) return;

    // Complete
    setState(() => _currentPhase = ShufflePhase.complete);
    
    // Haptic feedback
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }

    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    _mainController.dispose();
    _splitController.dispose();
    _riffleController.dispose();
    _bridgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate sizes based on screen dimensions - 75% of mobile screen
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final animationWidth = screenWidth * 0.9; // 90% of screen width
    final animationHeight = screenHeight * 0.4; // 40% of screen height for better proportion
    
    return SizedBox(
      width: animationWidth,
      height: animationHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow effect
          _buildBackgroundGlow(),
          
          // Animated cards
          ..._buildAnimatedCards(),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return Container(
          width: screenWidth * 0.6, // Larger background
          height: screenHeight * 0.25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AurennaTheme.electricViolet.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildAnimatedCards() {
    return _cards.map((cardData) {
      return AnimatedBuilder(
        animation: Listenable.merge([
          _splitController,
          _riffleController,
          _bridgeController,
        ]),
        builder: (context, child) {
          final position = _calculateCardPosition(cardData);
          final rotation = _calculateCardRotation(cardData);
          final scale = _calculateCardScale(cardData);
          final opacity = _calculateCardOpacity(cardData);

          return Positioned(
            left: position.dx,
            top: position.dy,
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
          );
        },
      );
    }).toList();
  }

  Offset _calculateCardPosition(CardAnimationData cardData) {
    // Calculate positions based on screen size and larger cards
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final centerX = screenWidth * 0.45; // Center position
    final centerY = screenHeight * 0.2; // Center position
    final cardWidth = screenWidth * 0.18;
    
    switch (_currentPhase) {
      case ShufflePhase.initial:
        return Offset(centerX + (cardData.id * cardWidth * 0.05), centerY + (cardData.id * cardWidth * 0.03));

      case ShufflePhase.split:
        final progress = _splitController.value;
        final curve = Curves.easeInOutBack.transform(progress);
        final separation = screenWidth * 0.22; // Larger separation for bigger cards
        final baseX = cardData.isLeftHalf ? centerX - separation : centerX + separation;
        final currentX = centerX + ((baseX - centerX) * curve);
        final currentY = centerY - (widget.shuffleDepth * curve) + (cardData.id * cardWidth * 0.03);
        return Offset(currentX + (cardData.id * cardWidth * 0.05), currentY);

      case ShufflePhase.riffle:
        final progress = _riffleController.value;
        final cardProgress = ((progress - cardData.delay).clamp(0.0, 1.0));
        final curve = Curves.easeInOutSine.transform(cardProgress);
        
        // Create interleaving effect scaled for larger cards
        final targetX = centerX + (cardData.stackOrder % 2) * cardWidth * 0.04;
        final targetY = centerY + (cardData.stackOrder * cardWidth * 0.06);
        
        // Arc trajectory scaled for screen size
        final startX = cardData.isLeftHalf ? centerX - screenWidth * 0.22 : centerX + screenWidth * 0.22;
        final startY = centerY - widget.shuffleDepth;
        
        final arcHeight = screenHeight * 0.05 * math.sin(curve * math.pi);
        final currentX = startX + ((targetX - startX) * curve);
        final currentY = startY + ((targetY - startY) * curve) - arcHeight;
        
        return Offset(currentX, currentY);

      case ShufflePhase.bridge:
        final progress = _bridgeController.value;
        final curve = Curves.elasticOut.transform(progress);
        final bridgeHeight = screenHeight * 0.04 * (1 - curve);
        return Offset(centerX + (cardData.stackOrder * cardWidth * 0.04), centerY - bridgeHeight);

      case ShufflePhase.complete:
        return Offset(centerX + (cardData.stackOrder * cardWidth * 0.04), centerY);
    }
  }

  double _calculateCardRotation(CardAnimationData cardData) {
    switch (_currentPhase) {
      case ShufflePhase.initial:
        return cardData.rotationVariance * 0.3;

      case ShufflePhase.split:
        final progress = _splitController.value;
        final splitRotation = cardData.isLeftHalf ? -0.1 : 0.1;
        return (cardData.rotationVariance * 0.3) + (splitRotation * progress);

      case ShufflePhase.riffle:
        final progress = _riffleController.value;
        final cardProgress = ((progress - cardData.delay).clamp(0.0, 1.0));
        final rotationCurve = Curves.easeInOutQuad.transform(cardProgress);
        
        // Add dynamic rotation during riffle
        final riffleRotation = cardData.rotationVariance * (1 - rotationCurve);
        return riffleRotation;

      case ShufflePhase.bridge:
        final progress = _bridgeController.value;
        final bridgeRotation = cardData.rotationVariance * 0.2 * (1 - progress);
        return bridgeRotation;

      case ShufflePhase.complete:
        return cardData.rotationVariance * 0.1;
    }
  }

  double _calculateCardScale(CardAnimationData cardData) {
    switch (_currentPhase) {
      case ShufflePhase.riffle:
        final progress = _riffleController.value;
        final cardProgress = ((progress - cardData.delay).clamp(0.0, 1.0));
        // Slight scale animation during riffle for depth
        return 0.95 + (0.05 * math.sin(cardProgress * math.pi));

      default:
        return 1.0;
    }
  }

  double _calculateCardOpacity(CardAnimationData cardData) {
    switch (_currentPhase) {
      case ShufflePhase.riffle:
        final progress = _riffleController.value;
        final cardProgress = ((progress - cardData.delay).clamp(0.0, 1.0));
        // Slight opacity variation for depth
        return 0.9 + (0.1 * cardProgress);

      default:
        return 1.0;
    }
  }

  Widget _buildCard(CardAnimationData cardData) {
    // Make cards much larger - 75% of mobile screen space
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.18; // Each card takes ~18% of screen width
    final cardHeight = cardWidth * 1.4; // Maintain tarot card aspect ratio
    
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8), // Larger border radius for bigger cards
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12, // Larger shadow for bigger cards
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          TarotCard.coverImagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AurennaTheme.electricViolet,
                    AurennaTheme.cosmicPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  '✦',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
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

  CardAnimationData({
    required this.id,
    required this.initialPosition,
    required this.targetPosition,
    required this.rotation,
    required this.rotationVariance,
    required this.isLeftHalf,
    required this.stackOrder,
    required this.delay,
  });
}