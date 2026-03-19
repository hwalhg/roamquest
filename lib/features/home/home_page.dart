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

  bool _isGenerating = false;

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
        // 有未完成的清单，直接打开
        AppLogger.info('找到未完成的清单，直接打开 - id: ${existingChecklist.id}');
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

      // 没有未完成的清单，创建新的
      AppLogger.info('没有未完成的清单，创建新清单');

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
}
