import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/services/subscription_status_service.dart';
import '../../l10n/app_localizations.dart';
import '../checkin/checkin_page.dart';
import '../report/report_page.dart';
import '../subscription/city_subscription_page.dart';
import 'add_checklist_item_page.dart';

/// Checklist display page
class ChecklistPage extends StatefulWidget {
  final Checklist checklist;

  const ChecklistPage({
    super.key,
    required this.checklist,
  });

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage>
    with SingleTickerProviderStateMixin {
  late Checklist _checklist;
  late TabController _tabController;
  String _selectedCategory = 'all';
  final ChecklistRepository _checklistRepo = ChecklistRepository();
  final SubscriptionStatusService _subscriptionService = SubscriptionStatusService();
  bool _isCityUnlocked = false;
  Map<String, int>? _remainingFreeCheckIns;

  List<CategoryItem> _categories = [];

  @override
  void initState() {
    super.initState();
    _checklist = widget.checklist;
    _tabController = TabController(length: 5, vsync: this); // 5 categories
    _tabController.addListener(_handleTabChange);
    _checkSubscriptionStatus();
  }

  void _initCategories(AppLocalizations l10n) {
    _categories = [
      CategoryItem(id: 'all', name: l10n.get('all'), icon: '📋'),
      CategoryItem(id: 'landmark', name: l10n.landmark, icon: '🏛️'),
      CategoryItem(id: 'food', name: l10n.food, icon: '🍜'),
      CategoryItem(id: 'experience', name: l10n.experience, icon: '🎭'),
      CategoryItem(id: 'hidden', name: l10n.hiddenGem, icon: '💎'),
    ];
  }

  Future<void> _checkSubscriptionStatus() async {
    final isUnlocked = await _subscriptionService.isCityUnlocked(_checklist.city);
    final remaining = await _subscriptionService.getRemainingFreeCheckIns(
      _checklist.city,
      _checklist.items,
    );
    if (mounted) {
      setState(() {
        _isCityUnlocked = isUnlocked;
        _remainingFreeCheckIns = remaining;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging && _categories.isNotEmpty) {
      setState(() {
        _selectedCategory = _categories[_tabController.index].id;
      });
    }
  }

  void _updateChecklist(Checklist updated) {
    setState(() {
      _checklist = updated;
    });
    // 保存更新后的清单
    _checklistRepo.saveChecklist(updated).then((_) {
      // Check if all items are completed
      if (updated.completedCount >= updated.items.length) {
        // Clear current checklist ID when all items are completed
        _checklistRepo.clearCurrentChecklist().catchError((e) {
          debugPrint('Failed to clear current checklist: $e');
        });
      }
    }).catchError((e) {
      // 静默失败，不影响用户体验
      debugPrint('Failed to save checklist: $e');
    });
  }

  List<ChecklistItem> get _filteredItems {
    if (_selectedCategory == 'all') {
      return _checklist.items;
    }
    return _checklist.getItemsByCategory(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Initialize categories with localized names
    if (_categories.isEmpty) {
      _initCategories(l10n);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildProgressHeader(l10n),
          ),
          SliverToBoxAdapter(
            child: _buildCategoryTabs(l10n),
          ),
          _buildItemsList(l10n),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Share button (only show when there are completed items)
          if (_checklist.completedCount > 0)
            FloatingActionButton.extended(
              onPressed: () => _viewReport(),
              icon: const Icon(Icons.share),
              label: Text('${l10n.get('share')} (${_checklist.completedCount})'),
              heroTag: 'share',
              backgroundColor: AppColors.success,
            ),
          if (_checklist.completedCount > 0) const SizedBox(height: 8),
          // Add item button (always show)
          FloatingActionButton.extended(
            onPressed: () => _openAddItemPage(),
            icon: const Icon(Icons.add),
            label: const Text('添加'),
            heroTag: 'add',
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _checklist.city.name,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.get('progress'),
                style: AppTextStyles.h3,
              ),
              Text(
                '${_checklist.completedCount}/${_checklist.items.length}',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: LinearProgressIndicator(
              value: _checklist.progress,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${l10n.get('completed')} ${_checklist.progressPercentage}%',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category.id;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text('${category.icon} ${category.name}'),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category.id;
                  });
                  _tabController.animateTo(_categories.indexOf(category));
                },
                backgroundColor: AppColors.surfaceVariant,
                selectedColor: AppColors.primary,
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.textOnDark : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildItemsList(AppLocalizations l10n) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _filteredItems[index];
            return _buildItemCard(item, index, l10n);
          },
          childCount: _filteredItems.length,
        ),
      ),
    );
  }

  Widget _buildItemCard(ChecklistItem item, int index, AppLocalizations l10n) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: AppConstants.animationDurationMs),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Card(
          child: InkWell(
            onTap: () => _openItem(item, l10n),
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _buildCategoryIcon(item.category),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                style: AppTextStyles.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildCompletionBadge(item, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    final icon = AppConstants.categoryIcons[category] ?? '📍';
    final color = AppColors.getCategoryColor(category);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Center(
        child: Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildCompletionBadge(ChecklistItem item, AppLocalizations l10n) {
    if (item.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          color: AppColors.textOnDark,
          size: 20,
        ),
      );
    } else if (_isCityUnlocked) {
      // City is unlocked - show unlock icon
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_open,
          color: AppColors.success,
          size: 20,
        ),
      );
    } else if (item.order < AppConstants.freeCheckinLimit) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
        child: Text(
          l10n.freeCheckin,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      return Icon(
        Icons.lock_outline,
        color: AppColors.textTertiary,
      );
    }
  }

  void _openItem(ChecklistItem item, AppLocalizations l10n) async {
    // If already completed, allow editing without subscription check
    if (item.isCompleted) {
      _navigateToCheckin(item);
      return;
    }

    // Check if user can check in (either unlocked or within free tier)
    final canCheckIn = await _subscriptionService.canCheckIn(
      _checklist.city,
      _checklist.completedItems,
      item, // Pass the item to check if it's within free tier
    );

    if (canCheckIn) {
      _navigateToCheckin(item);
    } else {
      _showPaywallDialog(l10n);
    }
  }

  void _navigateToCheckin(ChecklistItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckinPage(
          checklist: _checklist,
          item: item,
          onCheckinComplete: (updatedItem) {
            _updateChecklist(_checklist.updateItem(updatedItem));
          },
        ),
      ),
    );
  }

  void _showPaywallDialog(AppLocalizations l10n) {
    final remaining = _remainingFreeCheckIns;
    final cityPrice = _checklist.city.subscriptionPrice;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.upgradePremium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _checklist.city.isFree ? Icons.lock_open : Icons.lock,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.unlockUnlimited,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_checklist.city.isFree)
              Text(
                l10n.get('freeCity'),
                style: AppTextStyles.bodySmall,
              )
            else
              Text(
                '\$$cityPrice - ${l10n.get('oneTimePurchase')}',
                style: AppTextStyles.bodySmall,
              ),
            if (remaining != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${l10n.get('freeTierRemaining')}\n'
                '${l10n.landmark} ${remaining['landmark']}, '
                '${l10n.food} ${remaining['food']}, '
                '${l10n.experience} ${remaining['experience']}, '
                '${l10n.hiddenGem} ${remaining['hidden']}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.get('shareDiaryFree'),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('later')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CitySubscriptionPage(city: _checklist.city),
                ),
              ).then((_) => _checkSubscriptionStatus());
            },
            child: Text(_checklist.city.isFree ? l10n.get('unlockFree') : '${l10n.get('unlock')} \$${cityPrice.toStringAsFixed(2)}'),
          ),
        ],
      ),
    );
  }

  void _viewReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPage(checklist: _checklist),
      ),
    );
  }

  void _openAddItemPage() async {
    final result = await Navigator.push<ChecklistItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddChecklistItemPage(
          checklist: _checklist,
        ),
      ),
    );

    if (result != null) {
      // Reload checklist to show the new item
      final updatedChecklist = await _checklistRepo.getChecklistForCity(_checklist.city);
      if (updatedChecklist != null) {
        setState(() {
          _checklist = updatedChecklist;
        });
      }
    }
  }
}

class CategoryItem {
  final String id;
  final String name;
  final String icon;

  CategoryItem({required this.id, required this.name, required this.icon});
}
