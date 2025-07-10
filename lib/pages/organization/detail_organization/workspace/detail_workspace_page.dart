import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../pages/organization/detail_organization/workspace/reports/components/report_providers.dart';

class DetailWorkspacePage extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final Widget child;

  const DetailWorkspacePage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.child,
  });

  @override
  ConsumerState<DetailWorkspacePage> createState() =>
      _DetailWorkspacePageState();
}

class _DetailWorkspacePageState extends ConsumerState<DetailWorkspacePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Đảm bảo shouldLoadReports là false khi khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsPageShouldLoadProvider.notifier).state = false;
    });
  }

  @override
  void didUpdateWidget(DetailWorkspacePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final state = GoRouterState.of(context);
    final location = state.uri.path;

    // Cập nhật currentIndex dựa trên location
    if (location.contains('/customers')) {
      setState(() => _currentIndex = 0);
    } else if (location.contains('/teams')) {
      setState(() => _currentIndex = 1);
    } else if (location.contains('/reports')) {
      setState(() => _currentIndex = 2);
      // Delay việc set shouldLoadReports để tránh lỗi build
      Future.microtask(() {
        if (mounted) {
          ref.read(reportsPageShouldLoadProvider.notifier).state = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final location = state.uri.path;
    final hideBottomNav = location.contains('/customers/') || 
                          (location.contains('/teams/') && location.split('/').length > 6);

    // Sync currentIndex với location mỗi khi build (để handle FCM navigation)
    int correctIndex = 0;
    if (location.contains('/teams')) {
      correctIndex = 1;
    } else if (location.contains('/reports')) {
      correctIndex = 2;
      // Set shouldLoadReports khi vào reports page
      if (_currentIndex != 2) {
        Future.microtask(() {
          if (mounted) {
            ref.read(reportsPageShouldLoadProvider.notifier).state = true;
          }
        });
      }
    } else if (location.contains('/customers')) {
      correctIndex = 0;
    }
    
    // Cập nhật currentIndex nếu khác với correctIndex
    if (_currentIndex != correctIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _currentIndex = correctIndex);
        }
      });
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: hideBottomNav
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: NavigationBarTheme(
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
            selectedIndex: _currentIndex,
            animationDuration: const Duration(milliseconds: 500),
            indicatorColor: const Color(0xFFDCDBFF),
            backgroundColor: Colors.white,
            elevation: 4,
            shadowColor: Colors.black,
            surfaceTintColor: Colors.white,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 68,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);

              // Reset shouldLoadReports khi rời khỏi tab reports
              if (_currentIndex == 2 && index != 2) {
                ref.read(reportsPageShouldLoadProvider.notifier).state = false;
              }

              switch (index) {
                case 0:
                  context.replace(
                      '/organization/${widget.organizationId}/workspace/${widget.workspaceId}/customers');
                  break;
                case 1:
                  context.replace(
                      '/organization/${widget.organizationId}/workspace/${widget.workspaceId}/teams');
                  break;
                case 2:
                  context.replace(
                      '/organization/${widget.organizationId}/workspace/${widget.workspaceId}/reports');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.people_outline, color: AppColors.textTertiary),
                selectedIcon: Icon(Icons.people, color: AppColors.primary),
                label: 'Khách hàng',
              ),
              NavigationDestination(
                icon:
                    Icon(Icons.groups_outlined, color: AppColors.textTertiary),
                selectedIcon: Icon(Icons.groups, color: AppColors.primary),
                label: 'Đội sale',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined,
                    color: AppColors.textTertiary),
                selectedIcon: Icon(Icons.analytics, color: AppColors.primary),
                label: 'Báo cáo',
              ),
            ],
          ),
        ),
        secondChild: const SizedBox(height: 0),
      ),
    );
  }
}
