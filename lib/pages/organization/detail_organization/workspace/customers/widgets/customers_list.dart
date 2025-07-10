import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:collection/collection.dart';
import '../../../../../../api/repositories/customer_repository.dart';
import '../../../../../../api/api_client.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../providers/customer_provider.dart';
import 'customer_list_item.dart';

class CustomersList extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String? stageGroupId;
  final String? searchQuery;
  final Map<String, dynamic> queryParams;
  final VoidCallback? onRefresh;

  const CustomersList({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    this.stageGroupId,
    this.searchQuery,
    required this.queryParams,
    this.onRefresh,
  });

  @override
  ConsumerState<CustomersList> createState() => _CustomersListState();
}

extension CustomersListExtension on _CustomersListState {
  // Method public để trigger refresh từ bên ngoài
  void triggerRefresh() {
    print('CustomersListExtension: triggerRefresh called');
    if (mounted) {
      try {
        setState(() {
          _isFirstLoad = true;
        });
        _pagingController.refresh();
      } catch (e) {
        print('CustomersListExtension: Error during triggerRefresh: $e');
      }
    }
  }
}

class _CustomersListState extends ConsumerState<CustomersList> {
  late final PagingController<int, Map<String, dynamic>> _pagingController;
  final int _limit = 20;
  final _mapEquality = const MapEquality<String, dynamic>();
  final _customerRepository = CustomerRepository(ApiClient());
  bool _isFirstLoad = true;
  
  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, Map<String, dynamic>>(
      getNextPageKey: (state) {
        // Lần đầu tiên sẽ bắt đầu từ offset 0
        final currentOffset = state.keys?.last ?? -_limit; // Trick để lần đầu có offset = 0
        
        // Nếu page cuối cùng có ít hơn limit items, thì đã hết data
        final lastPage = state.pages?.last ?? [];
        if (lastPage.length < _limit && lastPage.isNotEmpty) {
          print('CustomersList: No more data - lastPageSize: ${lastPage.length} < $_limit');
          return null;
        }
        
        final nextOffset = currentOffset + _limit;
        print('CustomersList: getNextPageKey - currentOffset: $currentOffset, nextOffset: $nextOffset, lastPageSize: ${lastPage.length}');
        
        return nextOffset;
      },
      fetchPage: _fetchPage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pagingController.refresh();
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ refresh khi có thay đổi quan trọng
    bool hasImportantChanges = oldWidget.stageGroupId != widget.stageGroupId ||
        oldWidget.organizationId != widget.organizationId ||
        oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.searchQuery != widget.searchQuery;
        
    // Kiểm tra nếu có thay đổi query params quan trọng
    bool hasQueryParamChanges = false;
    if (!_mapEquality.equals(oldWidget.queryParams, widget.queryParams)) {
      // Bỏ qua tham số offset vì nó thay đổi khi phân trang
      Map<String, dynamic> oldParams = Map<String, dynamic>.from(oldWidget.queryParams)..remove('offset');
      Map<String, dynamic> newParams = Map<String, dynamic>.from(widget.queryParams)..remove('offset');
      hasQueryParamChanges = !_mapEquality.equals(oldParams, newParams);
    }
    
    if (hasImportantChanges || hasQueryParamChanges) {
      setState(() {
        _isFirstLoad = true;
      });
      // Sử dụng Future.delayed để tránh nhiều refresh liên tiếp
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _pagingController.refresh();
        }
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPage(int pageKey) async {
    if (!mounted) return [];

    try {
      final Map<String, dynamic> params =
          Map<String, dynamic>.from(widget.queryParams);
      
      // Đảm bảo offset được set đúng
      params['offset'] = pageKey;
      params['limit'] = _limit;
      params['searchText'] = widget.searchQuery;
      params['stageGroupId'] = widget.stageGroupId;

      print('CustomersList: Fetching page with offset: $pageKey, limit: $_limit');

      // Gọi API trực tiếp thay vì qua provider để tránh cache conflicts
      final response = await _customerRepository.getCustomers(
        widget.organizationId,
        widget.workspaceId,
        queryParameters: params.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      );

      if (!mounted) return [];

      final items = response['content'] as List;
      final customers = items.cast<Map<String, dynamic>>();
      
      print('CustomersList: Loaded ${customers.length} customers for offset: $pageKey');
      
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
      }

      return customers;

    } catch (e) {
      print('CustomersList: Error fetching page $pageKey: $e');
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
      }
      rethrow;
    }
  }

  Widget _buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to customer assignment changes để auto-refresh khi có assignment update
    ref.listen<int>(customerAssignmentRefreshProvider, (previous, next) {
      if (previous != null && previous != next && mounted) {
        print('CustomersList: Assignment change detected, refreshing list');
        if (mounted) {
          try {
            setState(() {
              _isFirstLoad = true;
            });
            _pagingController.refresh();
          } catch (e) {
            print('CustomersList: Error during assignment refresh: $e');
          }
        }
      }
    });

    // Listen to customer list changes để auto-refresh khi có thêm/xóa/sửa customer
    ref.listen<int>(customerListRefreshProvider, (previous, next) {
      if (previous != null && previous != next && mounted) {
        print('CustomersList: Customer list change detected, refreshing list');
        if (mounted) {
          try {
            setState(() {
              _isFirstLoad = true;
            });
            _pagingController.refresh();
          } catch (e) {
            print('CustomersList: Error during customer list refresh: $e');
          }
        }
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        print('CustomersList: Pull to refresh triggered');
        if (mounted) {
          setState(() {
            _isFirstLoad = true;
          });
          
          // Reset paging controller về page đầu tiên
          _pagingController.refresh();
          widget.onRefresh?.call();
        }
      },
      child: PagingListener<int, Map<String, dynamic>>(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) => PagedListView<int, Map<String, dynamic>>(
          state: state,
          fetchNextPage: fetchNextPage,
          builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
            itemBuilder: (context, customer, index) => CustomerListItem(
              customer: customer,
              organizationId: widget.organizationId,
              workspaceId: widget.workspaceId,
            ),
            firstPageProgressIndicatorBuilder: (context) => _isFirstLoad
                ? Column(
                    children: List.generate(
                      5,
                      (index) => _buildShimmerItem(),
                    ),
                  )
                : const SizedBox.shrink(),
            newPageProgressIndicatorBuilder: (context) => _buildShimmerItem(),
            firstPageErrorIndicatorBuilder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Có lỗi xảy ra khi tải danh sách khách hàng',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isFirstLoad = true;
                      });
                      _pagingController.refresh();
                    },
                    child: const Text(
                      'Thử lại',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            noItemsFoundIndicatorBuilder: (context) => _isFirstLoad
                ? const SizedBox.shrink()
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Không có khách hàng nào'),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
