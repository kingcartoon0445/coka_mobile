import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSubmit;
  final VoidCallback? onCancel;
  final String submitText;
  final String cancelText;
  final bool isLoading;
  final IconData? icon;
  final Color? iconColor;
  final bool showCancelButton;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSubmit,
    this.onCancel,
    this.submitText = 'Đồng ý',
    this.cancelText = 'Hủy',
    this.isLoading = false,
    this.icon,
    this.iconColor,
    this.showCancelButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.help_outline,
                size: 32,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2329),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Buttons
            if (showCancelButton)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : (onCancel ?? () => Navigator.pop(context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              submitText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          submitText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void showCustomAlert({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  bool isWarning = false,
  IconData? icon,
  Color? iconColor,
  bool showCancelButton = false,
}) {
  showDialog(
    context: context,
    builder: (context) => CustomAlertDialog(
      title: title,
      subtitle: message,
      onSubmit: () {
        Navigator.of(context).pop();
        if (onConfirm != null) onConfirm();
      },
      onCancel: onCancel,
      submitText: confirmText ?? 'OK',
      cancelText: cancelText ?? 'Hủy',
      isLoading: false,
      icon: icon,
      iconColor: iconColor,
      showCancelButton: showCancelButton,
    ),
  );
}

void showInfoAlert({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  VoidCallback? onConfirm,
}) {
  showCustomAlert(
    context: context,
    title: title,
    message: message,
    confirmText: confirmText ?? 'Đã hiểu',
    onConfirm: onConfirm,
    icon: Icons.info_outline,
    iconColor: Colors.blue,
    showCancelButton: false,
  );
} 