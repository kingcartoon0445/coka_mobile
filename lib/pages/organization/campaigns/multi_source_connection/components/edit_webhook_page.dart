import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/models/lead/connection_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/providers.dart';
import 'package:coka/api/repositories/workspace_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coka/core/utils/helpers.dart';
// Lớp quản lý dữ liệu workspace
class WorkspaceProvider {
  final WorkspaceRepository _repository;
  List<Map<String, dynamic>> workspaces = [];

  WorkspaceProvider({required WorkspaceRepository repository}) : _repository = repository;

  Future<void> loadWorkspaces(String organizationId) async {
    final response = await _repository.getWorkspaces(organizationId);
    if (Helpers.isResponseSuccess(response) && response['content'] != null) {
      final List<dynamic> data = response['content'];
      workspaces = data.map((item) => {
        'id': item['id'],
        'name': item['name'],
      }).toList().cast<Map<String, dynamic>>();
    }
  }
}

// Phương thức tiện ích để xử lý dữ liệu webhook
class WebhookUtils {
  // Chuyển đổi dữ liệu webhook từ API để sử dụng trong ConnectionModel
  static ConnectionModel fromApiResponse(Map<String, dynamic> data) {
    // Chuẩn bị additionalData
    final Map<String, dynamic> additionalData = {
      'source': data['source'],
      'expiryDate': data['expiryDate'],
      'url': data['url'], // Thêm URL vào additionalData để đảm bảo luôn có
    };
    
    // Tạo ConnectionModel từ dữ liệu API
    return ConnectionModel(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Webhook',
      connectionType: 'webhook',
      status: data['status'] ?? 0,
      connectionState: data['connectionState'] ?? 'Đã kết nối',
      organizationId: data['organizationId'] ?? '',
      workspaceId: data['workspaceId'] ?? '',
      workspaceName: data['workspaceName'] ?? 'Không có workspace',
      provider: data['source'] ?? 'FBS',
      url: data['url'],
      additionalData: additionalData,
    );
  }
}

class EditWebhookPage extends ConsumerStatefulWidget {
  final ConnectionModel data;

  const EditWebhookPage({
    super.key,
    required this.data,
  });

  @override
  ConsumerState<EditWebhookPage> createState() => _EditWebhookPageState();
}

class _EditWebhookPageState extends ConsumerState<EditWebhookPage> {
  bool isLoading = false;
  String? selectedService;
  DateTime? expiryDate;
  String? selectedWorkspaceId;
  List<Map<String, dynamic>> workspaceList = [];
  late final WorkspaceProvider _workspaceProvider;

  @override
  void initState() {
    super.initState();
    _workspaceProvider = WorkspaceProvider(repository: WorkspaceRepository(ApiClient()));
    _initData();
    _loadWorkspaces();
  }

  void _initData() {
    // Lấy thông tin trực tiếp từ model ConnectionModel
    setState(() {
      // 1. Lấy workspaceId từ model
      selectedWorkspaceId = widget.data.workspaceId;
      
      // 2. Khởi tạo mặc định dịch vụ là FBS nếu chưa có
      selectedService = 'FBS';
      
      // 3. Ưu tiên lấy source từ thuộc tính cụ thể
      if (widget.data.provider != null && widget.data.provider!.isNotEmpty) {
        selectedService = widget.data.provider!;
      }
      
      // 4. Kiểm tra thông tin trong additionalData với mức độ ưu tiên cao hơn
      if (widget.data.additionalData != null) {
        // Lấy source từ additionalData (nếu có)
        if (widget.data.additionalData!.containsKey('source') && 
            widget.data.additionalData!['source'] != null && 
            widget.data.additionalData!['source'].toString().isNotEmpty) {
          selectedService = widget.data.additionalData!['source'];
        }
        
        // Lấy ngày hết hạn từ additionalData (nếu có)
        if (widget.data.additionalData!.containsKey('expiryDate') && 
            widget.data.additionalData!['expiryDate'] != null && 
            widget.data.additionalData!['expiryDate'].toString().isNotEmpty) {
          try {
            expiryDate = DateTime.parse(widget.data.additionalData!['expiryDate']);
          } catch (e) {
            print('Lỗi parse ngày hết hạn từ additionalData: $e');
          }
        }
      }
      
      // 5. Mặc định ngày hết hạn là 30 ngày tới nếu chưa có
      expiryDate ??= DateTime.now().add(const Duration(days: 30));
      
      // Debug thông tin
      print('======= WEBHOOK DATA =======');
      print('Webhook ID: ${widget.data.id}');
      print('Source: $selectedService');
      print('ExpiryDate: $expiryDate');
      print('workspaceId: $selectedWorkspaceId');
      
      // Sử dụng phương thức _getWebhookUrl để lấy URL từ các nguồn khác nhau
      final webhookUrl = _getWebhookUrl();
      print('URL: $webhookUrl');
      
      if (widget.data.additionalData != null) {
        print('additionalData: ${widget.data.additionalData}');
      }
      print('===========================');
    });
  }

