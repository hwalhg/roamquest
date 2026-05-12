import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_page.dart';
import 'home_page.dart';
import '../profile/edit_profile_page.dart';
import '../profile/privacy_policy_page.dart';
import '../subscription/subscription_info_page.dart';
import '../subscription/subscription_page.dart';

/// Main navigation page with bottom tabs
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePageContent(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.textOnDark,
          border: Border(
            top: BorderSide(
              color: AppColors.textOnDark.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.get('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n.get('profile'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home page content (extracted for use in navigation)
class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse existing HomePage without the settings menu
    // We'll create a cleaner version
    return const HomePage();
  }
}

/// Profile page
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _auth = AuthService();
  final SubscriptionRepository _subscriptionRepo = SubscriptionRepository();
  Map<String, dynamic>? _profileData;
  Subscription? _currentSubscription;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSubscriptionSummary();
  }

  Future<void> _loadProfile() async {
    final profile = await _auth.getCurrentProfile();
    if (mounted && profile != null) {
      setState(() {
        _profileData = profile.toJson();
      });
    }
  }

  Future<void> _loadSubscriptionSummary() async {
    final subscription = await _subscriptionRepo.getSubscription();
    if (!mounted) return;

    setState(() {
      _currentSubscription = subscription;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: constraints.maxHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.sunsetGradient,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(user),
                    const SizedBox(height: 32),
                    _buildPremiumCard(l10n),
                    const SizedBox(height: 20),
                    _buildMenuItems(l10n),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumCard(AppLocalizations l10n) {
    final subscription = _currentSubscription;
    final hasPremium = subscription?.isValid ?? false;
    final planName = subscription != null
        ? _localizedPlanName(subscription.productId, l10n)
        : l10n.get('premiumAccess');
    final renewalText = subscription?.endDate != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(subscription!.endDate!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasPremium
              ? [
                  AppColors.textOnDark.withValues(alpha: 0.24),
                  AppColors.success.withValues(alpha: 0.24),
                ]
              : [
                  AppColors.textOnDark.withValues(alpha: 0.18),
                  AppColors.primary.withValues(alpha: 0.18),
                ],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.xl),
        border: Border.all(
          color: hasPremium
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.textOnDark.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.textOnDark.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Icon(
                  hasPremium
                      ? Icons.workspace_premium
                      : Icons.workspace_premium_outlined,
                  color: AppColors.textOnDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPremium
                          ? '$planName Premium'
                          : l10n.get('premiumAccess'),
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPremium
                          ? l10n.get('premiumAccessActiveDesc')
                          : l10n.get('premiumAccessInactiveDesc'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPremiumMetaRow(
                  l10n.get('statusLabel'),
                  hasPremium
                      ? l10n.get('activeStatus')
                      : l10n.get('notSubscribedStatus'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildPremiumMetaRow(
                  l10n.get('planLabel'),
                  hasPremium ? planName : l10n.get('premiumAccess'),
                ),
                if (renewalText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildPremiumMetaRow(l10n.get('renewalLabel'), renewalText),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionPage(),
                  ),
                );
                _loadSubscriptionSummary();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textOnDark,
                foregroundColor:
                    hasPremium ? AppColors.success : AppColors.primary,
              ),
              child: Text(
                hasPremium
                    ? l10n.get('managePremium')
                    : l10n.get('viewPremium'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _localizedPlanName(String productId, AppLocalizations l10n) {
    switch (productId) {
      case SubscriptionProducts.monthly:
        return l10n.get('monthly');
      case SubscriptionProducts.quarterly:
        return l10n.get('quarterly');
      case SubscriptionProducts.yearly:
        return l10n.get('yearly');
      default:
        return l10n.get('premiumAccess');
    }
  }

  Widget _buildPremiumMetaRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDark.withValues(alpha: 0.68),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(dynamic user) {
    final displayName = _profileData?['full_name'] ??
        _profileData?['username'] ??
        user?.email ??
        'Guest';
    final avatarUrl = _profileData?['avatar_url'];

    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditProfilePage(),
              ),
            );
            if (result == true) {
              _loadProfile(); // Refresh profile data
            }
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                _getInitials(displayName),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textOnDark,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          _getInitials(displayName),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnDark,
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: AppColors.textOnDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _profileData?['full_name'] ??
              _profileData?['username'] ??
              user?.email ??
              'Guest',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Column(
        children: [
          // 1. 关于订阅
          _buildMenuItem(
            icon: Icons.info_outline,
            title: l10n.get('aboutPremium'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionInfoPage(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.textOnDark),
          // 2. 隐私协议
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: l10n.get('privacyPolicy'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.textOnDark),
          // 3. 删除账号
          _buildMenuItem(
            icon: Icons.delete_forever_outlined,
            iconColor: AppColors.error,
            title: l10n.get('deleteAccount'),
            titleColor: AppColors.error,
            onTap:
                _isDeletingAccount ? () {} : () => _showDeleteAccountDialog(),
          ),
          const Divider(height: 1, color: AppColors.textOnDark),
          // 4. 退出登录
          _buildMenuItem(
            icon: Icons.logout,
            iconColor: AppColors.error,
            title: l10n.get('logout'),
            titleColor: AppColors.error,
            onTap: () => _showSignOutDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textOnDark),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: titleColor ?? AppColors.textOnDark,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: !_isDeletingAccount,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.get('deleteAccount')),
          content: Text(l10n.get('deleteAccountConfirm')),
          actions: [
            TextButton(
              onPressed: _isDeletingAccount
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: Text(l10n.get('cancel')),
            ),
            ElevatedButton(
              onPressed: _isDeletingAccount
                  ? null
                  : () async {
                      setDialogState(() {
                        _isDeletingAccount = true;
                      });
                      if (mounted) {
                        setState(() {
                          _isDeletingAccount = true;
                        });
                      }

                      final navigator = Navigator.of(context);
                      final dialogNavigator = Navigator.of(dialogContext);
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await _auth.deleteAccount();

                      if (!mounted) return;

                      setState(() {
                        _isDeletingAccount = false;
                      });
                      dialogNavigator.pop();

                      if (success) {
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.get('deleteAccountFailed')),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textOnDark,
              ),
              child: _isDeletingAccount
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnDark,
                      ),
                    )
                  : Text(l10n.get('deleteAccountConfirmButton')),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.get('logout')),
        content: Text(l10n.get('logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(dialogContext);
              final success = await _auth.signOut();
              if (!mounted) return;

              if (success) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnDark,
            ),
            child: Text(l10n.get('logout')),
          ),
        ],
      ),
    );
  }

  String _getInitials(String displayName) {
    if (displayName.isEmpty || displayName == 'Guest') return '?';
    // Get first character of display name
    return displayName[0].toUpperCase();
  }
}
