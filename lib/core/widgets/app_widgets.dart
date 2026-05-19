import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  bool isSuccess = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: isError
          ? AppColors.danger
          : isSuccess
              ? AppColors.success
              : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}

class AppSnackBar {
  static void success(BuildContext context, String message) =>
      showAppSnackBar(context, message, isSuccess: true);

  static void error(BuildContext context, String message) =>
      showAppSnackBar(context, message, isError: true);

  static void info(BuildContext context, String message) =>
      showAppSnackBar(context, message);
}

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextEditingController? controller;
  final int? maxLines;
  final Widget? suffix;
  final Widget? prefix;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.controller,
    this.maxLines = 1,
    this.suffix,
    this.prefix,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.label
                .copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: obscure ? 1 : maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            prefixIcon: prefix,
          ),
        ),
      ],
    );
  }
}
