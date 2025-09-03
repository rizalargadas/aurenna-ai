import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../settings/settings_screen.dart';
import '../reading/question_screen.dart';
import '../reading/card_of_the_day_screen.dart';
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
    await authService.hasActiveSubscription(); // Refresh subscription status
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Hero Section
            SliverToBoxAdapter(child: _buildHeroSection(isSmallScreen)),

            // Question Counter
            SliverToBoxAdapter(child: _buildQuestionCounter(isSmallScreen)),

            // Card of the Day
            SliverToBoxAdapter(child: _buildCardOfTheDay(isSmallScreen)),

            // Featured Reading
            SliverToBoxAdapter(
              child: _buildFeaturedReading(isSmallScreen, isTablet),
            ),

            // Categories Header
            SliverToBoxAdapter(child: _buildCategoriesHeader(isSmallScreen)),

            // Love & Relationships Section
            SliverToBoxAdapter(
              child: _buildLoveSection(authService, isSmallScreen, isTablet),
            ),

            // Career & Growth Section
            SliverToBoxAdapter(
              child: _buildCareerSection(authService, isSmallScreen, isTablet),
            ),

            // Spiritual & Mystical Section
            SliverToBoxAdapter(
              child: _buildSpiritualSection(
                authService,
                isSmallScreen,
                isTablet,
              ),
            ),

            // Other Readings Section
            SliverToBoxAdapter(
              child: _buildOtherSection(authService, isSmallScreen, isTablet),
            ),

            // Footer
            SliverToBoxAdapter(child: _buildFooter(isSmallScreen)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AppBar(
        toolbarHeight: 80,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Image.asset(
          Theme.of(context).brightness == Brightness.dark
              ? 'assets/img/logo/horizontal-transparent.png'
              : 'assets/img/logo/light-mode-horizontal-transparent.png',
          height: 180,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          // Cosmic greeting
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AurennaTheme.getElectricViolet(context).withValues(alpha: 0.15),
                  AurennaTheme.getCrystalBlue(context).withValues(alpha: 0.15),
                  AurennaTheme.getCosmicPurple(context).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text('✨', style: TextStyle(fontSize: isSmallScreen ? 32 : 40)),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  'Good to see you again!',
                  style: GoogleFonts.cinzel(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AurennaTheme.getPrimaryTextColor(context),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your cards are feeling chatty — shall we?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AurennaTheme.getSecondaryTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCounter(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(24, isSmallScreen ? 20 : 24, 24, 0),
      child: Center(child: QuestionCounter(showUpgradeButton: true)),
    );
  }

  String _getTimeUntilNextCard() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final difference = tomorrow.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} and $minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  Future<void> _handleCardOfTheDay() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;

    if (userId == null) return;

    // Check if already drawn today
    final prefs = await SharedPreferences.getInstance();
    final lastDrawKey = 'daily_card_last_draw_$userId';
    final lastDrawDate = prefs.getString(lastDrawKey);

    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (lastDrawDate == todayString) {
      // Show sassy alert - already drawn today
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AurennaTheme.getElectricViolet(context).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: AurennaTheme.getElectricViolet(context),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⏰ Hold Up, Speed Racer!',
                    style: TextStyle(
                      color: AurennaTheme.getPrimaryTextColor(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'It\'s called Card of the DAY, not Card of the Hour, bestie! 💅',
                  style: TextStyle(
                    color: AurennaTheme.getPrimaryTextColor(context),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The universe doesn\'t do instant replays. One cosmic download per 24 hours, that\'s the rules!',
                  style: TextStyle(
                    color: AurennaTheme.getSecondaryTextColor(context),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AurennaTheme.cosmicPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AurennaTheme.cosmicPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: AurennaTheme.cosmicPurple,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Come back in:',
                              style: TextStyle(
                                color: AurennaTheme.getSecondaryTextColor(context),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _getTimeUntilNextCard(),
                              style: TextStyle(
                                color: AurennaTheme.getElectricViolet(context),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AurennaTheme.electricViolet,
                        AurennaTheme.cosmicPurple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Fine, I\'ll Wait 🙄',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Haven't drawn today - navigate to the screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CardOfTheDayScreen()),
        );
      }
    }
  }

  Widget _buildCardOfTheDay(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(24, isSmallScreen ? 20 : 24, 24, 0),
      child: GestureDetector(
        onTap: _handleCardOfTheDay,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AurennaTheme.electricViolet.withOpacity(0.2),
                AurennaTheme.cosmicPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AurennaTheme.electricViolet.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AurennaTheme.electricViolet.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AurennaTheme.electricViolet,
                      AurennaTheme.cosmicPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🌅 Card of the Day',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AurennaTheme.getPrimaryTextColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AurennaTheme.electricViolet.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AurennaTheme.electricViolet.withOpacity(
                                0.4,
                              ),
                            ),
                          ),
                          child: Text(
                            'FREE',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AurennaTheme.getElectricViolet(context),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your daily cosmic check-in. Pull one card for guidance.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AurennaTheme.getSecondaryTextColor(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: AurennaTheme.getSecondaryTextColor(context),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedReading(bool isSmallScreen, bool isTablet) {
    return Container(
      margin: EdgeInsets.fromLTRB(24, isSmallScreen ? 24 : 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AurennaTheme.amberGlow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.star,
                  color: AurennaTheme.amberGlow,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Start Your Journey',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AurennaTheme.getPrimaryTextColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Three-Card Reading - Enhanced Hero Card
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 24 : 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AurennaTheme.electricViolet.withValues(alpha: 0.3),
                  AurennaTheme.cosmicPurple.withValues(alpha: 0.25),
                  AurennaTheme.crystalBlue.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AurennaTheme.electricViolet.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🔮',
                      style: TextStyle(fontSize: isSmallScreen ? 48 : 56),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'FREE',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                Text(
                  'Three-Card Reading',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AurennaTheme.getPrimaryTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  'Past • Present • Future',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AurennaTheme.getSecondaryTextColor(context),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask a question and let the cards reveal their ancient wisdom',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AurennaTheme.getSecondaryTextColor(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 20 : 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuestionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: const Text('Ask the Cards'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 16 : 18,
                      ),
                      backgroundColor: AurennaTheme.electricViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AurennaTheme.electricViolet.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesHeader(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(24, isSmallScreen ? 32 : 40, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AurennaTheme.crystalBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.category,
              color: AurennaTheme.crystalBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Premium Readings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AurennaTheme.getPrimaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AurennaTheme.amberGlow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildLoveSection(
    AuthService authService,
    bool isSmallScreen,
    bool isTablet,
  ) {
    return _buildSection(
      title: '💕 Love & Relationships',
      subtitle: 'Matters of the heart',
      color: AurennaTheme.amberGlow,
      isSmallScreen: isSmallScreen,
      isTablet: isTablet,
      children: [
        _buildPremiumCard(
          authService: authService,
          title: 'Love Compatibility',
          description: 'Discover the cosmic connection between two souls',
          icon: '💕',
          route: '/compatibility-reading',
          colors: [
            AurennaTheme.amberGlow.withValues(alpha: 0.2),
            AurennaTheme.electricViolet.withValues(alpha: 0.2),
          ],
          borderColor: AurennaTheme.amberGlow,
          isSmallScreen: isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        _buildPremiumCard(
          authService: authService,
          title: 'Situation Spread',
          description: 'Decode the mysteries of your undefined relationship',
          icon: '🧠',
          route: '/situationship-reading',
          colors: [
            AurennaTheme.electricViolet.withValues(alpha: 0.2),
            AurennaTheme.crystalBlue.withValues(alpha: 0.2),
          ],
          borderColor: AurennaTheme.electricViolet,
          isSmallScreen: isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        _buildPremiumCard(
          authService: authService,
          title: 'Relationship Decision',
          description: 'Get clarity on whether to stay or leave',
          icon: '💔',
          route: '/relationship-decision',
          colors: [
            AurennaTheme.amberGlow.withValues(alpha: 0.2),
            AurennaTheme.electricViolet.withValues(alpha: 0.2),
          ],
          borderColor: AurennaTheme.amberGlow,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildCareerSection(
    AuthService authService,
    bool isSmallScreen,
    bool isTablet,
  ) {
    return _buildSection(
      title: '💼 Career & Growth',
      subtitle: 'Professional guidance',
      color: AurennaTheme.crystalBlue,
      isSmallScreen: isSmallScreen,
      isTablet: isTablet,
      children: [
        _buildPremiumCard(
          authService: authService,
          title: 'Career Reading',
          description: 'Get brutally honest guidance about your career path',
          icon: '💼',
          route: '/career-reading',
          colors: [
            AurennaTheme.crystalBlue.withValues(alpha: 0.2),
            AurennaTheme.electricViolet.withValues(alpha: 0.2),
          ],
          borderColor: AurennaTheme.crystalBlue,
          isSmallScreen: isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        _buildPremiumCard(
          authService: authService,
          title: 'Career Change',
          description: 'Navigate your career transformation with confidence',
          icon: '🔄',
          route: '/career-change',
          colors: [
            AurennaTheme.electricViolet.withValues(alpha: 0.2),
            AurennaTheme.mysticBlue.withValues(alpha: 0.2),
          ],
          borderColor: AurennaTheme.electricViolet,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildSpiritualSection(
    AuthService authService,
    bool isSmallScreen,
    bool isTablet,
  ) {
    return _buildSection(
      title: '☪️ Spiritual & Mystical',
      subtitle: 'Journey into the unknown',
      color: AurennaTheme.electricViolet,
      isSmallScreen: isSmallScreen,
      isTablet: isTablet,
      children: [
        _buildPremiumCard(
          authService: authService,
          title: 'Past Life Reading',
          description: 'Discover who you were in a previous incarnation',
          icon: '☪️',
          route: '/past-life-reading',
          colors: [
            AurennaTheme.electricViolet.withValues(alpha: 0.2),
            AurennaTheme.crystalBlue.withValues(alpha: 0.2),
          ],
          borderColor: AurennaTheme.electricViolet,
          isSmallScreen: isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        _buildPremiumCard(
          authService: authService,
          title: 'Comprehensive General Reading',
          description: '12 cards revealing all aspects of your life',
          icon: '✨',
          route: '/general-reading',
          colors: [
            AurennaTheme.electricViolet.withValues(alpha: 0.2),
            AurennaTheme.cosmicPurple.withValues(alpha: 0.2),
          ],
          borderColor: AurennaTheme.electricViolet,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildOtherSection(
    AuthService authService,
    bool isSmallScreen,
    bool isTablet,
  ) {
    return _buildSection(
      title: '❓ Quick Guidance',
      subtitle: 'Direct answers',
      color: const Color(0xFF7C4DFF),
      isSmallScreen: isSmallScreen,
      isTablet: isTablet,
      children: [
        _buildPremiumCard(
          authService: authService,
          title: 'Yes or No Reading',
          description: 'Get straight-to-the-point cosmic guidance',
          icon: '❓',
          route: '/yes-or-no-reading',
          colors: [
            const Color(0xFF7C4DFF).withValues(alpha: 0.2),
            const Color(0xFF536DFE).withValues(alpha: 0.2),
          ],
          borderColor: const Color(0xFF7C4DFF),
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Color color,
    required bool isSmallScreen,
    required bool isTablet,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(24, isSmallScreen ? 20 : 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AurennaTheme.getPrimaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AurennaTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          if (isTablet && children.length > 1)
            // Grid layout for tablets
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: children.where((child) => child is! SizedBox).toList(),
            )
          else
            // Column layout for phones
            Column(children: children),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required AuthService authService,
    required String title,
    required String description,
    required String icon,
    required String route,
    required List<Color> colors,
    required Color borderColor,
    required bool isSmallScreen,
  }) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final hasSubscription = authService.cachedSubscriptionStatus ?? false;

        return GestureDetector(
          onTap: hasSubscription
              ? () => Navigator.pushNamed(context, route)
              : () => Navigator.pushNamed(context, '/premium-upgrade'),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasSubscription
                    ? colors
                    : [
                        AurennaTheme.getMysticBlue(context).withValues(alpha: 0.1),
                        AurennaTheme.voidBlack.withValues(alpha: 0.1),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasSubscription
                    ? borderColor.withValues(alpha: 0.4)
                    : AurennaTheme.silverMist.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasSubscription
                        ? borderColor.withValues(alpha: 0.2)
                        : AurennaTheme.silverMist.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    icon,
                    style: TextStyle(fontSize: isSmallScreen ? 20 : 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: hasSubscription
                                        ? AurennaTheme.getPrimaryTextColor(context)
                                        : AurennaTheme.getSecondaryTextColor(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (!hasSubscription)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AurennaTheme.amberGlow.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PREMIUM',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AurennaTheme.amberGlow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasSubscription
                            ? description
                            : 'Unlock ${title.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasSubscription
                              ? AurennaTheme.getSecondaryTextColor(context)
                              : AurennaTheme.getSecondaryTextColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasSubscription ? Icons.arrow_forward_ios : Icons.lock,
                  color: hasSubscription
                      ? borderColor.withValues(alpha: 0.7)
                      : AurennaTheme.getSecondaryTextColor(context),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.fromLTRB(24, isSmallScreen ? 32 : 40, 24, 24),
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AurennaTheme.getMysticBlue(context).withValues(alpha: 0.1),
            AurennaTheme.voidBlack.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AurennaTheme.silverMist.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            '✨ May the universe guide your journey ✨',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AurennaTheme.getSecondaryTextColor(context),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Every card drawn is a step closer to understanding your path',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AurennaTheme.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
