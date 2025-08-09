import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/reading.dart';
import '../../services/auth_service.dart';
import '../../services/tarot_service.dart';
import '../../utils/reading_messages.dart';
import '../../utils/share_reading.dart';
import '../../widgets/reading_animation_v1.dart';

class RelationshipDecisionScreen extends StatefulWidget {
  const RelationshipDecisionScreen({super.key});

  @override
  State<RelationshipDecisionScreen> createState() =>
      _RelationshipDecisionScreenState();
}

class _RelationshipDecisionScreenState
    extends State<RelationshipDecisionScreen> {
  List<DrawnCard> _drawnCards = [];
  String _aiReading = '';
  bool _isComplete = false;
  String _errorMessage = '';
  int _currentStep =
      0; // 0: shuffling, 1: cards revealed, 2: generating reading, 3: complete

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
    _generationMessage = ReadingMessages.getRandomGenerationMessage();
  }

  @override
  void dispose() {
    _yourNameController.dispose();
    _partnerNameController.dispose();
    super.dispose();
  }

  void _onShuffleComplete() {
    _drawnCards = TarotService.drawFourCardsForDecision();
    setState(() {
      _currentStep = 1;
    });
  }

  void _onCardsRevealed() async {
    if (!mounted) return;

    setState(() => _currentStep = 2);

    try {
      _aiReading = await TarotService.generateRelationshipDecisionReading(
        _drawnCards,
        yourName: _yourName,
        partnerName: _partnerName,
      );

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;

      if (userId != null) {
        await TarotService.saveReading(
          userId: userId,
          question: 'Relationship Decision: $_yourName & $_partnerName',
          drawnCards: _drawnCards,
          aiReading: _aiReading,
          authService: authService,
        );
      }

      setState(() {
        _isComplete = true;
        _currentStep = 3;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate reading: ${e.toString()}';
      });
    }
  }

  Future<void> _startReading() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Relationship Decision'),
        actions: [
          if (_isComplete)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                try {
                  await ShareReading.shareRelationshipDecisionReading(
                    person1: _yourName,
                    person2: _partnerName,
                    drawnCards: _drawnCards,
                    reading: _aiReading,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AurennaTheme.crystalBlue,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_showNameInput) {
      return _buildNameInputScreen();
    }

    if (_currentStep == 3 || _isComplete) {
      return _buildCompleteReading();
    }

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
        statusMessage = null;
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
              color: AurennaTheme.electricViolet.withValues(alpha: 0.5),
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
                  AurennaTheme.amberGlow.withValues(alpha: 0.3),
                  AurennaTheme.electricViolet.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AurennaTheme.amberGlow.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_outline,
                  color: AurennaTheme.amberGlow,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Relationship Decision',
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
            'Your Decision Reading',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Soft grouping container for the 2x2 grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AurennaTheme.mysticBlue.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AurennaTheme.silverMist.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: _buildCardGrid(),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AurennaTheme.amberGlow.withValues(alpha: 0.3),
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
                  color: AurennaTheme.amberGlow.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'Your Relationship Verdict',
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
                color: AurennaTheme.silverMist.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AurennaTheme.silverMist.withValues(alpha: 0.05),
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
                Divider(color: AurennaTheme.silverMist.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text(
                  'Trust your intuition. The cards have spoken, but the decision is yours.',
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
              '💕 May clarity guide your heart 💕',
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

  // ---------- UPDATED GRID (spacing + clamping + aspect) ----------
  Widget _buildCardGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;

        final w = constraints.maxWidth;
        final gutterX = w >= 360 ? 16.0 : 12.0;
        final gutterY = gutterX * 0.75; // tighter vertical rhythm

        final rawWidth = (w - (crossAxisCount - 1) * gutterX) / crossAxisCount;
        final cardWidth = rawWidth.clamp(120.0, 156.0);

        final cardHeight = cardWidth * 1.4;

        const chipHeight = 18.0;
        const titleHeight = 32.0; // up to 2 lines
        const vSpace = 8.0;

        final totalItemHeight =
            chipHeight + vSpace + cardHeight + vSpace + titleHeight;
        final aspectRatio = cardWidth / totalItemHeight;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gutterX / 2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: gutterX,
              mainAxisSpacing: gutterY,
              childAspectRatio: aspectRatio,
            ),
            itemCount: _drawnCards.length,
            itemBuilder: (context, index) {
              return _buildDecisionCard(_drawnCards[index], cardWidth);
            },
          ),
        );
      },
    );
  }

  // ---------- UPDATED CARD (rhythm + legibility) ----------
  Widget _buildDecisionCard(DrawnCard drawnCard, double cardWidth) {
    final borderColor = drawnCard.isReversed
        ? AurennaTheme.electricViolet
        : AurennaTheme.amberGlow;
    final cardHeight = cardWidth * 1.4;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Position chip
        Container(
          width: cardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AurennaTheme.amberGlow.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            drawnCard.positionName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.amberGlow,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.1,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Card image panel
        Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Center(
                          child: Text(
                            drawnCard.card.name,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AurennaTheme.textPrimary,
                                ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (drawnCard.isReversed)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AurennaTheme.electricViolet.withValues(
                          alpha: 0.92,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'R',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Card title
        SizedBox(
          width: cardWidth,
          child: Text(
            drawnCard.card.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AurennaTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
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
              // Mystical header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AurennaTheme.amberGlow.withValues(alpha: 0.3),
                      AurennaTheme.electricViolet.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AurennaTheme.amberGlow.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      color: AurennaTheme.amberGlow,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Relationship Decision',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AurennaTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let the cards guide your heart\'s biggest decision',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AurennaTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              TextFormField(
                controller: _yourNameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AurennaTheme.amberGlow,
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
                  hintText: 'Enter their name',
                  prefixIcon: Icon(
                    Icons.favorite_outline,
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
                onFieldSubmitted: (_) => _startReading(),
              ),

              const SizedBox(height: 16),

              Text(
                'The cards will reveal whether to stay or go',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AurennaTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _startReading,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('Get My Answer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedReading() {
    return SelectableText(
      _aiReading,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: AurennaTheme.silverMist,
      ),
    );
  }
}
