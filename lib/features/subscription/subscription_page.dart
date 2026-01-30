import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeSubscription();
  }

  @override
  void dispose() {
    _subscriptionRepo.dispose();
    super.dispose();
  }

  Future<void> _initializeSubscription() async {
    await _subscriptionRepo.initialize();

    // Default to yearly selection
    if (mounted) {
      setState(() {
        _selectedProduct = _getYearlyProduct();
      });
    }
  }

  ProductDetails? _getMonthlyProduct() {
    return _subscriptionRepo.products.value
        .where((p) => p.id == SubscriptionProducts.monthly)
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
    await _subscriptionRepo.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('购买已恢复')),
      );
    }
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
              '欢迎升级Premium！',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '您现在可以无限打卡',
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
                child: const Text('开始探索'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('购买失败'),
        content: const Text(
          '无法完成购买，请重试。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSubscriptionPlans(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFeatures(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPurchaseButton(),
                    const SizedBox(height: AppSpacing.md),
                    _buildRestoreButton(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTerms(),
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
          child: const Icon(
            Icons.workspace_premium,
            size: 48,
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '升级Premium',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '解锁无限城市探索',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionPlans() {
    return ValueListenableBuilder(
      valueListenable: _subscriptionRepo.status,
      builder: (context, status, _) {
        // Show message for web platform
        if (status == SubscriptionStatus.unavailable) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withOpacity(0.15),
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
                  'Web平台暂不支持订阅',
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '请在iOS或Android设备上使用订阅功能',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDark.withOpacity(0.8),
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
                  product: yearly,
                  isSelected: _selectedProduct == yearly,
                  onTap: () {
                    setState(() => _selectedProduct = yearly);
                  },
                  badge: _buildSavingsBadge(yearly, monthly),
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
          color: isSelected ? AppColors.textOnDark : AppColors.textOnDark.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
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
                        ? AppColors.textOnDark.withOpacity(0.8)
                        : AppColors.textOnDark.withOpacity(0.7),
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

  Widget _buildSavingsBadge(ProductDetails? yearly, ProductDetails? monthly) {
    if (yearly == null || monthly == null) return const SizedBox.shrink();

    // Calculate savings (rough estimate)
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
        'SAVE 50%',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w600,
        ),
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
            'Premium功能',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.all_inclusive,
            title: '无限打卡',
            description: '完成每个城市的全部20个体验',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.assessment,
            title: '完整探险报告',
            description: '包含所有回忆的精美报告',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildFeatureItem(
            icon: Icons.cloud_download,
            title: '下载与分享',
            description: '保存报告并与朋友分享',
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
        onPressed: _isPurchasing || _selectedProduct == null
            ? null
            : _purchaseSubscription,
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
            : const Text(
                '立即订阅',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _restorePurchase,
      child: Text(
        '恢复购买',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textOnDark,
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Column(
      children: [
        Text(
          '订阅即表示您同意我们的服务条款和隐私政策。',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textOnDark.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '订阅将自动续订，除非在到期前至少24小时取消。',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textOnDark.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
