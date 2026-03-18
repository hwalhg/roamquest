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
      body: _buildBody(l10n),
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

  /// Build main body content
  Widget _buildBody(AppLocalizations l10n) {
    // Centered circular design element at the top
    return Stack(
      children: [
        // Purple gradient app bar with title
        _buildTopBar(l10n),

        // Main content area
        _buildContent(l10n),

        // Floating action button (from Scaffold)
      ],
    );
  }

  /// Build purple gradient app bar
  Widget _buildTopBar(AppLocalizations l10n) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.sunsetGradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.textOnDark.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore,
                  size: 32,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(width: 16),
              // App title and slogan
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.get('appName') ?? 'RoamQuest',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.get('appSlogan') ?? 'Explore cities, discover wonders',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnDark.withValues(alpha: 0.8),
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build content with central circular design
  Widget _buildContent(AppLocalizations l10n) {
    if (_isGenerating) {
      return _buildLoadingState();
    }

    if (_error != null && _recentChecklists.isEmpty) {
      return _buildErrorState();
    }

    // Main content with centered circular design element
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Centered circular design element
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                  ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "Explore" text in circle
                  Text(
                    l10n.get('exploreCities') ?? 'Explore',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 32,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Location icons in circle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Auto-detect icon with gradient button
                      _buildLocationButton(l10n),
                      const SizedBox(width: 20),
                      // Select from list icon
                      _buildSelectButton(l10n),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Recent checklists section
          _buildRecentSection(l10n),
        ],
      ),
    );
  }

  /// Build auto-detect location button with gradient
  Widget _buildLocationButton(AppLocalizations l10n) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentYellow.withValues(alpha: 0.3),
            AppColors.accentYellow.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: InkWell(
          onTap: !kIsWeb ? _detectLocation : null,
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.my_location,
              size: 24,
              color: AppColors.textOnDark,
            ),
          ),
        ),
      ),
    );
  }

  /// Build select from list button
  Widget _buildSelectButton(AppLocalizations l10n) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.3),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: InkWell(
          onTap: _showCitySelection,
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.location_city,
              size: 24,
              color: AppColors.textOnDark,
            ),
          ),
        ),
      );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Generating checklist...',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
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
            'Failed to load checklists',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _showCitySelection,
            child: const Text('Select a City'),
          ),
        ],
      ),
    );
  }

  /// Build recent checklists section
  Widget _buildRecentSection(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg, bottom: AppSpacing.md),
            child: Text(
              l10n.get('recent') ?? 'Recent',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Recent list
          if (_recentChecklists.isEmpty) {
            _buildEmptyState(l10n);
          } else {
            _buildRecentList(l10n);
          },
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
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

  /// Build recent list with animated items
  Widget _buildRecentList(AppLocalizations l10n) {
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

  /// Build checklist tile with animation
  Widget _buildChecklistTile(Checklist checklist, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: AppConstants.animationDurationMs),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildChecklistCardContent(checklist),
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
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
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
                const Icon(
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
