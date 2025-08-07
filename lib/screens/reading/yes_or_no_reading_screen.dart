import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/reading.dart';
import '../../models/tarot_card.dart';
import '../../services/auth_service.dart';
import '../../services/tarot_service.dart';
import '../../widgets/mystical_loading.dart';
import '../../widgets/reading_animation_v1.dart';

class YesOrNoReadingScreen extends StatefulWidget {
  const YesOrNoReadingScreen({super.key});

  @override
  State<YesOrNoReadingScreen> createState() => _YesOrNoReadingScreenState();
}

class _YesOrNoReadingScreenState extends State<YesOrNoReadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _glowController;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  bool _disposed = false;

  List<DrawnCard> _drawnCards = [];
  String _aiReading = '';
  bool _isGenerating = false;
  bool _isComplete = false;
  String _errorMessage = '';
  int _currentStep = 0; // 0: input, 1: shuffling, 2: generating, 3: complete
  
  // User input
  bool _showQuestionInput = true;
  final _questionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _question = '';

  @override
  void initState() {
    super.initState();
    
    _showQuestionInput = true;
    
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _floatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (!_disposed) {
      _floatController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }

  void _onShuffleComplete() {
    if (_disposed || !mounted) return;
    
    // Draw 3 cards for Yes/No reading
    _drawnCards = TarotService.drawThreeCardsForYesOrNo();
    
    setState(() {
      _currentStep = 2; // Move to generating phase
    });
    
    // Start generating reading after a brief pause
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_disposed) {
        _generateReading();
      }
    });
  }

  Future<void> _generateReading() async {
    if (_disposed || !mounted) return;
    
    setState(() {
      _isGenerating = true;
      _errorMessage = '';
      _currentStep = 2;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isPremium = await authService.hasActiveSubscription();
      
      if (!isPremium) {
        throw Exception('Premium subscription required');
      }

      // Draw 3 cards for Yes/No reading
      _drawnCards = TarotService.drawThreeCardsForYesOrNo();
      
      // Get AI reading for Yes/No question
      final reading = await TarotService.generateYesOrNoReading(
        _drawnCards,
        question: _question,
      );
      
      if (!_disposed && mounted) {
        setState(() {
          _aiReading = reading;
          _isGenerating = false;
          _isComplete = true;
          _currentStep = 3; // Move to complete phase
        });
        
        // Save reading to history
        final userId = authService.currentUser?.id;
        if (userId != null) {
          await TarotService.saveReading(
            userId: userId,
            question: 'Yes or No: $_question',
            drawnCards: _drawnCards,
            aiReading: reading,
            authService: authService,
          );
        }
      }
    } catch (e) {
      if (!_disposed && mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isGenerating = false;
        });
      }
    }
  }

  void _submitQuestion() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _question = _questionController.text.trim();
        _showQuestionInput = false;
        _currentStep = 1; // Start shuffling
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _floatController.dispose();
    _glowController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AurennaTheme.voidBlack,
              AurennaTheme.mysticBlue.withOpacity(0.3),
              const Color(0xFF1A1B3A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background elements
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _floatAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: MysticalBackgroundPainter(
                        animationValue: _floatAnimation.value,
                        glowValue: _glowAnimation.value,
                      ),
                    );
                  },
                ),
              ),
              
              // Main content
              if (_showQuestionInput)
                _buildQuestionInput()
              else if (_currentStep == 3 && _isComplete)
                _buildReadingResult()
              else
                _buildAnimationPhase(),
              
              // Back button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: AurennaTheme.amberGlow.withOpacity(0.8),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                '✨ Yes or No Reading ✨',
                style: TextStyle(color: AurennaTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Ask your burning question',
                style: TextStyle(color: AurennaTheme.textSecondary).copyWith(
                  fontSize: 16,
                  color: AurennaTheme.stardustPurple.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Question input
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _questionController,
                      maxLines: 3,
                      style: TextStyle(color: AurennaTheme.textSecondary),
                      decoration: InputDecoration(
                        labelText: 'Your Question',
                        hintText: 'What decision weighs on your mind?',
                        hintStyle: TextStyle(
                          color: AurennaTheme.textPrimary.withOpacity(0.4),
                        ),
                        labelStyle: TextStyle(
                          color: AurennaTheme.amberGlow,
                        ),
                        filled: true,
                        fillColor: AurennaTheme.mysticBlue.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AurennaTheme.amberGlow.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AurennaTheme.amberGlow.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AurennaTheme.amberGlow,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your question';
                        }
                        if (value.trim().length < 10) {
                          return 'Please provide more detail in your question';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    
                    // Submit button
                    ElevatedButton(
                      onPressed: _submitQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AurennaTheme.amberGlow,
                        foregroundColor: AurennaTheme.voidBlack,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: AurennaTheme.amberGlow.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ask the Cards',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
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
        ),
      ),
    );
  }

  Widget _buildAnimationPhase() {
    // Use the reusable animation widget
    ReadingAnimationPhase phase;
    String? statusMessage;
    
    switch (_currentStep) {
      case 1:
        phase = ReadingAnimationPhase.shuffling;
        statusMessage = 'The cards are revealing your answer...';
        break;
      case 2:
        phase = ReadingAnimationPhase.generating;
        statusMessage = 'Aurenna is divining your cosmic verdict...';
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
      onShuffleComplete: () {
        if (mounted && !_disposed) {
          // Draw 3 cards for Yes/No reading
          _drawnCards = TarotService.drawThreeCardsForYesOrNo();
          setState(() {
            _currentStep = 2; // Move to generating phase
          });
          
          // Start generating reading after a brief pause
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_disposed) {
              _generateReading();
            }
          });
        }
      },
      onCardsRevealed: () {
        // This callback is not used for Yes/No reading since we move to generating immediately
      },
    );
  }


  Widget _buildReadingResult() {
    return AnimatedOpacity(
      opacity: _isComplete ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 800),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            
            // Title with question
            Center(
              child: Column(
                children: [
                  Text(
                    '🔮 Your Answer 🔮',
                    style: TextStyle(color: AurennaTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold).copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AurennaTheme.mysticBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AurennaTheme.amberGlow.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '"$_question"',
                      style: TextStyle(color: AurennaTheme.textSecondary).copyWith(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: AurennaTheme.stardustPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Cards drawn
            if (_drawnCards.isNotEmpty) ...[
              Center(
                child: Text(
                  'Your Cards',
                  style: TextStyle(color: AurennaTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold).copyWith(
                    fontSize: 20,
                    color: AurennaTheme.amberGlow,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _drawnCards.map((card) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Real tarot card image
                          Container(
                            width: 100,
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AurennaTheme.amberGlow.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: card.isReversed 
                                  ? (Matrix4.identity()..rotateZ(math.pi))
                                  : Matrix4.identity(),
                                child: Image.asset(
                                  'assets/img/cards/${card.card.id}.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback to cover image if specific card not found
                                    return Image.asset(
                                      'assets/img/cards/cover.png',
                                      fit: BoxFit.contain,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Card name and orientation
                          SizedBox(
                            width: 100,
                            child: Column(
                              children: [
                                Text(
                                  card.card.name,
                                  style: TextStyle(
                                    color: AurennaTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  card.isReversed ? 'Reversed' : 'Upright',
                                  style: TextStyle(
                                    color: card.isReversed 
                                      ? Colors.redAccent
                                      : AurennaTheme.stardustPurple,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],
            
            // AI Reading
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AurennaTheme.mysticBlue.withOpacity(0.5),
                    AurennaTheme.mysticBlue.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AurennaTheme.amberGlow.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AurennaTheme.amberGlow.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AurennaTheme.amberGlow,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Aurenna\'s Divine Verdict',
                        style: TextStyle(color: AurennaTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold).copyWith(
                          fontSize: 18,
                          color: AurennaTheme.amberGlow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _aiReading,
                    style: TextStyle(color: AurennaTheme.textSecondary).copyWith(
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/yes-or-no-reading');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ask Another Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AurennaTheme.amberGlow,
                    foregroundColor: AurennaTheme.voidBlack,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AurennaTheme.amberGlow,
                    side: BorderSide(color: AurennaTheme.amberGlow),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}


// Custom painter for mystical background
class MysticalBackgroundPainter extends CustomPainter {
  final double animationValue;
  final double glowValue;

  MysticalBackgroundPainter({
    required this.animationValue,
    required this.glowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 50);

    // Floating orbs
    paint.color = AurennaTheme.amberGlow.withOpacity(0.1 * glowValue);
    canvas.drawCircle(
      Offset(
        size.width * 0.2,
        size.height * 0.3 + (animationValue * 30),
      ),
      80,
      paint,
    );

    paint.color = AurennaTheme.stardustPurple.withOpacity(0.08 * glowValue);
    canvas.drawCircle(
      Offset(
        size.width * 0.8,
        size.height * 0.6 - (animationValue * 25),
      ),
      100,
      paint,
    );

    paint.color = const Color(0xFF9C27B0).withOpacity(0.06 * glowValue);
    canvas.drawCircle(
      Offset(
        size.width * 0.5,
        size.height * 0.8 + (animationValue * 20),
      ),
      90,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}