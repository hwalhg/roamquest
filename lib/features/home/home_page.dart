import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';
import '../../data/models/city.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/location_service.dart';
import '../../data/services/city_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/subscription_status_service.dart';
import '../../l10n/app_localizations.dart';
import 'city_selection_bottom_sheet.dart';
import '../checklist/checklist_page.dart';
import 'city_selection_dialog.dart' as selection;

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
  final SubscriptionStatusService _subscriptionStatus = SubscriptionStatusService();

  bool _isGenerating = false;
  List<City> _unlockedCities = [];

  @override
  void initState() {
    super.initState();
    _loadUnlockedCities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cities when returning to this page
    _loadUnlockedCities();
  }

  /// Load unlocked cities from user's checklists
  Future<void> _loadUnlockedCities() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      AppLogger.warning('User ID is null, cannot load unlocked cities');
      return;
    }

    try {
      AppLogger.info('开始加载用户的解锁城市，userId: $userId');

      // Get all checklists for this user
      final allChecklists = await _checklistRepo.getAllChecklists();
      AppLogger.info('从数据库获取到 ${allChecklists.length} 个 checklists');

      // Extract unique cities from checklists
      final uniqueCities = <City>{};
      for (final checklist in allChecklists) {
        AppLogger.info('Checklist: ${checklist.id}, 城市: ${checklist.city.name}');
        uniqueCities.add(checklist.city);
      }

      setState(() {
        _unlockedCities = uniqueCities.toList();
      });

      AppLogger.info('成功加载 ${_unlockedCities.length} 个解锁城市: ${_unlockedCities.map((c) => c.name).join(', ')}');
    } catch (e, stackTrace) {
      AppLogger.error('加载解锁城市失败', error: e, stackTrace: stackTrace);
    }
  }

  /// Auto-detect location and generate checklist
  Future<void> _detectLocation() async {
    setState(() {
      _isGenerating = true;
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
        });
        _showErrorDialog(e.message);
      }
    } catch (e) {
      AppLogger.error('自动检测失败', error: e);
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showErrorDialog('Failed to detect location. Please try selecting a city manually.');
      }
    }
  }

  /// Generate checklist for selected city
  Future<void> _generateChecklistForCity(City city) async {
    try {
      AppLogger.info('开始为城市生成清单: ${city.name}');

      // 先检查该城市是否已有未完成的 checklist
      final existingChecklist = await _checklistRepo.getIncompleteChecklistForCity(city);

      if (existingChecklist != null) {
        // 有该城市的清单，检查是否有 items
        AppLogger.info('找到已存在的清单，检查 items - id: ${existingChecklist.id}');

        // Load items for this checklist
        final items = await _checklistRepo.loadChecklistItems(existingChecklist.id);

        if (items.isEmpty) {
          // Items 为空，需要创建 items
          AppLogger.info('清单为空，创建 items');
          await _createChecklistItems(existingChecklist, city);
        }

        if (mounted) {
          setState(() {
            _isGenerating = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChecklistPage(checklist: existingChecklist),
            ),
          );
        }
        return;
      }

      // 没有该城市的清单，创建新的
      AppLogger.info('没有该城市的清单，创建新清单');

      // Get app language
      final l10n = AppLocalizations.of(context)!;
      final language = l10n.locale.languageCode;

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

      // Create checklist items
      await _createChecklistItems(checklist, city);

      // Navigate to checklist page
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });

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
        });
        _showErrorDialog('Failed to generate checklist. Please try again.');
      }
    } catch (e) {
      AppLogger.error('生成清单失败', error: e);
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showErrorDialog('Failed to generate checklist. Please try again.');
      }
    }
  }

  /// Show city selection dialog
  void _showCitySelection() {
    selection.CitySelectionBottomSheet.show(
      context: context,
      onDetectLocation: _detectLocation,
      onSelectFromList: () {
        CitySelectionBottomSheet.show(
          context: context,
          onCitySelected: (city) {
            _generateChecklistForCity(city);
          },
        );
      },
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A11CB), Color(0xFFFFA500)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App name
                    Text(
                      l10n.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      l10n.appSlogan,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Create Checklist button
                    GestureDetector(
                      onTap: _showCitySelection,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isGenerating
                              ? const SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Color(0xFF6A11CB),
                                  ),
                                )
                              : Text(
                                  l10n.createChecklist,
                                  style: const TextStyle(
                                    color: Color(0xFF6A11CB),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Unlocked cities list - Simple design
                    if (_unlockedCities.isNotEmpty)
                      Column(
                        children: [
                          // Title with count
                          Text(
                            'Unlocked Cities (${_unlockedCities.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Cities list - simple text chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _unlockedCities.map((city) {
                              return _buildSimpleCityChip(city);
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Auto-detect floating button (optional, small)
              if (!kIsWeb)
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: _isGenerating ? null : _detectLocation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build simple city chip - minimal design with click to navigate
  Widget _buildSimpleCityChip(City city) {
    return GestureDetector(
      onTap: () => _navigateToCityChecklist(city),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Small flag
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.network(
                'https://flagcdn.com/w20/${city.countryCode.toLowerCase()}.png',
                width: 20,
                height: 15,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(width: 6),
            // City name only
            Text(
              city.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to city checklist
  Future<void> _navigateToCityChecklist(City city) async {
    try {
      AppLogger.info('点击城市芯片，导航到: ${city.name}');

      // 查找该城市的 checklist
      final checklist = await _checklistRepo.getIncompleteChecklistForCity(city);

      if (checklist != null) {
        // 找到 checklist，检查是否有 items
        final items = await _checklistRepo.loadChecklistItems(checklist.id);

        if (items.isEmpty) {
          // Items 为空，创建 items
          AppLogger.info('清单为空，创建 items');
          await _createChecklistItems(checklist, city);
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChecklistPage(checklist: checklist),
            ),
          );
        }
      } else {
        // 没有找到 checklist，提示用户
        if (mounted) {
          _showErrorDialog('No checklist found for ${city.name}. Please create a new one.');
        }
      }
    } catch (e) {
      AppLogger.error('导航到城市清单失败', error: e);
      if (mounted) {
        _showErrorDialog('Failed to open checklist. Please try again.');
      }
    }
  }

  /// Create checklist items for a checklist
  Future<void> _createChecklistItems(Checklist checklist, City city) async {
    final l10n = AppLocalizations.of(context)!;
    final language = checklist.language;

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

    // Save checklist items
    await _checklistRepo.saveChecklistItems(checklist.id, items);
    AppLogger.info('保存 checklist items 完成 - checklistId: ${checklist.id}, 数量: ${items.length}');
  }
}