  Future<void> _loadWorkspaces() async {
    try {
      await _workspaceProvider.loadWorkspaces(widget.data.organizationId);
      setState(() {
        workspaceList = _workspaceProvider.workspaces;
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách workspace: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateWebhook() async {
    if (selectedService == null || selectedService!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn dịch vụ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày hết hạn'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedWorkspaceId == null || selectedWorkspaceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn không gian làm việc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final leadRepository = ref.read(leadRepositoryProvider);
      
      // Tạo dữ liệu webhook để cập nhật
      final Map<String, dynamic> data = {
        'title': 'Webhook $selectedService',  // Tên webhook hiển thị với dịch vụ
        'workspaceId': selectedWorkspaceId,
        'source': selectedService,
        'expiryDate': expiryDate?.toUtc().toIso8601String(), // Đảm bảo định dạng ISO8601 UTC
      };
      
      print('Cập nhật webhook với dữ liệu: $data');
      
      final response = await leadRepository.webhookUpdate(
        widget.data.organizationId, 
        widget.data.id, 
        data,
      );

      if (context.mounted) {
        if (Helpers.isResponseSuccess(response)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật webhook thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Trả về true để reload data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Lỗi cập nhật webhook'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép URL vào bộ nhớ đệm'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != expiryDate) {
      setState(() {
        expiryDate = picked;
      });
    }
  }

  void _launchFBSWebsite() async {
    final Uri url = Uri.parse('https://fbs.ai');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở trang web'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Phương thức để lấy URL webhook từ các nguồn khác nhau
  String? _getWebhookUrl() {
    // Kiểm tra trong additionalData (ưu tiên cao nhất)
    if (widget.data.additionalData != null && 
        widget.data.additionalData!.containsKey('url') && 
        widget.data.additionalData!['url'] != null &&
        widget.data.additionalData!['url'].toString().isNotEmpty) {
      return widget.data.additionalData!['url'];
    }
    
    // Kiểm tra nguồn dữ liệu chính
    if (widget.data.url != null && widget.data.url!.isNotEmpty) {
      return widget.data.url;
    }
    
    // Trả về null nếu không tìm thấy
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        title: const Text(
          'Chỉnh sửa cấu hình Webhook',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workspace selection
            const Text(
              'Không gian làm việc*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedWorkspaceId,
                  hint: const Text('Chọn không gian làm việc'),
                  isExpanded: true,
                  items: workspaceList.map((workspace) {
                    return DropdownMenuItem<String>(
                      value: workspace['id'] as String,
                      child: Text(workspace['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedWorkspaceId = value;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Service selection
            const Text(
              'Dịch vụ*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedService,
                  hint: const Text('Chọn dịch vụ'),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'FBS',
                      child: Text('FBS'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'OTHER',
                      child: Text('Khác'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedService = value;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Expiry date selection
            const Text(
              'Ngày hết hạn*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      expiryDate != null
                          ? DateFormat('dd/MM/yyyy', 'vi_VN').format(expiryDate!)
                          : 'Chọn ngày hết hạn',
                      style: TextStyle(
                        color: expiryDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Webhook URL display and copy button
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Webhook Url',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getWebhookUrl() ?? 'Bạn sẽ nhận được URL sau khi lưu',
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_getWebhookUrl() != null && _getWebhookUrl()!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _copyToClipboard(_getWebhookUrl()!),
                          icon: const Icon(Icons.copy, size: 14, color: AppColors.primary),
                          label: const Text(
                            'Sao chép',
                            style: TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Usage instructions
                const Text(
                  'Sử dụng Webhook Coka trên FBS:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _buildInstructionItem(
                  'Truy cập vào địa chỉ ',
                  isLink: true,
                  linkText: 'FBS.AI',
                  onLinkTap: _launchFBSWebsite,
                ),
                _buildInstructionItem('Bạn cần đăng nhập và chọn mua gói dịch vụ phù hợp với nhu cầu.'),
                _buildInstructionItem(
                  'Chọn ',
                  boldText: '"Quản lý thành viên nhóm"',
                ),
                _buildInstructionItem(
                  'Nhấn vào mục ',
                  boldText: '"Webhook"',
                ),
                _buildInstructionItem(
                  'Dán ',
                  boldText: '"Webhook Url"',
                  additionalText: ' phía trên',
                ),
                _buildInstructionItem('Giờ đây bạn đã có thể kết nối Coka với FBS, chúc bạn thành công.'),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : _updateWebhook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Lưu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructionItem(
    String text, {
    bool isLink = false,
    String? linkText,
    VoidCallback? onLinkTap,
    String? boldText,
    String? additionalText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isLink
                ? Row(
                    children: [
                      Text(
                        text,
                        style: const TextStyle(fontSize: 12),
                      ),
                      GestureDetector(
                        onTap: onLinkTap,
                        child: Text(
                          linkText ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  )
                : boldText != null
                    ? RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(text: text),
                            TextSpan(
                              text: boldText,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (additionalText != null)
                              TextSpan(text: additionalText),
                          ],
                        ),
                      )
                    : Text(
                        text,
                        style: const TextStyle(fontSize: 12),
                      ),
          ),
        ],
      ),
    );
  }
} 