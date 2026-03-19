import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// City selection bottom sheet
/// Shows options to detect location or select from list
class CitySelectionBottomSheet extends StatelessWidget {
  final VoidCallback onDetectLocation;
  final VoidCallback onSelectFromList;

  const CitySelectionBottomSheet({
    super.key,
    required this.onDetectLocation,
    required this.onSelectFromList,
  });

  /// Show the bottom sheet
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onDetectLocation,
    required VoidCallback onSelectFromList,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CitySelectionBottomSheet(
        onDetectLocation: () {
          Navigator.pop(context);
          onDetectLocation();
        },
        onSelectFromList: () {
          Navigator.pop(context);
          onSelectFromList();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'Select City',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Detect My Location button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onDetectLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: const Text(
                    'Detect My Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Select from List button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onSelectFromList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(
                    Icons.list_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: const Text(
                    'Select from List',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Cancel button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
