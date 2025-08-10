import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String? couponCode;
  final double? discountAmount;
  final double? finalPrice;

  const PaymentSuccessScreen({
    super.key,
    this.couponCode,
    this.discountAmount,
    this.finalPrice,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Start animations
    _bounceController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });

    // Refresh subscription status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.hasActiveSubscription();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get route arguments if passed
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final couponCode = args?['couponCode'] ?? widget.couponCode;
    final finalPrice = args?['finalPrice'] ?? widget.finalPrice;

    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Close button (top right)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _navigateToHome(),
                    icon: const Icon(
                      Icons.close,
                      color: AurennaTheme.textSecondary,
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated success icon
                    ScaleTransition(
                      scale: _bounceAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AurennaTheme.amberGlow,
                              AurennaTheme.electricViolet,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AurennaTheme.amberGlow.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Welcome text
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Welcome to Premium!',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AurennaTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 16),

                          Text(
                            '🌟 Your cosmic journey just got unlimited',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AurennaTheme.amberGlow,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 24),

                          // Payment details (if coupon was used)
                          if (couponCode != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AurennaTheme.electricViolet.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Coupon Applied:',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AurennaTheme.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        couponCode!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AurennaTheme.electricViolet,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (finalPrice != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Amount Paid:',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AurennaTheme.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '₱${finalPrice!.toStringAsFixed(2)}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AurennaTheme.amberGlow,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Premium features
                          Text(
                            'You now have access to:',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AurennaTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 16),

                          _buildFeaturesList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _exploreReadings(),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Explore Premium Readings'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToHome(),
                        icon: const Icon(Icons.home),
                        label: const Text('Go to Home Screen'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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

  Widget _buildFeaturesList() {
    final features = [
      '✨ Unlimited premium readings',
      '📚 Complete reading history',
      '🎯 All advanced spreads',
      '🔮 Priority cosmic guidance',
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                feature,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AurennaTheme.crystalBlue,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _navigateToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _exploreReadings() {
    // Navigate to home and let them explore
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Could also navigate to a specific reading screen if desired
  }
}