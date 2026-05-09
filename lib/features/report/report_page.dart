import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';
import '../../data/repositories/checklist_repository.dart';

const Color _reportBackground = Color(0xFFF7F1E8);
const Color _reportSurface = Color(0xFFFFFBF5);
const Color _reportInk = Color(0xFF1F1A17);
const Color _reportMuted = Color(0xFF6F655C);
const Color _reportClay = Color(0xFFD86F3D);
const Color _reportGold = Color(0xFFE8C56B);
const Color _reportSage = Color(0xFF6A8872);
const Color _reportBerry = Color(0xFF8D4E64);

/// Report page - refined trip diary and share card preview.
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
  final ChecklistRepository _checklistRepo = ChecklistRepository();
  final String _userNickname = 'Lion';
  List<ChecklistItem> _items = [];
  bool _isLoading = true;
  bool _isOpeningPreview = false;

  Checklist get checklist => widget.checklist;
  List<ChecklistItem> get _completedItems =>
      Checklist.getCompletedItems(_items);
  String get _reportTitle => checklist.displayTitle;
  String get _reportRegion =>
      checklist.isCustom ? checklist.displaySubtitle : checklist.displayTitle;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _checklistRepo.loadChecklistItems(checklist.id);
    if (!mounted) return;

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canShare = _completedItems.isNotEmpty;

    return Scaffold(
      backgroundColor: _reportBackground,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Travel Diary'),
        backgroundColor: Colors.transparent,
        foregroundColor: _reportInk,
        elevation: 0,
      ),
      bottomNavigationBar: _buildShareButton(canShare),
      body: Stack(
        children: [
          _buildReportBackgroundDecor(),
          SafeArea(
            top: false,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _reportClay),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: AppSpacing.lg),
                        if (_completedItems.isEmpty)
                          _buildEmptyState()
                        else ...[
                          _buildSnapshotRow(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildSectionHeader(
                            eyebrow: 'Captured Moments',
                            title: 'A cleaner timeline of every completed stop',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ..._completedItems.asMap().entries.map((entry) {
                            return _buildMomentCard(entry.value, entry.key + 1);
                          }),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final completedCount = _completedItems.length;
    final progress = Checklist.getProgressPercentage(_items);
    final averageRating = _averageRating(_completedItems);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _reportSurface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _reportGold.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.full),
                      ),
                      child: Text(
                        _formatDate(checklist.createdAt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _reportInk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _reportTitle,
                      style: AppTextStyles.h1.copyWith(
                        color: _reportInk,
                        fontSize: 38,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      checklist.isCustom
                          ? 'A visual diary for your custom route with photos, ratings, and the moments worth keeping.'
                          : 'A visual diary for $_reportRegion with photos, ratings, and the moments worth keeping.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _reportMuted,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 88,
                height: 112,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_reportClay, _reportBerry],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$completedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'moments',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  label: 'Progress',
                  value: '$progress%',
                  accent: _reportClay,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeroMetric(
                  label: 'Rated Spots',
                  value: averageRating == null
                      ? 'None'
                      : averageRating.toStringAsFixed(1),
                  accent: _reportGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeroMetric(
                  label: 'Categories',
                  value: '${_categoryCount(_completedItems)}',
                  accent: _reportSage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: _reportMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: _reportInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotRow() {
    final items = _completedItems.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          eyebrow: 'Quick Snapshot',
          title: 'A bold preview before you generate the share card',
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildSnapshotTile(
                  items.isNotEmpty ? items.first : null,
                  height: 180,
                  showTitle: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildSnapshotTile(
                        items.length > 1 ? items[1] : null,
                        height: 84,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildSnapshotTile(
                        items.length > 2 ? items[2] : null,
                        height: 84,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String eyebrow,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: _reportClay,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: AppTextStyles.h4.copyWith(
            color: _reportInk,
            fontSize: 22,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSnapshotTile(
    ChecklistItem? item, {
    required double height,
    bool showTitle = false,
  }) {
    if (item == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        ),
        child: Center(
          child: Text(
            'More moments soon',
            style: AppTextStyles.bodySmall.copyWith(
              color: _reportMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPhoto(item, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: _buildCategoryBadge(item.category),
            ),
            if (showTitle)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  item.title,
                  style: AppTextStyles.h4.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentCard(ChecklistItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _reportSurface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.getCategoryColor(item.category)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: AppTextStyles.h4.copyWith(
                      color: _reportInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildCategoryBadge(item.category),
                        _buildInfoPill(
                          icon: Icons.place_outlined,
                          label: item.location,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: AppTextStyles.h4.copyWith(
                        color: _reportInk,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _buildPhoto(item, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 14),
          if ((item.notes ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                item.notes!.trim(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _reportInk,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if ((item.notes ?? '').trim().isNotEmpty) const SizedBox(height: 12),
          Row(
            children: [
              if (item.rating != null)
                Expanded(
                  child: _buildRatingStrip(item.rating! / 2.0),
                )
              else
                Expanded(
                  child: _buildInfoPill(
                    icon: Icons.camera_alt_outlined,
                    label: 'Captured and saved',
                  ),
                ),
              const SizedBox(width: 10),
              _buildInfoPill(
                icon: Icons.schedule_rounded,
                label: _formatTime(item.completedAt ?? checklist.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final color = AppColors.getCategoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
      ),
      child: Text(
        '${AppConstants.categoryIcons[category] ?? '📍'} ${_categoryName(category)}',
        style: AppTextStyles.caption.copyWith(
          color: _reportInk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(AppBorderRadius.full),
        border: Border.all(color: const Color(0xFFE8DED0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _reportMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: _reportMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStrip(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ...List.generate(5, (index) {
            final starValue = index + 1;
            final isHalf = rating >= starValue - 0.5 && rating < starValue;
            final isFull = rating >= starValue;

            return Icon(
              isFull
                  ? Icons.star_rounded
                  : (isHalf
                      ? Icons.star_half_rounded
                      : Icons.star_border_rounded),
              size: 18,
              color: _reportClay,
            );
          }),
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.bodyMedium.copyWith(
              color: _reportInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(
    ChecklistItem item, {
    required BoxFit fit,
  }) {
    final photoUrl = item.photoUrl;
    final hasNetworkPhoto = photoUrl != null &&
        photoUrl.isNotEmpty &&
        (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'));

    if (!hasNetworkPhoto) {
      return _buildReportPhotoPlaceholder(item);
    }

    return Image.network(
      photoUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFF0E8DC),
          child: const Center(
            child: CircularProgressIndicator(color: _reportClay),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildReportPhotoPlaceholder(item);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: _reportSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: _reportClay.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 42,
              color: _reportClay,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No check-ins yet',
            style: AppTextStyles.h3.copyWith(
              color: _reportInk,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete a few spots and this page will turn into a polished travel diary with a shareable poster.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: _reportMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(bool canShare) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: _reportSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: canShare && !_isOpeningPreview ? _showShareDialog : null,
            icon: _isOpeningPreview
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              canShare
                  ? 'Generate Share Poster'
                  : 'Complete a check-in to share',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _reportInk,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _reportMuted.withValues(alpha: 0.24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showShareDialog() {
    setState(() {
      _isOpeningPreview = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareCardPreviewPage(
          checklist: checklist,
          userNickname: _userNickname,
        ),
      ),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isOpeningPreview = false;
      });
    });
  }
}

/// Share card preview page - polished poster-style export.
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
  final ChecklistRepository _checklistRepo = ChecklistRepository();

  bool _isCapturing = false;
  List<ChecklistItem> _items = [];

  Checklist get checklist => widget.checklist;
  List<ChecklistItem> get _completedItems =>
      Checklist.getCompletedItems(_items);
  String get _reportTitle => checklist.displayTitle;
  String get _reportRegion =>
      checklist.isCustom ? checklist.displaySubtitle : checklist.displayTitle;
  String get _shareSlug =>
      _reportTitle.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  String get _userNickname => widget.userNickname;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _checklistRepo.loadChecklistItems(checklist.id);
    if (!mounted) return;

    setState(() {
      _items = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EBE1),
      appBar: AppBar(
        title: const Text('Share Poster'),
        backgroundColor: Colors.transparent,
        foregroundColor: _reportInk,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isCapturing ? null : _captureAndShare,
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildReportBackgroundDecor(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              child: Column(
                children: [
                  Text(
                    'Export-ready poster preview',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _reportMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    key: _cardKey,
                    child: _buildShareCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCapturing ? null : _captureAndShare,
        backgroundColor: _reportInk,
        foregroundColor: Colors.white,
        icon: _isCapturing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.ios_share_rounded),
        label: Text(_isCapturing ? 'Exporting...' : 'Save Poster'),
      ),
    );
  }

  Widget _buildShareCard() {
    final featured = _completedItems.isNotEmpty ? _completedItems.first : null;
    final secondary = _completedItems.skip(1).take(3).toList();
    final averageRating = _averageRating(_completedItems);

    return Container(
      width: 390,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _reportSurface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_reportInk, _reportBerry],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reportTitle.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 38,
                    height: 1.0,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        checklist.isCustom
                            ? '$_userNickname captured ${_completedItems.length} moments in a custom checklist'
                            : '$_userNickname captured ${_completedItems.length} moments in $_reportRegion',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(checklist.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildPosterMetric(
                        label: 'Completed',
                        value: '${_completedItems.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPosterMetric(
                        label: 'Categories',
                        value: '${_categoryCount(_completedItems)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPosterMetric(
                        label: 'Avg Rating',
                        value: averageRating == null
                            ? '--'
                            : averageRating.toStringAsFixed(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (featured != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: double.infinity,
                height: 260,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPosterPhoto(featured),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.56),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPosterCategoryBadge(featured.category),
                          const SizedBox(height: 10),
                          Text(
                            featured.title,
                            style: AppTextStyles.h3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            featured.location,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFF2EADE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  'No completed moments yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _reportMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: secondary.map((item) {
                final isLast = item == secondary.last;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 104,
                        child: _buildPosterPhoto(item),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'MOMENTS LOG',
            style: AppTextStyles.caption.copyWith(
              color: _reportClay,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ..._completedItems.take(6).toList().asMap().entries.map((entry) {
            return _buildPosterListRow(entry.value, entry.key + 1);
          }),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EBDC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.explore_rounded,
                  color: _reportInk,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Made with RoamQuest',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _reportInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '#CITYDIARY',
                  style: AppTextStyles.caption.copyWith(
                    color: _reportMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterPhoto(ChecklistItem item) {
    final photoUrl = item.photoUrl;
    final hasNetworkPhoto = photoUrl != null &&
        photoUrl.isNotEmpty &&
        (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'));

    if (!hasNetworkPhoto) {
      return _buildReportPhotoPlaceholder(item);
    }

    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _buildReportPhotoPlaceholder(item),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFEFE3D5),
          child: const Center(
            child: CircularProgressIndicator(color: _reportClay),
          ),
        );
      },
    );
  }

  Widget _buildPosterListRow(ChecklistItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADFD0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _reportClay,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _reportInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: _reportMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            AppConstants.categoryIcons[item.category] ?? '📍',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndShare() async {
    setState(() => _isCapturing = true);

    try {
      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showError('Failed to capture image');
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement()
          ..href = url
          ..download =
              'roamquest_${_shareSlug}_${DateTime.now().millisecondsSinceEpoch}.png'
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSuccess('Poster downloaded');
      } else {
        _showSuccess('Poster created');

        await Share.shareXFiles(
          [
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
              name:
                  'roamquest_${_shareSlug}_${DateTime.now().millisecondsSinceEpoch}.png',
            ),
          ],
          subject: checklist.isCustom
              ? 'My Custom Checklist Journey'
              : 'My Journey in $_reportTitle',
          text: checklist.isCustom
              ? '$_userNickname explored ${Checklist.getCompletedCount(_items)} amazing places in $_reportTitle.'
              : '$_userNickname explored ${Checklist.getCompletedCount(_items)} amazing places in $_reportTitle.',
        );
      }
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

double? _averageRating(List<ChecklistItem> items) {
  final ratings = items
      .where((item) => item.rating != null)
      .map((item) => item.rating! / 2.0)
      .toList();

  if (ratings.isEmpty) return null;
  final sum = ratings.reduce((a, b) => a + b);
  return sum / ratings.length;
}

int _categoryCount(List<ChecklistItem> items) {
  return items.map((item) => item.category).toSet().length;
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

Widget _buildReportBackgroundDecor() {
  return Stack(
    children: [
      Positioned(
        top: -120,
        right: -60,
        child: Container(
          width: 240,
          height: 240,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x44E8C56B), Color(0x00E8C56B)],
            ),
          ),
        ),
      ),
      Positioned(
        left: -80,
        bottom: 80,
        child: Container(
          width: 220,
          height: 220,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x30D86F3D), Color(0x00D86F3D)],
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _buildReportPhotoPlaceholder(ChecklistItem item) {
  final color = AppColors.getCategoryColor(item.category);
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.20),
          color.withValues(alpha: 0.05),
        ],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppConstants.categoryIcons[item.category] ?? '📍',
            style: const TextStyle(fontSize: 52),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              item.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: _reportInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPosterCategoryBadge(String category) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(AppBorderRadius.full),
    ),
    child: Text(
      '${AppConstants.categoryIcons[category] ?? '📍'} ${_categoryName(category)}',
      style: AppTextStyles.caption.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

String _categoryName(String category) {
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
