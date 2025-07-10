import 'package:coka/core/constants/app_constants.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/pages/organization/campaigns/ai_chatbot/components/facebook_page_dialog.dart';
import 'package:coka/pages/organization/campaigns/ai_chatbot/components/zalo_page_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:coka/api/repositories/chatbot_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/core/utils/helpers.dart';

class EditChatbotPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String chatbotId;

  const EditChatbotPage({
    super.key,
    required this.organizationId,
    required this.chatbotId,
  });

  @override
  ConsumerState<EditChatbotPage> createState() => _EditChatbotPageState();
}

class _EditChatbotPageState extends ConsumerState<EditChatbotPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  
  List<FacebookPage> _selectedFacebookPages = [];
  List<ZaloPage> _selectedZaloPages = [];
  int _replyType = 2; // 1: Chỉ lần đầu, 2: Luôn luôn
  String _chatbotType = 'AI'; // 'AI' hoặc 'QA'
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';
  late final ChatbotRepository _chatbotRepository;

  @override
  void initState() {
    super.initState();
    _chatbotRepository = ChatbotRepository(ApiClient());
    _loadChatbotDetails();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadChatbotDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Thay thế việc gọi API getChatbotDetail bằng việc lấy từ danh sách chatbot
      final response = await _chatbotRepository.getChatbotList(widget.organizationId);

      if (Helpers.isResponseSuccess(response) && response['content'] != null) {
        final chatbotList = response['content'] as List;
        // Tìm chatbot theo id trong danh sách
        final chatbotData = chatbotList.firstWhere(
          (item) => item['id'] == widget.chatbotId,
          orElse: () => {},
        );
        
        if (chatbotData != null && chatbotData['id'] != null) {
          // Cập nhật state với dữ liệu chatbot
          setState(() {
            _titleController.text = chatbotData['title'] ?? '';
            _promptController.text = chatbotData['promptSystem'] ?? '';
            _replyType = chatbotData['response'] ?? 2;
            _chatbotType = chatbotData['typeResponse'] ?? 'AI';
            
            // Xử lý danh sách kênh kết nối
            if (chatbotData['subscribed'] != null) {
              final subscribedList = chatbotData['subscribed'] as List;
              
              // Tách danh sách kênh thành Facebook và Zalo
              _selectedFacebookPages = subscribedList
                  .where((item) => item['provider'] == 'FACEBOOK')
                  .map((item) => FacebookPage(
                        id: item['id'] ?? '',
                        name: item['name'] ?? '',
                        avatar: item['avatar'],
                      ))
                  .toList();
                  
              _selectedZaloPages = subscribedList
                  .where((item) => item['provider'] == 'ZALO')
                  .map((item) => ZaloPage(
                        id: item['id'] ?? '',
                        name: item['name'] ?? '',
                        avatar: item['avatar'],
                      ))
                  .toList();
            }
            
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Không tìm thấy thông tin chatbot';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Lỗi không xác định';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải thông tin chatbot: $e';
        _isLoading = false;
      });
      print('Lỗi khi tải thông tin chatbot: $e');
    }
  }

  void _showFacebookPagesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FacebookPageDialog(
          organizationId: widget.organizationId,
          selectedPages: _selectedFacebookPages,
          onPagesSelected: (pages) {
            setState(() {
              _selectedFacebookPages = pages;
            });
          },
        );
      },
    );
  }

  void _showZaloPagesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ZaloPageDialog(
          organizationId: widget.organizationId,
          selectedPages: _selectedZaloPages,
          onPagesSelected: (pages) {
            setState(() {
              _selectedZaloPages = pages;
            });
          },
        );
      },
    );
  }

  void _removeFacebookPage(FacebookPage page) {
    setState(() {
      _selectedFacebookPages.removeWhere((p) => p.id == page.id);
    });
  }

  void _removeZaloPage(ZaloPage page) {
    setState(() {
      _selectedZaloPages.removeWhere((p) => p.id == page.id);
    });
  }

  Future<void> _updateChatbot() async {
    // Kiểm tra dữ liệu đầu vào
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên kịch bản')),
      );
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập prompt')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Tạo danh sách ID kênh kết nối
      final subscribedIds = [
        ..._selectedFacebookPages.map((p) => p.id),
        ..._selectedZaloPages.map((p) => p.id),
      ];
      
      final data = {
        'subscribedIds': subscribedIds,
        'title': _titleController.text.trim(),
        'description': '',
        'promptSystem': _promptController.text.trim(),
        'promptUser': '',
        'response': _replyType,
        'typeResponse': _chatbotType,
      };
      
      final response = await _chatbotRepository.updateChatbot(
        widget.organizationId,
        widget.chatbotId,
        data
      );

      if (Helpers.isResponseSuccess(response)) {
        // Cập nhật thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật chatbot thành công')),
        );
        // Quay lại trang danh sách
        if (!mounted) return;
        context.pop();
      } else {
        // Có lỗi từ server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Lỗi không xác định')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật chatbot: $e')),
      );
      print('Lỗi khi cập nhật chatbot: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chỉnh sửa AI Chatbot'),
        elevation: 0,
      ),
      body: _isLoading 
          ? _buildLoadingSkeleton()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tên kịch bản
                          const Text(
                            'Tên kịch bản',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên kịch bản',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Chọn kênh kết nối
                          const Text(
                            'Chọn kênh kết nối',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Facebook Messenger
                          InkWell(
                            onTap: _showFacebookPagesDialog,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        '${AppConstants.imagePath}/fb_messenger_icon.png',
                                        width: 32,
                                        height: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Facebook Messenger',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                                  if (_selectedFacebookPages.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _selectedFacebookPages.map((page) {
                                        return Chip(
                                          label: Text(page.name),
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                          onDeleted: () => _removeFacebookPage(page),
                                          backgroundColor: Colors.grey[200],
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Zalo OA
                          InkWell(
                            onTap: _showZaloPagesDialog,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        '${AppConstants.imagePath}/zalo_icon.png',
                                        width: 32,
                                        height: 32,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Zalo OA',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.arrow_forward_ios, size: 16),
                                    ],
                                  ),
                                  if (_selectedZaloPages.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _selectedZaloPages.map((page) {
                                        return Chip(
                                          label: Text(page.name),
                                          deleteIcon: const Icon(Icons.close, size: 16),
                                          onDeleted: () => _removeZaloPage(page),
                                          backgroundColor: Colors.grey[200],
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Số lần phản hồi
                          const Text(
                            'Số lần phản hồi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Radio<int>(
                                value: 2,
                                groupValue: _replyType,
                                onChanged: (value) {
                                  setState(() {
                                    _replyType = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const Text('Luôn luôn'),
                              const SizedBox(width: 16),
                              Radio<int>(
                                value: 1,
                                groupValue: _replyType,
                                onChanged: (value) {
                                  setState(() {
                                    _replyType = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const Text('Chỉ lần đầu'),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Loại chatbot
                          const Text(
                            'Loại chatbot',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'AI',
                                groupValue: _chatbotType,
                                onChanged: (value) {
                                  setState(() {
                                    _chatbotType = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const Text('AI'),
                              const SizedBox(width: 16),
                              Radio<String>(
                                value: 'QA',
                                groupValue: _chatbotType,
                                onChanged: (value) {
                                  setState(() {
                                    _chatbotType = value!;
                                  });
                                },
                                activeColor: AppColors.primary,
                              ),
                              const Text('Q & A'),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Nhập prompt
                          const Text(
                            'Nhập prompt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _promptController,
                            maxLines: 8,
                            decoration: InputDecoration(
                              hintText: 'Hãy trở thành chuyên gia tư vấn trong lĩnh vực bất động sản về dự án...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.primary),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Nút lưu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => context.pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  side: BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Hủy'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _updateChatbot,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Lưu'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 100,
              height: 16,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 150,
              height: 16,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
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
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Đã xảy ra lỗi',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadChatbotDetails,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}