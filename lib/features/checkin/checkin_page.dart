import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/services/location_service.dart';
import '../../l10n/app_localizations.dart';

/// Check-in page for capturing photo memories
class CheckinPage extends StatefulWidget {
  final Checklist checklist;
  final ChecklistItem item;
  final Function(ChecklistItem) onCheckinComplete;

  const CheckinPage({
    super.key,
    required this.checklist,
    required this.item,
    required this.onCheckinComplete,
  });

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  final ImagePicker _picker = ImagePicker();
  final ChecklistRepository _repository = ChecklistRepository();
  final LocationService _locationService = LocationService();
  final GlobalKey _starsKey = GlobalKey();
  XFile? _imageFile;
  bool _isUploading = false;
  double? _displayRating; // Display rating (0.5-10.0 scale)

  bool get _isEditMode => widget.item.isCompleted;

  @override
  void initState() {
    super.initState();
    // Initialize rating if editing existing check-in (convert from stored int to display double)
    if (_isEditMode && widget.item.rating != null) {
      _displayRating = widget.item.rating! / 2.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkin, style: const TextStyle(fontSize: 18)),
      ),
      body: Column(
        children: [
          // Scrollable content (minimal scrolling needed)
          Expanded(
            child: Column(
              children: [
                _buildItemInfo(),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    l10n.captureMoment,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    l10n.captureMomentDesc,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Photo preview takes remaining space, but keep it square
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: _buildPhotoPreview(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          // Fixed bottom buttons
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildActionButtons(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.surfaceVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.getCategoryColor(widget.item.category)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  AppConstants.categoryIcons[widget.item.category] ?? '📍',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.title,
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Rating section
                    _buildRatingSection(),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.item.location,
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 10 stars with slide/tap support
        _buildInteractiveStars(),
        // Rating text below stars
        if (_displayRating != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_displayRating!.toStringAsFixed(1)}/10',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInteractiveStars() {
    return GestureDetector(
      key: _starsKey,
      onHorizontalDragUpdate: (details) {
        _updateRatingFromPosition(details.globalPosition);
      },
      onTapDown: (details) {
        _updateRatingFromPosition(details.globalPosition);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(10, (index) {
          final starValue = (index + 1).toDouble();
          final isHalfSelected = _displayRating != null && _displayRating! >= starValue - 0.5 && _displayRating! < starValue;
          final isFullSelected = _displayRating != null && _displayRating! >= starValue;

          return Icon(
            isFullSelected
                ? Icons.star
                : (isHalfSelected ? Icons.star_half : Icons.star_border),
            size: 20,
            color: (isFullSelected || isHalfSelected)
                ? Colors.amber
                : AppColors.textTertiary,
          );
        }),
      ),
    );
  }

  void _updateRatingFromPosition(Offset globalPosition) {
    // Get the render box of the stars row
    final RenderBox? renderBox = _starsKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // Get the position of the stars row in global coordinates
    final objectPosition = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Calculate the relative x position within the stars row
    final relativeX = globalPosition.dx - objectPosition.dx;

    // Clamp to the bounds of the stars row
    final clampedX = relativeX.clamp(0.0, size.width);

    // Calculate rating based on position (0-10 with 0.5 steps = 20 steps)
    final rating = (clampedX / size.width) * 10;

    // Round to nearest 0.5
    final roundedRating = (rating * 2).roundToDouble() / 2;

    // Clamp to 0-10
    final finalRating = roundedRating.clamp(0.0, 10.0);

    // Update state only if rating changed
    if (_displayRating != finalRating) {
      setState(() {
        _displayRating = finalRating > 0 ? finalRating : null;
      });
    }
  }

  Widget _buildPhotoPreview() {
    final hasExistingPhoto = _isEditMode && widget.item.photoUrl != null && widget.item.photoUrl!.isNotEmpty;
    final displayImage = _imageFile != null ? _imageFile!.path : (hasExistingPhoto ? widget.item.photoUrl : null);
    final isNetworkImage = _imageFile == null && hasExistingPhoto;

    return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          border: Border.all(
            color: AppColors.border,
            width: 2,
          ),
        ),
        child: displayImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    child: isNetworkImage
                        ? Image.network(
                            displayImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(_imageFile!.path),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.overlay,
                        foregroundColor: AppColors.textOnDark,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No photo selected',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 20),
              label: Text(l10n.takePhoto, style: const TextStyle(fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnDark,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, size: 20),
              label: Text(l10n.selectFromGallery, style: const TextStyle(fontSize: 15)),
            ),
          ),
          if (_imageFile != null || (_isEditMode && widget.item.photoUrl != null && widget.item.photoUrl!.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _completeCheckin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.textOnDark,
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnDark,
                        ),
                      )
                    : Text(_isEditMode ? 'Save Changes' : l10n.completeCheckin, style: const TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _completeCheckin() async {
    // In edit mode, allow saving without new photo (just update rating)
    if (!_isEditMode && _imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String? photoUrl = widget.item.photoUrl;
      double? latitude = widget.item.latitude;
      double? longitude = widget.item.longitude;

      // Only upload new photo if user selected one
      if (_imageFile != null) {
        // Get current location for new photos
        try {
          final position = await _locationService.getCurrentPosition();
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (e) {
          // Location not available, use city center
          AppLogger.warning('Could not get location: $e');
        }

        // Upload photo
        photoUrl = await _repository.uploadPhoto(
          checklistId: widget.checklist.id,
          itemId: widget.item.id,
          photoFile: _imageFile!,
          latitude: latitude ?? widget.checklist.city.latitude,
          longitude: longitude ?? widget.checklist.city.longitude,
          rating: _displayRating != null ? (_displayRating! * 2).toInt() : null,
        );
      }

      // Convert display rating to stored rating (multiply by 2)
      final int? storedRating = _displayRating != null ? (_displayRating! * 2).toInt() : null;

      // Update checklist item
      final updatedItem = widget.item.copyWith(
        photoUrl: photoUrl,
        latitude: latitude ?? widget.checklist.city.latitude,
        longitude: longitude ?? widget.checklist.city.longitude,
        rating: storedRating,
        isCompleted: true,
        completedAt: _isEditMode && widget.item.completedAt != null
            ? widget.item.completedAt
            : DateTime.now(),
      );

      // Save updated checklist
      await _repository.updateItem(widget.checklist, updatedItem);

      widget.onCheckinComplete(updatedItem);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar();
      }
    } catch (e) {
      _showErrorDialog('Failed to complete check-in: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.textOnDark),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Check-in complete! Great job! 🎉',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnDark,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
