import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/tarot_service.dart';
import '../../models/reading.dart';
import 'reading_result_screen.dart';
import '../../widgets/mystical_loading.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/simple_card_shuffle.dart';
import '../../utils/connectivity_check.dart';
import '../../utils/reading_messages.dart';
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
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;

  List<DrawnCard>? _drawnCards;
  int _currentStep = 0; // 0: shuffling, 1: cards revealed, 2: generating reading
  bool _isRetrying = false; // Add this to track retry state
  bool _shuffleStarted = false;
  
  // Random messages selected once per session
  String _cardRevealMessage = '';
  String _generationMessage = '';

  @override
  void initState() {
    super.initState();
    
    // Select random messages once for this session
    _cardRevealMessage = ReadingMessages.getRandomCardRevealMessage();
    _generationMessage = ReadingMessages.getRandomGenerationMessage();
    
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
        ErrorDialog.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          onRetry: () {
            // Mark as retrying to keep the same cards
            _isRetrying = true;
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
                          AurennaTheme.voidBlack.withValues(alpha: 0.9),
                          AurennaTheme.voidBlack.withValues(alpha: 0.7),
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
                                  color: Colors.black.withValues(alpha: 0.8),
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
        revealMessage: _cardRevealMessage,
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
                          AurennaTheme.electricViolet.withValues(alpha: (_glowAnimation.value * 0.4).clamp(0.0, 1.0)),
                          AurennaTheme.cosmicPurple.withValues(alpha: (_glowAnimation.value * 0.35).clamp(0.0, 1.0)),
                          AurennaTheme.mysticBlue.withValues(alpha: (_glowAnimation.value * 0.25).clamp(0.0, 1.0)),
                          AurennaTheme.crystalBlue.withValues(alpha: (_glowAnimation.value * 0.15).clamp(0.0, 1.0)),
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
                          AurennaTheme.electricViolet.withValues(alpha: (_glowAnimation.value * 0.3).clamp(0.0, 1.0)),
                          AurennaTheme.amberGlow.withValues(alpha: (_glowAnimation.value * 0.2).clamp(0.0, 1.0)),
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
                          color: AurennaTheme.electricViolet.withValues(alpha: (_glowAnimation.value * 0.8).clamp(0.0, 1.0)),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                        BoxShadow(
                          color: AurennaTheme.cosmicPurple.withValues(alpha: (_glowAnimation.value * 0.6).clamp(0.0, 1.0)),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: MysticalLoading(
                      message: _generationMessage.isNotEmpty ? _generationMessage : 'Channeling universal wisdom...',
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





  String _getStatusText() {
    if (_isRetrying && _currentStep == 1) {
      return 'Using your previously drawn cards...';
    }

    switch (_currentStep) {
      case 0:
        return _shuffleStarted ? 'Shuffling the cosmic deck...' : '';
      case 1:
        return _cardRevealMessage.isNotEmpty ? _cardRevealMessage : 'Your cards have been revealed...';
      case 2:
        return _isRetrying
            ? 'Reconnecting to the cosmos...'
            : (_generationMessage.isNotEmpty ? _generationMessage : 'Channeling universal wisdom...');
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
