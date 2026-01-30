import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/city.dart';
import '../../data/services/subscription_status_service.dart';

/// City subscription page for unlocking individual cities
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
  final SubscriptionStatusService _subscriptionService = SubscriptionStatusService();
  final InAppPurchase _iap = InAppPurchase.instance;

  bool _isUnlocked = false;
  bool _isPurchasing = false;
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _checkIAPAvailability();
  }

  Future<void> _checkStatus() async {
    final unlocked = await _subscriptionService.isCityUnlocked(widget.city);
    if (mounted) {
      setState(() {
        _isUnlocked = unlocked;
      });
    }
  }

  Future<void> _checkIAPAvailability() async {
    final available = await _iap.isAvailable();
    if (mounted) {
      setState(() {
        _isAvailable = available;
      });
    }
  }

  Future<void> _unlockCity() async {
    setState(() => _isPurchasing = true);

    try {
      // For free cities or when IAP is not available (web), just unlock directly
      if (!mounted) return;

      final success = widget.city.isFree || !_isAvailable
          ? await _subscriptionService.unlockCity(widget.city)
          : await _purchaseWithIAP();

      if (success && mounted) {
        setState(() {
          _isUnlocked = true;
        });
        _showSuccessDialog();
      } else if (mounted) {
        _showErrorDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog();
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<bool> _purchaseWithIAP() async {
    // TODO: Implement actual IAP purchase with product ID
    // For now, just unlock directly for demo purposes
    return await _subscriptionService.unlockCity(widget.city);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${widget.city.name} Unlocked!',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You now have permanent access to all ${widget.city.name} experiences',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Start Exploring'),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => Navigator.of(context).pop());
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Failed'),
        content: const Text(
          'Unable to complete purchase. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                    _buildPriceCard(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFeatures(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPurchaseButton(),
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
            color: AppColors.textOnDark.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
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
          'Get unlimited access to all ${widget.city.name} experiences',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPriceCard() {
    final price = widget.city.subscriptionPrice;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: widget.city.isFree
            ? AppColors.success.withOpacity(0.2)
            : AppColors.textOnDark.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(
          color: widget.city.isFree
              ? AppColors.success
              : AppColors.textOnDark,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.city.isFree ? 'FREE' : 'One-time Purchase',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.city.isFree ? 'Forever' : '\$${price.toStringAsFixed(2)}',
            style: AppTextStyles.h2.copyWith(
              color: widget.city.isFree
                  ? AppColors.success
                  : AppColors.textOnDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Permanent access',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textOnDark.withOpacity(0.8),
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
        color: AppColors.textOnDark.withOpacity(0.15),
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
            icon: Icons.all_inclusive,
            title: 'Unlimited Check-ins',
            description: 'Complete all 20 experiences in ${widget.city.name}',
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
            title: 'Complete Diary',
            description: 'Beautiful report of your journey',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.share,
            title: 'Share & Download',
            description: 'Share your diary with friends',
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
            color: AppColors.primary.withOpacity(0.2),
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
                  color: AppColors.textOnDark.withOpacity(0.8),
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

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPurchasing ? null : _unlockCity,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textOnDark,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.textOnDark.withOpacity(0.5),
        ),
        child: _isPurchasing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Text(
                widget.city.isFree ? 'Unlock Free' : 'Unlock \$${widget.city.subscriptionPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                color: AppColors.success.withOpacity(0.1),
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
              'You have full access to all experiences',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
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
