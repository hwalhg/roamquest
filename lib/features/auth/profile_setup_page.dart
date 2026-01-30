import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/profile.dart';
import '../../data/services/auth_service.dart';

/// Profile setup page for username entry
class ProfileSetupPage extends StatefulWidget {
  final User user;

  const ProfileSetupPage({
    super.key,
    required this.user,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final AuthService _auth = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.userMetadata?['full_name'] ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildAvatar(),
                  const SizedBox(height: 32),
                  _buildTitle(),
                  const SizedBox(height: 40),
                  _buildForm(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],
                  const SizedBox(height: 32),
                  _buildContinueButton(),
                  const SizedBox(height: 16),
                  _buildSkipButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final avatarUrl = widget.user.userMetadata?['avatar_url'] as String?;
    final initials = _getInitials();

    return GestureDetector(
      onTap: () {
        // TODO: Implement avatar picker
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.textOnDark.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitialsAvatar(initials);
                  },
                ),
              )
            : _buildInitialsAvatar(initials),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.textOnDark,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Welcome aboard!',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s set up your profile',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.words,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark,
          ),
          decoration: InputDecoration(
            labelText: 'Display Name',
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
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _usernameController,
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.none,
          onChanged: _onUsernameChanged,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark,
          ),
          decoration: InputDecoration(
            labelText: 'Username (optional)',
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
            suffixIcon: _isCheckingUsername
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnDark,
                      ),
                    ),
                  )
                : _usernameController.text.isNotEmpty
                    ? Icon(
                        _isUsernameAvailable ? Icons.check : Icons.close,
                        color: _isUsernameAvailable
                            ? AppColors.success
                            : AppColors.error,
                      )
                    : null,
          ),
        ),
        if (!_isUsernameAvailable && _usernameController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              'This username is already taken',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Choose a unique username so others can find you',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDark.withOpacity(0.7),
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

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleContinue,
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
            : const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _isLoading ? null : _handleSkip,
      child: Text(
        'Skip for now',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textOnDark.withOpacity(0.8),
        ),
      ),
    );
  }

  // Helpers

  String _getInitials() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      final email = widget.user.email ?? '';
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // Handlers

  void _onUsernameChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        _isUsernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }

    // Username validation: only letters, numbers, underscores
    if (!RegExp(r'^[a-zA-Z0-9_]*$').hasMatch(value)) {
      setState(() {
        _isUsernameAvailable = false;
        _isCheckingUsername = false;
      });
      return;
    }

    // Debounce username check
    setState(() {
      _isCheckingUsername = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_usernameController.text != value) return;

      final available = await _auth.isUsernameAvailable(value);
      if (mounted) {
        setState(() {
          _isUsernameAvailable = available;
          _isCheckingUsername = false;
        });
      }
    });
  }

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your display name';
      });
      return;
    }

    if (username.isNotEmpty && !_isUsernameAvailable) {
      setState(() {
        _errorMessage = 'Please choose a different username';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Update profile
      await _auth.updateProfile({
        'full_name': name,
        if (username.isNotEmpty) 'username': username,
      });

      if (mounted) {
        // Navigate to home
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _handleSkip() {
    // Navigate to home without setting username
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
