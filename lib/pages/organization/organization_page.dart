import 'package:coka/core/theme/text_styles.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coka/api/repositories/auth_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/shared/widgets/custom_bottom_navigation.dart';
import 'package:coka/api/repositories/organization_repository.dart';
import 'package:coka/api/repositories/notification_repository.dart';
import 'package:coka/shared/widgets/organization_drawer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:coka/shared/widgets/notification_list_widget.dart';
import 'dart:async';

class OrganizationPage extends StatefulWidget {
  final String organizationId;
  final Widget child;

  const OrganizationPage({
    super.key,
    required this.organizationId,
    required this.child,
  });

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  Map<String, dynamic>? _userInfo;
  Map<String, dynamic>? _organizationInfo;
  List<dynamic> _organizations = [];
  bool _isLoading = true;
  bool _isLoadingOrganizationsError = false;
  int _unreadNotificationCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void didUpdateWidget(OrganizationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    print(
        'didUpdateWidget - old: ${oldWidget.organizationId}, new: ${widget.organizationId}');
    if (oldWidget.organizationId != widget.organizationId) {
      print('Organization ID changed - reloading data');
      _loadOrganizations();
    }
  }

  Future<void> _initData() async {
    await Future.wait([
      _loadUserInfo(),
      _loadOrganizations(),
      _loadUnreadNotificationCount(),
    ]);
  }

  Future<void> _loadOrganizations() async {
    if (mounted) {
      setState(() {
        _isLoadingOrganizationsError = false;
      });
    }

    try {
      final organizationRepository = OrganizationRepository(ApiClient());
      final response = await organizationRepository.getOrganizations();

      if (!mounted) return;

      final organizations = response['content'] ?? [];
      setState(() {
        _organizations = organizations;
        _isLoadingOrganizationsError = false;
      });

      if (widget.organizationId == 'default') {
        final defaultOrgId =
            await ApiClient.storage.read(key: 'default_organization_id');
        print('Đọc organization mặc định: $defaultOrgId');

        if (defaultOrgId != null && organizations.isNotEmpty) {
          final defaultOrg = organizations.firstWhere(
            (org) => org['id'] == defaultOrgId,
            orElse: () => organizations[0],
          );
          print('Tìm thấy organization mặc định: ${defaultOrg['id']}');
          if (mounted) {
            context.go('/organization/${defaultOrg['id']}');
          }
        } else if (organizations.isNotEmpty) {
          print(
              'Không có organization mặc định, dùng organization đầu tiên: ${organizations[0]['id']}');
          if (mounted) {
            context.go('/organization/${organizations[0]['id']}');
          }
        } else {
          print('Không có tổ chức nào được tìm thấy.');
          if (mounted) {
            setState(() {
              _isLoadingOrganizationsError = true;
            });
          }
        }
      } else {
        final currentOrg = organizations.firstWhere(
          (org) => org['id'] == widget.organizationId,
          orElse: () => null,
        );
        if (currentOrg != null) {
          if (mounted) {
            setState(() {
              _organizationInfo = currentOrg;
            });
          }
          print('Lưu organization mặc định: ${widget.organizationId}');
          await ApiClient.storage.write(
            key: 'default_organization_id',
            value: widget.organizationId,
          );
          final savedOrgId =
              await ApiClient.storage.read(key: 'default_organization_id');
          print('Kiểm tra lại organization mặc định đã lưu: $savedOrgId');
        } else {
          print('Organization ID ${widget.organizationId} không tìm thấy trong danh sách.');
          if (mounted) {
            if (organizations.isNotEmpty) {
              context.go('/organization/${organizations[0]['id']}');
            } else {
              setState(() {
                _isLoadingOrganizationsError = true;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Lỗi khi load organizations: $e');
      if (mounted) {
        setState(() {
          _isLoadingOrganizationsError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tải danh sách tổ chức'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final authRepository = AuthRepository(ApiClient());
      final response = await authRepository.getUserInfo();
      if (mounted) {
        setState(() {
          _userInfo = response['content'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải thông tin người dùng')),
        );
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final notificationRepository = NotificationRepository(ApiClient());
      final response = await notificationRepository.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = response['content'] ?? 0;
        });
      }
    } catch (e) {
      print('Lỗi khi load số lượng thông báo chưa đọc: $e');
      // Không hiển thị lỗi cho user vì đây không phải chức năng quan trọng
    }
  }

  String _getRoleText(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'OWNER':
        return 'Chủ tổ chức';
      default:
        return 'Thành viên';
    }
  }

  Widget _buildSkeletonTitle() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 130,
            height: 14,
            color: Colors.white,
          ),
          const SizedBox(height: 2),
          Container(
            width: 80,
            height: 12,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        child: AppAvatar(
          size: 48,
          shape: AvatarShape.rectangle,
          borderRadius: 16,
          fallbackText: _userInfo?['fullName'],
          imageUrl: _userInfo?['avatar'],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.contains('/messages')) {
      return const Text('Tin nhắn');
    }
    if (location.contains('/campaigns')) {
      return const Text('Chiến dịch');
    }

    if (_isLoading) {
      return _buildSkeletonTitle();
    }

    if (_isLoadingOrganizationsError) {
        return const Text(
          'Lỗi tải tổ chức',
          style: TextStyle(color: Colors.red),
        );
    }

    if (_organizationInfo == null && widget.organizationId != 'default') {
       return _buildSkeletonTitle();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _userInfo?['fullName'] ?? '',
          style: TextStyles.heading3,
        ),
        if (_organizationInfo != null)
          Text(
            _getRoleText(_organizationInfo?['type']),
            style: TextStyles.subtitle2,
          ),
      ],
    );
  }

  Widget _buildDrawer() {
    return OrganizationDrawer(
      userInfo: _userInfo,
      currentOrganizationId: widget.organizationId,
      organizations: _organizations,
      onLogout: () => _handleLogout(context),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.contains('/messages')) {
      return 1;
    }
    if (location.contains('/campaigns')) {
      return 2;
    }
    return 0;
  }

  // Kiểm tra xem có đang ở trang AI Chatbot không
  bool _isAIChatbotPage(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return location.contains('/campaigns/ai-chatbot');
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.replace('/organization/${widget.organizationId}');
        break;
      case 1:
        context.replace('/organization/${widget.organizationId}/messages');
        break;
      case 2:
        context.replace('/organization/${widget.organizationId}/campaigns');
        break;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authRepository = AuthRepository(ApiClient());
    await authRepository.logout();
    if (context.mounted) {
      context.replace('/');
    }
  }

  void _navigateToNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          const notificationWidget = NotificationListWidget(
            showTitle: false,
            showMoreOption: false,
            fullScreen: true,
          );
          
          return notificationWidget;
        },
      ),
    ).then((_) {
      // Reload unread count khi đóng notification modal
      _loadUnreadNotificationCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem có đang ở trang AI Chatbot không
    final isAIChatbotPage = _isAIChatbotPage(context);
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: isAIChatbotPage ? null : AppBar(
        leading: _buildAvatar(),
        title: _buildTitle(context),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: _navigateToNotifications,
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
                            color: Colors.grey.withValues(alpha: 0.2),
          ),
        ),
      ),
      body: widget.child,
      bottomNavigationBar: isAIChatbotPage ? null : CustomBottomNavigation(
        selectedIndex: _calculateSelectedIndex(context),
        onTapped: (index) => _onItemTapped(index, context),
        showCampaignBadge: false,
        showSettingsBadge: false,
      ),
    );
  }
}
