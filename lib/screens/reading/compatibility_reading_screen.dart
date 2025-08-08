import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/reading.dart';
import '../../services/auth_service.dart';
import '../../services/tarot_service.dart';
import '../../utils/reading_messages.dart';
import '../../widgets/reading_animation_v1.dart';

class CompatibilityReadingScreen extends StatefulWidget {
  const CompatibilityReadingScreen({super.key});

  @override
  State<CompatibilityReadingScreen> createState() => _CompatibilityReadingScreenState();
}

class _CompatibilityReadingScreenState extends State<CompatibilityReadingScreen> {
  List<DrawnCard> _drawnCards = [];
  String _aiReading = '';
  bool _isComplete = false;
  String _errorMessage = '';
  int _currentStep = 0; // 0: shuffling, 1: cards revealed, 2: generating reading, 3: complete
  
  // User input
  bool _showNameInput = true;
  final _yourNameController = TextEditingController();
  final _partnerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _yourName = '';
  String _partnerName = '';
  
  // Generation message selected once per session
  String _generationMessage = '';

  @override
  void initState() {
    super.initState();
    _showNameInput = true;
    
    // Select generation message once for this session
    _generationMessage = ReadingMessages.getRandomGenerationMessage();
  }

  @override
  void dispose() {
    _yourNameController.dispose();
    _partnerNameController.dispose();
    super.dispose();
  }

  void _onShuffleComplete() {
    // Draw the 5 cards when shuffle completes
    _drawnCards = TarotService.drawFiveCards();
    setState(() {
      _currentStep = 1; // Move to revealing phase
    });
  }

  void _onCardsRevealed() async {
    if (!mounted) return;
    
    // Move to generation phase
    setState(() => _currentStep = 2);

    try {
      // Generate AI reading
      _aiReading = await TarotService.generateCompatibilityReading(
        _drawnCards,
        yourName: _yourName,
        partnerName: _partnerName,
      );

      // Save reading to database
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId != null) {
        await TarotService.saveReading(
          userId: userId,
          question: 'Love Compatibility Reading: $_yourName & $_partnerName',
          drawnCards: _drawnCards,
          aiReading: _aiReading,
          authService: authService,
        );
      }

      setState(() {
        _isComplete = true;
        _currentStep = 3; // Move to completed state
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate reading: ${e.toString()}';
      });
    }
  }

  Future<void> _startReading() async {
    // Validate and save names first
    if (_showNameInput) {
      if (!_formKey.currentState!.validate()) return;
      
      setState(() {
        _yourName = _yourNameController.text.trim();
        _partnerName = _partnerNameController.text.trim();
        _showNameInput = false;
        _currentStep = 0; // Start shuffling
      });
    }
  }

  String _getStatusText() {
    switch (_currentStep) {
      case 0:
        return '';
      case 1:
        return 'Your love cards have been revealed';
      case 2:
        return 'Aurenna is reading your romantic compatibility...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Love Compatibility Reading'),
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

    // For completed state, show reading directly
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
        statusMessage = null; // No bottom text, just radial effect
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
                _startReading();
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
                  AurennaTheme.amberGlow.withOpacity(0.3),
                  AurennaTheme.electricViolet.withOpacity(0.3),
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
                  Icons.favorite,
                  color: AurennaTheme.amberGlow,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Love Compatibility Reading',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AurennaTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '$_yourName & $_partnerName',
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
            'Your Love Spread',
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
                  color: AurennaTheme.amberGlow.withOpacity(0.3),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.favorite,
                  color: AurennaTheme.amberGlow,
                  size: 20,
                ),
              ),
              Expanded(
                child: Divider(
                  color: AurennaTheme.amberGlow.withOpacity(0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'Your Love Reading',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Reading container
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
                _buildFormattedReading(),
                const SizedBox(height: 16),
                Divider(color: AurennaTheme.silverMist.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  'Remember, love is a journey of growth and understanding. Trust in the connection you share.',
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
              '💕 May love guide your hearts 💕',
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
        // Calculate card size for 3-2 layout
        final availableWidth = constraints.maxWidth;
        final cardWidth = math.min((availableWidth - 32) / 3, 110.0); // Bigger cards
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row - 3 cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCompatibilityCard(_drawnCards[0], cardWidth),
                const SizedBox(width: 8),
                _buildCompatibilityCard(_drawnCards[1], cardWidth),
                const SizedBox(width: 8),
                _buildCompatibilityCard(_drawnCards[2], cardWidth),
              ],
            ),
            const SizedBox(height: 16),
            // Second row - 2 cards
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCompatibilityCard(_drawnCards[3], cardWidth),
                const SizedBox(width: 8),
                _buildCompatibilityCard(_drawnCards[4], cardWidth),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompatibilityCard(DrawnCard drawnCard, double cardWidth) {
    final borderColor = drawnCard.isReversed
        ? AurennaTheme.electricViolet
        : AurennaTheme.amberGlow;
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
            color: AurennaTheme.amberGlow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            drawnCard.positionName,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.amberGlow,
              fontWeight: FontWeight.w600,
              fontSize: 9,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 8),

        // Card container
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
                      AurennaTheme.amberGlow.withOpacity(0.3),
                      AurennaTheme.electricViolet.withOpacity(0.3),
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
                      Icons.favorite,
                      color: AurennaTheme.amberGlow,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Love Compatibility Reading',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AurennaTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover the cosmic connection between two souls',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AurennaTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Name inputs
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
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _partnerNameController,
                decoration: InputDecoration(
                  labelText: 'Partner\'s Name',
                  hintText: 'Enter your partner\'s name',
                  prefixIcon: Icon(
                    Icons.favorite_outline,
                    color: AurennaTheme.amberGlow,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your partner\'s name';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _startReading(),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'The cards will reveal your romantic compatibility',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AurennaTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Start button
              ElevatedButton(
                onPressed: _startReading,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('Reveal Our Connection'),
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
    // Simple text display
    return SelectableText(
      _aiReading,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: AurennaTheme.silverMist,
      ),
    );
  }
}