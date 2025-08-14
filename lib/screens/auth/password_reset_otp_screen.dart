import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class PasswordResetOtpScreen extends StatefulWidget {
  final String email;
  final String newPassword;
  
  const PasswordResetOtpScreen({
    super.key,
    required this.email,
    required this.newPassword,
  });

  @override
  State<PasswordResetOtpScreen> createState() => _PasswordResetOtpScreenState();
}

class _PasswordResetOtpScreenState extends State<PasswordResetOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _resendCountdown--);
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  void _onOtpFieldChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-submit when all fields are filled
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyOtpAndResetPassword();
    }
  }

  Future<void> _verifyOtpAndResetPassword() async {
    if (_otpCode.length != 6) {
      _showError(
        'Incomplete Code',
        'Please enter all 6 digits of your verification code.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Verify OTP and reset password in one step
      await authService.resetPasswordWithOTP(
        email: widget.email,
        token: _otpCode,
        newPassword: widget.newPassword,
      );

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AurennaTheme.successColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Password Reset! ✨',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your password has been successfully updated!',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'You can now sign in with your new password.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorTitle = 'Verification Failed';
        String errorMessage = 'Something went wrong. Please try again.';
        
        final error = e.toString().toLowerCase();
        if (error.contains('invalid') || error.contains('incorrect')) {
          errorTitle = 'Incorrect Code';
          errorMessage = 'The code you entered is incorrect. Please check and try again.';
        } else if (error.contains('expired')) {
          errorTitle = 'Code Expired';
          errorMessage = 'This verification code has expired. Please request a new one.';
        } else if (error.contains('rate limit')) {
          errorTitle = 'Too Many Attempts';
          errorMessage = 'You\'ve tried too many times. Please wait a moment before trying again.';
        }
        
        _showError(errorTitle, errorMessage);
        
        // Clear OTP fields on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() => _isResending = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Resend password reset OTP
      await authService.sendPasswordResetOTP(widget.email);
      
      if (mounted) {
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'New code sent! Check your inbox ✨',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AurennaTheme.crystalBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'Resend Failed',
          'Could not send a new code. Please check your internet connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AurennaTheme.errorColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: AurennaTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                style: TextStyle(
                  color: AurennaTheme.crystalBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AurennaTheme.crystalBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 40,
                    color: AurennaTheme.crystalBlue,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Verify & Reset Password 🔑',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'We sent a 6-digit verification code to',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AurennaTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                widget.email,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Enter the code to reset your password',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AurennaTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: Theme.of(context).textTheme.headlineSmall,
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AurennaTheme.crystalBlue,
                            width: 2,
                          ),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onOtpFieldChanged(value, index),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtpAndResetPassword,
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
                    : const Text('Reset Password'),
              ),

              const SizedBox(height: 24),

              // Resend Section
              Center(
                child: Column(
                  children: [
                    Text(
                      "Didn't receive the code?",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AurennaTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: (_resendCountdown > 0 || _isResending) 
                          ? null 
                          : _resendOtp,
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend code in ${_resendCountdown}s'
                            : _isResending
                                ? 'Sending...'
                                : 'Resend Code',
                        style: TextStyle(
                          color: (_resendCountdown > 0 || _isResending)
                              ? AurennaTheme.textSecondary
                              : AurennaTheme.crystalBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AurennaTheme.crystalBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AurennaTheme.crystalBlue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Pro Tips:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Check your spam folder',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• The code expires in 60 seconds',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Your new password will be set after verification',
                      style: Theme.of(context).textTheme.bodySmall,
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
}