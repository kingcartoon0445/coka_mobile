import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/providers.dart';
import 'package:intl/intl.dart';

class WebhookConfigPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String workspaceName;
  
  const WebhookConfigPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.workspaceName,
  });
  
  @override
  ConsumerState<WebhookConfigPage> createState() => _WebhookConfigPageState();
}

class _WebhookConfigPageState extends ConsumerState<WebhookConfigPage> {
  String _selectedWebhookSource = 'FBS'; // Mặc định là FBS
  DateTime? _expiryDate;
  bool isLoading = false;
  Map<String, dynamic>? _webhook;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cấu hình Webhook',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_webhook != null)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Xong',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị thông tin workspace đã chọn
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Không gian làm việc: ${widget.workspaceName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Row(
                children: [
                  Text(
                    'Dịch vụ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildServiceDropdown(),
              
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text(
                    'Ngày hết hạn',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDatePicker(),
              
              if (_webhook != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Webhook Url',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _buildWebhookUrlBox(),
                const SizedBox(height: 12),
                _buildFbsInstructions(),
              ] else ...[
                const SizedBox(height: 16),
                const Text(
                  '*FBS là công cụ quét số điện thoại hàng loạt trên nền tảng Facebook: Fanpage, Group, Profile, Avatar, Inbox, Comment, Like, Share... hổ trợ bán hàng online, khai thác khách hàng với chi phí cực kỳ thấp',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
              
              if (_webhook == null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _buildSubmitButton(),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildServiceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedWebhookSource,
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: _webhook != null ? null : (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedWebhookSource = newValue;
            });
          }
        },
        items: [
          DropdownMenuItem<String>(
            value: 'FBS',
            child: const Text('FBS'),
          ),
          DropdownMenuItem<String>(
            value: 'OTHER',
            child: const Text('Khác'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDatePicker() {
    return InkWell(
      onTap: _webhook != null ? null : () => _selectDate(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              _expiryDate != null 
                  ? DateFormat('dd/MM/yyyy').format(_expiryDate!)
                  : 'Chọn ngày hết hạn',
              style: TextStyle(
                color: _expiryDate != null ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }
  
  Widget _buildWebhookUrlBox() {
    String webhookUrl = _webhook?['url'] ?? 'Url chưa có';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              webhookUrl,
              style: const TextStyle(
                fontSize: 13, 
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: webhookUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.copy, color: AppColors.primary, size: 14),
                  const SizedBox(width: 4),
                  const Text(
                    'Sao chép',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFbsInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sử dụng Webhook Coka trên FBS:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildListItem('Truy cập vào địa chỉ ', 'FBS.AI', true),
        _buildListItem('Bạn cần đăng nhập và chọn mua gói dịch vụ phù hợp với nhu cầu.'),
        _buildListItem('Chọn ', '"Quản lý thành viên nhóm"', false),
        _buildListItem('Nhấn vào mục ', '"Webhook"', false),
        _buildListItem('Dán ', '"Webhook Url"', false),
        _buildListItem('Giờ đây bạn đã có thể kết nối Coka với FBS, chúc bạn thành công.'),
      ],
    );
  }
  
  Widget _buildListItem(String text, [String? boldText, bool isLink = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black),
                children: [
                  TextSpan(text: text),
                  if (boldText != null)
                    TextSpan(
                      text: boldText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isLink ? TextDecoration.underline : null,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    bool isEnabled = _expiryDate != null;
    
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: isEnabled ? _createWebhook : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Tiếp theo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
      ),
    );
  }
  
  Future<void> _createWebhook() async {
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày hết hạn'),
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
      
      // Chuẩn bị dữ liệu để tạo webhook
      final Map<String, dynamic> data = {
        'title': 'Webhook',
        'workspaceId': widget.workspaceId,
        'source': _selectedWebhookSource,
        'expiryDate': _expiryDate!.toUtc().toIso8601String(),
      };
      
      // Gọi API để tạo webhook
      final response = await leadRepository.webhookCreate(
        widget.organizationId,
        data,
      );
      
      if (context.mounted) {
        // Kiểm tra kết quả từ server
        if ((response['code'] == 0 || response['code'] == 201) && response['content'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo webhook thành công'),
              backgroundColor: Colors.green,
            ),
          );
          
          setState(() {
            _webhook = response['content'];
          });
        } else if (response['message'] != null) {
          // Hiển thị thông báo lỗi từ server
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // Hiển thị thông báo lỗi chung
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo kết nối Webhook thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Xử lý lỗi từ server
        String errorMessage = e.toString();
        
        // Kiểm tra xem lỗi có phải từ API response không
        if (errorMessage.contains('"message"')) {
          try {
            // Cố gắng trích xuất message từ chuỗi lỗi JSON
            final startIndex = errorMessage.indexOf('"message"') + 11; // Độ dài của '"message":"'
            final endIndex = errorMessage.indexOf('"', startIndex);
            if (startIndex > 0 && endIndex > startIndex) {
              errorMessage = errorMessage.substring(startIndex, endIndex);
            }
          } catch (_) {
            // Nếu không trích xuất được, giữ nguyên message lỗi
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
} 