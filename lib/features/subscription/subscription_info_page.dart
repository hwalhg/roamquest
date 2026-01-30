import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../home/main_navigation_page.dart';

/// Subscription info page - explains how subscription works
class SubscriptionInfoPage extends StatelessWidget {
  const SubscriptionInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.sunsetGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _buildHeader(l10n),
                      const SizedBox(height: AppSpacing.xl),
                      _buildFreeTierSection(l10n),
                      const SizedBox(height: AppSpacing.xl),
                      _buildPremiumSection(l10n),
                      const SizedBox(height: AppSpacing.xl),
                      _buildHowToUnlockSection(l10n),
                      const SizedBox(height: AppSpacing.xl * 2),
                      _buildStartButton(context, l10n),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.textOnDark.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium,
            size: 48,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.get('appName'),
          style: AppTextStyles.h1.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.appSlogan,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildFreeTierSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.textOnDark.withOpacity(0.2),
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
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: AppColors.textOnDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.get('freeTier'),
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            l10n.freeTierDesc,
            l10n.get('freeTierItems'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            l10n.get('permanentSave'),
            l10n.get('photoLocationSafe'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            l10n.get('shareDiaryTitle'),
            l10n.get('shareDiaryDesc'),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.success.withOpacity(0.5),
          width: 2,
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
                  color: AppColors.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.get('unlockCity'),
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            l10n.get('unlockAll20'),
            l10n.get('exploreCityEssence'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            l10n.get('permanentAccess'),
            l10n.get('oneTimeForever'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildFeatureItem(
            l10n.get('flexibleSubscription'),
            l10n.get('payForInterestedCity'),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToUnlockSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.textOnDark.withOpacity(0.2),
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
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: AppColors.textOnDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.get('howToUnlock'),
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStepItem(
            step: '1',
            title: l10n.get('step1Title'),
            description: l10n.get('step1Desc'),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStepItem(
            step: '2',
            title: l10n.get('step2Title'),
            description: l10n.get('step2Desc'),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStepItem(
            step: '3',
            title: l10n.get('step3Title'),
            description: l10n.get('step3Desc'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textOnDark.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem({
    required String step,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textOnDark.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to home page and clear all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainNavigationPage()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textOnDark,
          foregroundColor: AppColors.primary,
        ),
        child: Text(
          l10n.get('startExploring'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
