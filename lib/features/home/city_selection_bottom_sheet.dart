import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';
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

  /// Show the city selection as a full-screen modal
  static Future<void> show({
    required BuildContext context,
    required Function(City) onCitySelected,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CitySelectionPage(onCitySelected: onCitySelected),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Full-screen city selection page
class CitySelectionPage extends StatefulWidget {
  final Function(City) onCitySelected;

  const CitySelectionPage({
    super.key,
    required this.onCitySelected,
  });

  @override
  State<CitySelectionPage> createState() => _CitySelectionPageState();
}

class _CitySelectionPageState extends State<CitySelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CityService _cityService = CityService.instance;
  List<City> _filteredCities = [];
  List<City> _allCities = [];
  bool _isLoading = true;
  String? _error;

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
      AppLogger.error('Failed to load cities', error: e);
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

  void _selectCity(City city) {
    Navigator.pop(context);
    widget.onCitySelected(city);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '选择城市',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '搜索城市...',
                  hintStyle: TextStyle(color: Color(0xFF999999)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.search, color: Color(0xFF999999), size: 20),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // City list
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6A11CB)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF999999)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCities,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A11CB),
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
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
            const Icon(Icons.search_off, size: 48, color: Color(0xFFCCCCCC)),
            const SizedBox(height: 16),
            const Text(
              '未找到城市',
              style: TextStyle(color: Color(0xFF666666), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCities.length,
      itemBuilder: (context, index) {
        final city = _filteredCities[index];
        return _buildCityTile(city);
      },
    );
  }

  Widget _buildCityTile(City city) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: InkWell(
        onTap: () => _selectCity(city),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              // Country flag
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getCityFlag(city.countryCode),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // City name and country
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.name,
                      style: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      city.country,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Right arrow
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFCCCCCC),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
