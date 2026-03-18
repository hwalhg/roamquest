import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/city.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/services/subscription_status_service.dart';
import 'subscription_page.dart';

/// City subscription page - now redirects to global subscription
class CitySubscriptionPage extends StatefulWidget {
  final City city;

  const CitySubscriptionPage({
    super.key,
    required this.city,
  });

  @override
  State<CitySubscriptionPage> createState() => _CitySubscriptionPageState();
}

class _CitySubscriptionPageState extends State<CitySubscriptionPage> {
  final SubscriptionRepository _subscriptionRepo = SubscriptionRepository();
  final SubscriptionStatusService _subscriptionService = SubscriptionStatusService();

  bool _isUnlocked = false;
  bool _hasActiveSubscription = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _subscriptionRepo.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    // Check if user has active global subscription
    final subscription = await _subscriptionRepo.getSubscription();
    final hasActiveSubscription = subscription?.isActive ?? false;

    // Check if this specific city is unlocked (for backward compatibility)
    final cityUnlocked = await _subscriptionService.isCityUnlocked(widget.city);

    if (mounted) {
      setState(() {
        _hasActiveSubscription = hasActiveSubscription;
        _isUnlocked = hasActiveSubscription || cityUnlocked;
      });
    }
  }

  void _goToSubscriptionPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionPage(),
      ),
    ).then((_) => _checkStatus());
  }

  @override
  Widget build(BuildContext context) {
    if (_isUnlocked) {
      return _buildUnlockedView();
    }

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
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSubscriptionInfo(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFeatures(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSubscribeButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
              Icons.close,
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.textOnDark.withValues(alpha:0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.location_city,
            size: 48,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Unlock ${widget.city.name}',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Subscribe to unlock all cities including ${widget.city.name}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withValues(alpha:0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubscriptionInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.workspace_premium,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Premium Subscription',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Unlock ALL cities',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose Monthly, Quarterly, or Yearly',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textOnDark.withValues(alpha:0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What You Get',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.public,
            title: 'All Cities Access',
            description: 'Unlock every city worldwide with one subscription',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.all_inclusive,
            title: 'Unlimited Check-ins',
            description: 'Complete all experiences in any city',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.photo_library,
            title: 'Photo Memories',
            description: 'Capture and save every moment',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.assessment,
            title: 'Complete Reports',
            description: 'Beautiful diaries of your journeys',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.share,
            title: 'Share & Download',
            description: 'Share your adventures with friends',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha:0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.textOnDark,
            size: 20,
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
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textOnDark.withValues(alpha:0.8),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscribeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _goToSubscriptionPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textOnDark,
          foregroundColor: AppColors.primary,
        ),
        child: const Text(
          'View Subscription Plans',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildUnlockedView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${widget.city.name} is Unlocked!',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _hasActiveSubscription
                  ? 'Your active subscription unlocks all cities'
                  : 'You have full access to all experiences',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Checklist'),
            ),
          ],
        ),
      ),
    );
  }
}
