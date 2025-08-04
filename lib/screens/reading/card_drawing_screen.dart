import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/tarot_service.dart';
import '../../models/reading.dart';
import '../../models/tarot_card.dart';
import 'reading_result_screen.dart';
import '../../widgets/mystical_loading.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/advanced_card_shuffle.dart';
import '../../utils/connectivity_check.dart';
import '../../utils/platform_utils.dart';
import '../../utils/simple_connectivity.dart';

class CardDrawingScreen extends StatefulWidget {
  final String question;

  const CardDrawingScreen({super.key, required this.question});

  @override
  State<CardDrawingScreen> createState() => _CardDrawingScreenState();
}

class _CardDrawingScreenState extends State<CardDrawingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _shuffleController;
  late AnimationController _floatController;
  late AnimationController _glowController;
  bool _disposed = false;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;

  List<DrawnCard>? _drawnCards;
  bool _isDrawing = false;
  int _currentStep = 0; // 0: shuffling, 1: drawing, 2: generating reading
  bool _isRetrying = false; // Add this to track retry state

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Shuffle animation controller
    _shuffleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
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
    
    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _shuffleController, curve: Curves.easeInOut),
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

    // Start the drawing process
    _startDrawing();
  }

  @override
  void dispose() {
    _disposed = true;
    
    // Stop all repeating animations first
    _floatController.stop();
    _glowController.stop();
    
    // Reset all controllers to ensure they're in a clean state
    _animationController.reset();
    _shuffleController.reset();
    _floatController.reset();
    _glowController.reset();
    
    // Dispose all controllers
    _animationController.dispose();
    _shuffleController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    
    super.dispose();
  }

  Future<void> _startDrawing() async {
    if (!mounted || _disposed) return;
    setState(() => _isDrawing = true);

    // Start shuffling animation
    if (mounted && !_disposed) _shuffleController.forward();
    await Future.delayed(const Duration(seconds: 16)); // Even longer for 78 cards

    if (!mounted || _disposed) return;
    setState(() => _currentStep = 1);

    // Draw the cards with dramatic entrance
    _drawnCards = TarotService.drawThreeCards();
    if (mounted && !_disposed) _animationController.forward();

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted || _disposed) return;
    setState(() => _currentStep = 2);

    // Check connectivity before attempting to generate reading
    try {
      // Reset retry flag after using it
      if (_isRetrying) {
        _isRetrying = false;
      }

      // Use simple HTTP check for Android
      if (Platform.isAndroid) {
        await SimpleConnectivity.ensureInternet();
      } else {
        await ConnectivityCheck.checkConnectivityWithError();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDrawing = false);
        ErrorDialog.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          onRetry: () {
            // Mark as retrying to keep the same cards
            _isRetrying = true;
            if (mounted) {
              setState(() {
                _isDrawing = false;
              });
            }
            // Small delay before retrying
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _startDrawing();
              }
            });
          },
        );
        return;
      }
    }

    // Generate the reading
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser!.id;

      final aiReading = await TarotService.generateReading(
        widget.question,
        _drawnCards!,
      );

      // Save the reading
      await TarotService.saveReading(
        userId: userId,
        question: widget.question,
        drawnCards: _drawnCards!,
        aiReading: aiReading,
        authService: authService,
      );

      if (mounted && _drawnCards != null && aiReading.isNotEmpty) {
        // Stop animations before navigation to prevent disposal issues
        _floatController.stop();
        _glowController.stop();
        
        // Small delay to ensure animations are fully stopped
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          // Navigate to results
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReadingResultScreen(
                question: widget.question,
                drawnCards: _drawnCards!,
                reading: aiReading,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          onRetry: _startDrawing,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Full-screen animation layer
              Positioned.fill(
                child: _buildAnimatedContent(),
              ),
              
              // UI overlay at bottom
              Positioned(
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
                        // Status text
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            _getStatusText(),
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AurennaTheme.silverMist,
                              fontSize: constraints.maxHeight < 600 ? 20 : 24,
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

                        const SizedBox(height: 16),

                        // Loading indicator
                        if (_isDrawing)
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AurennaTheme.electricViolet,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedContent() {
    if (_currentStep == 0) {
      // Epic full-screen card shuffling animation with all 78 tarot cards
      return AdvancedCardShuffle(
        cardCount: 78, // Full tarot deck
        shuffleSpeed: 0.5, // Slower for more cards
        shuffleDepth: 100.0, // More dramatic depth
        rotationVariance: 20.0, // More chaotic rotation
        shuffleStyle: ShuffleStyle.bridge,
        enableHaptics: true,
        enableMotionBlur: true,
        enable3DEffects: true,
        onComplete: () {
          // Animation completed, but don't interrupt the flow
          // The main sequence will continue based on the timer
        },
      );
    } else if (_currentStep == 1 && _drawnCards != null) {
      // Three cards centered on screen with dramatic reveal
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final cardWidth = screenWidth * 0.2; // Optimal size for visibility
          final cardSpacing = screenWidth * 0.05; // Spacing between cards
          
          return Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: _drawnCards!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final drawnCard = entry.value;
                    final delay = index * 0.15;
                    final endTime = (delay + 0.5).clamp(0.0, 1.0);
                    final cardAnimation = Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          delay,
                          endTime,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    );
                    
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: cardSpacing / 2),
                      child: AnimatedBuilder(
                        animation: cardAnimation,
                        builder: (context, child) {
                          if (!mounted || _disposed) return const SizedBox.shrink();
                          
                          return Transform.scale(
                            scale: cardAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - cardAnimation.value) * 80),
                              child: Opacity(
                                opacity: cardAnimation.value.clamp(0.0, 1.0),
                                child: _buildCleanDrawnCard(drawnCard, cardWidth),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          );
        },
      );
    } else {
      // Epic cosmos-channeling animation that fills and extends beyond screen
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          
          return AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              if (!mounted || _disposed) return const SizedBox.shrink();
              
              return Stack(
                alignment: Alignment.center,
                children: [
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
                    child: const MysticalLoading(
                      message: 'Channeling the cosmos...',
                      size: 80,
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Widget _buildCardBack() {
    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          TarotCard.coverImagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient if image fails to load
            return Container(
              decoration: BoxDecoration(
                gradient: AurennaTheme.cosmicGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '✦',
                  style: TextStyle(fontSize: 32, color: AurennaTheme.silverMist),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedDrawnCard(DrawnCard drawnCard, int index) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: drawnCard.isReversed
                    ? AurennaTheme.amberGlow.withOpacity((_glowAnimation.value * 0.6).clamp(0.0, 1.0))
                    : AurennaTheme.crystalBlue.withOpacity((_glowAnimation.value * 0.6).clamp(0.0, 1.0)),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Transform.rotate(
                        angle: drawnCard.isReversed ? 3.14159 : 0,
                        child: Image.asset(
                          drawnCard.card.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: drawnCard.isReversed
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [AurennaTheme.cosmicPurple, AurennaTheme.mysticBlue],
                                      )
                                    : AurennaTheme.mysticalGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    drawnCard.card.name,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      fontSize: 12,
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
                      // Mystical particle effect overlay
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            return Stack(
                              children: List.generate(3, (particleIndex) {
                                final offset = Offset(
                                  (particleIndex * 30) + (_floatAnimation.value * 20),
                                  (particleIndex * 40) + (_floatAnimation.value * 30),
                                );
                                return Positioned(
                                  left: offset.dx % 100,
                                  top: offset.dy % 140,
                                  child: Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AurennaTheme.electricViolet.withOpacity(
                                        (_glowAnimation.value * 0.7).clamp(0.0, 1.0),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AurennaTheme.electricViolet.withOpacity(
                                            (_glowAnimation.value * 0.5).clamp(0.0, 1.0),
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                drawnCard.positionName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AurennaTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (drawnCard.isReversed) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AurennaTheme.amberGlow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AurennaTheme.amberGlow.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Reversed',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AurennaTheme.amberGlow,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawnCard(DrawnCard drawnCard) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: drawnCard.isReversed
                    ? AurennaTheme.amberGlow.withOpacity(0.4)
                    : AurennaTheme.crystalBlue.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Transform.rotate(
              angle: drawnCard.isReversed ? 3.14159 : 0, // Rotate 180 degrees if reversed
              child: Image.asset(
                drawnCard.card.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient design if image fails to load
                  return Container(
                    decoration: BoxDecoration(
                      gradient: drawnCard.isReversed
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AurennaTheme.cosmicPurple, AurennaTheme.mysticBlue],
                            )
                          : AurennaTheme.mysticalGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          drawnCard.card.name,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontSize: 12,
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
        ),
        const SizedBox(height: 8),
        Text(
          drawnCard.positionName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AurennaTheme.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        if (drawnCard.isReversed) ...[
          Text(
            '(Reversed)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.amberGlow,
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCleanDrawnCard(DrawnCard drawnCard, double cardWidth) {
    final cardHeight = cardWidth * 1.4; // Maintain aspect ratio
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              // Subtle drop shadow instead of intense glow
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Transform.rotate(
              angle: drawnCard.isReversed ? 3.14159 : 0,
              child: Image.asset(
                drawnCard.card.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: drawnCard.isReversed
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AurennaTheme.cosmicPurple, AurennaTheme.mysticBlue],
                            )
                          : AurennaTheme.mysticalGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          drawnCard.card.name,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontSize: 12,
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
        ),
        const SizedBox(height: 12),
        // Position name
        Text(
          drawnCard.positionName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AurennaTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        // Reversed indicator without extra spacing
        if (drawnCard.isReversed) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AurennaTheme.amberGlow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AurennaTheme.amberGlow.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Reversed',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AurennaTheme.amberGlow,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusText() {
    if (_isRetrying && _currentStep == 1) {
      return 'Using your previously drawn cards...';
    }

    switch (_currentStep) {
      case 0:
        return 'Shuffling the cosmic deck...';
      case 1:
        return 'Your cards have been pulled';
      case 2:
        return _isRetrying
            ? 'Reconnecting to the cosmos...'
            : 'Time for some cosmic real talk...';
      default:
        return '';
    }
  }
}
