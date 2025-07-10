import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../shared/widgets/avatar_widget.dart';
import '../../../../../../../shared/widgets/custom_alert_dialog.dart';
import '../../../../../../../api/repositories/team_repository.dart';
import '../../../../../../../api/repositories/organization_repository.dart';
import '../../../../../../../api/api_client.dart';
import '../../../../../../../providers/customer_provider.dart';

class AssignToBottomSheet extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String customerId;
  final Function(Map<String, dynamic>) onSelected;
  final List<Map<String, dynamic>>? defaultAssignees;

  const AssignToBottomSheet({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.customerId,
    required this.onSelected,
    this.defaultAssignees,
  });

  @override
  ConsumerState<AssignToBottomSheet> createState() =>
      _AssignToBottomSheetState();
}

class _AssignToBottomSheetState extends ConsumerState<AssignToBottomSheet>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _memberSubTabController;
  
  final TextEditingController _orgMemberSearchController = TextEditingController();
  final TextEditingController _salesMemberSearchController = TextEditingController();
  final TextEditingController _teamSearchController = TextEditingController();
  
  final TeamRepository _teamRepository = TeamRepository(ApiClient());
  final OrganizationRepository _orgRepository = OrganizationRepository(ApiClient());

  // Cancel tokens để hủy bỏ các HTTP requests khi cần thiết
  CancelToken? _orgMembersCancelToken;
  CancelToken? _salesMembersCancelToken;
  CancelToken? _teamsCancelToken;
  CancelToken? _assignCancelToken;

  // Debounce timers để tránh quá nhiều API calls
  Timer? _orgSearchDebounce;
  Timer? _salesSearchDebounce;
  Timer? _teamSearchDebounce;

  List<Map<String, dynamic>> _orgMembers = [];
  List<Map<String, dynamic>> _salesMembers = [];
  List<Map<String, dynamic>> _teams = [];
  final List<Map<String, dynamic>> _selectedMembers = [];
  
  bool _isLoadingOrgMembers = false;
  bool _isLoadingSalesMembers = false;
  bool _isLoadingTeams = false;
  bool _isAssigning = false;
  
  String _orgMemberSearchText = '';
  String _salesMemberSearchText = '';
  String _teamSearchText = '';

  // Helper method để safely call setState
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  // Helper method để safely show snackbar
  void _safeShowSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _memberSubTabController = TabController(length: 2, vsync: this);
    
    // Set default assignees for organization tab only
    if (widget.defaultAssignees != null) {
      _selectedMembers.addAll(widget.defaultAssignees!);
    }
    
    _loadInitialData();
  }

  @override
  void dispose() {
    // Hủy bỏ tất cả các HTTP requests đang pending
    _orgMembersCancelToken?.cancel();
    _salesMembersCancelToken?.cancel();
    _teamsCancelToken?.cancel();
    _assignCancelToken?.cancel();
    
    // Hủy bỏ các debounce timers
    _orgSearchDebounce?.cancel();
    _salesSearchDebounce?.cancel();
    _teamSearchDebounce?.cancel();
    
    // Dispose controllers
    _mainTabController.dispose();
    _memberSubTabController.dispose();
    _orgMemberSearchController.dispose();
    _salesMemberSearchController.dispose();
    _teamSearchController.dispose();
    
    // Reset flags
    _isAssigning = false;
    _isLoadingOrgMembers = false;
    _isLoadingSalesMembers = false;
    _isLoadingTeams = false;
    
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadOrgMembers(),
      _loadTeams(),
    ]);
  }

  Future<void> _loadOrgMembers() async {
    if (_isLoadingOrgMembers || !mounted) return;
    
    // Hủy bỏ request trước đó nếu có
    _orgMembersCancelToken?.cancel();
    _orgMembersCancelToken = CancelToken();
    
    try {
      setState(() => _isLoadingOrgMembers = true);
      
      final response = await _orgRepository.getOrgMembers(
        widget.organizationId,
        offset: 0,
        searchText: _orgMemberSearchText.isNotEmpty ? _orgMemberSearchText : null,
        workspaceId: widget.workspaceId,
      );

      if (mounted && !_orgMembersCancelToken!.isCancelled) {
        setState(() {
          _orgMembers = (response['content'] as List).map((member) {
            return {
              'profileId': member['profileId'],
              'fullName': member['fullName'],
              'avatar': member['avatar'],
              'email': member['email'],
            };
          }).toList();
        });
      }
    } catch (e) {
      if (mounted && !_orgMembersCancelToken!.isCancelled) {
        // Không hiển thị lỗi nếu request bị cancel
        if (e is DioException && e.type == DioExceptionType.cancel) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi tải danh sách thành viên tổ chức')),
        );
      }
    } finally {
      if (mounted && !_orgMembersCancelToken!.isCancelled) {
        setState(() => _isLoadingOrgMembers = false);
      }
    }
  }

  Future<void> _loadSalesMembers() async {
    if (_isLoadingSalesMembers || !mounted) return;
    
    // Hủy bỏ request trước đó nếu có
    _salesMembersCancelToken?.cancel();
    _salesMembersCancelToken = CancelToken();
    
    try {
      setState(() => _isLoadingSalesMembers = true);
      
      final response = await _teamRepository.getUserCurrentManagerList(
        widget.organizationId,
        widget.workspaceId,
        searchText: _salesMemberSearchText.isNotEmpty ? _salesMemberSearchText : null,
      );

      if (mounted && !_salesMembersCancelToken!.isCancelled) {
        setState(() {
          _salesMembers = (response['content'] as List).map((member) {
            return {
              'profileId': member['profileId'],
              'fullName': member['fullName'],
              'avatar': member['avatar'],
              'teamId': member['teamId'],
              'teamName': member['teamName'],
            };
          }).toList();
        });
      }
    } catch (e) {
      if (mounted && !_salesMembersCancelToken!.isCancelled) {
        // Không hiển thị lỗi nếu request bị cancel
        if (e is DioException && e.type == DioExceptionType.cancel) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi tải danh sách thành viên đội sale')),
        );
      }
    } finally {
      if (mounted && !_salesMembersCancelToken!.isCancelled) {
        setState(() => _isLoadingSalesMembers = false);
      }
    }
  }

  Future<void> _loadTeams() async {
    if (_isLoadingTeams || !mounted) return;
    
    // Hủy bỏ request trước đó nếu có
    _teamsCancelToken?.cancel();
    _teamsCancelToken = CancelToken();
    
    try {
      setState(() => _isLoadingTeams = true);
      
      final response = await _teamRepository.getTeamList(
        widget.organizationId,
        widget.workspaceId,
      );

      if (mounted && !_teamsCancelToken!.isCancelled) {
        final allTeams = (response['content'] as List).map((team) {
          return {
            'id': team['id'],
            'name': team['name'],
            'managers': team['managers'] ?? [],
          };
        }).toList();

        setState(() {
          _teams = _teamSearchText.isEmpty
              ? allTeams
              : allTeams
                  .where((team) => team['name']
                    .toLowerCase()
                    .contains(_teamSearchText.toLowerCase()))
                .toList();
        });
      }
    } catch (e) {
      if (mounted && !_teamsCancelToken!.isCancelled) {
        // Không hiển thị lỗi nếu request bị cancel
        if (e is DioException && e.type == DioExceptionType.cancel) {
          setState(() => _isLoadingTeams = false);
          return;
        }
        setState(() => _isLoadingTeams = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi tải danh sách đội')),
        );
      }
    } finally {
      if (mounted && !_teamsCancelToken!.isCancelled) {
        setState(() => _isLoadingTeams = false);
      }
    }
  }

  Widget _buildSearchBar({
    required TextEditingController controller,
    required String hintText,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          constraints: const BoxConstraints(maxHeight: 40),
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14),
          prefixIconConstraints: const BoxConstraints(maxHeight: 40),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.search, size: 20),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCustomTabButton({
    required bool active,
    required VoidCallback onTap,
    required String text,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSearchBar() {
    final isOrgTab = _memberSubTabController.index == 0;
    final controller = isOrgTab ? _orgMemberSearchController : _salesMemberSearchController;
    final hintText = isOrgTab ? 'Tìm thành viên tổ chức...' : 'Tìm thành viên đội sale...';
    
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (value) {
          if (isOrgTab) {
            setState(() => _orgMemberSearchText = value);
            _orgSearchDebounce?.cancel();
            _orgSearchDebounce = Timer(const Duration(milliseconds: 500), () {
              _loadOrgMembers();
            });
          } else {
            setState(() => _salesMemberSearchText = value);
            _salesSearchDebounce?.cancel();
            _salesSearchDebounce = Timer(const Duration(milliseconds: 500), () {
              _loadSalesMembers();
            });
          }
        },
      ),
    );
  }

  void _handleOrgMemberSelect(Map<String, dynamic> member) {
    setState(() {
      final index = _selectedMembers.indexWhere(
        (selected) {
          final selectedId = selected['profileId'] ?? selected['id'];
          final memberId = member['profileId'] ?? member['id'];
          
          // Nếu có profileId/id thì so sánh, nếu không thì so sánh fullName
          if (selectedId != null && memberId != null) {
            return selectedId == memberId;
          }
          
          // Fallback: so sánh theo fullName
          return selected['fullName'] == member['fullName'];
        },
      );
      
      if (index >= 0) {
        _selectedMembers.removeAt(index);
      } else {
        _selectedMembers.add(member);
      }
    });
  }

  void _handleSalesMemberSelect(Map<String, dynamic> member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CustomAlertDialog(
        title: 'Chuyển phụ trách?',
        subtitle: 'Bạn có chắc muốn phân phối data đến ${member['fullName']}?',
        onSubmit: () async {
          Navigator.pop(dialogContext);
          
                      try {
              _assignCancelToken?.cancel();
              _assignCancelToken = CancelToken();
              
              final assignData = {
                'assignTo': member['profileId'],
                'teamId': member['teamId'],
              };
              
              // Gọi API assign trực tiếp
              await ref.read(customerDetailProvider(widget.customerId).notifier)
                  .assignToCustomer(widget.organizationId, widget.workspaceId, assignData);
              
              // Invalidate customer list để refresh danh sách khách hàng
              ref.invalidate(customerListProvider);
                  
              if (mounted && !_assignCancelToken!.isCancelled) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã chuyển phụ trách thành công cho ${member['fullName']}')),
                );
              }
            } catch (e) {
              if (mounted && !_assignCancelToken!.isCancelled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Có lỗi xảy ra: $e')),
                );
              }
            }
        },
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  void _handleTeamSelect(Map<String, dynamic> team) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CustomAlertDialog(
        title: 'Chuyển phụ trách?',
        subtitle: 'Bạn có chắc muốn phân phối data đến đội sale ${team['name']}?',
        onSubmit: () async {
          Navigator.pop(dialogContext);
          
                      try {
              _assignCancelToken?.cancel();
              _assignCancelToken = CancelToken();
              
              final assignData = {'teamId': team['id']};
              
              // Gọi API assign trực tiếp
              await ref.read(customerDetailProvider(widget.customerId).notifier)
                  .assignToCustomer(widget.organizationId, widget.workspaceId, assignData);
              
              // Invalidate customer list để refresh danh sách khách hàng
              ref.invalidate(customerListProvider);
                  
              if (mounted && !_assignCancelToken!.isCancelled) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã chuyển phụ trách thành công cho đội sale ${team['name']}')),
                );
              }
            } catch (e) {
              if (mounted && !_assignCancelToken!.isCancelled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Có lỗi xảy ra: $e')),
                );
              }
            }
        },
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 32,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Thành công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2329),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Message
              Text(
                'Khách hàng này đã được phân phối thành công cho ${_selectedMembers.length} thành viên',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // OK Button
              SizedBox(
                width: double.infinity,
                                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext); // Đóng success dialog
                      Navigator.pop(context); // Đóng bottomsheet
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMultipleAssign() {
    if (_selectedMembers.isEmpty || _isAssigning) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => CustomAlertDialog(
          title: 'Chuyển phụ trách?',
          subtitle: _selectedMembers.length == 1
              ? 'Bạn có chắc muốn phân phối data đến người này?'
              : 'Bạn có chắc muốn phân phối data đến ${_selectedMembers.length} người này?',
          isLoading: _isAssigning,
          onSubmit: () async {
            setState(() {
              _isAssigning = true;
            });
            
            try {
              _assignCancelToken?.cancel();
              _assignCancelToken = CancelToken();
              
              // Gửi tất cả thành viên được chọn (bao gồm cả default assignees)
              final profileIds = _selectedMembers
                  .map((member) => member['profileId'] ?? member['id'])
                  .where((id) => id != null && id.toString().isNotEmpty)
                  .toList();
              final assignData = {'profileIds': profileIds};
              
              print('Sending assign data: $assignData');
              print('Selected members count: ${_selectedMembers.length}');
              print('ProfileIds being sent: $profileIds');
              
                          // Gọi API assignToCustomerV2 cho tab tổ chức
            await ref.read(customerDetailProvider(widget.customerId).notifier).assignToCustomerV2(
              widget.organizationId,
              widget.workspaceId,
              assignData,
            );
            
            // Invalidate customer list để refresh danh sách khách hàng
            ref.invalidate(customerListProvider);
            
            if (mounted && !_assignCancelToken!.isCancelled) {
              Navigator.pop(dialogContext);
              _showSuccessDialog();
            }
            } catch (e) {
              if (mounted && !_assignCancelToken!.isCancelled) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Có lỗi xảy ra: $e')),
                );
              }
            } finally {
              if (mounted && !_assignCancelToken!.isCancelled) {
                setState(() {
                  _isAssigning = false;
                });
              }
            }
          },
          onCancel: _isAssigning ? null : () => Navigator.pop(dialogContext),
        ),
      ),
    );
  }



  Widget _buildOrgMembersList() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingOrgMembers
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _orgMembers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Không tìm thấy thành viên nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _orgMembers.length,
                      itemBuilder: (context, index) {
                        final member = _orgMembers[index];
                        final isSelected = _selectedMembers.any(
                          (selected) {
                            // Kiểm tra nhiều trường có thể có để so sánh
                            final selectedId = selected['profileId'] ?? selected['id'];
                            final memberId = member['profileId'] ?? member['id'];
                            
                            // Nếu có profileId/id thì so sánh, nếu không thì so sánh fullName
                            if (selectedId != null && memberId != null) {
                              return selectedId == memberId;
                            }
                            
                            // Fallback: so sánh theo fullName
                            return selected['fullName'] == member['fullName'];
                          },
                        );
                        
                        return GestureDetector(
                          onTap: _isAssigning ? null : () => _handleOrgMemberSelect(member),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                              border: isSelected ? Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1,
                              ) : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                AppAvatar(
                                  imageUrl: member['avatar'],
                                  fallbackText: member['fullName'],
                                  size: 44,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member['fullName'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1F2329),
                                        ),
                                      ),
                                      if (member['email'] != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          member['email'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (_selectedMembers.isNotEmpty)
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đã chọn ${_selectedMembers.length} thành viên',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2329),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                      ),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isAssigning ? null : _handleMultipleAssign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isAssigning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Xác nhận'),
                    ),
                  ],
                ),
              ],
                    ),
        ),
      ],
    );
  }

  Widget _buildSalesMembersList() {
    return _isLoadingSalesMembers
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _salesMembers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy thành viên đội sale nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _salesMembers.length,
                itemBuilder: (context, index) {
                  final member = _salesMembers[index];
                  return GestureDetector(
                    onTap: () => _handleSalesMemberSelect(member),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          AppAvatar(
                            imageUrl: member['avatar'],
                            fallbackText: member['fullName'],
                            size: 44,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member['fullName'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2329),
                                  ),
                                ),
                                if (member['teamName'] != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.group, size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        member['teamName'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  );
                },
    );
  }

  Widget _buildTeamsList() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
          controller: _teamSearchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Tìm kiếm đội sale...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
          onChanged: (value) {
                setState(() => _teamSearchText = value);
            _teamSearchDebounce?.cancel();
            _teamSearchDebounce = Timer(const Duration(milliseconds: 500), () {
              _loadTeams();
            });
          },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoadingTeams
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _teams.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Không tìm thấy đội sale nào',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      itemCount: _teams.length,
                      itemBuilder: (context, index) {
                        final team = _teams[index];
                        final managers = team['managers'] as List;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            leading: AppAvatar(
                              fallbackText: team['name'],
                              size: 44,
                            ),
                            title: Text(
                              team['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2329),
                              ),
                            ),
                            subtitle: managers.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Quản lý: ${managers.first['fullName'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  )
                                : null,
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                            onTap: () => _handleTeamSelect(team),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        height: mediaQuery.size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chuyển phụ trách',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2329),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Main tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[100]!, width: 1),
              ),
            ),
            child: TabBar(
              controller: _mainTabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: const Color(0xFF667085),
            indicatorColor: AppColors.primary,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            tabs: const [
              Tab(text: 'Thành viên'),
              Tab(text: 'Đội sale'),
            ],
          ),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                // Members tab with sub-tabs
                Column(
                  children: [
                    const SizedBox(height: 12),
                    // Sub-tab buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildCustomTabButton(
                            active: _memberSubTabController.index == 0,
                            onTap: () {
                              _memberSubTabController.animateTo(0);
                              setState(() {});
                            },
                            text: 'Tổ chức',
                          ),
                          const SizedBox(width: 8),
                          _buildCustomTabButton(
                            active: _memberSubTabController.index == 1,
                            onTap: () {
                              _memberSubTabController.animateTo(1);
                              if (_salesMembers.isEmpty) {
                                _loadSalesMembers();
                              }
                              setState(() {});
                            },
                            text: 'Đội sale',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildCompactSearchBar(),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        controller: _memberSubTabController,
                        children: [
                          _buildOrgMembersList(),
                          _buildSalesMembersList(),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Teams tab
                _buildTeamsList(),
              ],
            ),
          ),
          
          // Bottom padding để tránh bị keyboard che
          if (bottomPadding > 0) SizedBox(height: bottomPadding),
        ],
        ),
      ),
    );
  }
}
