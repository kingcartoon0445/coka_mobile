import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../api/repositories/workspace_repository.dart';
import '../../../../../api/api_client.dart';
import '../../../../../shared/widgets/workspace_list_modal.dart';
import '../../../../../shared/widgets/dropdown_button_widget.dart';
import '../../../../../core/theme/app_colors.dart';
import 'dart:developer' as developer;
import 'dart:async';
import 'widgets/customers_list.dart';
import 'widgets/filter_modal.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../api/repositories/report_repository.dart';
import '../../../../../core/utils/helpers.dart';
import 'widgets/import_contact_bottomsheet.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

class CustomersPage extends StatefulWidget {
  final String organizationId;
  final String workspaceId;

  const CustomersPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
  });

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage>
    with SingleTickerProviderStateMixin {
  late final WorkspaceRepository _workspaceRepository;
  late final ReportRepository _reportRepository;
  late final TabController _tabController;
  Map<String, dynamic>? _currentWorkspace;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showClearButton = false;
  String? _searchQuery;
  FilterResult? _currentFilter;
  bool _isFetchingCounts = false;
  Timer? _countsDebounce;
  late final _mapEquality = const MapEquality<String, dynamic>();
  Map<String, dynamic>? _lastQueryParams;

  static const Map<String, ({String name, Color badgeColor})> _tabConfig = {
    'all': (name: 'Tất cả', badgeColor: Color(0xFF5C33F0)),
    'potential': (name: 'Tiềm năng', badgeColor: Color(0xFF92F7A8)),
    'transaction': (name: 'Giao dịch', badgeColor: Color(0xFFA4F3FF)),
    'non_potential': (name: 'Không tiềm năng', badgeColor: Color(0xFFFEC067)),
    'undefined': (name: 'Chưa xác định', badgeColor: Color(0xFF9F87FF)),
  };

  final Map<String, int> _customerCounts = Map.fromEntries(
    _tabConfig.values.map((config) => MapEntry(config.name, 0)),
  );

  Color getTabBadgeColor(String tabName) {
    return _tabConfig.values
        .firstWhere(
          (config) => config.name == tabName,
          orElse: () => _tabConfig['undefined']!,
        )
        .badgeColor;
  }

  @override
  void initState() {
    super.initState();
    _workspaceRepository = WorkspaceRepository(ApiClient());
    _reportRepository = ReportRepository(ApiClient());
    _tabController = TabController(length: _tabConfig.length, vsync: this);
    
    // Thêm listener cho tabController để tránh refresh không cần thiết khi tab đang chuyển
    _tabController.addListener(() {
      // Chỉ xử lý khi tab thực sự thay đổi (animation đã hoàn thành)
      if (!_tabController.indexIsChanging) {
        // Khi tab đã chuyển hoàn toàn, gọi _fetchCustomerCounts nếu cần
        _fetchCustomerCounts();
      }
    });
    
    _fetchCurrentWorkspace();
    _fetchCustomerCounts();
    _searchController.addListener(_handleSearchChange);
  }

  void _handleSearchChange() {
    setState(() {
      _showClearButton = _searchController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChange);
    _searchController.dispose();
    _debounce?.cancel();
    _countsDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      developer.log(
          'WorkspaceId changed from ${oldWidget.workspaceId} to ${widget.workspaceId}');
      setState(() => _isLoading = true);
      _fetchCurrentWorkspace();
    }
    _fetchCustomerCounts();
  }

  Future<void> _fetchCurrentWorkspace() async {
    try {
      developer.log('Fetching workspace detail for ID: ${widget.workspaceId}');
      final response = await _workspaceRepository.getWorkspaceDetail(
        widget.organizationId,
        widget.workspaceId,
      );
      if (mounted) {
        setState(() {
          _currentWorkspace = response['content'];
          _isLoading = false;
        });
        developer
            .log('Current workspace updated: ${_currentWorkspace?['name']}');
      }
    } catch (e) {
      developer.log('Error fetching workspace detail: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra khi tải thông tin workspace')),
        );
      }
    }
  }

  void _showWorkspaceList() {
    WorkspaceListModal.show(
      context: context,
      organizationId: widget.organizationId,
      currentWorkspaceId: widget.workspaceId,
      showAvatar: true,
      showMemberCount: true,
      onWorkspaceSelected: (workspace) {
        final String newPath =
            '/organization/${widget.organizationId}/workspace/${workspace['id']}/customers';
        context.replace(newPath);
      },
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        _fetchCustomerCounts();
      }
    });
  }

  void _showFilterModal() async {
    final result = await FilterModal.show(
      context,
      widget.organizationId,
      widget.workspaceId,
      initialValue: _currentFilter,
    );
    if (result != null && mounted) {
      setState(() {
        _currentFilter = result;
      });
      _fetchCustomerCounts();
    }
  }

  Map<String, dynamic> _buildQueryParams({
    required int page,
    required int limit,
    String? stageGroupId,
  }) {
    final Map<String, dynamic> params = {
      'offset': page,
      'limit': limit,
    };

    if (stageGroupId != null) {
      params['stageGroupId'] = stageGroupId;
    }

    if (_searchQuery?.isNotEmpty ?? false) {
      params['searchText'] = _searchQuery;
    }

    if (_currentFilter != null) {
      if (_currentFilter!.dateRange != null) {
        params['startDate'] =
            _currentFilter!.dateRange!.start.toIso8601String();
        params['endDate'] = _currentFilter!.dateRange!.end.toIso8601String();
      }

      if (_currentFilter!.categories.isNotEmpty) {
        _currentFilter!.categories.asMap().forEach((index, category) {
          params['categoryList[$index]'] = category.id;
        });
      }

      if (_currentFilter!.sources.isNotEmpty) {
        _currentFilter!.sources.asMap().forEach((index, source) {
          params['sourceList[$index]'] = source.name;
        });
      }

      if (_currentFilter!.ratings.isNotEmpty) {
        params['rating'] = _currentFilter!.ratings.first.id;
      }

      if (_currentFilter!.tags.isNotEmpty) {
        _currentFilter!.tags.asMap().forEach((index, tag) {
          params['tags[$index]'] = tag.name;
        });
      }

      if (_currentFilter!.assignees.isNotEmpty) {
        int assignToIndex = 0;
        int teamIdIndex = 0;

        for (var assignee in _currentFilter!.assignees) {
          if (assignee.isTeam) {
            params['teamId[$teamIdIndex]'] = assignee.id;
            teamIdIndex++;
          } else {
            params['assignTo[$assignToIndex]'] = assignee.id;
            assignToIndex++;
          }
        }
      }
    }

    return params;
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
      color: Colors.white,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, color: AppColors.text, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.0,
                ),
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (_showClearButton)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                color: Colors.grey,
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
              ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/page_info.svg',
                width: 20,
                colorFilter: ColorFilter.mode(
                  _currentFilter?.hasActiveFilters == true
                      ? AppColors.primary
                      : AppColors.text,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: _showFilterModal,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: 150,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    return StandardDropdownButton(
      text: _currentWorkspace?['name'] ?? 'Không có tên',
      onTap: _showWorkspaceList,
      isEnabled: !_isLoading,
      iconSize: 24,
      spaceBetweenTextAndIcon: 4,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
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
      tabs: _tabConfig.values.map((config) {
        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(config.name),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: config.badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_customerCounts[config.name]}',
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

  Future<void> _fetchCustomerCounts() async {
    // Hủy bỏ debounce hiện tại nếu có
    _countsDebounce?.cancel();
    
    // Nếu đang lấy dữ liệu, đặt lịch lấy sau 500ms
    if (_isFetchingCounts) {
      _countsDebounce = Timer(const Duration(milliseconds: 500), _fetchCustomerCounts);
      return;
    }
    
    // Tạo params
    final Map<String, dynamic> params = {
      'workspaceId': widget.workspaceId,
      'limit': 9999,
    };

    if (_currentFilter != null) {
      if (_currentFilter!.dateRange != null) {
        params['startDate'] =
            _currentFilter!.dateRange!.start.toIso8601String();
        params['endDate'] = _currentFilter!.dateRange!.end.toIso8601String();
      }

      if (_currentFilter!.categories.isNotEmpty) {
        _currentFilter!.categories.asMap().forEach((index, category) {
          params['categoryList[$index]'] = category.id;
        });
      }

      if (_currentFilter!.sources.isNotEmpty) {
        _currentFilter!.sources.asMap().forEach((index, source) {
          params['sourceList[$index]'] = source.name;
        });
      }

      if (_currentFilter!.ratings.isNotEmpty) {
        params['rating'] = _currentFilter!.ratings.first.id;
      }

      if (_currentFilter!.tags.isNotEmpty) {
        _currentFilter!.tags.asMap().forEach((index, tag) {
          params['tags[$index]'] = tag.name;
        });
      }

      if (_currentFilter!.assignees.isNotEmpty) {
        int assignToIndex = 0;
        int teamIdIndex = 0;

        for (var assignee in _currentFilter!.assignees) {
          if (assignee.isTeam) {
            params['teamId[$teamIdIndex]'] = assignee.id;
            teamIdIndex++;
          } else {
            params['assignTo[$assignToIndex]'] = assignee.id;
            assignToIndex++;
          }
        }
      }
    }

    if (_searchQuery?.isNotEmpty ?? false) {
      params['searchText'] = _searchQuery;
    }
    
    // So sánh với các tham số cuối cùng, nếu giống nhau thì không gọi lại API
    if (_lastQueryParams != null && 
        _mapEquals(_lastQueryParams, params)) {
      return;
    }
    
    _isFetchingCounts = true;
    try {
      final response = await _reportRepository.getStatisticsByStageGroup(
        widget.organizationId,
        widget.workspaceId,
        queryParameters: params.toQueryParameters(),
      );
      
      // Lưu lại tham số cuối cùng
      _lastQueryParams = Map<String, dynamic>.from(params);

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
          _isFetchingCounts = false;
        });
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          _isFetchingCounts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra khi tải số liệu thống kê')),
        );
      }
    }
  }

  bool _mapEquals(Map<String, dynamic>? map1, Map<String, dynamic>? map2) {
    if (map1 == null || map2 == null) return map1 == map2;
    if (map1.length != map2.length) return false;
    
    return _mapEquality.equals(map1, map2);
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilter = null;
    });
    _fetchCustomerCounts();
  }

  Widget _buildActiveFiltersBar() {
    if (_currentFilter == null || !_currentFilter!.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    List<Widget> filterChips = [];

    // Date range filter
    if (_currentFilter!.dateRange != null) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      final startDate = dateFormat.format(_currentFilter!.dateRange!.start);
      final endDate = dateFormat.format(_currentFilter!.dateRange!.end);
      filterChips.add(_buildFilterChip(
        'Từ $startDate đến $endDate',
        () {
          setState(() {
            _currentFilter = FilterResult(
              assignees: _currentFilter!.assignees,
              categories: _currentFilter!.categories,
              sources: _currentFilter!.sources,
              tags: _currentFilter!.tags,
              ratings: _currentFilter!.ratings,
              dateRange: null,
            );
          });
          _fetchCustomerCounts();
        },
      ));
    }

    // Categories
    for (var category in _currentFilter!.categories) {
      filterChips.add(_buildFilterChip(
        'Danh mục: ${category.name}',
        () {
          setState(() {
            final newCategories = List<Category>.from(_currentFilter!.categories);
            newCategories.remove(category);
            _currentFilter = FilterResult(
              assignees: _currentFilter!.assignees,
              categories: newCategories,
              sources: _currentFilter!.sources,
              tags: _currentFilter!.tags,
              ratings: _currentFilter!.ratings,
              dateRange: _currentFilter!.dateRange,
            );
          });
          _fetchCustomerCounts();
        },
      ));
    }

    // Sources
    for (var source in _currentFilter!.sources) {
      filterChips.add(_buildFilterChip(
        'Nguồn: ${source.name}',
        () {
          setState(() {
            final newSources = List<Source>.from(_currentFilter!.sources);
            newSources.remove(source);
            _currentFilter = FilterResult(
              assignees: _currentFilter!.assignees,
              categories: _currentFilter!.categories,
              sources: newSources,
              tags: _currentFilter!.tags,
              ratings: _currentFilter!.ratings,
              dateRange: _currentFilter!.dateRange,
            );
          });
          _fetchCustomerCounts();
        },
      ));
    }

    // Ratings
    for (var rating in _currentFilter!.ratings) {
      filterChips.add(_buildFilterChip(
        'Đánh giá: ${rating.name}',
        () {
          setState(() {
            final newRatings = List<Rating>.from(_currentFilter!.ratings);
            newRatings.remove(rating);
            _currentFilter = FilterResult(
              assignees: _currentFilter!.assignees,
              categories: _currentFilter!.categories,
              sources: _currentFilter!.sources,
              tags: _currentFilter!.tags,
              ratings: newRatings,
              dateRange: _currentFilter!.dateRange,
            );
          });
          _fetchCustomerCounts();
        },
      ));
    }

    // Tags
    for (var tag in _currentFilter!.tags) {
      filterChips.add(_buildFilterChip(
        'Tag: ${tag.name}',
        () {
          setState(() {
            final newTags = List<Tag>.from(_currentFilter!.tags);
            newTags.remove(tag);
            _currentFilter = FilterResult(
              assignees: _currentFilter!.assignees,
              categories: _currentFilter!.categories,
              sources: _currentFilter!.sources,
              tags: newTags,
              ratings: _currentFilter!.ratings,
              dateRange: _currentFilter!.dateRange,
            );
          });
          _fetchCustomerCounts();
        },
      ));
    }

    // Assignees - gộp tất cả thành 1 badge
    if (_currentFilter!.assignees.isNotEmpty) {
      final assigneeNames = _currentFilter!.assignees.map((assignee) => assignee.name).join(', ');
      filterChips.add(_buildFilterChip(
        'Phụ trách: $assigneeNames',
        () {
          setState(() {
            _currentFilter = FilterResult(
              assignees: [],
              categories: _currentFilter!.categories,
              sources: _currentFilter!.sources,
              tags: _currentFilter!.tags,
              ratings: _currentFilter!.ratings,
              dateRange: _currentFilter!.dateRange,
            );
          });
          _fetchCustomerCounts();
        },
      ));
    }

    return Column(
      children: [
        const Divider(
          thickness: 0.2,
          height: 1,
          color: Color(0xFFE5E7EB),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Bộ lọc đang áp dụng:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAllFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Xóa tất cả',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < filterChips.length; i++) ...[
                        filterChips[i],
                        if (i < filterChips.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/organization/${widget.organizationId}'),
          ),
          centerTitle: true,
          title: _buildTitle(),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(_currentFilter?.hasActiveFilters == true ? 145 : 100),
            child: Column(
              children: [
                const Divider(
                  thickness: 0.2,
                  height: 1,
                ),
                _buildTabBar(),
                _buildSearchBar(),
                _buildActiveFiltersBar(),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabConfig.values.map((config) {
            String? stageGroupId;
            if (config.name != 'Tất cả') {
              stageGroupId = AppConstants.stageObject.entries
                  .firstWhere(
                    (entry) => entry.value['name'] == config.name,
                    orElse: () => const MapEntry('', {}),
                  )
                  .key;

              if (stageGroupId == '') {
                stageGroupId = null;
              }
            }
            return CustomersList(
              organizationId: widget.organizationId,
              workspaceId: widget.workspaceId,
              stageGroupId: stageGroupId,
              searchQuery: _searchQuery,
              queryParams: _buildQueryParams(
                page: 0,
                limit: 20,
                stageGroupId: stageGroupId,
              ),
              onRefresh: _fetchCustomerCounts,
            );
          }).toList(),
        ),
        floatingActionButton: SpeedDial(
          icon: Icons.add,
          spacing: 15,
          backgroundColor: const Color(0xFF5C33F0),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14))),
          activeIcon: Icons.close,
          iconTheme: const IconThemeData(color: Colors.white),
          children: [
            SpeedDialChild(
              label: "Thủ công",
              backgroundColor: const Color(0xFFE3DFFF),
              child: const Icon(
                Icons.create,
                color: Colors.black,
              ),
              onTap: () {
                context.push(
                  '/organization/${widget.organizationId}/workspace/${widget.workspaceId}/customers/new',
                );
              },
            ),
            SpeedDialChild(
              backgroundColor: const Color(0xFFE3DFFF),
              label: "Google Sheet",
              child: const Icon(
                Icons.description,
                color: Colors.black,
              ),
              onTap: () {
                context.push(
                  '/organization/${widget.organizationId}/workspace/${widget.workspaceId}/customers/import-googlesheet',
                );
              },
            ),
            SpeedDialChild(
              backgroundColor: const Color(0xFFE3DFFF),
              label: "Nhập từ danh bạ",
              child: const Icon(
                Icons.perm_contact_cal_rounded,
                color: Colors.black,
              ),
              onTap: () async {
                if (await FlutterContacts.requestPermission()) {
                  if (!context.mounted) return;

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    backgroundColor: Colors.transparent,
                    builder: (context) => ImportContactBottomSheet(
                      organizationId: widget.organizationId,
                      workspaceId: widget.workspaceId,
                      onCustomerImported: () {
                        _fetchCustomerCounts();
                      },
                    ),
                  );
                }
              },
            ),
          ],
        ));
  }
}
