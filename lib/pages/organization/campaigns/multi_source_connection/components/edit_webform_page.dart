import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/models/lead/connection_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/providers.dart';
import 'package:url_launcher/url_launcher.dart';

class EditWebformPage extends ConsumerStatefulWidget {
  final ConnectionModel data;

  const EditWebformPage({
    super.key,
    required this.data,
  });

  @override
  ConsumerState<EditWebformPage> createState() => _EditWebformPageState();
}

class _EditWebformPageState extends ConsumerState<EditWebformPage> {
  bool isLoading = false;

  String _formatDisplayUrl(String url) {
    if (url.isEmpty) return '';
    if (url.contains("https://") || url.contains("http://")) {
      return url;
    }
    return "https://$url";
  }

  String getWebformStr(String id) {
    return '<meta name="coka-site-verification" content="$id" />'
        '<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({\'gtm.start\': '
        'new Date().getTime(),event:\'gtm.js\'});var f=d.getElementsByTagName(s)[0], '
        'j=d.createElement(s),dl=l!=\'dataLayer\'?\'&l=\'+l:\'\';j.async=true;j.src= '
        '\'https://www.googletagmanager.com/gtm.js?id=\'+i+dl;f.parentNode.insertBefore(j,f); '
        '})(window,document,\'script\',\'dataLayer\',\'GTM-NM778J2J\');</script>';
  }

  void handleVerifyWebform() async {
    setState(() {
      isLoading = true;
    });

    try {
      final leadRepository = ref.read(leadRepositoryProvider);
      final response = await leadRepository.verifyWebform(
        widget.data.id,
        widget.data.organizationId,
        widget.data.workspaceId,
      );

      if (response['content'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kết nối website ${widget.data.url} thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Trả về true để reload data
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Kết nối website ${widget.data.url} thất bại, vui lòng kiểm tra lại cấu hình',
              ),
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

  void handleTestForm() async {
    if (widget.data.url != null) {
      final url = Uri.parse(widget.data.url!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  void copyUrlToClipboard() {
    final formattedUrl = _formatDisplayUrl(widget.data.url ?? '');
    if (formattedUrl.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: formattedUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép URL vào bộ nhớ đệm')),
      );
    }
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu đoạn mã vào bộ nhớ đệm')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final webformCode = getWebformStr(widget.data.id);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        title: const Text(
          'Chỉnh sửa cấu hình Web Form',
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
            // Form title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trạng thái kết nối',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.data.connectionState != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStateColor(widget.data.connectionState!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStateColor(widget.data.connectionState!),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.data.connectionState!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _getStateColor(widget.data.connectionState!),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // URL Field
            Row(
              children: [
                const Text(
                  'Đường dẫn Website*',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: copyUrlToClipboard,
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text(
                    'Sao chép URL',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _formatDisplayUrl(widget.data.url ?? ''),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Script details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Copy đoạn script phía dưới và dán vào giữa <head>...</head> của phần source website, sau đó bấm xác minh để kiểm tra',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  
                  // Script code with copy button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          webformCode,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => copyToClipboard(webformCode),
                            icon: const Icon(Icons.copy, size: 14),
                            label: const Text(
                              'Sao chép',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: widget.data.status == 1 
                ? <Widget>[
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Đã xác minh', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: handleTestForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Test Form', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleVerifyWebform,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        isLoading ? 'Đang xác minh...' : 'Xác minh lại',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ]
                : <Widget>[
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleVerifyWebform,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(
                        isLoading ? 'Đang xác minh...' : 'Xác minh',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStateColor(String state) {
    switch (state) {
      case 'Chưa xác minh':
        return Colors.grey;
      case 'Mất kết nối':
        return Colors.red;
      case 'Đang kết nối':
        return Colors.green;
      case 'Đã kết nối':
        return AppColors.primary;
      case 'Gỡ kết nối':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
} 