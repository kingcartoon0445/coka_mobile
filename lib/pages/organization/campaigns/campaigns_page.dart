import 'package:coka/core/constants/app_constants.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:coka/api/repositories/auth_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/models/campaign.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/providers/organization_provider.dart';
import 'package:coka/providers/campaign_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:coka/shared/widgets/custom_alert_dialog.dart';
import 'package:coka/core/utils/helpers.dart';
class CampaignsPage extends ConsumerStatefulWidget {
  final String organizationId;

  const CampaignsPage({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends ConsumerState<CampaignsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _userInfo;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadUserInfo();
      
      // Tải thông tin tổ chức thông qua provider
      ref.read(currentOrganizationProvider.notifier).loadOrganization(widget.organizationId);
      
      // Tải danh sách tổ chức (nếu cần)
      ref.read(organizationsListProvider.notifier).loadOrganizations();
      
      // Tải danh sách chiến dịch
      await _loadCampaigns();
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải dữ liệu: $e';
      });
      print('Lỗi khi tải dữ liệu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCampaigns() async {
    try {
      await ref.read(campaignsProvider.notifier).loadCampaignsPaging(
        widget.organizationId,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải danh sách chiến dịch: $e';
      });
      print('Lỗi khi tải danh sách chiến dịch: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final authRepository = AuthRepository(ApiClient());
      final response = await authRepository.getUserInfo();
      if (Helpers.isResponseSuccess(response)) {
        setState(() {
          _userInfo = response['content'];
        });
      }
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.blue;
      case 'OWNER':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayText(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Quản trị viên';
      case 'OWNER':
        return 'Chủ tổ chức';
      default:
        return 'Thành viên';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đọc thông tin tổ chức, vai trò và quyền từ provider
    final organizationState = ref.watch(currentOrganizationProvider);
    final isAdminOrOwner = ref.watch(isAdminOrOwnerProvider);
    final userRole = ref.watch(userRoleProvider);
    final campaignsState = ref.watch(campaignsProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isLoading || organizationState is AsyncLoading
        ? null  // Không hiển thị appbar khi đang loading
        : isAdminOrOwner
          ? null  // Admin/Owner không cần AppBar
          : AppBar(
              title: const Text('Chiến dịch đang chạy'),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _showAddCampaignDialog();
                  },
                ),
              ],
            ),
      body: _isLoading || organizationState is AsyncLoading
          ? _buildLoadingSkeleton()
          : _buildBody(isAdminOrOwner, userRole, campaignsState),
    );
  }
  
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton cho loading state
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 20,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isAdminOrOwner, String userRole, AsyncValue<List<Campaign>> campaignsState) {
    if (isAdminOrOwner) {
      return _buildAdminView(userRole);
    } else {
      return _buildMemberView(userRole, campaignsState);
    }
  }

  Widget _buildAdminView(String userRole) {
    // Màu nền tròn cho icon
    final Color iconBgColor = Color(0xFFF5F2FF);
    
    // Danh sách các tính năng grid
    final List<Map<String, dynamic>> features = [
      {
        'title': 'Kết nối đa nguồn',
        'icon': '${AppConstants.imagePath}/campaign_icon_0.png',
        'onTap': () {
          // Sử dụng GoRouter để điều hướng, hỗ trợ deeplink sau này
          context.push('/organization/${widget.organizationId}/campaigns/multi-source-connection');
        },
      },
      {
        'title': 'AI Chatbot',
        'icon': '${AppConstants.imagePath}/campaign_icon_1.png',
        'onTap': () {
          context.push('/organization/${widget.organizationId}/campaigns/ai-chatbot');
        },
      },
      {
        'title': 'Làm giàu dữ liệu',
        'icon': '${AppConstants.imagePath}/campaign_icon_2.png',
        'onTap': () {
          context.push('/organization/${widget.organizationId}/campaigns/fill-data');
        },
      },
      {
        'title': 'Automation',
        'icon': '${AppConstants.imagePath}/campaign_icon_3.png',
        'onTap': () {
          context.push('/organization/${widget.organizationId}/campaigns/automation');
        },
      },
      {
        'title': 'Tổng đài',
        'icon': '${AppConstants.imagePath}/campaign_icon_4.png',
        'onTap': () => _showFeatureComingSoonDialog('Tổng đài'),
      },
      {
        'title': 'Gọi hàng loạt',
        'icon': '${AppConstants.imagePath}/campaign_icon_5.png',
        'onTap': () => _showFeatureComingSoonDialog('Gọi hàng loạt'),
      },
    ];

    return Column(
      children: [
        const SizedBox(height: 4),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return InkWell(
                onTap: feature['onTap'],
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            feature['icon'],
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feature['title'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberView(String userRole, AsyncValue<List<Campaign>> campaignsState) {
    return campaignsState.when(
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Đang tải danh sách chiến dịch...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Đã xảy ra lỗi',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Bạn không có chiến dịch nào được phân công',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hàng 1: Icon, tiêu đề và nút gọi
                      Row(
                        children: [
                          Image.asset(
                            '${AppConstants.imagePath}/call_campaign_icon.png',
                            width: 28,
                            height: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              campaign.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Xử lý khi nhấn nút gọi ngay
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary, // Màu tím đậm (Deep Purple)
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: const Size(70, 30), // Giảm kích thước tối thiểu
                              textStyle: const TextStyle(fontSize: 13),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_outlined, size: 14),
                                SizedBox(width: 4),
                                Text('Gọi ngay'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Hàng 2: Icon sim và số sim
                      Row(
                        children: [
                          Image.asset(
                            '${AppConstants.imagePath}/sim_card_icon.png',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            campaign.telephoneNumber != null ? 'Đầu số ${campaign.telephoneNumber}' : 'Mặc định',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showFeatureComingSoonDialog(String featureName) {
    showInfoAlert(
      context: context,
      title: '$featureName đang phát triển',
      message: 'Tính năng này đang được phát triển trên ứng dụng di động.\n'
          'Vui lòng truy cập bản website tại app.coka.ai để sử dụng tính năng này.',
    );
  }

  void _showAddCampaignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo chiến dịch mới'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Tên chiến dịch',
                hintText: 'Nhập tên chiến dịch',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Mô tả chi tiết về chiến dịch',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // Chưa xử lý thêm chiến dịch thực tế
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng này sẽ được triển khai sau')),
              );
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}
