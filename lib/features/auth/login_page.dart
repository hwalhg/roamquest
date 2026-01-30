import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/auth_service.dart';
import '../../l10n/app_localizations.dart';

/// Simple login page with email + password
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true; // true = login, false = signup
  bool _agreedToTerms = false; // Privacy policy agreement
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.sunsetGradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildTitle(l10n),
                  const SizedBox(height: 48),
                  _buildForm(l10n),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],
                  const SizedBox(height: 24),
                  _buildToggleMode(l10n),
                  const SizedBox(height: 24),
                  _buildTermsText(l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.explore,
        size: 48,
        color: AppColors.textOnDark,
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.appName,
          style: AppTextStyles.h1.copyWith(
            color: AppColors.textOnDark,
            fontSize: 42,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.appSlogan,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark,
          ),
          decoration: InputDecoration(
            labelText: l10n.email,
            filled: true,
            fillColor: AppColors.textOnDark.withOpacity(0.15),
            labelStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDark.withOpacity(0.8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDark.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: true,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark,
          ),
          decoration: InputDecoration(
            labelText: l10n.passwordMin,
            filled: true,
            fillColor: AppColors.textOnDark.withOpacity(0.15),
            labelStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDark.withOpacity(0.8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDark.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Privacy policy checkbox (only for signup)
        if (!_isLogin) _buildTermsCheckbox(l10n),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _handleSubmit(l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textOnDark,
              foregroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.textOnDark.withOpacity(0.5),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    _isLogin ? l10n.signIn : l10n.signUp,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(
          color: AppColors.error.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.textOnDark,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleMode(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? l10n.dontHaveAccount : l10n.alreadyHaveAccount,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withOpacity(0.8),
          ),
        ),
        GestureDetector(
          onTap: _isLoading ? null : () {
            setState(() {
              _isLogin = !_isLogin;
              _errorMessage = null;
            });
          },
          child: Text(
            _isLogin ? l10n.signUp : l10n.signIn,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText(AppLocalizations l10n) {
    return Text(
      l10n.get('termsOfService'),
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textOnDark.withOpacity(0.7),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTermsCheckbox(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: _isLoading ? null : (bool? value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.textOnDark;
              }
              return AppColors.textOnDark.withOpacity(0.3);
            }),
            checkColor: AppColors.primary,
            side: BorderSide(
              color: _agreedToTerms
                  ? AppColors.textOnDark
                  : AppColors.textOnDark.withOpacity(0.5),
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            children: [
              Text(
                'I agree to the ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
              GestureDetector(
                onTap: () => _showTermsDialog(l10n, 'terms'),
                child: Text(
                  'Terms of Service',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnDark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
              GestureDetector(
                onTap: () => _showTermsDialog(l10n, 'privacy'),
                child: Text(
                  'Privacy Policy',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnDark,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit(AppLocalizations l10n) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validation
    if (email.isEmpty) {
      setState(() {
        _errorMessage = l10n.get('pleaseEnterEmail');
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = l10n.get('pleaseEnterValidEmail');
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = l10n.get('pleaseEnterPassword');
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = l10n.get('passwordTooShort');
      });
      return;
    }

    // Check terms agreement for signup
    if (!_isLogin && !_agreedToTerms) {
      setState(() {
        _errorMessage = l10n.get('mustAgreeToTerms');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Login
        await _auth.signInWithEmail(email: email, password: password);
      } else {
        // Sign up (no email verification needed)
        await _auth.signUpWithEmail(email: email, password: password);

        // Auto-login after signup
        await _auth.signInWithEmail(email: email, password: password);
      }

      // Auth state change will be handled by main.dart
      // Navigation to home will happen automatically
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _isLogin
              ? l10n.loginFailed
              : l10n.signupFailed;
          _isLoading = false;
        });
      }
    }
  }

  void _showTermsDialog(AppLocalizations l10n, String type) {
    final isTerms = type == 'terms';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTerms ? 'Terms of Service' : 'Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTerms) ...[
                _buildSection('1. Acceptance of Terms',
                    'By using RoamQuest, you agree to these terms. If you do not agree, please do not use our app.'),
                _buildSection('2. User Accounts',
                    'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.'),
                _buildSection('3. User Content',
                    'You retain ownership of content you post to RoamQuest. By posting content, you grant us a license to use, modify, and display it for the purpose of operating the app.'),
                _buildSection('4. Privacy',
                    'Your privacy is important to us. Please review our Privacy Policy, which also governs the app and explains how we collect, use, and share your data.'),
                _buildSection('5. Termination',
                    'We may terminate or suspend your account at any time for violation of these terms or for any other reason at our sole discretion.'),
              ] else ...[
                _buildSection('1. Information We Collect',
                    'We collect information you provide directly, including email address, photos, location data, and ratings you provide for check-ins.'),
                _buildSection('2. How We Use Your Information',
                    'We use your information to provide and improve the app, process check-ins, generate personalized recommendations, and communicate with you.'),
                _buildSection('3. Information Sharing',
                    'We do not sell your personal information. We may share data with service providers who help us operate the app and with your consent.'),
                _buildSection('4. Data Security',
                    'We implement reasonable security measures to protect your information. However, no method of transmission over the internet is 100% secure.'),
                _buildSection('5. Your Rights',
                    'You have the right to access, update, or delete your personal information. You can also opt out of communications from us.'),
                _buildSection('6. Contact Us',
                    'If you have questions about this Privacy Policy, please contact us at: support@roamquest.app'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            content,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
