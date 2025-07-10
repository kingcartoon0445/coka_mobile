import 'package:coka/core/constants/app_constants.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/providers/organization_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:coka/api/repositories/chatbot_repository.dart';
import 'package:coka/api/api_client.dart';

class ChatbotModel {
  final String id;
  final String title;
  final String description;
  final String promptSystem;
  final String promptUser;
  final int response; // 1 - Chỉ lần đầu, 2 - Luôn luôn
  final String typeResponse; // "AI" hoặc "QA"
  final int status; // 1 - Hoạt động, 0 - Không hoạt động
  final List<SubscribedModel>? subscribed;

  ChatbotModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.promptSystem,
    this.promptUser = '',
    required this.response,
    required this.typeResponse,
    required this.status,
    this.subscribed,
  });

  factory ChatbotModel.fromJson(Map<String, dynamic> json) {
    return ChatbotModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      promptSystem: json['promptSystem'] ?? '',
      promptUser: json['promptUser'] ?? '',
      response: json['response'] ?? 2,
      typeResponse: json['typeResponse'] ?? 'AI',
      status: json['status'] ?? 0,
      subscribed: json['subscribed'] != null
          ? (json['subscribed'] as List)
              .map((e) => SubscribedModel.fromJson(e))
              .toList()
          : null,
    );
  }
}

class SubscribedModel {
  final String id;
  final String name;
  final String? avatar;
  final String provider; // "FACEBOOK" hoặc "ZALO"

  SubscribedModel({
    required this.id,
    required this.name,
    this.avatar,
    required this.provider,
  });

  factory SubscribedModel.fromJson(Map<String, dynamic> json) {
    return SubscribedModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      provider: json['provider'] ?? '',
    );
  }
}

class AIChatbotPage extends ConsumerStatefulWidget {
  final String organizationId;

  const AIChatbotPage({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<AIChatbotPage> createState() => _AIChatbotPageState();
}

class _AIChatbotPageState extends ConsumerState<AIChatbotPage> {
  bool _isLoading = true;
  List<ChatbotModel> _chatbotList = [];
  String _errorMessage = '';
  late final ChatbotRepository _chatbotRepository;

  @override
  void initState() {
    super.initState();
    _chatbotRepository = ChatbotRepository(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tải thông tin tổ chức thông qua provider
      ref.read(currentOrganizationProvider.notifier).loadOrganization(widget.organizationId);
      
      // Tải danh sách chatbot
      await _loadChatbots();
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

  Future<void> _loadChatbots() async {
    try {
      final response = await _chatbotRepository.getChatbotList(widget.organizationId);
      
      if ((response['code'] == 0 || response['code'] == 200) && response['content'] != null) {
        setState(() {
          _chatbotList = (response['content'] as List)
              .map((item) => ChatbotModel.fromJson(item))
              .toList();
          _errorMessage = ''; // Clear error message khi load thành công
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Lỗi không xác định';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải danh sách chatbot: $e';
      });
      print('Lỗi khi tải danh sách chatbot: $e');
    }
  }

  Future<void> _updateChatbotStatus(String chatbotId, bool status) async {
    try {
      final response = await _chatbotRepository.updateChatbotStatus(
        widget.organizationId,
        chatbotId,
        status ? 1 : 0,
      );

      if (response['code'] != 0 && response['code'] != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Lỗi không xác định')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
      );
      print('Lỗi khi cập nhật trạng thái chatbot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Đọc thông tin tổ chức từ provider
    final organizationState = ref.watch(currentOrganizationProvider);
    final isAdminOrOwner = ref.watch(isAdminOrOwnerProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AI Chatbot'),
        elevation: 0,
      ),
      body: _isLoading || organizationState is AsyncLoading
          ? _buildLoadingSkeleton()
          : _buildBody(isAdminOrOwner),
      floatingActionButton: isAdminOrOwner ? FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/organization/${widget.organizationId}/campaigns/ai-chatbot/create');
          // Nếu tạo chatbot thành công, reload danh sách
          if (result == true) {
            _loadChatbots();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 80,
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

  Widget _buildBody(bool isAdminOrOwner) {
    if (_errorMessage.isNotEmpty) {
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
                _errorMessage,
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
      );
    }

    if (_chatbotList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              '${AppConstants.imagePath}/empty_state.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có chatbot nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo chatbot mới để bắt đầu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: _chatbotList.length,
        itemBuilder: (context, index) {
          final chatbot = _chatbotList[index];
          return _buildChatbotItem(chatbot);
        },
      ),
    );
  }

  Widget _buildChatbotItem(ChatbotModel chatbot) {
    return InkWell(
      onTap: () {
        context.push('/organization/${widget.organizationId}/campaigns/ai-chatbot/edit/${chatbot.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Icon AI Chatbot
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE3DFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Image.asset(
                  '${AppConstants.imagePath}/campaign_icon_1.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Thông tin chatbot
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatbot.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Loại: ${chatbot.typeResponse}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Switch trạng thái
            Switch(
              value: chatbot.status == 1,
              activeColor: AppColors.primary,
              onChanged: (value) {
                // Update chatbot tại đây trước khi gọi API
                setState(() {
                  // Tìm chatbot trong danh sách và cập nhật trạng thái
                  final index = _chatbotList.indexWhere((c) => c.id == chatbot.id);
                  if (index != -1) {
                    _chatbotList[index] = ChatbotModel(
                      id: chatbot.id,
                      title: chatbot.title,
                      description: chatbot.description,
                      promptSystem: chatbot.promptSystem,
                      promptUser: chatbot.promptUser,
                      response: chatbot.response,
                      typeResponse: chatbot.typeResponse,
                      status: value ? 1 : 0,
                      subscribed: chatbot.subscribed,
                    );
                  }
                });
                
                // Gọi API cập nhật trạng thái
                _updateChatbotStatus(chatbot.id, value);
              },
            ),
          ],
        ),
      ),
    );
  }
} 