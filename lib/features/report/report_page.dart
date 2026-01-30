import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';

/// Report page - Check-in Diary with Xiaohongshu-style share card
class ReportPage extends StatefulWidget {
  final Checklist checklist;

  const ReportPage({
    super.key,
    required this.checklist,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  Checklist get checklist => widget.checklist;
  final GlobalKey _shareCardKey = GlobalKey();

  // TODO: Get real user nickname from auth service
  final String _userNickname = 'Lion';
  bool _isCapturing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDiaryList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          // Bottom share button
          _buildShareButton(),
        ],
      ),
    );
  }

  /// Build header with back button and title
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Text(
              'Check-in Diary',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  /// Build diary list
  Widget _buildDiaryList() {
    final completedItems = checklist.completedItems;

    if (completedItems.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
            child: Text(
              '${checklist.createdAt.month}/${checklist.createdAt.day}/${checklist.createdAt.year}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Diary entries
          ...completedItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildDiaryEntry(item, index + 1);
          }).toList(),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No check-ins yet',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your amazing moments will appear here after check-in',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build single diary entry
  Widget _buildDiaryEntry(ChecklistItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '$index. ${item.title}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (item.rating != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: _buildRatingDisplay(item.rating! / 2.0),
            ),
          if (item.rating != null) const SizedBox(height: AppSpacing.sm),
          _buildPhotoCard(item),
        ],
      ),
    );
  }

  /// Build photo card
  Widget _buildPhotoCard(ChecklistItem item) {
    final hasPhoto = item.photoUrl != null && item.photoUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        child: hasPhoto
            ? Image.network(
                item.photoUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
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
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(item);
                },
              )
            : _buildPlaceholder(item),
      ),
    );
  }

  /// Build rating display
  Widget _buildRatingDisplay(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(10, (index) {
          final starValue = index + 1;
          final isHalfSelected = rating >= starValue - 0.5 && rating < starValue;
          final isFullSelected = rating >= starValue;

          return Icon(
            isFullSelected
                ? Icons.star
                : (isHalfSelected ? Icons.star_half : Icons.star_border),
            color: (isFullSelected || isHalfSelected)
                ? Colors.amber
                : AppColors.textTertiary,
            size: 16,
          );
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Build placeholder when no photo
  Widget _buildPlaceholder(ChecklistItem item) {
    return Container(
      color: AppColors.getCategoryColor(item.category).withOpacity(0.1),
      child: Center(
        child: Text(
          AppConstants.categoryIcons[item.category] ?? '📍',
          style: const TextStyle(fontSize: 48),
        ),
      ),
    );
  }

  /// Build share button
  Widget _buildShareButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isCapturing ? null : _showShareDialog,
            icon: _isCapturing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnDark,
                    ),
                  )
                : const Icon(Icons.share),
            label: Text(_isCapturing ? 'Creating...' : 'Create Share Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnDark,
            ),
          ),
        ),
      ),
    );
  }

  /// Show share dialog and navigate to preview
  void _showShareDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareCardPreviewPage(
          checklist: checklist,
          userNickname: _userNickname,
        ),
      ),
    );
  }
}

/// Share card preview page - generates Xiaohongshu-style share card
class ShareCardPreviewPage extends StatefulWidget {
  final Checklist checklist;
  final String userNickname;

  const ShareCardPreviewPage({
    super.key,
    required this.checklist,
    required this.userNickname,
  });

  @override
  State<ShareCardPreviewPage> createState() => _ShareCardPreviewPageState();
}

class _ShareCardPreviewPageState extends State<ShareCardPreviewPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isCapturing = false;

  Checklist get checklist => widget.checklist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Share Card'),
        backgroundColor: AppColors.surface,
        actions: [
          if (!_isCapturing)
            IconButton(
              onPressed: _captureAndShare,
              icon: const Icon(Icons.download),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Share card
            RepaintBoundary(
              key: _cardKey,
              child: _buildShareCard(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCapturing ? null : _captureAndShare,
        icon: _isCapturing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnDark,
                ),
              )
            : const Icon(Icons.share),
        label: Text(_isCapturing ? 'Creating...' : 'Share'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
      ),
    );
  }

  /// Build simplified waterfall-style share card
  Widget _buildShareCard() {
    final completedItems = checklist.completedItems;
    final categoryColors = AppColors.primaryGradient;

    return Container(
      width: 350,
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simplified header - only city name and date
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: categoryColors,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // City name - large, uppercase
                Text(
                  checklist.city.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                // Date - small, semi-transparent
                Text(
                  '${checklist.createdAt.month}/${checklist.createdAt.day}/${checklist.createdAt.year}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDark.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Waterfall photos section
          if (completedItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: completedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildWaterfallPhotoCard(item, index + 1);
                }).toList(),
              ),
            ),
          ],

          // Bottom rounded cap
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build waterfall photo card
  Widget _buildWaterfallPhotoCard(ChecklistItem item, int index) {
    final hasPhoto = item.photoUrl != null && item.photoUrl!.isNotEmpty;
    final categoryEmoji = AppConstants.categoryIcons[item.category] ?? '📍';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.getCategoryColor(item.category).withOpacity(0.15),
              ),
              child: hasPhoto
                  ? Image.network(
                      item.photoUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primary,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            categoryEmoji,
                            style: const TextStyle(fontSize: 64),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            categoryEmoji,
                            style: const TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number badge and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Category tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getCategoryColor(item.category).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        categoryEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getCategoryName(item.category),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Rating if exists
                if (item.rating != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        final displayRating = item.rating! / 2.0;
                        final starValue = index + 1;
                        final isHalfSelected = displayRating >= starValue - 0.5 && displayRating < starValue;
                        final isFullSelected = displayRating >= starValue;

                        return Icon(
                          isFullSelected
                              ? Icons.star
                              : (isHalfSelected ? Icons.star_half : Icons.star_border),
                          color: (isFullSelected || isHalfSelected)
                              ? Colors.amber
                              : AppColors.textTertiary,
                          size: 18,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        (item.rating! / 2.0).toStringAsFixed(1),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get category display name
  String _getCategoryName(String category) {
    switch (category) {
      case 'landmark':
        return 'Landmark';
      case 'food':
        return 'Food';
      case 'experience':
        return 'Experience';
      case 'hidden':
        return 'Hidden Gem';
      default:
        return category;
    }
  }

  /// Capture share card and share
  Future<void> _captureAndShare() async {
    setState(() => _isCapturing = true);

    try {
      // Capture the share card
      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showError('Failed to capture image');
        return;
      }

      // Save to temp directory
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = await File('${tempDir.path}/roamquest_$timestamp.png')
          .writeAsBytes(byteData.buffer.asUint8List());

      _showSuccess('Image created! Sharing...');

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'My Journey in ${checklist.city.name}',
        text:
            '${widget.userNickname} explored ${checklist.completedCount} amazing places in ${checklist.city.name}! 🌍\n\nDownload RoamQuest and start your own journey!',
      );
    } catch (e) {
      _showError('Failed to share: $e');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.textOnDark,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
