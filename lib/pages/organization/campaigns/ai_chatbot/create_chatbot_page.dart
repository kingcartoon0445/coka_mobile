import 'package:coka/core/constants/app_constants.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/pages/organization/campaigns/ai_chatbot/components/facebook_page_dialog.dart';
import 'package:coka/pages/organization/campaigns/ai_chatbot/components/zalo_page_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coka/api/repositories/chatbot_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/core/utils/helpers.dart';

class CreateChatbotPage extends ConsumerStatefulWidget {
  final String organizationId;

  const CreateChatbotPage({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<CreateChatbotPage> createState() => _CreateChatbotPageState();
}

class _CreateChatbotPageState extends ConsumerState<CreateChatbotPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  
  List<FacebookPage> _selectedFacebookPages = [];
  List<ZaloPage> _selectedZaloPages = [];
  int _replyType = 2; // 1: Chỉ lần đầu, 2: Luôn luôn
  String _chatbotType = 'AI'; // 'AI' hoặc 'QA'
  bool _isLoading = false;
  late final ChatbotRepository _chatbotRepository;

  @override
  void initState() {
    super.initState();
    _chatbotRepository = ChatbotRepository(ApiClient());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
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

  Future<void> _createChatbot() async {
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
      _isLoading = true;
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
      
      final response = await _chatbotRepository.createChatbot(widget.organizationId, data);

      if (Helpers.isResponseSuccess(response)) {
        // Tạo thành công
        final message = response['message'] ?? 'Tạo chatbot thành công';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        // Quay lại trang danh sách và báo hiệu cần reload
        if (!mounted) return;
        context.pop(true); // Trả về true để báo hiệu đã tạo thành công
      } else {
        // Có lỗi từ server
        final message = response['message'] ?? 'Có lỗi xảy ra, xin vui lòng thử lại';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo chatbot: $e')),
      );
      print('Lỗi khi tạo chatbot: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tạo AI Chatbot mới'),
        elevation: 0,
      ),
      body: _isLoading
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
                        onPressed: _createChatbot,
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
} 