import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// City selection bottom sheet
/// Shows options to detect location or select from list
class CitySelectionBottomSheet extends StatelessWidget {
  final VoidCallback onDetectLocation;
  final VoidCallback onSelectFromList;
  final VoidCallback onCreateCustomChecklist;

  const CitySelectionBottomSheet({
    super.key,
    required this.onDetectLocation,
    required this.onSelectFromList,
    required this.onCreateCustomChecklist,
  });

  /// Show the bottom sheet
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onDetectLocation,
    required VoidCallback onSelectFromList,
    required VoidCallback onCreateCustomChecklist,
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
        onCreateCustomChecklist: () {
          Navigator.pop(context);
          onCreateCustomChecklist();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
              Text(
                l10n.createChecklist,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Detect My Location button
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: SizedBox(
                  width: double.infinity,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Select from List button
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: SizedBox(
                  width: double.infinity,
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
                    label: Text(
                      l10n.selectFromList,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCreateCustomChecklist,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.04),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.playlist_add_circle_outlined,
                      size: 24,
                    ),
                    label: Text(
                      l10n.get('createCustomChecklist'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.get('createCustomChecklistDesc'),
                style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Cancel button
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    child: Text(
                      l10n.get('cancel'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
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
}
