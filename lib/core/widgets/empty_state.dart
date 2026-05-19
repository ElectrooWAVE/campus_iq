import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? submessage;
  final IconData? icon;

  const EmptyState({
    super.key,
    required this.message,
    this.submessage,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: 40,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: AppTextStyles.h3.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (submessage != null) ...[
              const SizedBox(height: 8),
              Text(
                submessage!,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
