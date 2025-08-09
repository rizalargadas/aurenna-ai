import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/reading.dart';
import '../../services/auth_service.dart';
import '../../services/tarot_service.dart';
import '../../utils/reading_messages.dart';
import '../../utils/share_reading.dart';
import '../../widgets/reading_animation_v1.dart';
import '../../widgets/tarot_spread_grid.dart';

class CareerReadingScreen extends StatefulWidget {
  const CareerReadingScreen({super.key});

  @override
  State<CareerReadingScreen> createState() => _CareerReadingScreenState();
}

class _CareerReadingScreenState extends State<CareerReadingScreen> {
  List<DrawnCard> _drawnCards = [];
  String _aiReading = '';
  bool _isComplete = false;
  String _errorMessage = '';
  int _currentStep = 0; // 0: shuffling, 1: cards revealed, 2: generating reading, 3: complete
  
  // User input
  bool _showInfoInput = true;
  final _nameController = TextEditingController();
  final _currentJobController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _currentJob = '';
  
  // Generation message selected once per session
  String _generationMessage = '';

  @override
  void initState() {
    super.initState();
    _showInfoInput = true;
    
    // Select generation message once for this session
    _generationMessage = ReadingMessages.getRandomGenerationMessage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentJobController.dispose();
    super.dispose();
  }

  void _onShuffleComplete() {
    // Draw the 5 cards when shuffle completes
    _drawnCards = TarotService.drawFiveCardsForCareer();
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
      _aiReading = await TarotService.generateCareerReading(
        _drawnCards,
        name: _name,
        currentJob: _currentJob,
      );

      // Save reading to database
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;
      
      if (userId != null) {
        await TarotService.saveReading(
          userId: userId,
          question: 'Career Guidance for $_name',
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
    // Validate and save info first
    if (_showInfoInput) {
      if (!_formKey.currentState!.validate()) return;
      
      setState(() {
        _name = _nameController.text.trim();
        _currentJob = _currentJobController.text.trim();
        _showInfoInput = false;
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
        title: const Text('Career Reading'),
        actions: [
          if (_isComplete)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                try {
                  await ShareReading.shareCareerReading(
                    name: _name,
                    currentJob: _currentJob,
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
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }
    
    if (_showInfoInput) {
      return _buildInfoInputScreen();
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
                  AurennaTheme.crystalBlue.withValues(alpha: 0.3),
                  AurennaTheme.electricViolet.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AurennaTheme.crystalBlue.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.work_outline,
                  color: AurennaTheme.crystalBlue,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Career Reading',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AurennaTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _name.isNotEmpty ? 'For $_name' : 'Professional Guidance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AurennaTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_currentJob.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _currentJob,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AurennaTheme.textSecondary.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Your Career Reading',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Card grid container
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
            child: TarotSpreadGrid(
              cards: _drawnCards,
              crossAxisCount: 3, // 5 cards in flexible layout
              minCardWidth: 90,
              maxCardWidth: 130,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AurennaTheme.crystalBlue.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.work,
                  color: AurennaTheme.crystalBlue,
                  size: 20,
                ),
              ),
              Expanded(
                child: Divider(
                  color: AurennaTheme.crystalBlue.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            'Your Career Truth Bomb',
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
                  'Your career is in your hands. The cards show possibilities, but your actions create reality.',
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
              '💼 May success follow your path 💼',
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

  Widget _buildInfoInputScreen() {
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
                      AurennaTheme.crystalBlue.withValues(alpha: 0.3),
                      AurennaTheme.electricViolet.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AurennaTheme.crystalBlue.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: AurennaTheme.crystalBlue,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Career Reading',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AurennaTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get brutally honest guidance about your professional path',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AurennaTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Name input
              TextFormField(
                controller: _nameController,
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
              
              // Current job input
              TextFormField(
                controller: _currentJobController,
                decoration: InputDecoration(
                  labelText: 'Current Role (Optional)',
                  hintText: 'e.g. Software Engineer, Teacher, Student',
                  prefixIcon: Icon(
                    Icons.work_outline,
                    color: AurennaTheme.electricViolet,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onFieldSubmitted: (_) => _startReading(),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'The cards will reveal your professional truth',
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
                child: const Text('Get Career Guidance'),
              ),
            ],
          ),
        ),
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