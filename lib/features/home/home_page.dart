import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/city.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';
import '../../data/services/location_service.dart';
import '../../data/services/city_service.dart';
import '../../data/services/ai_service.dart';
import '../../data/repositories/checklist_repository.dart';
import '../checklist/checklist_page.dart';
import 'city_selection_bottom_sheet.dart';

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

    try {
      // Check if there's already a checklist for this city (user's local checklist)
      final existingChecklist = await _checklistRepo.getChecklistForCity(city);

      if (existingChecklist != null) {
        // Open existing checklist
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
      final templateItems = await _checklistRepo.getChecklistTemplate(
        cityName: city.name,
        country: city.country,
        language: 'en',
      );

      List<ChecklistItem> items;

      if (templateItems != null && templateItems.isNotEmpty) {
        // Use template items
        items = templateItems;
      } else {
        // No template, generate with AI
        final checklist = await _aiService.generateChecklistWithRetry(
          city,
          'en', // Use English
        );
        items = checklist.items;

        // Save as template for future use
        try {
          await _checklistRepo.saveChecklistTemplate(
            city: city,
            items: items,
            language: 'en',
          );
        } catch (e) {
          // Failed to save template, but continue with checklist
          // ignore
        }
      }

      // Create checklist with items
      final checklist = Checklist(
        id: 'checklist_${DateTime.now().millisecondsSinceEpoch}',
        city: city,
        items: items,
        createdAt: DateTime.now(),
        language: 'en',
      );

      // Save checklist to local and cloud
      await _checklistRepo.saveChecklist(checklist);

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
                      '${checklist.completedCount}/${checklist.items.length} Completed',
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
