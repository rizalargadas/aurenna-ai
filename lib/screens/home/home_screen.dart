import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../settings/settings_screen.dart';
import '../reading/question_screen.dart';
import '../../widgets/question_counter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh question count when screen loads
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.refreshQuestionCount();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          toolbarHeight: 80,
          title: Image.asset(
            'assets/img/logo/horizontal-transparent.png',
            height: 180,
            fit: BoxFit.contain,
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top spacing
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Welcome message
              Text(
                'Welcome back, mystic soul!',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Question counter
              Center(child: QuestionCounter(showUpgradeButton: true)),

              // Flexible spacing that adapts to screen size
              Spacer(flex: isSmallScreen ? 1 : 2),

              // Main tarot card container
              Container(
                constraints: BoxConstraints(
                  maxHeight: isSmallScreen ? 280 : 320,
                  minHeight: 240,
                ),
                padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                decoration: AurennaTheme.mysticalGradientBox,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🔮',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: isSmallScreen ? 48 : 56,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text(
                      'Your tarot journey begins here',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Text(
                      'Ask a question and let the cards reveal their wisdom',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuestionScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        child: const Text('Ask the Cards'),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom flexible spacing
              Spacer(flex: isSmallScreen ? 1 : 3),

              // Bottom padding
              SizedBox(height: isSmallScreen ? 16 : 24),
            ],
          ),
        ),
      ),
    );
  }
}
