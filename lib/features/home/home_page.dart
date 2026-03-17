import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/city.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';
import '../../data/services/location_service.dart';
import '../../data/services/city_service.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/checklist_repository.dart';
import '../checklist/checklist_page.dart';
import 'city_selection_bottom_sheet.dart';
import 'package:uuid/uuid.dart';

/// Home page - City discovery & checklist generation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _locationService = LocationService();
  final CityService _cityService = CityService.instance;
  final AIService _aiService = AIService();
  final ChecklistRepository _checklistRepo = ChecklistRepository();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  List<Checklist> _recentChecklists = [];

  @override
  void initState() {
    super.initState();
    _loadRecentChecklists();
  }

  /// Load recent checklists
  Future<void> _loadRecentChecklists() async {
    try {
      final recent = await _checklistRepo.getAllChecklists();
      // Sort by creation time descending, take last 5
      recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _recentChecklists = recent.take(5).toList();
        });
      }
    } catch (e) {
      // Ignore errors, history is optional
    }
  }

  /// Generate checklist for a city, or open existing one
  Future<void> _generateChecklist(City city) async {
    setState(() {
      _isLoading = true;
    });

    AppLogger.info('生成清单 - 城市名称: ${city.name}, 国家: ${city.country}, ID: ${city.id}');

    try {
      // Check if there's already a checklist for this city (user's local checklist)
      final existingChecklist = await _checklistRepo.getChecklistForCity(city);

      AppLogger.info('用户清单查询结果: ${existingChecklist != null ? "找到清单 ${existingChecklist.id}" : "未找到清单"}');

      if (existingChecklist != null) {
        // Open existing checklist
        AppLogger.info('打开已有清单: ${existingChecklist.id}');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChecklistPage(checklist: existingChecklist),
            ),
          ).then((_) => _loadRecentChecklists());
        }
        return;
      }

      // Check if there's a template for this city
      AppLogger.info('查询景点模板 - cityId: ${city.id}, language: en');
      final templateItems = await _checklistRepo.getChecklistTemplate(
        cityId: city.id,
        language: 'en',
      );

      AppLogger.info('景点模板查询结果: ${templateItems != null ? "找到 ${templateItems!.length} 个景点" : "未找到模板"}');

      List<ChecklistItem> items;

      if (templateItems != null && templateItems!.isNotEmpty) {
        // Use template items
        items = templateItems!;
      } else {
        // No template, generate with AI
        AppLogger.info('使用 AI 生成景点 - 城市: ${city.name}');
        final aiResult = await _aiService.generateChecklistWithRetry(
          city,
          'en', // Use English
        );
        items = aiResult.items;
        AppLogger.info('AI 生成完成 - ${items.length} 个景点');

        // Save as template for future use
        try {
          await _checklistRepo.saveChecklistTemplate(
            cityId: city.id,
            items: items,
            language: 'en',
          );
          AppLogger.info('AI 生成的景点已保存到 attractions 表');
        } catch (e) {
          // Failed to save template, but continue with checklist
          AppLogger.error('保存 AI 生成的景点失败', error: e);
        }
      }

      // Create checklist (header only, items saved separately)
      final userId = _authService.currentUserId ?? 'anonymous';
      final checklistId = const Uuid().v4(); // 生成正确的 UUID 格式
      final checklist = Checklist(
        id: checklistId,
        city: city,
        cityId: city.id,
        userId: userId,
        createdAt: DateTime.now(),
        language: 'en',
      );

      AppLogger.info('创建 checklist - id: ${checklist.id}, userId: $userId, cityId: ${city.id}');

      // Save checklist header to local and cloud
      await _checklistRepo.saveChecklist(checklist);

      AppLogger.info('保存 checklist 完成 - id: ${checklist.id}');

      // Save checklist items separately
      await _checklistRepo.saveChecklistItems(checklist.id, items);

      AppLogger.info('保存 checklist items 完成 - checklistId: ${checklist.id}, 数量: ${items.length}');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChecklistPage(checklist: checklist),
          ),
        ).then((_) => _loadRecentChecklists());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load city: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      _buildContent(),
                      // Show recent checklists
                      if (_recentChecklists.isNotEmpty) ...[
                        const SizedBox(height: 40),
                        _buildRecentChecklists(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'RoamQuest',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.textOnDark,
            fontSize: 42,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Explore cities, discover wonders',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    // Always show the create button (but disabled when loading)
    return _buildCreateButton();
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const CircularProgressIndicator(
          color: AppColors.textOnDark,
        ),
        const SizedBox(height: 16),
        Text(
          'Loading...',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
      ],
    );
  }

  /// Large circular create button
  Widget _buildCreateButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive size: 200px or 60% of screen width, whichever is smaller
        final buttonSize = (200.0).clamp(0.0, constraints.maxWidth * 0.6);

        return GestureDetector(
          // Disable button interactions when loading
          onTapDown: _isLoading ? null : (_) => setState(() {}),
          onTapUp: _isLoading ? null : (_) {
            setState(() {});
            _showCreateOptions();
          },
          onTapCancel: () => setState(() {}),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Stack(
                  children: [
                    // Base button container
                    Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.sunsetGradient,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF81C784), // Popular green
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _isLoading ? 'Loading...' : 'Create Checklist',
                                style: AppTextStyles.h3.copyWith(
                                  color: _isLoading
                                      ? AppColors.textOnDark.withValues(alpha: 0.7)
                                      : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Semi-transparent overlay when loading
                    if (_isLoading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.textOnDark.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Show create options bottom sheet
  void _showCreateOptions() {
    AppActionSheet.show(
      context: context,
      title: 'Select City',
      actions: [
        AppActionSheetItem(
          label: '📍 Detect My Location',
          value: 'location',
          onTap: _detectMyLocation,
        ),
        AppActionSheetItem(
          label: '🏙️ Select from List',
          value: 'list',
          onTap: _showCityList,
        ),
      ],
      cancelLabel: 'Cancel',
    );
  }

  /// Detect current location and generate checklist
  Future<void> _detectMyLocation() async {
    print('[Home] Detect My Location clicked');
    setState(() {
      _isLoading = true;
    });

    try {
      // Get city from location service
      print('[Home] Calling getCurrentCity...');
      final locationCity = await _locationService.getCurrentCity();
      print('[Home] Location detected: ${locationCity.name}, ${locationCity.country}');

      // Find or create city in database (handles new cities automatically)
      print('[Home] Checking if city exists in database...');
      final city = await _cityService.findOrCreateCity(
        locationCity.name,
        locationCity.country,
        locationCity.countryCode,
        locationCity.latitude,
        locationCity.longitude,
      );
      print('[Home] City ready: ${city.name}');

      if (mounted) {
        await _generateChecklist(city);
      }
    } catch (e) {
      // If location detection fails, silently close the sheet
      // User can try again or select from list
      print('[Home] Location detection failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to detect location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show city selection list
  void _showCityList() {
    CitySelectionBottomSheet.show(
      context: context,
      onCitySelected: (city) async {
        await _generateChecklist(city);
      },
    );
  }

  /// Show recent checklists
  Widget _buildRecentChecklists() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Explorations',
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
        const SizedBox(height: 16),
        ..._recentChecklists.map((checklist) => _buildRecentChecklistCard(checklist)),
      ],
    );
  }

  /// Single recent checklist card
  Widget _buildRecentChecklistCard(Checklist checklist) {
    return FutureBuilder<List<ChecklistItem>>(
      future: _checklistRepo.loadChecklistItems(checklist.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final completedCount = Checklist.getCompletedCount(items);

        return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openChecklist(checklist),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.textOnDark.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textOnDark.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getCityEmoji(checklist.city.name),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checklist.city.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedCount/${items.length} Completed',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textOnDark.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  /// Get emoji icon based on city name
  String _getCityEmoji(String cityName) {
    final emojis = {
      'Amsterdam': '🌷',
      'Athens': '🏛️',
      'Auckland': '🇳🇿',
      'Bangkok': '🛕',
      'Barcelona': '⚽',
      'Berlin': '🏰',
      'Boston': '🦞',
      'Cairo': '🏜️',
      'Copenhagen': '🧜',
      'Dubai': '🏗️',
      'Dublin': '🍺',
      'Edinburgh': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
      'Florence': '🎨',
      'Hong Kong': '🇭🇰',
      'Istanbul': '🕌',
      'Las Vegas': '🎰',
      'Lisbon': '🧭',
      'London': '🎡',
      'Los Angeles': '🌴',
      'Madrid': '🐂',
      'Miami': '🏖️',
      'Milan': '👗',
      'Montreal': '🍁',
      'Moscow': '🏰',
      'Mumbai': '🕌',
      'New York': '🗽',
      'Oslo': '🇳🇴',
      'Paris': '🗼',
      'Prague': '🌉',
      'Rio de Janeiro': '🎭',
      'Rome': '🏛️',
      'San Francisco': '🌉',
      'Seattle': '☕',
      'Seoul': '🇰🇷',
      'Shanghai': '🏙️',
      'Singapore': '🇸🇬',
      'Stockholm': '🇸🇪',
      'Sydney': '🦘',
      'Tokyo': '🗼',
      'Toronto': '🍁',
      'Vancouver': '🍁',
      'Venice': '⛵',
      'Vienna': '🎵',
      'Washington DC': '🏛️',
      'Zurich': '🇨🇭',
      'Beijing': '🏯',
      'Shanghai': '🏙️',
    };
    return emojis[cityName] ?? '🌍';
  }

  /// Open checklist
  void _openChecklist(Checklist checklist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistPage(checklist: checklist),
      ),
    ).then((_) {
      // Refresh history when returning
      _loadRecentChecklists();
    });
  }
}
