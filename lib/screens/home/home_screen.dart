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
      backgroundColor: AurennaTheme.voidBlack,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Hero Section
            SliverToBoxAdapter(child: _buildHeroSection(isSmallScreen)),
            
            // Question Counter
            SliverToBoxAdapter(child: _buildQuestionCounter(isSmallScreen)),
            
            // Featured Reading
            SliverToBoxAdapter(child: _buildFeaturedReading(isSmallScreen, isTablet)),
            
            // Categories Header
            SliverToBoxAdapter(child: _buildCategoriesHeader(isSmallScreen)),
            
            // Love & Relationships Section
            SliverToBoxAdapter(child: _buildLoveSection(authService, isSmallScreen, isTablet)),
            
            // Career & Growth Section
            SliverToBoxAdapter(child: _buildCareerSection(authService, isSmallScreen, isTablet)),
            
            // Spiritual & Mystical Section
            SliverToBoxAdapter(child: _buildSpiritualSection(authService, isSmallScreen, isTablet)),
            
            // Other Readings Section
            SliverToBoxAdapter(child: _buildOtherSection(authService, isSmallScreen, isTablet)),
            
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
        backgroundColor: AurennaTheme.voidBlack,
        elevation: 0,
        title: Image.asset(
          'assets/img/logo/horizontal-transparent.png',
          height: 180,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AurennaTheme.mysticBlue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: AurennaTheme.textPrimary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                  AurennaTheme.electricViolet.withValues(alpha: 0.15),
                  AurennaTheme.crystalBlue.withValues(alpha: 0.15),
                  AurennaTheme.cosmicPurple.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AurennaTheme.silverMist.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '✨',
                  style: TextStyle(fontSize: isSmallScreen ? 32 : 40),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  'Welcome back, mystic soul!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AurennaTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The universe has messages waiting for you',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AurennaTheme.textSecondary.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
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
      child: Center(
        child: QuestionCounter(showUpgradeButton: true),
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
                  color: AurennaTheme.textPrimary,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'FREE',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AurennaTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  'Past • Present • Future',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AurennaTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask a question and let the cards reveal their ancient wisdom',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AurennaTheme.textSecondary.withValues(alpha: 0.9),
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
                        MaterialPageRoute(builder: (context) => const QuestionScreen()),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: const Text('Ask the Cards'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 18),
                      backgroundColor: AurennaTheme.electricViolet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AurennaTheme.electricViolet.withValues(alpha: 0.5),
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
              color: AurennaTheme.textPrimary,
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

  Widget _buildLoveSection(AuthService authService, bool isSmallScreen, bool isTablet) {
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

  Widget _buildCareerSection(AuthService authService, bool isSmallScreen, bool isTablet) {
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

  Widget _buildSpiritualSection(AuthService authService, bool isSmallScreen, bool isTablet) {
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

  Widget _buildOtherSection(AuthService authService, bool isSmallScreen, bool isTablet) {
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
                      color: AurennaTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AurennaTheme.textSecondary.withValues(alpha: 0.8),
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
                colors: hasSubscription ? colors : [
                  AurennaTheme.mysticBlue.withValues(alpha: 0.1),
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
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: hasSubscription 
                                    ? AurennaTheme.textPrimary
                                    : AurennaTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!hasSubscription)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AurennaTheme.amberGlow.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'PREMIUM',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                        hasSubscription ? description : 'Unlock ${title.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: hasSubscription 
                              ? AurennaTheme.textSecondary.withValues(alpha: 0.9)
                              : AurennaTheme.textSecondary.withValues(alpha: 0.7),
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
                      : AurennaTheme.textSecondary.withValues(alpha: 0.5),
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
            AurennaTheme.mysticBlue.withValues(alpha: 0.1),
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
              color: AurennaTheme.textSecondary.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Every card drawn is a step closer to understanding your path',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AurennaTheme.textSecondary.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}