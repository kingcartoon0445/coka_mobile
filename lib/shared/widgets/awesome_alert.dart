import 'package:flutter/material.dart';
import 'package:coka/shared/widgets/custom_alert_dialog.dart';

void successAlert({
  required String title,
  required String desc,
  VoidCallback? btnOkOnPress,
}) {
  // TODO: Implement success alert
}

void errorAlert({
  required String title,
  required String desc,
  VoidCallback? btnOkOnPress,
}) {
  // TODO: Implement error alert
}

void warningAlert({
  required String title,
  required String desc,
  VoidCallback? btnOkOnPress,
  String? nameOkBtn,
}) {
  // TODO: Implement warning alert
}

void showAwesomeAlert({
  required BuildContext context,
  required String title,
  required String description,
  String? confirmText,
  String? cancelText,
  Function()? onConfirm,
  Function()? onCancel,
  bool isWarning = false,
  IconData? icon,
  Color? iconColor,
}) {
  showCustomAlert(
    context: context,
    title: title,
    message: description,
    confirmText: confirmText,
    cancelText: cancelText,
    onConfirm: onConfirm,
    onCancel: onCancel,
    isWarning: isWarning,
    icon: icon,
    iconColor: iconColor,
  );
}

final navigatorKey = GlobalKey<NavigatorState>();
