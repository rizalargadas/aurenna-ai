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
        child: SingleChildScrollView(
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

                // Spacing before cards - less on small screens
                SizedBox(height: isSmallScreen ? 24 : 32),

                // Reading options
                Column(
                  children: [
                  // Three-Card Reading
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                    decoration: AurennaTheme.mysticalGradientBox,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🔮',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontSize: isSmallScreen ? 36 : 42,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Text(
                          'Three-Card Reading',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          'Ask a question and let the cards reveal their wisdom',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 20),
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
                                vertical: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            child: const Text('Ask the Cards'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // General Reading (Premium)
                  FutureBuilder<bool>(
                    future: authService.hasActiveSubscription(),
                    builder: (context, snapshot) {
                      final hasSubscription = snapshot.data ?? false;
                      
                      return Container(
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: hasSubscription 
                                ? [
                                    AurennaTheme.electricViolet.withOpacity(0.2),
                                    AurennaTheme.cosmicPurple.withOpacity(0.2),
                                  ]
                                : [
                                    AurennaTheme.mysticBlue.withOpacity(0.1),
                                    AurennaTheme.voidBlack.withOpacity(0.1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasSubscription 
                                ? AurennaTheme.electricViolet.withOpacity(0.5)
                                : AurennaTheme.silverMist.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '✨',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontSize: isSmallScreen ? 36 : 42,
                                  ),
                                ),
                                if (!hasSubscription) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, 
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AurennaTheme.amberGlow.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'PREMIUM',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AurennaTheme.amberGlow,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'Comprehensive General Reading',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: hasSubscription 
                                    ? AurennaTheme.textPrimary
                                    : AurennaTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              hasSubscription 
                                  ? '12 cards revealing all aspects of your life'
                                  : 'Unlock a complete view of your cosmic energy',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: hasSubscription 
                                    ? AurennaTheme.textSecondary
                                    : AurennaTheme.textSecondary.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            SizedBox(
                              width: double.infinity,
                              child: hasSubscription 
                                  ? ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/general-reading');
                                      },
                                      icon: const Icon(Icons.auto_awesome, size: 20),
                                      label: const Text('Begin General Reading'),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 14,
                                        ),
                                        backgroundColor: AurennaTheme.electricViolet,
                                        foregroundColor: Colors.white,
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/premium-upgrade');
                                      },
                                      icon: const Icon(Icons.lock, size: 18),
                                      label: const Text('Upgrade to Unlock'),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 14,
                                        ),
                                        side: BorderSide(
                                          color: AurennaTheme.amberGlow.withOpacity(0.5),
                                        ),
                                        foregroundColor: AurennaTheme.amberGlow,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Compatibility Reading (Premium)
                  FutureBuilder<bool>(
                    future: authService.hasActiveSubscription(),
                    builder: (context, snapshot) {
                      final hasSubscription = snapshot.data ?? false;
                      
                      return Container(
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: hasSubscription 
                                ? [
                                    AurennaTheme.amberGlow.withOpacity(0.2),
                                    AurennaTheme.electricViolet.withOpacity(0.2),
                                  ]
                                : [
                                    AurennaTheme.mysticBlue.withOpacity(0.1),
                                    AurennaTheme.voidBlack.withOpacity(0.1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasSubscription 
                                ? AurennaTheme.amberGlow.withOpacity(0.5)
                                : AurennaTheme.silverMist.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '💕',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontSize: isSmallScreen ? 36 : 42,
                                  ),
                                ),
                                if (!hasSubscription) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, 
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AurennaTheme.amberGlow.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'PREMIUM',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AurennaTheme.amberGlow,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'Love Compatibility Reading',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: hasSubscription 
                                    ? AurennaTheme.textPrimary
                                    : AurennaTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              hasSubscription 
                                  ? 'Discover the cosmic connection between two souls'
                                  : 'Unlock deep insights into your romantic compatibility',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: hasSubscription 
                                    ? AurennaTheme.textSecondary
                                    : AurennaTheme.textSecondary.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            SizedBox(
                              width: double.infinity,
                              child: hasSubscription 
                                  ? ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/compatibility-reading');
                                      },
                                      icon: const Icon(Icons.favorite, size: 20),
                                      label: const Text('Begin Compatibility Reading'),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 14,
                                        ),
                                        backgroundColor: AurennaTheme.amberGlow,
                                        foregroundColor: AurennaTheme.voidBlack,
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/premium-upgrade');
                                      },
                                      icon: const Icon(Icons.lock, size: 18),
                                      label: const Text('Upgrade to Unlock'),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 14,
                                        ),
                                        side: BorderSide(
                                          color: AurennaTheme.amberGlow.withOpacity(0.5),
                                        ),
                                        foregroundColor: AurennaTheme.amberGlow,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  
                  // Situationship Reading (Premium)
                  FutureBuilder<bool>(
                    future: authService.hasActiveSubscription(),
                    builder: (context, snapshot) {
                      final hasSubscription = snapshot.data ?? false;
                      
                      return Container(
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: hasSubscription 
                                ? [
                                    AurennaTheme.electricViolet.withOpacity(0.2),
                                    AurennaTheme.crystalBlue.withOpacity(0.2),
                                  ]
                                : [
                                    AurennaTheme.mysticBlue.withOpacity(0.1),
                                    AurennaTheme.voidBlack.withOpacity(0.1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasSubscription 
                                ? AurennaTheme.electricViolet.withOpacity(0.5)
                                : AurennaTheme.silverMist.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '🧠',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontSize: isSmallScreen ? 36 : 42,
                                  ),
                                ),
                                if (!hasSubscription) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, 
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AurennaTheme.amberGlow.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'PREMIUM',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AurennaTheme.amberGlow,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'Situation Spread',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: hasSubscription 
                                    ? AurennaTheme.textPrimary
                                    : AurennaTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 6),
                            Text(
                              hasSubscription 
                                  ? 'Decode the mysteries of your undefined relationship'
                                  : 'Unlock clarity about your complicated connections',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: hasSubscription 
                                    ? AurennaTheme.textSecondary
                                    : AurennaTheme.textSecondary.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            SizedBox(
                              width: double.infinity,
                              child: hasSubscription 
                                  ? ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/situationship-reading');
                                      },
                                      icon: const Icon(Icons.psychology, size: 20),
                                      label: const Text('Begin Situation Reading'),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 14,
                                        ),
                                        backgroundColor: AurennaTheme.electricViolet,
                                        foregroundColor: Colors.white,
                                      ),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/premium-upgrade');
                                      },
                                      icon: const Icon(Icons.lock, size: 18),
                                      label: const Text('Upgrade to Unlock'),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: isSmallScreen ? 12 : 14,
                                        ),
                                        side: BorderSide(
                                          color: AurennaTheme.amberGlow.withOpacity(0.5),
                                        ),
                                        foregroundColor: AurennaTheme.amberGlow,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                ),

                // Bottom spacing instead of Spacer
                SizedBox(height: isSmallScreen ? 24 : 48),

                // Footer message
                Center(
                  child: Text(
                    '✨ May the universe guide your journey ✨',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AurennaTheme.textSecondary.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                // Final bottom padding
                SizedBox(height: isSmallScreen ? 24 : 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
