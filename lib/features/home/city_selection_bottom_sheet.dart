import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/city.dart';
import '../../data/services/city_service.dart';
import '../../data/services/location_service.dart';

/// City selection bottom sheet
/// Shows a scrollable list of supported cities fetched from database
class CitySelectionBottomSheet {
  CitySelectionBottomSheet({
    required this.onCitySelected,
  });

  final Function(City) onCitySelected;

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
  final LocationService _locationService = LocationService();
  List<City> _filteredCities = [];
  List<City> _allCities = [];
  List<City> _remoteCities = [];
  bool _isLoading = true;
  bool _isSearchingRemote = false;
  bool _isSelectingRemoteCity = false;
  String? _error;
  String? _remoteError;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCities);
    _loadCities();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _cityService.getCities(forceRefresh: true);
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
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCities = _allCities;
        _remoteCities = [];
        _remoteError = null;
      } else {
        _filteredCities = _allCities
            .where((city) =>
                city.name.toLowerCase().contains(query) ||
                city.country.toLowerCase().contains(query))
            .toList();
      }
    });

    _searchDebounce?.cancel();
    if (query.isEmpty) return;
    if (query.length < 2) {
      setState(() {
        _remoteCities = [];
        _remoteError = null;
        _isSearchingRemote = false;
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchRemoteCities(query),
    );
  }

  void _selectCity(City city) {
    Navigator.pop(context);
    widget.onCitySelected(city);
  }

  Future<void> _searchRemoteCities(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isSearchingRemote = true;
      _remoteError = null;
    });

    try {
      final results = await _locationService.searchCity(query);
      final existingKeys = _allCities
          .map((city) =>
              '${city.name.toLowerCase()}_${city.country.toLowerCase()}')
          .toSet();
      final dedupedResults = results.where((city) {
        final key = '${city.name.toLowerCase()}_${city.country.toLowerCase()}';
        return !existingKeys.contains(key);
      }).toList();

      if (!mounted || _searchController.text.trim().toLowerCase() != query) {
        return;
      }

      setState(() {
        _remoteCities = dedupedResults;
      });
    } catch (e) {
      AppLogger.error('Failed to search remote cities', error: e);
      if (!mounted || _searchController.text.trim().toLowerCase() != query) {
        return;
      }

      setState(() {
        _remoteError = 'Failed to search online cities';
      });
    } finally {
      if (mounted && _searchController.text.trim().toLowerCase() == query) {
        setState(() {
          _isSearchingRemote = false;
        });
      }
    }
  }

  Future<void> _selectRemoteCity(City city) async {
    if (_isSelectingRemoteCity) return;

    setState(() {
      _isSelectingRemoteCity = true;
    });

    try {
      final persistedCity = await _cityService.findOrCreateCity(
        city.name,
        city.country,
        city.countryCode,
        city.latitude,
        city.longitude,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCitySelected(persistedCity);
    } catch (e) {
      AppLogger.error('Failed to persist remote city', error: e);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unable to add this city. Please try again later.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingRemoteCity = false;
        });
      }
    }
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
          'Select City',
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
                  hintText: 'Search cities...',
                  hintStyle: TextStyle(color: Color(0xFF999999)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child:
                        Icon(Icons.search, color: Color(0xFF999999), size: 20),
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
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredCities.isEmpty &&
        _remoteCities.isEmpty &&
        !_isSearchingRemote &&
        _remoteError == null) {
      return _buildEmptyState();
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_filteredCities.isNotEmpty) ...[
          ..._filteredCities.map(_buildCityTile),
        ],
        if (_searchController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Online Search Results',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_isSearchingRemote)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF6A11CB)),
              ),
            )
          else if (_remoteError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                _remoteError!,
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
              ),
            )
          else if (_remoteCities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                'No more matching cities',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
              ),
            )
          else
            ..._remoteCities.map((city) => _buildRemoteCityTile(city)),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          const Text(
            'No cities found',
            style: TextStyle(color: Color(0xFF666666), fontSize: 16),
          ),
          if (_searchController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Keep typing to search online and add a city',
              style: TextStyle(color: Color(0xFF999999), fontSize: 13),
            ),
          ],
        ],
      ),
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
              // City icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_city_rounded,
                    color: Color(0xFF6A11CB),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // City name
              Expanded(
                child: Text(
                  city.name,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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

  Widget _buildRemoteCityTile(City city) {
    return Opacity(
      opacity: _isSelectingRemoteCity ? 0.65 : 1,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
          ),
        ),
        child: InkWell(
          onTap: _isSelectingRemoteCity ? null : () => _selectRemoteCity(city),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE7FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_location_alt_outlined,
                      color: Color(0xFF6A11CB),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    city.name,
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isSelectingRemoteCity)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6A11CB),
                    ),
                  )
                else
                  const Text(
                    'Add',
                    style: TextStyle(
                      color: Color(0xFF6A11CB),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
