import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'card_drawing_screen.dart';
import '../../widgets/question_counter.dart';
import '../../widgets/error_dialog.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final _questionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      final hasQuestions = await authService.getFreeQuestionsRemaining() > 0;
      final hasSubscription = await authService.hasActiveSubscription();

      if (!hasQuestions && !hasSubscription) {
        if (mounted) {
          ErrorDialog.show(
            context,
            'You have no free questions remaining.',
            onRetry: null,
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CardDrawingScreen(question: _questionController.text.trim()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AurennaTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask the Cards')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mystical header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AurennaTheme.mysticalGradientBox,
                child: Column(
                  children: [
                    const Text('🔮', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      'What guidance do you seek?',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Focus your mind and ask your question',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Question form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _questionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Your Question',
                        hintText:
                            'What would you like to know about your journey?',
                        alignLabelWithHint: true,
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

                    const SizedBox(height: 24),

                    // Tips section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AurennaTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: AurennaTheme.crystalBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tips for meaningful questions:',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTip(
                            '• Be specific about what you want to know',
                          ),
                          _buildTip('• Focus on yourself, not others'),
                          _buildTip('• Ask what feels right for you'),
                          _buildTip('• Trust your intuition with the answer'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitQuestion,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Draw My Cards'),
                    ),

                    const SizedBox(height: 32),

                    Center(child: QuestionCounter(showUpgradeButton: true)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AurennaTheme.textSecondary),
      ),
    );
  }
}
