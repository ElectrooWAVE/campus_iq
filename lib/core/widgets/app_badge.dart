import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final double fontSize;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.fontSize = 11,
  });

  factory AppBadge.priority(String priority) {
    final colors = {
      'urgent': AppColors.danger,
      'high': AppColors.warning,
      'medium': AppColors.accent,
      'low': AppColors.success,
      'important': AppColors.warning,
      'general': AppColors.textMuted,
    };
    return AppBadge(
      label: priority.toUpperCase(),
      color: (colors[priority.toLowerCase()] ?? AppColors.textMuted)
          .withOpacity(0.15),
      textColor: colors[priority.toLowerCase()] ?? AppColors.textMuted,
    );
  }

  factory AppBadge.year(int year) {
    return AppBadge(
      label: 'Year $year',
      color: AppColors.accent.withOpacity(0.15),
      textColor: AppColors.accent,
    );
  }

  factory AppBadge.branch(String branch) {
    return AppBadge(
      label: branch,
      color: AppColors.primary.withOpacity(0.12),
      textColor: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
