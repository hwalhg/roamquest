import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Custom bottom sheet with rounded corners
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final double? height;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.children,
    this.height,
  });

  /// Show the bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required List<Widget> children,
    double? height,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(
        title: title,
        children: children,
        height: height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                title!,
                style: AppTextStyles.h3,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
          ],
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: bottomPadding + AppSpacing.lg,
                top: AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action sheet for simple choices
class AppActionSheet extends StatelessWidget {
  final String title;
  final List<AppActionSheetItem> actions;
  final String? cancelLabel;

  const AppActionSheet({
    super.key,
    required this.title,
    required this.actions,
    this.cancelLabel,
  });

  /// Show action sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<AppActionSheetItem> actions,
    String? cancelLabel,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AppActionSheet(
        title: title,
        actions: actions,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: title,
      children: [
        ...actions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildActionButton(context, action),
            )),
        if (cancelLabel != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelLabel!),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, AppActionSheetItem action) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context, action.value);
          action.onTap?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: action.isDestructive
              ? AppColors.error
              : AppColors.primary,
        ),
        child: Text(
          action.label,
          style: AppTextStyles.button.copyWith(
            color: AppColors.textOnDark,
          ),
        ),
      ),
    );
  }
}

/// Action sheet item
class AppActionSheetItem {
  final String label;
  final dynamic value;
  final VoidCallback? onTap;
  final bool isDestructive;

  AppActionSheetItem({
    required this.label,
    required this.value,
    this.onTap,
    this.isDestructive = false,
  });
}
