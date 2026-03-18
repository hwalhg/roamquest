import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';
import '../../data/models/city.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/city_service.dart';
import '../../data/services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import 'city_selection_bottom_sheet.dart';
import '../checklist/checklist_page.dart';
import '../subscription/city_subscription_page.dart';

/// Home page - Main entry for city exploration
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChecklistRepository _checklistRepo = ChecklistRepository();
  final CityService _cityService = CityService.instance;
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  final AIService _aiService = AIService();

  List<Checklist> _recentChecklists = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentChecklists();
  }

  /// Load recent checklists
  Future<void> _loadRecentChecklists() async {
    try {
      final checklists = await _checklistRepo.getAllChecklists();
      // Sort by created date descending and take only first 5
      checklists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final recentChecklists = checklists.take(5).toList();

      if (mounted) {
        setState(() {
          _recentChecklists = recentChecklists;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load recent checklists', error: e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load checklists';
          _isLoading = false;
        });
      }
    }
  }

  /// Auto-detect location and generate checklist
  Future<void> _detectLocation() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      AppLogger.info('开始自动位置检测');

      // Get current city from location service
      final currentCity = await _locationService.getCurrentCity();
      AppLogger.info('检测到城市: ${currentCity.name}, ${currentCity.country}');

      // Find or create city in database
      final city = await _cityService.findOrCreateCity(
        currentCity.name,
        currentCity.country,
        currentCity.countryCode,
        currentCity.latitude,
        currentCity.longitude,
      );

      // Generate checklist for this city
      await _generateChecklistForCity(city);
    } on LocationException catch (e) {
      AppLogger.error('位置检测失败: ${e.message}');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = e.message;
        });
        _showErrorDialog(e.message);
      }
    } catch (e) {
      AppLogger.error('自动检测失败', error: e);
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = 'Failed to detect location';
        });
        _showErrorDialog('Failed to detect location. Please try selecting a city manually.');
      }
    }
  }

  /// Generate checklist for selected city
  Future<void> _generateChecklistForCity(City city) async {
    try {
      AppLogger.info('开始为城市生成清单: ${city.name}');

      // Get app language
      final l10n = AppLocalizations.of(context)!;
      final language = l10n.locale.languageCode;

      // Check if template already exists
      final template = await _checklistRepo.getChecklistTemplate(
        cityId: city.id,
        language: language,
      );

      List<ChecklistItem> items;

      if (template != null && template.isNotEmpty) {
        // Use existing template
        AppLogger.info('使用已存在的模板，${template.length} 个项目');
        items = template;
      } else {
        // Generate with AI
        AppLogger.info('调用 AI 生成新清单');
        final result = await _aiService.generateChecklistWithRetry(
          city,
          language,
        );
        items = result.items;

        // Save as template for future use
        await _checklistRepo.saveChecklistTemplate(
          cityId: city.id,
          items: items,
          language: language,
        );
      }

      // Get current user ID
      final userId = _authService.currentUserId ?? 'anonymous';

      // Create checklist
      final checklist = Checklist(
        id: const Uuid().v4(),
        cityId: city.id,
        city: city,
        userId: userId,
        createdAt: DateTime.now(),
        language: language,
      );

      // Save checklist header to local and cloud
      await _checklistRepo.saveChecklist(checklist);

      AppLogger.info('保存 checklist 完成 - id: ${checklist.id}');
      AppLogger.info('即将保存 checklist items，items 数量: ${items.length}');

      // Save checklist items separately
      await _checklistRepo.saveChecklistItems(checklist.id, items);

      AppLogger.info('保存 checklist items 完成 - checklistId: ${checklist.id}, 数量: ${items.length}');

      // Navigate to checklist page
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

        // Reload recent checklists
        await _loadRecentChecklists();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChecklistPage(checklist: checklist),
          ),
        );
      }
    } on AIServiceException catch (e) {
      AppLogger.error('AI 生成失败', error: e);
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = e.message;
        });
        _showErrorDialog('Failed to generate checklist. Please try again.');
      }
    } catch (e) {
      AppLogger.error('生成清单失败', error: e);
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = 'Failed to generate checklist';
        });
        _showErrorDialog('Failed to generate checklist. Please try again.');
      }
    }
  }

  /// Show city selection
  void _showCitySelection() {
    CitySelectionBottomSheet.show(
      context: context,
      onCitySelected: (city) {
        _generateChecklistForCity(city);
      },
    );
  }

  /// Open checklist from history
  void _openChecklist(Checklist checklist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistPage(checklist: checklist),
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(l10n),
          _buildContent(l10n),
        ],
      ),
      floatingActionButton: _isGenerating
          ? null
          : FloatingActionButton.extended(
              onPressed: _showCitySelection,
              icon: const Icon(Icons.location_city),
              label: Text(l10n.get('selectCity') ?? 'Select City'),
              backgroundColor: AppColors.primary,
            ),
    );
  }

  Widget _buildAppBar(AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          l10n.get('exploreCities') ?? 'Explore Cities',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.sunsetGradient,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isGenerating) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.get('generating') ?? 'Generating checklist...',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _recentChecklists.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: _showCitySelection,
                icon: const Icon(Icons.location_city),
                label: Text(l10n.get('selectCity') ?? 'Select City'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-detect button
            if (!kIsWeb)
              _buildAutoDetectButton(l10n),
            const SizedBox(height: AppSpacing.lg),

            // Recent checklists
            Text(
              l10n.get('recent') ?? 'Recent',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRecentList(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoDetectButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: ElevatedButton.icon(
        onPressed: _detectLocation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
          ),
        ),
        icon: const Icon(
          Icons.my_location,
          color: AppColors.textOnDark,
        ),
        label: Text(
          AppLocalizations.of(context)!.get('detectLocation') ?? 'Auto-detect Location',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentList(AppLocalizations l10n) {
    if (_recentChecklists.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.explore_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.get('noRecent') ?? 'No recent explorations',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentChecklists.length,
      itemBuilder: (context, index) {
        final checklist = _recentChecklists[index];
        return _buildChecklistTile(checklist, index);
      },
    );
  }

  Widget _buildChecklistTile(Checklist checklist, int index) {
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
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: InkWell(
          onTap: () => _openChecklist(checklist),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      _getCityEmoji(checklist.city.name),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checklist.city.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(checklist.createdAt),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCityEmoji(String cityName) {
    final lowerName = cityName.toLowerCase();
    if (lowerName.contains('paris')) return '🗼';
    if (lowerName.contains('london')) return '🎡';
    if (lowerName.contains('tokyo')) return '🗼';
    if (lowerName.contains('new york')) return '🗽';
    if (lowerName.contains('sydney')) return '🦘';
    if (lowerName.contains('beijing')) return '🏯';
    if (lowerName.contains('rome')) return '🏛️';
    return '🏙️';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Exception wrapper for LocationService
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
