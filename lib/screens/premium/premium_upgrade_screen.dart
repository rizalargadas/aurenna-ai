import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/paypal_service.dart';
import '../../services/auth_service.dart';
import '../../models/subscription_plan.dart';

class PremiumUpgradeScreen extends StatefulWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  State<PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<PremiumUpgradeScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _floatController;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  
  // Plan selection
  SubscriptionPlan _selectedPlan = SubscriptionPlan.monthly;
  
  // Coupon code controller
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCoupon;
  double _discountAmount = 0;
  double _discountPercentage = 0;
  String? _couponMessage;
  bool _isValidatingCoupon = false;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _floatAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AurennaTheme.voidBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // Spacer
                    Text(
                      'Upgrade to Premium',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AurennaTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AurennaTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Animated premium illustration
                _buildAnimatedIllustration(),
                
                const SizedBox(height: 32),
                
                // Premium title
                Text(
                  'Unlock Your Full\nCosmic Potential',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AurennaTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Access unlimited readings and your complete reading history',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AurennaTheme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Premium features
                _buildFeaturesList(),
                
                const SizedBox(height: 40),
                
                // Plan selection
                _buildPlanSelection(),
                
                const SizedBox(height: 24),
                
                // Coupon code input
                _buildCouponSection(),
                
                const SizedBox(height: 32),
                
                // Upgrade buttons
                _buildUpgradeButtons(),
                
                const SizedBox(height: 24),
                
                // Terms and conditions
                Text(
                  'By subscribing, you agree to our Terms of Service and Privacy Policy. Cancel anytime.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AurennaTheme.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIllustration() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, _floatAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AurennaTheme.electricViolet.withValues(alpha: _glowAnimation.value * 0.8),
                  AurennaTheme.cosmicPurple.withValues(alpha: _glowAnimation.value * 0.6),
                  AurennaTheme.mysticBlue.withValues(alpha: _glowAnimation.value * 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AurennaTheme.electricViolet.withValues(alpha: _glowAnimation.value * 0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 60,
              color: AurennaTheme.silverMist,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.all_inclusive,
        'title': 'Unlimited Readings',
        'description': 'Ask as many questions as your heart desires',
      },
      {
        'icon': Icons.history,
        'title': 'Reading History',
        'description': 'Access your complete cosmic journey anytime',
      },
      {
        'icon': Icons.star_purple500,
        'title': 'Priority Support',
        'description': 'Get help faster when you need it most',
      },
      {
        'icon': Icons.new_releases,
        'title': 'Early Access',
        'description': 'Be first to try new features and spreads',
      },
    ];

    return Column(
      children: features.map((feature) => _buildFeatureItem(
        icon: feature['icon'] as IconData,
        title: feature['title'] as String,
        description: feature['description'] as String,
      )).toList(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AurennaTheme.mysticBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AurennaTheme.electricViolet.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AurennaTheme.electricViolet,
                  AurennaTheme.cosmicPurple,
                ],
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AurennaTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AurennaTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AurennaTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...SubscriptionPlan.values.map((plan) => _buildPlanOption(plan)).toList(),
      ],
    );
  }

  Widget _buildPlanOption(SubscriptionPlan plan) {
    final isSelected = _selectedPlan == plan;
    final finalPrice = plan.price - (_selectedPlan == plan ? _discountAmount : 0);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AurennaTheme.electricViolet.withValues(alpha: 0.2),
              AurennaTheme.cosmicPurple.withValues(alpha: 0.2),
            ],
          ) : null,
          color: isSelected ? null : AurennaTheme.mysticBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? AurennaTheme.electricViolet 
              : AurennaTheme.electricViolet.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AurennaTheme.electricViolet : AurennaTheme.textSecondary,
                  width: 2,
                ),
                color: isSelected ? AurennaTheme.electricViolet : Colors.transparent,
              ),
              child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AurennaTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (plan.savingsText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AurennaTheme.amberGlow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            plan.savingsText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AurennaTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_discountAmount > 0 && isSelected) ...[
                        Text(
                          '\$${plan.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AurennaTheme.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '\$${finalPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AurennaTheme.electricViolet,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plan != SubscriptionPlan.monthly) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(\$${plan.monthlyEquivalent.toStringAsFixed(2)}/month)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AurennaTheme.amberGlow,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _startPayPalSubscription,
        icon: const Icon(Icons.payment),
        label: const Text('Subscribe with PayPal'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AurennaTheme.mysticBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AurennaTheme.electricViolet.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have a coupon code?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AurennaTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isValidatingCoupon && _appliedCoupon == null,
                  style: const TextStyle(color: AurennaTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter coupon code',
                    hintStyle: TextStyle(
                      color: AurennaTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: AurennaTheme.voidBlack,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AurennaTheme.electricViolet.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AurennaTheme.electricViolet,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AurennaTheme.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: _isValidatingCoupon
                      ? null 
                      : _appliedCoupon == null 
                          ? _validateAndApplyCoupon
                          : _removeCoupon,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isValidatingCoupon
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_appliedCoupon == null ? 'Apply' : 'Remove'),
                ),
              ),
            ],
          ),
          if (_couponMessage != null && _appliedCoupon != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AurennaTheme.amberGlow,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _couponMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AurennaTheme.amberGlow,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _validateAndApplyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a coupon code'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isValidatingCoupon = true;
    });

    final paypalService = PayPalService();
    final couponDetails = await paypalService.validateCoupon(code, planPrice: _selectedPlan.price);

    setState(() {
      _isValidatingCoupon = false;
      if (couponDetails.isValid) {
        _appliedCoupon = couponDetails.code;
        _discountAmount = couponDetails.discountAmount;
        _discountPercentage = couponDetails.discountPercentage;
        _couponMessage = couponDetails.message;
      }
    });

    if (!couponDetails.isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(couponDetails.message ?? 'Invalid coupon code'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0;
      _discountPercentage = 0;
      _couponMessage = null;
      _couponController.clear();
    });
  }

  void _startPayPalSubscription() async {
    final paypalService = PayPalService();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AurennaTheme.electricViolet,
        ),
      ),
    );

    try {
      final success = await paypalService.startSubscription(
        context,
        couponCode: _appliedCoupon,
        selectedPlan: _selectedPlan,
      );
      
      // Dismiss loading
      if (mounted) Navigator.pop(context);
      
      if (success) {
        // Navigate to payment success screen
        if (mounted) {
          Navigator.pushReplacementNamed(
            context, 
            '/payment-success',
            arguments: {
              'couponCode': _appliedCoupon,
              'discountAmount': _discountAmount,
              'finalPrice': _selectedPlan.price - _discountAmount,
              'selectedPlan': _selectedPlan,
            },
          );
        }
      } else {
        // Show detailed cancellation message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment cancelled or failed. ${_appliedCoupon != null ? 'Coupon $_appliedCoupon was valid but payment did not complete.' : 'Please try again.'}'),
              backgroundColor: AurennaTheme.textSecondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Dismiss loading
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

}