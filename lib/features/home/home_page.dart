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
import '../checklist/create_custom_checklist_page.dart';
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
  bool _isOpeningStartedCity = false;
  List<City> _startedCities = [];
  List<Checklist> _customChecklists = [];
  Map<String, int> _customChecklistSpotCounts = {};

  @override
  void initState() {
    super.initState();
    _loadStartedCities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStartedCities();
  }

  /// Load cities and custom checklists from checklist history.
  Future<void> _loadStartedCities() async {
    final userId = _authService.currentUserId;
    if (userId == null) {
      AppLogger.warning('User ID is null, cannot load started cities');
      return;
    }

    try {
      AppLogger.info('开始加载用户已开始的城市，userId: $userId');

      // Get all checklists for this user
      final allChecklists = await _checklistRepo.getAllChecklists();
      AppLogger.info('从数据库获取到 ${allChecklists.length} 个 checklists');

      // Extract unique cities from checklists
      final uniqueCities = <City>{};
      final customChecklists = <Checklist>[];
      final customChecklistSpotCounts = <String, int>{};
      for (final checklist in allChecklists) {
        AppLogger.info('Checklist: ${checklist.id}, 标题: ${checklist.displayTitle}');
        if (checklist.isCustom) {
          customChecklists.add(checklist);
          final items = await _checklistRepo.loadChecklistItems(checklist.id);
          customChecklistSpotCounts[checklist.id] = items.length;
        } else if (checklist.city != null) {
          uniqueCities.add(checklist.city!);
        }
      }

      if (!mounted) return;
      setState(() {
        _startedCities = uniqueCities.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        _customChecklists = customChecklists
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _customChecklistSpotCounts = customChecklistSpotCounts;
      });

      AppLogger.info(
        '成功加载 ${_startedCities.length} 个已开始城市: ${_startedCities.map((c) => c.name).join(', ')}',
      );
    } catch (e, stackTrace) {
      AppLogger.error('加载已开始城市失败', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _refreshStartedCities() async {
    await _loadStartedCities();
  }

  void _trackStartedCity(City city) {
    final exists = _startedCities.any(
      (startedCity) =>
          startedCity.name == city.name && startedCity.country == city.country,
    );
    if (exists || !mounted) return;

    setState(() {
      _startedCities = [..._startedCities, city]
        ..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _trackCustomChecklist(Checklist checklist) {
    if (!checklist.isCustom || !mounted) return;

    final exists = _customChecklists.any((item) => item.id == checklist.id);
    if (exists) return;

    setState(() {
      _customChecklists = [checklist, ..._customChecklists]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _customChecklistSpotCounts = {
        ..._customChecklistSpotCounts,
        checklist.id: _customChecklistSpotCounts[checklist.id] ?? 0,
      };
    });
  }

  Future<void> _openChecklistPage(
    Checklist checklist, {
    bool openAddCustomSpot = false,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChecklistPage(
          checklist: checklist,
          openAddCustomSpotOnLoad: openAddCustomSpot,
        ),
      ),
    );

    if (mounted) {
      await _loadStartedCities();
    }
  }

  Future<void> _createCustomChecklist() async {
    final userId = _authService.currentUserId ?? 'anonymous';
    final language = AppLocalizations.of(context).locale.languageCode;

    final checklist = await Navigator.push<Checklist>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCustomChecklistPage(
          userId: userId,
          language: language,
        ),
      ),
    );

    if (checklist == null) return;

    await _checklistRepo.saveChecklist(checklist);

    if (!mounted) return;

    _trackCustomChecklist(checklist);
    await _openChecklistPage(checklist);
  }

  /// Auto-detect location and generate checklist
  Future<void> _detectLocation() async {
    setState(() {
      _isGenerating = true;
    });

    City currentCity;
    try {
      AppLogger.info('开始自动位置检测');
      currentCity = await _locationService.getCurrentCity();
      AppLogger.info('检测到城市: ${currentCity.name}, ${currentCity.country}');
    } on LocationException catch (e) {
      AppLogger.error('位置检测失败: ${e.message}');
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showErrorDialog(e.message);
      }
      return;
    } catch (e) {
      AppLogger.error('获取当前位置失败', error: e);
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showErrorDialog(
          'Failed to get your current location. Please try selecting a city manually.',
        );
      }
      return;
    }

    try {
      final city = await _cityService.findOrCreateCity(
        currentCity.name,
        currentCity.country,
        currentCity.countryCode,
        currentCity.latitude,
        currentCity.longitude,
      );

      await _generateChecklistForCity(city);
    } catch (e) {
      AppLogger.error('定位成功，但城市匹配或清单生成失败', error: e);
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        _showErrorDialog(
          'Location detected, but we could not match a supported city. Please select a city manually.',
        );
      }
    }
  }

  /// Generate checklist for selected city
  Future<void> _generateChecklistForCity(
    City city, {
    bool openAddCustomSpot = false,
  }) async {
    if (mounted && !_isGenerating) {
      setState(() {
        _isGenerating = true;
      });
    }

    final language = AppLocalizations.of(context).locale.languageCode;

    try {
      AppLogger.info('开始为城市生成清单: ${city.name}');

      // 先检查该城市是否已有未完成的 checklist
      final existingChecklist =
          await _checklistRepo.getIncompleteChecklistForCity(city);

      if (existingChecklist != null) {
        // 有该城市的清单，检查是否有 items
        AppLogger.info('找到已存在的清单，检查 items - id: ${existingChecklist.id}');

        // Load items for this checklist
        final items =
            await _checklistRepo.loadChecklistItems(existingChecklist.id);

        if (items.length < 4) {
          // Items 为空或异常少，重建该城市的 checklist items
          AppLogger.info('清单项目数量异常 (${items.length})，重建 items');
          await _createChecklistItems(existingChecklist, city);
        }

        if (mounted) {
          _trackStartedCity(city);
          setState(() {
            _isGenerating = false;
          });

          await _openChecklistPage(
            existingChecklist,
            openAddCustomSpot: openAddCustomSpot,
          );
        }
        return;
      }

      // 没有该城市的清单，创建新的
      AppLogger.info('没有该城市的清单，创建新清单');

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
        _trackStartedCity(city);
        setState(() {
          _isGenerating = false;
        });

        await _openChecklistPage(
          checklist,
          openAddCustomSpot: openAddCustomSpot,
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
      onCreateCustomChecklist: () {
        _createCustomChecklist();
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
    final l10n = AppLocalizations.of(context);

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
              RefreshIndicator(
                onRefresh: _refreshStartedCities,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.appName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.appSlogan,
                              style: const TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 60),
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
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
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
                            Text(
                              l10n.get('pullToRefreshLists'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildChecklistSection(
                              title:
                                  '${l10n.get('startedCities')} (${_startedCities.length})',
                              subtitle: l10n.get('startedCitiesHint'),
                              icon: Icons.public_rounded,
                              accentColor: const Color(0xFF7FDBFF),
                              child: _startedCities.isEmpty
                                  ? _buildEmptySectionHint(
                                      l10n.get('noStartedCities'),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: _startedCities.map((city) {
                                        return _buildSimpleCityChip(city);
                                      }).toList(),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            _buildChecklistSection(
                              title:
                                  '${l10n.get('customLists')} (${_customChecklists.length})',
                              subtitle: l10n.get('customListsHint'),
                              icon: Icons.edit_note_rounded,
                              accentColor: const Color(0xFFFFD166),
                              child: _customChecklists.isEmpty
                                  ? _buildEmptySectionHint(
                                      l10n.get('customListsHint'),
                                    )
                                  : Column(
                                      children: _customChecklists.map((checklist) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: _buildCustomChecklistCard(checklist),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
              if (_isGenerating)
                Positioned.fill(
                  child: AbsorbPointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.24),
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Color(0xFF6A11CB),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Preparing your checklist...',
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isOpeningStartedCity)
                Positioned.fill(
                  child: AbsorbPointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.18),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
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
  Widget _buildChecklistSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptySectionHint(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSimpleCityChip(City city) {
    return Opacity(
      opacity: _isOpeningStartedCity ? 0.65 : 1,
      child: GestureDetector(
        onTap:
            _isOpeningStartedCity ? null : () => _navigateToCityChecklist(city),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
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
      ),
    );
  }

  Widget _buildCustomChecklistCard(Checklist checklist) {
    final l10n = AppLocalizations.of(context);
    final spotCount = _customChecklistSpotCounts[checklist.id] ?? 0;
    final spotCountLabel = spotCount == 1
        ? l10n.get('spotCountSingle')
        : l10n.get('spotCountPlural').replaceAll('{count}', '$spotCount');
    final subtitle = checklist.description?.trim().isNotEmpty == true
        ? checklist.description!.trim()
        : l10n.get('customListsHint');

    return Opacity(
      opacity: _isOpeningStartedCity ? 0.65 : 1,
      child: GestureDetector(
        onTap: _isOpeningStartedCity
            ? null
            : () => _navigateToCustomChecklist(checklist),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD166).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checklist.displayTitle.isEmpty
                          ? l10n.get('untitledChecklist')
                          : checklist.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  spotCountLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigate to city checklist
  Future<void> _navigateToCityChecklist(City city) async {
    if (_isOpeningStartedCity) return;

    if (mounted) {
      setState(() {
        _isOpeningStartedCity = true;
      });
    }

    try {
      AppLogger.info('点击城市芯片，导航到: ${city.name}');

      // 查找该城市的 checklist
      final checklist =
          await _checklistRepo.getIncompleteChecklistForCity(city);

      if (checklist != null) {
        // 找到 checklist，检查是否有 items
        final items = await _checklistRepo.loadChecklistItems(checklist.id);

        if (items.isEmpty) {
          // Items 为空，创建 items
          AppLogger.info('清单为空，创建 items');
          await _createChecklistItems(checklist, city);
        }

        if (mounted) {
          await _openChecklistPage(checklist);
        }
      } else {
        // 没有找到 checklist，提示用户
        if (mounted) {
          _showErrorDialog(
              'No checklist found for ${city.name}. Please create a new one.');
        }
      }
    } catch (e) {
      AppLogger.error('导航到城市清单失败', error: e);
      if (mounted) {
        _showErrorDialog('Failed to open checklist. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningStartedCity = false;
        });
      }
    }
  }

  Future<void> _navigateToCustomChecklist(Checklist checklist) async {
    if (_isOpeningStartedCity) return;

    if (mounted) {
      setState(() {
        _isOpeningStartedCity = true;
      });
    }

    try {
      final loadedChecklist = await _checklistRepo.loadChecklist(checklist.id);
      final checklistToOpen = loadedChecklist ?? checklist;

      if (mounted) {
        await _openChecklistPage(checklistToOpen);
      }
    } catch (e) {
      AppLogger.error('打开自定义清单失败', error: e);
      if (mounted) {
        _showErrorDialog('Failed to open checklist. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningStartedCity = false;
        });
      }
    }
  }

  /// Create checklist items for a checklist
  Future<void> _createChecklistItems(Checklist checklist, City city) async {
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
    AppLogger.info(
        '保存 checklist items 完成 - checklistId: ${checklist.id}, 数量: ${items.length}');
  }
}
