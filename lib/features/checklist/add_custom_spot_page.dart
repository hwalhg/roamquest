import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';
import '../../data/services/location_service.dart';
import '../../l10n/app_localizations.dart';

class AddCustomSpotPage extends StatefulWidget {
  final Checklist checklist;
  final int nextSortOrder;
  final ChecklistItem? initialItem;

  const AddCustomSpotPage({
    super.key,
    required this.checklist,
    required this.nextSortOrder,
    this.initialItem,
  });

  @override
  State<AddCustomSpotPage> createState() => _AddCustomSpotPageState();
}

class _AddCustomSpotPageState extends State<AddCustomSpotPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final LocationService _locationService = LocationService();

  String _selectedCategory = AppConstants.categories.first;
  bool _isSaving = false;
  bool _isCapturingLocation = false;
  double? _spotLatitude;
  double? _spotLongitude;
  String? _locationStatusMessage;
  bool _locationStatusIsError = false;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialItem?.title ?? '';
    _locationController.text = widget.initialItem?.location ?? '';
    _selectedCategory = widget.initialItem?.category ?? AppConstants.categories.first;
    _spotLatitude = widget.initialItem?.spotLatitude;
    _spotLongitude = widget.initialItem?.spotLongitude;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _captureCurrentLocation() async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isCapturingLocation = true;
      _locationStatusMessage = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _spotLatitude = position.latitude;
        _spotLongitude = position.longitude;
        _locationStatusMessage = l10n.get('currentLocationSaved');
        _locationStatusIsError = false;
        if (address != null && address.isNotEmpty) {
          _locationController.text = address;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationStatusMessage = l10n.get('currentLocationUnavailable');
        _locationStatusIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingLocation = false;
        });
      }
    }
  }

  void _saveSpot() {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final location = _locationController.text.trim();

    final customItem = _isEditing
        ? widget.initialItem!.copyWith(
            title: _titleController.text.trim(),
            location: location,
            category: _selectedCategory,
            spotLatitude: _spotLatitude,
            spotLongitude: _spotLongitude,
          )
        : ChecklistItem.customSpot(
            checklistId: widget.checklist.id,
            title: _titleController.text.trim(),
            location: location,
            category: _selectedCategory,
            sortOrder: widget.nextSortOrder,
            spotLatitude: _spotLatitude,
            spotLongitude: _spotLongitude,
          );

    Navigator.pop(context, customItem);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.get('editSpot') : l10n.addCustomSpot,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? l10n.get('addCustomSpotDesc')
                          : l10n.get('addCustomSpotDesc'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.get('customSpotPrivateNote'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.get('spotName'),
                  hintText: l10n.get('spotNameHint'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.get('pleaseEnterSpotName');
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.get('spotLocation'),
                  hintText: l10n.get('spotLocationHint'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: l10n.get('customSpotCategory'),
                ),
                items: AppConstants.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(_categoryLabel(category, l10n)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _isCapturingLocation ? null : _captureCurrentLocation,
                icon: _isCapturingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: Text(l10n.get('useCurrentLocation')),
              ),
              if (_locationStatusMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: (_locationStatusIsError
                            ? Colors.red
                            : AppColors.success)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(
                      color: (_locationStatusIsError
                              ? Colors.red
                              : AppColors.success)
                          .withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _locationStatusIsError
                                ? Icons.info_outline
                                : Icons.check_circle_outline,
                            size: 16,
                            color: _locationStatusIsError
                                ? Colors.red.shade400
                                : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationStatusMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: _locationStatusIsError
                                    ? Colors.red.shade400
                                    : AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_spotLatitude != null && _spotLongitude != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${_spotLatitude!.toStringAsFixed(5)}, ${_spotLongitude!.toStringAsFixed(5)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _isSaving = true;
                      });
                      _saveSpot();
                    },
              child: Text(
                _isEditing
                    ? l10n.get('saveChecklistChanges')
                    : l10n.get('saveAndCheckin'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String category, AppLocalizations l10n) {
    switch (category) {
      case 'landmark':
        return l10n.landmark;
      case 'food':
        return l10n.food;
      case 'experience':
        return l10n.experience;
      case 'hidden':
        return l10n.hiddenGem;
      default:
        return category;
    }
  }
}
