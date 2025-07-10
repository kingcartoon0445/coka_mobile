import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/models/lead/connection_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/providers.dart';

class WebFormConfigPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String workspaceName;
  
  const WebFormConfigPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.workspaceName,
  });
  
  @override
  ConsumerState<WebFormConfigPage> createState() => _WebFormConfigPageState();
}

class _WebFormConfigPageState extends ConsumerState<WebFormConfigPage> {
  final TextEditingController _webFormUrlController = TextEditingController();
  bool isLoading = false;
  bool isContinue = false;
  ConnectionModel? webform;
  bool isVerifying = false;
  
  @override
  void initState() {
    super.initState();
    // Thêm listener để cập nhật trạng thái khi giá trị thay đổi
    _webFormUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _webFormUrlController.dispose();
    super.dispose();
  }

  String _refactoryWebsite(String website) {
    if (website.contains("https://") || website.contains("http://")) {
      return website;
    }
    return "https://$website";
  }

  String _getWebformStr(String id) {
    return '<meta name="coka-site-verification" content="$id" /><script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({\'gtm.start\': new Date().getTime(),event:\'gtm.js\'});var f=d.getElementsByTagName(s)[0], j=d.createElement(s),dl=l!=\'dataLayer\'?\'&l=\'+l:\'\';j.async=true;j.src= \'https://www.googletagmanager.com/gtm.js?id=\'+i+dl;f.parentNode.insertBefore(j,f); })(window,document,\'script\',\'dataLayer\',\'GTM-NM778J2J\');</script>';
  }
  
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
          'Cấu hình Web Form',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
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
              Row(
                children: [
                  const Text(
                    'Đường dẫn Website',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
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
              TextFormField(
                controller: _webFormUrlController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: example.com hoặc https://example.com',
                  helperText: 'Nhập tên miền của website muốn kết nối với Coka',
                  helperStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Hướng dẫn kết nối Web Form',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Nhập URL website đầy đủ, bao gồm cả http:// hoặc https://',
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '2. Sau khi nhập, bấm Tiếp theo để nhận mã nhúng',
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '3. Sao chép mã và nhúng vào thẻ <head> của website',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: _webFormUrlController.text.isNotEmpty 
                    ? _handleSubmitWebsite 
                    : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Tiếp theo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
              
              if (isContinue && webform != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Copy đoạn script phía dưới và dán vào giữa <head>...</head> của phần source website, sau đó bấm xác minh để kiểm tra',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SelectableText(
                              _getWebformStr(webform!.id),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          InkWell(
                            onTap: () => _copyToClipboard(_getWebformStr(webform!.id)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sao chép',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _handleVerifyWebform,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isVerifying 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Đang xác minh...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Xác minh',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu đoạn mã vào bộ nhớ đệm'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<void> _handleSubmitWebsite() async {
    if (_webFormUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập website cần kết nối hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      // Sử dụng LeadRepository trực tiếp thay vì qua provider
      final leadRepository = ref.read(leadRepositoryProvider);
      final url = _refactoryWebsite(_webFormUrlController.text);
      
      // Chuẩn bị dữ liệu để tạo webform
      final Map<String, dynamic> data = {
        'title': 'Webform $url',
        'url': url,
        'workspaceId': widget.workspaceId,
      };
      
      // Gọi API để tạo webform
      final response = await leadRepository.addWebform(
        widget.organizationId,
        widget.workspaceId,
        data,
      );
      
      print("API Response: $response");
      
      if (context.mounted) {
        // Kiểm tra response từ server
        if ((response['code'] == 201 || response['code'] == 0) && response['content'] != null) {
          // Tạo đối tượng ConnectionModel từ response
          final connectionData = response['content'];
          final webformModel = ConnectionModel(
            id: connectionData['id'] ?? '',
            title: connectionData['title'] ?? 'Webform $url',
            connectionType: 'webform',
            status: connectionData['status'] ?? 1,
            connectionState: connectionData['connectionState'] ?? 'Chưa xác minh',
            organizationId: widget.organizationId,
            workspaceId: widget.workspaceId,
            workspaceName: widget.workspaceName,
            provider: 'webform',
            url: url,
          );
          
          setState(() {
            webform = webformModel;
            isContinue = true;
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
              content: Text('Đã có lỗi xảy ra xin vui lòng thử lại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Exception in createWebform: $e");
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
  
  Future<void> _handleVerifyWebform() async {
    if (webform == null) return;
    
    setState(() {
      isVerifying = true;
    });
    
    try {
      final leadRepository = ref.read(leadRepositoryProvider);
      final response = await leadRepository.verifyWebform(
        webform!.id,
        widget.organizationId,
        widget.workspaceId,
      );
      
      print("Verify API Response: $response");
      
      if (context.mounted) {
        // Kiểm tra kết quả xác minh
        if ((response['code'] == 0 || response['code'] == 200) && response['content'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kết nối website ${webform!.url} thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Trả về true để reload data
        } else {
          // Kiểm tra xem có message từ server hay không
          String errorMessage = 'Kết nối website ${webform!.url} thất bại, vui lòng kiểm tra lại cấu hình';
          
          if (response.containsKey('message') && response['message'] != null) {
            errorMessage = response['message'];
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Exception in verifyWebform: $e");
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
        isVerifying = false;
      });
    }
  }
} 