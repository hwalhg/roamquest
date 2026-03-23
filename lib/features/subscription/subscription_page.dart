import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/subscription.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../l10n/app_localizations.dart';

/// Subscription page for premium upgrade
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionRepository _subscriptionRepo = SubscriptionRepository();
  ProductDetails? _selectedProduct;
  bool _isPurchasing = false;
  Subscription? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSubscription();
  }

  @override
  void dispose() {
    _subscriptionRepo.products.removeListener(_onProductsLoaded);
    _subscriptionRepo.dispose();
    super.dispose();
  }

  Future<void> _initializeSubscription() async {
    await _subscriptionRepo.initialize();

    // Load current subscription details
    final subscription = await _subscriptionRepo.getSubscription();

    // Wait for products to load and select one
    _subscriptionRepo.products.addListener(_onProductsLoaded);

    if (mounted) {
      setState(() {
        _currentSubscription = subscription;
      });

      // Try to set selected product immediately if already loaded
      _onProductsLoaded();
    }
  }

  void _onProductsLoaded() {
    if (!mounted) return;

    final products = _subscriptionRepo.products.value;
    if (products.isEmpty) return;

    // Try to select yearly, then quarterly, then monthly as fallback
    ProductDetails? selected = _getYearlyProduct();
    if (selected == null) {
      selected = _getQuarterlyProduct();
    }
    if (selected == null) {
      selected = _getMonthlyProduct();
    }

    if (selected != null && _selectedProduct == null) {
      setState(() {
        _selectedProduct = selected;
      });
    }
  }

  ProductDetails? _getMonthlyProduct() {
    return _subscriptionRepo.products.value
        .where((p) => p.id == SubscriptionProducts.monthly)
        .firstOrNull;
  }

  ProductDetails? _getQuarterlyProduct() {
    return _subscriptionRepo.products.value
        .where((p) => p.id == SubscriptionProducts.quarterly)
        .firstOrNull;
  }

  ProductDetails? _getYearlyProduct() {
    return _subscriptionRepo.products.value
        .where((p) => p.id == SubscriptionProducts.yearly)
        .firstOrNull;
  }

  Future<void> _purchaseSubscription() async {
    if (_selectedProduct == null || _isPurchasing) return;

    setState(() => _isPurchasing = true);

    try {
      final success = await _subscriptionRepo.purchaseSubscription(
        _selectedProduct!.id,
      );

      if (success && mounted) {
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

  Future<void> _restorePurchase() async {
    final l10n = AppLocalizations.of(context)!;
    await _subscriptionRepo.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('restorePurchaseCompleted'))),
      );
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
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
                color: AppColors.success.withValues(alpha:0.1),
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
              l10n.get('welcomePremium'),
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.get('unlimitedCity'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Close dialog
                  Navigator.of(context).pop();
                  // Navigate to home page
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(l10n.get('startExploring')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('paymentFailed')),
        content: Text(l10n.get('paymentFailedDesc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
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
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _buildHeader(l10n),
                    const SizedBox(height: AppSpacing.md),
                    _buildSubscriptionStatus(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSubscriptionPlans(l10n),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFeatures(l10n),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPurchaseButton(l10n),
                    const SizedBox(height: AppSpacing.md),
                    _buildRestoreButton(l10n),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTerms(l10n),
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

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.textOnDark.withValues(alpha:0.2),
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
          l10n.get('upgradePremium'),
          style: AppTextStyles.h1.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.get('unlockUnlimited'),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withValues(alpha:0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionStatus() {
    if (_currentSubscription == null) {
      return const SizedBox.shrink();
    }

    final subscription = _currentSubscription!;
    final isExpiringSoon = subscription.daysRemaining > 0 && subscription.daysRemaining <= 3;
    final isExpired = subscription.daysRemaining < 0;

    final dateFormatter = DateFormat.yMd();
    final expiryDate = subscription.endDate;
    final expiryText = expiryDate != null
        ? dateFormatter.format(expiryDate)
        : 'Lifetime';

    final bgColor = isExpired
        ? AppColors.error.withValues(alpha:0.1)
        : isExpiringSoon
            ? AppColors.warning.withValues(alpha:0.1)
            : AppColors.success.withValues(alpha:0.1);

    final icon = isExpired
        ? Icons.error_outline
        : isExpiringSoon
            ? Icons.warning_amber_outlined
            : Icons.check_circle_outline;

    final iconColor = isExpired
        ? AppColors.error
        : isExpiringSoon
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired
                      ? 'Subscription Expired'
                      : isExpiringSoon
                          ? 'Expiring Soon'
                          : 'Active Subscription',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (expiryDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expires: $expiryText',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnDark.withValues(alpha:0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans(AppLocalizations l10n) {
    return ValueListenableBuilder(
      valueListenable: _subscriptionRepo.status,
      builder: (context, status, _) {
        // Show message for web platform
        if (status == SubscriptionStatus.unavailable) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 48,
                  color: AppColors.textOnDark,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.get('webNotSupported'),
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.get('webNotSupportedDesc'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDark.withValues(alpha:0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder(
          valueListenable: _subscriptionRepo.products,
          builder: (context, products, _) {
            if (products.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.textOnDark,
                ),
              );
            }

            final monthly = _getMonthlyProduct();
            final quarterly = _getQuarterlyProduct();
            final yearly = _getYearlyProduct();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPlanOption(
                  product: monthly,
                  isSelected: _selectedProduct == monthly,
                  onTap: () {
                    setState(() => _selectedProduct = monthly);
                  },
                  badge: null,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildPlanOption(
                  product: quarterly,
                  isSelected: _selectedProduct == quarterly,
                  onTap: () {
                    setState(() => _selectedProduct = quarterly);
                  },
                  badge: _buildSavingsBadge(quarterly, monthly, quarterly: true),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildPlanOption(
                  product: yearly,
                  isSelected: _selectedProduct == yearly,
                  onTap: () {
                    setState(() => _selectedProduct = yearly);
                  },
                  badge: _buildBestValueBadge(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlanOption({
    required ProductDetails? product,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? badge,
  }) {
    if (product == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textOnDark : AppColors.textOnDark.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha:0.3),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        style: AppTextStyles.h4.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textOnDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      badge!,
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  product.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.textOnDark.withValues(alpha:0.8)
                        : AppColors.textOnDark.withValues(alpha:0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  product.price,
                  style: AppTextStyles.h2.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textOnDark,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsBadge(ProductDetails? current, ProductDetails? monthly, {bool quarterly = false}) {
    if (current == null || monthly == null) return const SizedBox.shrink();

    // Calculate savings percentage
    String savingsText;
    if (quarterly) {
      savingsText = 'SAVE 15%';
    } else {
      savingsText = 'SAVE 50%';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        savingsText,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBestValueBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        'BEST VALUE',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeatures(AppLocalizations l10n) {
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
            l10n.get('premiumFeatures'),
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.all_inclusive,
            title: l10n.get('unlimitedCheckin'),
            description: l10n.get('unlimitedCheckinDesc'),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.assessment,
            title: l10n.get('fullReport'),
            description: l10n.get('fullReportDesc'),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.cloud_download,
            title: l10n.get('downloadShare'),
            description: l10n.get('downloadShareDesc'),
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

  Widget _buildPurchaseButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isPurchasing || _selectedProduct == null
            ? null
            : _purchaseSubscription,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textOnDark,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.textOnDark.withValues(alpha:0.5),
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
                l10n.get('subscribeNow'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildRestoreButton(AppLocalizations l10n) {
    return TextButton(
      onPressed: _restorePurchase,
      child: Text(
        l10n.get('restorePurchase'),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textOnDark,
        ),
      ),
    );
  }

  Widget _buildTerms(AppLocalizations l10n) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textOnDark.withValues(alpha:0.7),
            ),
            children: [
              TextSpan(text: l10n.get('termsOfService') + ' '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: InkWell(
                  onTap: () => _openUrl('https://roamquest.xyz/terms'),
                  child: Text(
                    l10n.get('termsAndPrivacy'),
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textOnDark,
                    ),
                  ),
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text.rich(
          TextSpan(
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textOnDark.withValues(alpha:0.6),
            ),
            children: [
              TextSpan(text: l10n.get('autoRenew')),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: InkWell(
                  onTap: () => _openUrl('https://support.apple.com/HT202039'),
                  child: Text(
                    '\n\n' + l10n.get('howToCancel'),
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textOnDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
