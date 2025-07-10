import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../api/repositories/customer_repository.dart';
import '../../../../../../api/api_client.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/widgets/border_textfield.dart';
import '../../../../../../shared/widgets/loading_dialog.dart';

class ImportGoogleSheetPage extends StatefulWidget {
  final String organizationId;
  final String workspaceId;

  const ImportGoogleSheetPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
  });

  @override
  State<ImportGoogleSheetPage> createState() => _ImportGoogleSheetPageState();
}

class _ImportGoogleSheetPageState extends State<ImportGoogleSheetPage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _headerController = TextEditingController(text: "1");
  final formKey = GlobalKey<FormState>();
  
  late final CustomerRepository _customerRepository;
  List<Map<String, dynamic>> _menuItemList = [];
  String? _successMessage, _errorMessage, _fileName;
  int? _rowCount;
  List<Map<String, dynamic>> _mappingList = [
    {"googleFieldId": "", "googleFieldTitle": "", "cokaField": ""}
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customerRepository = CustomerRepository(ApiClient());
    _fetchMenuItems();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenuItems() async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final response = await dio.get('https://automation.coka.ai/googlesheet_config.json');
      
      setState(() {
        _menuItemList = List<Map<String, dynamic>>.from(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // Sử dụng dữ liệu mẫu khi không thể tải được cấu hình
        _useDefaultData();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sử dụng cấu hình mặc định do không thể tải được cấu hình từ máy chủ')),
        );
      }
    }
  }
  
  void _useDefaultData() {
    _menuItemList = [
      {"id": "FullName", "name": "Họ và tên"},
      {"id": "Email", "name": "Email"},
      {"id": "Phone", "name": "Số điện thoại"},
      {"id": "Gender", "name": "Giới tính"},
      {"id": "Dob", "name": "Ngày sinh"},
      {"id": "Address", "name": "Địa chỉ"},
      {"id": "Website", "name": "Website"},
      {"id": "UtmSource", "name": "Utm Source"}
    ];
  }

  Future<void> _checkUrlAndGenerateMapping() async {
    if (!formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = "Vui lòng điền đầy đủ thông tin";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _customerRepository.generateGoogleSheetMapping(
        widget.organizationId, 
        widget.workspaceId,
        _urlController.text,
        int.parse(_headerController.text),
      );

      if (result['code'] == 0 || (result['code'] >= 200 && result['code'] < 300)) {
        setState(() {
          _successMessage = "Đã lấy được ${result['content']['rowCount']} dữ liệu từ file";
          _fileName = result['content']['sheetName'];
          _rowCount = result['content']['rowCount'];
          _mappingList = List<Map<String, dynamic>>.from(result['content']['mappingField']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Có lỗi xảy ra khi kiểm tra URL';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _importData() async {
    setState(() => _isLoading = true);
    
    try {
      showLoadingDialog(context);
      final result = await _customerRepository.importGoogleSheet(
        widget.organizationId,
        widget.workspaceId,
        _urlController.text,
        int.parse(_headerController.text),
        _rowCount!,
        _mappingList,
      );
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng dialog loading

      if (result['code'] == 0 || (result['code'] >= 200 && result['code'] < 300)) {
        // Thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã import thành công ${result['metadata']['totalSuccess']}/${result['metadata']['totalRow']} dữ liệu'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // Quay lại trang trước
      } else {
        // Thất bại
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Có lỗi xảy ra khi import dữ liệu'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng dialog loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUrlGoogleSheetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BorderTextField(
          name: "URL Google Sheet",
          nameHolder: "Nhập URL Google Sheet",
          controller: _urlController,
          isRequire: true,
          borderRadius: 4,
          fillColor: Colors.white,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Vui lòng nhập URL Google Sheet";
            }
            if (!value.contains("docs.google.com/spreadsheets")) {
              return "URL không hợp lệ";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        if (_isLoading && _successMessage == null)
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )
        else if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  child: const Text("Thử lại"),
                )
              ],
            ),
          )
        else if (_successMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Tên file: $_fileName",
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: _checkUrlAndGenerateMapping,
              child: const Text("Kiểm tra URL"),
            ),
          ),
      ],
    );
  }

  Widget _buildMappingField() {
    if (_rowCount == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Text(
                "Cấu hình GoogleSheet",
                style: TextStyle(
                  color: Color(0xFF1F2329),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "*",
                style: TextStyle(color: Color(0xFFFB0038), fontSize: 20),
              )
            ],
          ),
        ),
        _buildMappingHeader(),
        ..._mappingList.map((mapping) => _buildMappingRow(mapping)),
      ],
    );
  }

  Widget _buildMappingHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - 25,
            child: const Text(
              "Google Sheet",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - 25,
            child: const Text(
              "Coka Field",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(Map<String, dynamic> mapping) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Google Sheet Field
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - 25,
            child: TextFormField(
              readOnly: true,
              initialValue: mapping["googleFieldTitle"],
              decoration: InputDecoration(
                hintText: "Nội dung",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
          
          // Đường nối
          Expanded(
            child: Container(
              height: 1,
              color: Colors.black,
            ),
          ),
          
          // Coka Field
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - 25,
            child: DropdownButtonFormField<String>(
              value: mapping["cokaField"] == "" ? null : mapping["cokaField"],
              decoration: InputDecoration(
                hintText: "Form Field",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _menuItemList.map((item) {
                return DropdownMenuItem<String>(
                  value: item["id"],
                  child: Text(item["name"]),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  mapping["cokaField"] = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8F8),
          title: const Text(
            "Nhập từ Google Sheet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _rowCount != null
            ? FloatingActionButton.extended(
                onPressed: _isLoading ? null : _importData,
                backgroundColor: const Color(0xFF5C33F0),
                label: const Text(
                  "Hoàn tất",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                extendedPadding: const EdgeInsets.symmetric(horizontal: 100),
              )
            : null,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_successMessage == null)
                  BorderTextField(
                    name: "Chọn dòng tiêu đề",
                    nameHolder: "Điền dòng tiêu đề",
                    borderRadius: 4,
                    fillColor: Colors.white,
                    controller: _headerController,
                    onTooltipClick: () {
                      _showHeaderTooltip();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Vui lòng điền dòng tiêu đề";
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return "Dòng tiêu đề chỉ được nhập số";
                      }
                      if (int.parse(value) <= 0) {
                        return "Dòng tiêu đề phải lớn hơn 0";
                      }
                      return null;
                    },
                    textInputType: TextInputType.number,
                  ),
                const SizedBox(height: 16),
                _buildUrlGoogleSheetField(),
                _buildMappingField(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHeaderTooltip() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "Dòng tiêu đề",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2329),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Image.asset("assets/images/row_header_tooltip.png"),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "Dòng tiêu đề",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF47464F),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "Đây là dòng đầu tiên của bản dữ liệu có chứa các nhãn hoặc tiêu đề mô tả các cột dưới đó.\n(Ở ví dụ phía trên dòng tiêu đề là 3)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF47464F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 