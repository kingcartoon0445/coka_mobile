import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../api/repositories/notification_repository.dart';
import '../../api/api_client.dart';
import 'loading_dialog.dart';

class NotificationListWidget extends ConsumerStatefulWidget {
  final String? organizationId;
  final int? maxItems;
  final bool showTitle;
  final bool showMoreOption;
  final VoidCallback? onMoreTap;
  final Function(String)? onMarkAsRead;
  final bool fullScreen;

  const NotificationListWidget({
    super.key,
    this.organizationId,
    this.maxItems,
    this.showTitle = true,
    this.showMoreOption = true,
    this.onMoreTap,
    this.onMarkAsRead,
    this.fullScreen = false,
  });

  @override
  ConsumerState<NotificationListWidget> createState() => _NotificationListWidgetState();
}

class _NotificationListWidgetState extends ConsumerState<NotificationListWidget> {
  late final NotificationRepository _notificationRepository;
  late final PagingController<int, Map<String, dynamic>> _pagingController;
  List<dynamic>? _notifications;
  bool _isLoading = true;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _notificationRepository = NotificationRepository(ApiClient());
    _pagingController = PagingController<int, Map<String, dynamic>>(
      getNextPageKey: (state) => (state.keys?.last ?? 0) + _limit,
      fetchPage: _fetchPage,
    );
    _fetchNotifications();

    if (widget.fullScreen) {
      _scrollController.addListener(_scrollListener);
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore && 
        _notifications != null) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || _notifications == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _notificationRepository.getNotifications(
        organizationId: widget.organizationId,
        limit: _limit,
        offset: _notifications!.length,
      );

