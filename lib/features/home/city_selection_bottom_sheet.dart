import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/city.dart';
import '../../data/services/city_service.dart';

/// City selection bottom sheet
/// Shows a scrollable list of supported cities fetched from database
class CitySelectionBottomSheet extends StatefulWidget {
  final Function(City) onCitySelected;

  const CitySelectionBottomSheet({
    super.key,
    required this.onCitySelected,
  });

  /// Show the city selection bottom sheet
  static Future<void> show({
    required BuildContext context,
    required Function(City) onCitySelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CitySelectionBottomSheet(
        onCitySelected: onCitySelected,
      ),
    );
  }

  @override
  State<CitySelectionBottomSheet> createState() =>
      _CitySelectionBottomSheetState();
}

class _CitySelectionBottomSheetState extends State<CitySelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CityService _cityService = CityService.instance;
  List<City> _filteredCities = [];
  List<City> _allCities = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedLetter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCities);
    _loadCities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _cityService.getCities();
      if (mounted) {
        setState(() {
          _allCities = cities;
          _filteredCities = cities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load cities';
          _isLoading = false;
        });
      }
    }
  }

  void _filterCities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _selectedLetter = null; // Reset selected letter when searching
      if (query.isEmpty) {
        _filteredCities = _allCities;
      } else {
        _filteredCities = _allCities
            .where((city) =>
                city.name.toLowerCase().contains(query) ||
                city.country.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  'Select a City',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSpacing.md),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search cities...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),

          // City list with A-Z indexer
          Expanded(
            child: Row(
              children: [
                // City list
                Expanded(
                  child: _buildContent(),
                ),
                // A-Z indexer (only show when not searching)
                if (_searchController.text.isEmpty && _filteredCities.isNotEmpty)
                  _buildAZIndexer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
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
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadCities,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredCities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No cities found',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredCities.length,
      itemBuilder: (context, index) {
        final city = _filteredCities[index];
        return _buildCityTile(city);
      },
    );
  }

  Widget _buildCityTile(City city) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onCitySelected(city);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Center(
                child: Text(
                  _getCityFlag(city.countryCode),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    city.country,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
    );
  }

  /// Build A-Z indexer on the right side
  Widget _buildAZIndexer() {
    // Get available letters from city names
    final availableLetters = _getAvailableLetters();

    return Container(
      width: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(AppBorderRadius.sm),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: availableLetters.length,
        itemBuilder: (context, index) {
          final letter = availableLetters[index];
          final isSelected = _selectedLetter == letter;

          return GestureDetector(
            onTap: () => _scrollToLetter(letter),
            child: Container(
              height: 20,
              alignment: Alignment.center,
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    )
                  : null,
              child: Text(
                letter,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? AppColors.textOnDark
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSelected ? 12 : 10,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Get available letters from filtered cities
  List<String> _getAvailableLetters() {
    final letters = _filteredCities
        .map((city) => city.name.toUpperCase().substring(0, 1))
        .toSet()
        .toList()
      ..sort();

    return letters;
  }

  /// Scroll to the first city starting with the given letter
  void _scrollToLetter(String letter) {
    final index = _filteredCities.indexWhere(
      (city) => city.name.toUpperCase().startsWith(letter),
    );

    if (index != -1) {
      setState(() {
        _selectedLetter = letter;
      });

      // Use a more precise calculation based on actual item height
      // Each city tile is approximately 72px, but we need to account for list overhead
      const double itemHeight = 72.0;
      const double estimatedHeaderOffset = 90.0;

      // Calculate target position with better precision
      final targetPosition = (index * itemHeight) + estimatedHeaderOffset;

      // Ensure we have a scroll controller attached
      if (_scrollController.hasClients) {
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        final minScrollExtent = _scrollController.position.minScrollExtent;

        // Clamp position to valid scroll range
        final clampedPosition = targetPosition.clamp(minScrollExtent, maxScrollExtent);

        // Scroll to the calculated position
        _scrollController.animateTo(
          clampedPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      // Clear selection after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _selectedLetter = null;
          });
        }
      });
    }
  }

  String _getCityFlag(String countryCode) {
    // Simple flag emoji mapping for common countries
    final flags = {
      'AE': '🇦🇪',
      'AR': '🇦🇷',
      'AT': '🇦🇹',
      'AU': '🇦🇺',
      'BR': '🇧🇷',
      'CA': '🇨🇦',
      'CH': '🇨🇭',
      'CL': '🇨🇱',
      'CN': '🇨🇳',
      'CU': '🇨🇺',
      'CZ': '🇨🇿',
      'DE': '🇩🇪',
      'DK': '🇩🇰',
      'EC': '🇪🇨',
      'EG': '🇪🇬',
      'ES': '🇪🇸',
      'FI': '🇫🇮',
      'FR': '🇫🇷',
      'GB': '🇬🇧',
      'GR': '🇬🇷',
      'HK': '🇭🇰',
      'HU': '🇭🇺',
      'ID': '🇮🇩',
      'IE': '🇮🇪',
      'IS': '🇮🇸',
      'IT': '🇮🇹',
      'JP': '🇯🇵',
      'KR': '🇰🇷',
      'MA': '🇲🇦',
      'MX': '🇲🇽',
      'MY': '🇲🇾',
      'NL': '🇳🇱',
      'NO': '🇳🇴',
      'NZ': '🇳🇿',
      'PE': '🇵🇪',
      'PT': '🇵🇹',
      'RU': '🇷🇺',
      'SE': '🇸🇪',
      'SG': '🇸🇬',
      'TH': '🇹🇭',
      'TR': '🇹🇷',
      'TW': '🇹🇼',
      'UA': '🇺🇦',
      'UK': '🇬🇧',
      'US': '🇺🇸',
      'ZA': '🇿🇦',
    };
    return flags[countryCode] ?? '🌍';
  }
}
