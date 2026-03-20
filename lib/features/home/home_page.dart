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

  /// Load unlocked cities from user's checklists
  Future<void> _loadUnlockedCities() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      // Get all checklists for this user
      final allChecklists = await _checklistRepo.getAllChecklists();

      // Extract unique cities from checklists
      final uniqueCities = <City>{};
      for (final checklist in allChecklists) {
        uniqueCities.add(checklist.city);
      }

      setState(() {
        _unlockedCities = uniqueCities.toList();
      });

      AppLogger.info('Loaded ${_unlockedCities.length} unlocked cities from checklists');
    } catch (e) {
      AppLogger.error('Failed to load unlocked cities', error: e);
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
                    const SizedBox(height: 40),
                    // Unlocked cities list
                    if (_unlockedCities.isNotEmpty)
                      Container(
                        height: 150,
                        width: 300,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Cities',
                              style: const TextStyle(
                                color: Color(0xFF2D3436),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _unlockedCities.length,
                                itemBuilder: (context, index) {
                                  final city = _unlockedCities[index];
                                  return _buildCityChip(city);
                                },
                              ),
                            ),
                          ],
                        ),
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

  /// Build city chip widget
  Widget _buildCityChip(City city) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://flagcdn.com/w40/${city.countryCode.toLowerCase()}.png',
              width: 32,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    size: 16,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            city.name,
            style: const TextStyle(
              color: Color(0xFF2D3436),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