      if (mounted) {
        setState(() {
          final newItems = response['content'] as List;
          _notifications!.addAll(newItems);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải thêm thông báo')),
        );
      }
    }
  }

  @override
  void didUpdateWidget(NotificationListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      setState(() {
        _isLoading = true;
        _notifications = null;
      });
      _pagingController.refresh();
      _fetchNotifications();
    }
    
    if (oldWidget.fullScreen != widget.fullScreen) {
      if (widget.fullScreen) {
        _scrollController.addListener(_scrollListener);
      } else {
        _scrollController.removeListener(_scrollListener);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int pageKey) async {
    if (widget.organizationId == 'default') return [];

    try {
      final response = await _notificationRepository.getNotifications(
        organizationId: widget.organizationId,
        limit: _limit,
        offset: pageKey,
      );

      final items = response['content'] as List;
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await _notificationRepository.getNotifications(
        organizationId: widget.organizationId,
        limit: _limit,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _notifications = response['content'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra khi tải danh sách thông báo')),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationRepository.setNotificationRead(notificationId);
      if (widget.onMarkAsRead != null) {
        widget.onMarkAsRead!(notificationId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể đánh dấu là đã đọc')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      showLoadingDialog(context);
      await _notificationRepository.setAllNotificationsRead();
      Navigator.pop(context); // Đóng dialog loading
      _fetchNotifications(); // Tải lại dữ liệu
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Đóng dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi đánh dấu đã đọc tất cả thông báo'),
          ),
        );
      }
    }
  }

  void _showAllNotifications() {
    if (widget.onMoreTap != null) {
      widget.onMoreTap!();
    } else {
      _pagingController.refresh();
      _showNotificationBottomSheet(context);
    }
  }

  void _showNotificationBottomSheet(BuildContext context) {
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
          return _buildBottomSheetContent(scrollController);
        },
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Điều hướng dựa trên thông báo (mark as read được xử lý trong onTap)
    _navigateBasedOnNotificationType(notification);
  }

  // Hàm điều hướng dựa trên loại thông báo
  void _navigateBasedOnNotificationType(Map<String, dynamic> notification) async {
    if (!mounted) return;
    
    // Đóng bottom sheet nếu đang hiển thị
    if (widget.fullScreen && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    final String organizationId = notification['organizationId'] ?? widget.organizationId ?? '';
    if (organizationId.isEmpty) return;
    
    final String workspaceId = notification['workspaceId'] ?? '';
    final String category = notification['category'] ?? '';
    
    // Parse metadata nếu có
    Map<String, dynamic> metadata = {};
    if (notification['metadata'] != null) {
      try {
        if (notification['metadata'] is String) {
          metadata = jsonDecode(notification['metadata']);
        } else if (notification['metadata'] is Map) {
          metadata = Map<String, dynamic>.from(notification['metadata']);
        }
      } catch (e) {
        print('Lỗi parse metadata: $e');
      }
    }

    // Kiểm tra xem có cần đổi tổ chức không
    final currentOrgId = widget.organizationId;
    if (organizationId != currentOrgId && organizationId.isNotEmpty) {
      // Nếu thông báo từ tổ chức khác, lưu default organization
      // Navigation sẽ trigger OrganizationPage.didUpdateWidget và tự động load tổ chức mới
      try {
        await ApiClient.storage.write(
          key: 'default_organization_id', 
          value: organizationId
        );
        print('Đã cập nhật default organization thành: $organizationId');
      } catch (e) {
        print('Lỗi khi lưu default organization: $e');
      }
    }

    // Xác định route dựa vào category và metadata
    String route = '';
    
    if (['ASSIGN_CONTACT', 'NEW_CONTACT', 'RETURN_CONTACT', 'IMPORT_CONTACT', 'LEAD_RECOVERY'].contains(category)) {
      final customerId = metadata['Id'];
      if (customerId != null) {
        route = '/organization/$organizationId/workspace/$workspaceId/customers/$customerId';
      } else {
        route = '/organization/$organizationId/workspace/$workspaceId/customers';
      }
    } else if (['NEW_CONVERSATION', 'ASSIGN_CONVERSATION'].contains(category)) {
      final conversationId = metadata['Id'];
      if (conversationId != null) {
        route = '/organization/$organizationId/messages/detail/$conversationId';
      } else {
        route = '/organization/$organizationId/messages';
      }
    } else if (['GRANT_ROLE_USER_TEAM', 'ADD_USER_TEAM'].contains(category)) {
      route = '/organization/$organizationId/workspace/$workspaceId/teams';
    } else if (['VERIFY_WEBSITE', 'CONNECT_FORM', 'EXPIRED_ACCESSTOKEN'].contains(category)) {
      route = '/organization/$organizationId/campaigns/multi-source-connection';
    } else if (['INVITE_MEMBER', 'REQUEST_ORGANIZATION'].contains(category)) {
      // Trường hợp đặc biệt - không điều hướng
      return;
    } else {
      // Các trường hợp khác hoặc không xác định, điều hướng về trang chính của tổ chức
      route = '/organization/$organizationId';
    }

    // Thực hiện điều hướng  
    if (route.isNotEmpty) {
      // Phân loại routes
      final routesWithoutShell = [
        '/organization/$organizationId/campaigns/multi-source-connection',
        '/organization/$organizationId/campaigns/fill-data', 
        '/organization/$organizationId/campaigns/automation'
      ];
      
      final workspaceRoutes = route.contains('/workspace/');
      final isRouteWithoutShell = routesWithoutShell.contains(route);
      
      if (organizationId != currentOrgId) {
        // Đổi tổ chức
        if (isRouteWithoutShell) {
          print('Navigate đến tổ chức khác qua route ngoài shell, đi qua base trước: $route');
          // Đối với routes ngoài shell, phải đi qua base organization trước để trigger OrganizationPage
          context.go('/organization/$organizationId');
          // Đợi OrganizationPage load xong, rồi mới navigate đến route đích
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              context.push(route);
            }
          });
        } else {
          print('Navigate đến tổ chức khác qua route có shell: $route');
          // Routes có shell, có thể go trực tiếp
          context.go(route);
        }
      } else {
        // Cùng tổ chức
        print('Navigate trong cùng tổ chức: $route');
        
        if (widget.fullScreen) {
          // Trong bottom sheet - an toàn dùng context.go cho tất cả cases
          print('Navigate từ bottom sheet - sử dụng context.go: $route');
          context.push(route);
        } else {
          // Trong compact view - cần cẩn thận với navigation
          if (isRouteWithoutShell) {
            // Routes ngoài shell - dùng push để giữ stack, GoRouter sẽ tự handle
            print('Compact view - route ngoài shell, sử dụng push: $route');
            context.push(route);
          } else if (workspaceRoutes) {
            // Workspace routes - dùng context.go để tránh stack corruption
            print('Compact view - sử dụng context.go cho workspace route: $route');
            context.go(route);
          } else {
            // Routes đơn giản - có thể push an toàn
            print('Compact view - sử dụng context.push cho route đơn giản: $route');
            context.push(route);
          }
        }
      }
    }
  }

  Widget _buildBottomSheetContent(ScrollController scrollController) {
    final effectiveController = scrollController;
    
    if (scrollController != _scrollController) {
      scrollController.addListener(() {
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent * 0.9 &&
            !_isLoadingMore && _notifications != null) {
          _loadMoreNotifications();
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBottomSheetHeader(),
        Expanded(
          child: _isLoading 
            ? ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) => _buildShimmerNotificationItem(),
              )
            : RefreshIndicator(
                edgeOffset: 70,
                onRefresh: _fetchNotifications,
                child: _notifications == null || _notifications!.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Chưa có thông báo nào'),
                      ),
                    )
                  : ListView.builder(
                      controller: effectiveController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _notifications!.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _notifications!.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        return Column(
                          children: [
                            _buildNotificationItem(_notifications![index]),
                          ],
                        );
                      },
                    ),
              ),
        ),
      ],
    );
  }

  Widget _buildBottomSheetHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông báo',
                style: TextStyles.title,
              ),
              IconButton(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all),
                tooltip: 'Đánh dấu tất cả là đã đọc',
              ),
            ],
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }

  List<InlineSpan> _parseHtmlText(String htmlText) {
    final List<InlineSpan> spans = [];
    final RegExp exp = RegExp(r'<b>(.*?)</b>|([^<>]+)');

    final Iterable<Match> matches = exp.allMatches(htmlText);
    for (final Match match in matches) {
      if (match.group(1) != null) {
        // Bold text
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            fontFamily: 'GoogleSans',
            color: AppColors.text,
          ),
        ));
      } else if (match.group(2) != null) {
        // Normal text
        spans.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            fontFamily: 'GoogleSans',
            color: AppColors.text,
          ),
        ));
      }
    }
    return spans;
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final createdDate = DateTime.parse(notification['createdDate']);
    final timeAgo = timeago.format(createdDate, locale: 'vi');
    final bool isRead = notification['status'] == 0;

    return InkWell(
      onTap: () async {
        // Xử lý điều hướng trước để tránh conflict với setState
        _handleNotificationTap(notification);
        
        // Đánh dấu đã đọc sau khi navigate để tránh interrupt
        if (!isRead) {
          _markAsRead(notification['id']);
          // Delay setState để đảm bảo navigation đã hoàn thành
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              setState(() {
                notification['status'] = 0;
              });
            }
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: notification['avatar'] == null
                  ? SvgPicture.asset(
                      'assets/icons/logo_without_text.svg',
                      width: 24,
                      height: 24,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        notification['avatar'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return SvgPicture.asset(
                            'assets/icons/logo_without_text.svg',
                            width: 24,
                            height: 24,
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'GoogleSans',
                        color: AppColors.text,
                      ),
                      children: _parseHtmlText(notification['contentHtml'] ?? ''),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'GoogleSans',
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding:
                const EdgeInsets.only(left: 16, right: 16, bottom: 0, top: 8),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 8),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 60,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (widget.showMoreOption)
            Column(
              children: [
                const Divider(
                  height: 1,
                  color: Color(0xFFE4E7EC),
                  thickness: 0.3,
                ),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompactView() {
    if (_notifications == null || _notifications!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có thông báo nào'),
        ),
      );
    }

    final displayNotifications = widget.maxItems != null
        ? _notifications!.take(widget.maxItems!).toList()
        : _notifications!;
    
    final hasMore = _notifications!.length > (widget.maxItems ?? _notifications!.length);

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding:
                const EdgeInsets.only(left: 0, right: 0, bottom: 0, top: 8),
            itemCount: displayNotifications.length,
            itemBuilder: (context, index) =>
                _buildNotificationItem(displayNotifications[index]),
          ),
          if (widget.showMoreOption && hasMore)
            Column(
              children: [
                const Divider(
                  height: 1,
                  color: Color(0xFFE4E7EC),
                  thickness: 0.3,
                ),
                InkWell(
                  onTap: _showAllNotifications,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Xem tất cả',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFullscreenView() {
    if (_notifications == null || _notifications!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chưa có thông báo nào'),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _notifications!.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications!.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return Column(
          children: [
            _buildNotificationItem(_notifications![index]),
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullScreen) {
      return _buildBottomSheetContent(_scrollController);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Cập nhật mới nhất',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        _isLoading ? _buildShimmerLoading() : _buildCompactView(),
      ],
    );
  }
  
  Widget _buildShimmerNotificationItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 