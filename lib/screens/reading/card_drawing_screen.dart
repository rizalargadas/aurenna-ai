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
import '../../widgets/simple_card_shuffle.dart';
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
  int _currentStep = 0; // 0: shuffling, 1: cards revealed, 2: generating reading
  bool _isRetrying = false; // Add this to track retry state
  bool _shuffleStarted = false;

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
    
    // Start the drawing process after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_disposed) {
        _startDrawing();
      }
    });
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
    setState(() {
      _isDrawing = true;
      _shuffleStarted = true;
    });
  }

  void _onShuffleComplete() {
    if (!mounted || _disposed) return;
    // Draw the cards when shuffle completes
    _drawnCards = TarotService.drawThreeCards();
    setState(() {});
  }

  void _onCardsRevealed() async {
    if (!mounted || _disposed) return;
    setState(() => _currentStep = 1);
    
    // Wait a moment before starting the reading generation
    await Future.delayed(const Duration(seconds: 1));
    
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

                        // No loading indicator
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
    if (_currentStep == 0 && _shuffleStarted) {
      // Simplified card shuffling animation
      return SimpleCardShuffle(
        onShuffleComplete: _onShuffleComplete,
        onCardsRevealed: _onCardsRevealed,
        drawnCards: _drawnCards,
      );
    } else if (_currentStep == 1) {
      // Cards are still being revealed in the SimpleCardShuffle widget
      return SimpleCardShuffle(
        onShuffleComplete: _onShuffleComplete,
        onCardsRevealed: _onCardsRevealed,
        drawnCards: _drawnCards,
      );
    } else if (_currentStep == 2) {
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
    } else {
      // Default empty state before animation starts
      return const SizedBox.shrink();
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
        return _shuffleStarted ? 'Shuffling the cosmic deck...' : '';
      case 1:
        return 'Your cards have been revealed. Please wait...';
      case 2:
        return _isRetrying
            ? 'Reconnecting to the cosmos...'
            : 'Time for some cosmic real talk...';
      default:
        return '';
    }
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
