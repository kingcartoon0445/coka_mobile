import 'package:flutter/material.dart';

class ContextMenuItem {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  const ContextMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });
}

class ContextMenu {
  static void show({
    required BuildContext context,
    required RenderBox itemBox,
    required List<ContextMenuItem> items,
    double offsetX = -50,
    double offsetY = -8,
  }) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset itemPosition = itemBox.localToGlobal(Offset.zero);
    final Size itemSize = itemBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        itemPosition.dx + itemSize.width + offsetX,
        itemPosition.dy + itemSize.height + offsetY,
        -offsetX,
        overlay.size.height - itemPosition.dy - itemSize.height - offsetY,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFE4E7EC),
          width: 1,
        ),
      ),
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      items: items.map((item) => PopupMenuItem(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: item.onTap,
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: item.iconColor ?? const Color(0xFF667085),
            ),
            const SizedBox(width: 12),
            Text(
              item.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: item.textColor ?? const Color(0xFF101828),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
} 