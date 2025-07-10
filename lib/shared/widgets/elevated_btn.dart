import 'package:flutter/material.dart';

class ElevatedBtn extends StatelessWidget {
  final void Function()? onPressed;
  final Widget child;
  final double? circular;
  final double? paddingAllValue;
  final Color? backgroundColor;

  const ElevatedBtn({
    super.key,
    required this.onPressed,
    required this.child,
    this.circular,
    this.paddingAllValue,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(circular ?? 8),
        ),
        padding: EdgeInsets.all(paddingAllValue ?? 8),
      ),
      child: child,
    );
  }
}
