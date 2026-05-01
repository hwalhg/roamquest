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

  const AddCustomSpotPage({
    super.key,
    required this.checklist,
    required this.nextSortOrder,
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

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.checklist.isCustom
        ? ''
        : widget.checklist.city?.name ?? '';
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
    });

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _spotLatitude = position.latitude;
        _spotLongitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('currentLocationSaved'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('currentLocationUnavailable'))),
      );
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

    final customItem = ChecklistItem.customSpot(
      checklistId: widget.checklist.id,
      title: _titleController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? widget.checklist.displayTitle
          : _locationController.text.trim(),
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
        title: Text(l10n.addCustomSpot),
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
                      l10n.get('addCustomSpotDesc'),
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
              if (_spotLatitude != null && _spotLongitude != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${_spotLatitude!.toStringAsFixed(5)}, ${_spotLongitude!.toStringAsFixed(5)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
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
              child: Text(l10n.get('saveAndCheckin')),
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
