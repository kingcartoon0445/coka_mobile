import 'package:flutter/material.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/api/repositories/auth_repository.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/core/theme/text_styles.dart';
import 'package:coka/pages/auth/complete_profile_page.dart';
import 'package:coka/pages/organization/invitation_page.dart';
import 'package:coka/pages/organization/join_organization_page.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';
import 'package:coka/shared/widgets/awesome_alert.dart';
import 'package:coka/shared/widgets/loading_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/utils/helpers.dart';
class SettingsPage extends StatefulWidget {
  final String? organizationId;
  final String? userRole;
  
  const SettingsPage({
    super.key,
    this.organizationId,
    this.userRole,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String _appVersion = '';
  String _buildNumber = '';
  final _authRepository = AuthRepository(ApiClient());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.wait([
      _loadUserInfo(),
      _loadAppVersion(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserInfo() async {
    try {
      final response = await _authRepository.getUserInfo();
      if (Helpers.isResponseSuccess(response)) {
        setState(() {
          _userInfo = response['content'];
        });
      }
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      print('Lỗi khi tải thông tin ứng dụng: $e');
    }
  }

  bool get isAdminOrOwner {
    final userRole = widget.userRole?.toUpperCase() ?? '';
    return userRole == 'ADMIN' || userRole == 'OWNER';
  }

  void _handleLogout(BuildContext context) async {
    showAwesomeAlert(
      context: context,
      title: 'Đăng xuất',
      description: 'Bạn có chắc muốn đăng xuất khỏi tài khoản?',
      confirmText: 'Đăng xuất',
      cancelText: 'Hủy',
      icon: Icons.logout,
      isWarning: true,
      onConfirm: () async {
        try {
          // Thực hiện đăng xuất
          await ApiClient.storage.deleteAll();
          if (context.mounted) {
            context.go('/auth/login');
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng xuất không thành công')),
            );
          }
        }
      },
    );
  }

  void _handleDeleteAccount(BuildContext context) {
    showAwesomeAlert(
      context: context,
      title: 'Xóa tài khoản',
      description: 'Thao tác này sẽ xóa tài khoản khỏi hệ thống. Bạn có chắc muốn xóa tài khoản?',
      confirmText: 'Xác nhận xóa',
      cancelText: 'Hủy',
      icon: Icons.delete_forever,
      isWarning: true,
      iconColor: Colors.red.shade100,
      onConfirm: () async {
        try {
          // TODO: Gọi API xóa tài khoản
          await ApiClient.storage.deleteAll();
          if (context.mounted) {
            context.go('/auth/login');
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Xóa tài khoản không thành công')),
            );
          }
        }
      },
    );
  }

  Widget _buildUserProfile() {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CompleteProfilePage(),
        ));
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            AppAvatar(
              size: 44,
              shape: AvatarShape.circle,
              imageUrl: _userInfo?['avatar'],
              fallbackText: _userInfo?['fullName'],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userInfo?['fullName'] ?? '',
                  style: TextStyles.heading3,
                ),
                const Text(
                  'Xem profile của bạn',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    decoration: TextDecoration.underline,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
    bool showArrow = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            decoration: const BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(4),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor ?? Colors.black,
                  ),
                ),
                const Spacer(),
                if (showArrow)
                  const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
        if (showArrow)
          const Divider(height: 1, color: Colors.transparent),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    final List<List<Map<String, dynamic>>> settingItems = [
      // Tổ chức
      [
        {
          'title': 'Tạo tổ chức',
          'icon': Icons.add,
          'onTap': () {
            context.push('/organization/create');
          },
        },
        {
          'title': 'Tham gia tổ chức',
          'icon': Icons.group_add_outlined,
          'onTap': () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const JoinOrganizationPage(),
            ));
          },
        },
        {
          'title': 'Lời mời',
          'icon': Icons.person_add_outlined,
          'onTap': () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const InvitationPage(),
            ));
          },
        },
      ],
      // Tài khoản & Thông tin
      [
        {
          'title': 'Giới thiệu về Coka',
          'icon': Icons.info_outline,
          'onTap': () {
            // TODO: Navigate to info
          },
        },
        {
          'title': 'Chỉnh sửa tài khoản',
          'icon': Icons.settings_outlined,
          'onTap': () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const CompleteProfilePage(),
            ));
          },
        },
        if (isAdminOrOwner)
          {
            'title': 'Nâng cấp tài khoản',
            'icon': Icons.workspace_premium_outlined,
            'onTap': () {
              // TODO: Navigate to upgrade account
            },
          },
      ],
      // Đăng xuất & Xóa tài khoản
      [
        {
          'title': 'Đăng xuất',
          'icon': Icons.logout,
          'onTap': () => _handleLogout(context),
          'showArrow': false,
        },
        {
          'title': 'Xóa tài khoản',
          'icon': Icons.delete_outline,
          'onTap': () => _handleDeleteAccount(context),
          'textColor': Colors.red,
          'showArrow': false,
        },
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8FD),
        title: const Text(
          "Cài đặt",
          style: TextStyle(
            color: Color(0xFF1F2329),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildUserProfile(),
            const SizedBox(height: 20),
            ...settingItems.map((section) {
              return Column(
                children: [
                  ...section.map((item) {
                    return _buildSettingItem(
                      title: item['title'],
                      icon: item['icon'],
                      onTap: item['onTap'],
                      textColor: item['textColor'],
                      showArrow: item['showArrow'] ?? true,
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              );
            }),
            Center(
              child: Text(
                "v$_appVersion($_buildNumber)",
                style: const TextStyle(
                  color: Color(0xFF646A72),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
} 