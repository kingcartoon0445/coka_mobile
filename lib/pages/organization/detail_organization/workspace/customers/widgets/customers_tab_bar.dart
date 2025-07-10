import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../api/repositories/report_repository.dart';
import '../../../../../../api/api_client.dart';

class CustomersTabBar extends StatefulWidget {
  final String organizationId;
  final String workspaceId;
  final Map<String, dynamic> queryParams;
  final TabController tabController;

  const CustomersTabBar({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.queryParams,
    required this.tabController,
  });

  @override
  State<CustomersTabBar> createState() => _CustomersTabBarState();
}

class _CustomersTabBarState extends State<CustomersTabBar> {
  late final ReportRepository _reportRepository;
  final _mapEquality = const MapEquality<String, dynamic>();
  final Map<String, int> _customerCounts = {
    'Tất cả': 0,
    'Tiềm năng': 0,
    'Giao dịch': 0,
    'Không tiềm năng': 0,
    'Chưa xác định': 0,
  };
  
  // Biến để kiểm soát việc load dữ liệu
  bool _isLoading = false;
  
  // Lưu trữ params cuối cùng để tránh gọi lại API khi params không thay đổi
  Map<String, String>? _lastParams;

  @override
  void initState() {
    super.initState();
    _reportRepository = ReportRepository(ApiClient());
    _fetchCustomerCounts();
  }

  @override
  void didUpdateWidget(CustomersTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId ||
        oldWidget.workspaceId != widget.workspaceId ||
        !_mapEquality.equals(oldWidget.queryParams, widget.queryParams)) {
      _fetchCustomerCounts();
    }
  }

  Color getTabBadgeColor(String tabName) {
    if (tabName == "Tất cả") {
      return const Color(0xFF5C33F0);
    } else if (tabName == "Tiềm năng") {
      return const Color(0xFF92F7A8);
    } else if (tabName == "Giao dịch") {
      return const Color(0xFFA4F3FF);
    } else if (tabName == "Không tiềm năng") {
      return const Color(0xFFFEC067);
    } else if (tabName == "Chưa xác định") {
      return const Color(0xFF9F87FF);
    }
    return const Color(0xFF9F87FF);
  }

  Future<void> _fetchCustomerCounts() async {
    // Nếu đang trong quá trình lấy dữ liệu, bỏ qua
    if (_isLoading) return;
    
    try {
      final Map<String, String> params = {
        'workspaceId': widget.workspaceId,
        'limit': '9999',
        ...widget.queryParams
            .map((key, value) => MapEntry(key, value.toString())),
      };
      
      // So sánh với params trước đó, nếu giống nhau thì không gọi lại API
      if (_lastParams != null && 
          _mapEquality.equals(_lastParams as Map<String, dynamic>, params as Map<String, dynamic>)) {
        return;
      }
      
      _isLoading = true;
      final response = await _reportRepository.getStatisticsByStageGroup(
        widget.organizationId,
        widget.workspaceId,
        queryParameters: params,
      );
      
      // Cập nhật params cuối cùng
      _lastParams = Map<String, String>.from(params);

      if (mounted) {
        setState(() {
          int total = 0;
          final List<dynamic> groups = response['content'];
          for (var group in groups) {
            final String groupName = group['groupName'];
            final int count = group['count'];
            _customerCounts[groupName] = count;
            total += count;
          }
          _customerCounts['Tất cả'] = total;
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
              content: Text('Có lỗi xảy ra khi tải số liệu thống kê')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: widget.tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.label,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.text,
      indicatorColor: AppColors.primary,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      tabs: _customerCounts.entries.map((entry) {
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.key),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: getTabBadgeColor(entry.key),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entry.value}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, int> get customerCounts => _customerCounts;
}
