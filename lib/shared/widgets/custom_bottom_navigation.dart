import 'package:coka/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTapped;
  final bool showCampaignBadge;
  final bool showSettingsBadge;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTapped,
    this.showCampaignBadge = false,
    this.showSettingsBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w400,
            fontSize: 12,
          );
        }),
      ),
      child: NavigationBar(
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.business_outlined, size: 26),
            selectedIcon: Icon(
              Icons.business_sharp,
              size: 22,
              color: Color(0xFF5A48EF),
            ),
            label: 'Tổ chức',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_outlined, size: 22),
            selectedIcon: Icon(
              Icons.chat_outlined,
              size: 22,
              color: Color(0xFF5A48EF),
            ),
            label: 'Chat đa kênh',
          ),
          NavigationDestination(
            icon: badges.Badge(
              showBadge: showCampaignBadge,
              position: badges.BadgePosition.topEnd(top: -3, end: -3),
              child: Image.asset(
                "assets/images/target_outline_icon.png",
                width: 20,
                height: 20,
              ),
            ),
            selectedIcon: Image.asset(
              "assets/images/target_icon.png",
              width: 20,
              height: 20,
            ),
            label: 'Chiến dịch',
          ),
        ],
        onDestinationSelected: onTapped,
        selectedIndex: selectedIndex,
        animationDuration: const Duration(milliseconds: 500),
        indicatorColor: const Color(0xFFDCDBFF),
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
      ),
    );
  }
}
