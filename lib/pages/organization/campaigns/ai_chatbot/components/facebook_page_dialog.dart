import 'package:coka/api/api_client.dart';
import 'package:coka/core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';

class FacebookPage {
  final String id;
  final String name;
  final String? avatar;

  FacebookPage({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory FacebookPage.fromJson(Map<String, dynamic> json) {
    return FacebookPage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
    );
  }
}

class FacebookPageDialog extends ConsumerStatefulWidget {
  final String organizationId;
  final List<FacebookPage> selectedPages;
  final Function(List<FacebookPage>) onPagesSelected;

  const FacebookPageDialog({
    super.key,
    required this.organizationId,
    required this.selectedPages,
    required this.onPagesSelected,
  });

  @override
  ConsumerState<FacebookPageDialog> createState() => _FacebookPageDialogState();
}

class _FacebookPageDialogState extends ConsumerState<FacebookPageDialog> {
  List<FacebookPage> _fbPageList = [];
  List<FacebookPage> _selectedPages = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedPages = List.from(widget.selectedPages);
    _loadFacebookPages();
  }

  Future<void> _loadFacebookPages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy token từ secure storage
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');

      if (token == null) {
        setState(() {
          _errorMessage = 'Không tìm thấy token xác thực';
          _isLoading = false;
        });
        return;
      }

      final dio = Dio();
      final response = await dio.get(
        '${ApiClient.baseUrl}/api/v1/integration/omnichannel/getlistpaging',
        queryParameters: {
          'offset': 0,
          'limit': 1000,
          'subscribed': 'messages',
          'provider': 'FACEBOOK',
        },
        options: Options(
          headers: {
            'Accept-Language':
                'vi-VN,vi;q=0.9,en-VN;q=0.8,en;q=0.7,fr-FR;q=0.6,fr;q=0.5,en-US;q=0.4',
            'Authorization': 'Bearer $token',
            'Connection': 'keep-alive',
            'Content-Type': 'application/json',
            'accept': '*/*',
            'organizationId': widget.organizationId,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 0 && data['content'] != null) {
          setState(() {
            _fbPageList =
                (data['content'] as List).map((item) => FacebookPage.fromJson(item)).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Lỗi không xác định';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Lỗi kết nối: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải danh sách trang Facebook: $e';
        _isLoading = false;
      });
      print('Lỗi khi tải danh sách trang Facebook: $e');
    }
  }

  bool _isSelected(FacebookPage page) {
    return _selectedPages.any((element) => element.id == page.id);
  }

  void _toggleSelection(FacebookPage page) {
    setState(() {
      if (_isSelected(page)) {
        _selectedPages.removeWhere((element) => element.id == page.id);
      } else {
        _selectedPages.add(page);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.025, // 2.5% padding mỗi bên = 95% width
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    '${AppConstants.imagePath}/fb_messenger_icon.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Chọn trang Facebook',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(8),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            _isLoading
                ? Expanded(child: _buildLoadingSkeleton())
                : _errorMessage.isNotEmpty
                    ? Expanded(child: _buildErrorState())
                    : Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: _buildPageList(),
                        ),
                      ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    widget.onPagesSelected(_selectedPages);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              title: Container(
                width: double.infinity,
                height: 14,
                color: Colors.white,
              ),
              trailing: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Đã xảy ra lỗi',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFacebookPages,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageList() {
    if (_fbPageList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.facebook, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Không có trang Facebook nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _fbPageList.length,
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemBuilder: (context, index) {
        final page = _fbPageList[index];
        final isSelected = _isSelected(page);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.blue.shade200 : Colors.grey.shade200,
            ),
            color: isSelected ? Colors.blue.shade50 : Colors.white,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: page.avatar != null ? NetworkImage(page.avatar!) : null,
              child: page.avatar == null
                  ? Text(
                      page.name.isNotEmpty ? page.name[0] : '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            title: Text(
              page.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Checkbox(
              value: isSelected,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (value) => _toggleSelection(page),
            ),
            onTap: () => _toggleSelection(page),
          ),
        );
      },
    );
  }
}
