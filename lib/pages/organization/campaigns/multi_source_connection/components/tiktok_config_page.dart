import 'package:coka/api/api_client.dart';
import 'package:coka/api/providers.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/core/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class TiktokConfigPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String workspaceName;

  const TiktokConfigPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  ConsumerState<TiktokConfigPage> createState() => _TiktokConfigPageState();
}

class _TiktokConfigPageState extends ConsumerState<TiktokConfigPage> {
  bool isLoading = true;
  bool isSubmitting = false;

  List<dynamic> tiktokAccounts = [];
  dynamic selectedAccount;

  List<dynamic> tiktokForms = [];
  dynamic selectedForm;

  List<FieldMapping> mappingData = [FieldMapping()];

  static const List<String> cokaFieldMenu = [
    "FullName",
    "Email",
    "Phone",
    "Gender",
    "Note",
    "Dob",
    "PhysicalId",
    "DateOfIssue",
    "Address",
    "Rating",
    "Work",
    "Avatar",
    "AssignTo",
  ];

  @override
  void initState() {
    super.initState();
    _fetchTiktokAccounts();
  }

  // 1. Lấy danh sách tài khoản Tiktok
  Future<void> _fetchTiktokAccounts() async {
    setState(() => isLoading = true);

    try {
      final leadRepository = ref.read(leadRepositoryProvider);
      final response =
          await leadRepository.getLeadList(widget.organizationId, widget.workspaceId, "TIKTOK");

      if (Helpers.isResponseSuccess(response) && response['content'] != null) {
        setState(() {
          tiktokAccounts = response['content'];
        });
        print("Đã tải ${tiktokAccounts.length} tài khoản Tiktok");
      } else {
        print("Không có tài khoản Tiktok: ${response['message']}");
      }
    } catch (e) {
      print("Lỗi khi tải tài khoản Tiktok: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh sách tài khoản Tiktok: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 2. Lấy danh sách form của tài khoản Tiktok đã chọn
  Future<void> _fetchTiktokForms(dynamic account) async {
    if (account == null) return;

    setState(() => isLoading = true);

    try {
      final leadRepository = ref.read(leadRepositoryProvider);
      final response = await leadRepository.getTiktokFormList(
          widget.organizationId, widget.workspaceId, account['id'], false);

      if (Helpers.isResponseSuccess(response) && response['content'] != null) {
        setState(() {
          tiktokForms = response['content'];
        });
        print("Đã tải ${tiktokForms.length} form Tiktok");
      } else {
        print("Không có form Tiktok: ${response['message']}");
      }
    } catch (e) {
      print("Lỗi khi tải form Tiktok: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh sách form Tiktok: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 3. Lấy chi tiết form Tiktok
  Future<void> _getFormDetail(dynamic form) async {
    if (form == null || form['pageId'] == null) return;

    setState(() => isLoading = true);

    try {
      final leadRepository = ref.read(leadRepositoryProvider);
      final response = await leadRepository.getTiktokFormDetail(
          widget.organizationId, widget.workspaceId, selectedAccount['id'], form['pageId']);

      if (Helpers.isResponseSuccess(response) && response['content'] != null) {
        final content = response['content'];

        if (content['mappingField'] != null && content['mappingField'].isNotEmpty) {
          final List<dynamic> mappingFields = content['mappingField'];
          setState(() {
            mappingData = mappingFields.map((field) => FieldMapping.fromJson(field)).toList();

            // Cập nhật thông tin form với thông tin chi tiết
            selectedForm = {
              ...selectedForm,
              ...content,
              'mappingField': content['mappingField'],
            };
          });
          print("Đã tải ${mappingData.length} trường mapping từ API");
        } else {
          // Khởi tạo mapping rỗng
          setState(() {
            mappingData = [FieldMapping()];
          });
        }
      } else {
        print("Không thể lấy chi tiết form: ${response['message']}");
      }
    } catch (e) {
      print("Lỗi khi tải chi tiết form Tiktok: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải chi tiết form Tiktok: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 4. Tạo kết nối mới với form Tiktok
  Future<void> _handleSubmitTiktok() async {
    if (selectedForm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Form cần kết nối'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn tài khoản Tiktok'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // Chuyển đổi từ dynamic sang Map<String, dynamic>
      final Map<String, dynamic> formData = {
        'title': selectedForm['title'] ?? '',
        'description': selectedForm['description'] ?? "",
        'pageId': selectedForm['pageId'] ?? '',
        'tiktokFormId': selectedForm['tiktokFormId'] ?? selectedForm['pageId'] ?? '',
        'subscribedId': selectedAccount['id'] ?? '',
        'mappingField': mappingData.map((field) => field.toJson()).toList(),
      };

      final leadRepository = ref.read(leadRepositoryProvider);
      final response = await leadRepository.createTiktokForm(
          widget.organizationId, widget.workspaceId, formData);

      if (Helpers.isResponseSuccess(response)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo kết nối form thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Trả về true để reload danh sách kết nối
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Tạo kết nối form thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Lỗi khi tạo kết nối form Tiktok: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo kết nối form Tiktok: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  // 5. Mở popup kết nối tài khoản Tiktok
  Future<void> _openTiktokAuthWindow() async {
    try {
      // Lấy accessToken từ secure storage
      final accessToken = await const FlutterSecureStorage().read(key: 'access_token');

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception("Không tìm thấy access token");
      }

      final url = Uri.parse(
          "${ApiClient.baseUrl}/api/v1/integration/tiktok/auth/lead?accessToken=$accessToken&organizationId=${widget.organizationId}&workspaceId=${widget.workspaceId}");

      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Không thể mở URL: $url');
      }

      // Đợi một thời gian rồi refresh danh sách tài khoản
      await Future.delayed(const Duration(seconds: 10));
      await _fetchTiktokAccounts();
    } catch (e) {
      print("Lỗi khi mở cửa sổ xác thực Tiktok: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể kết nối với Tiktok: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleAccountChange(dynamic account) {
    setState(() {
      selectedAccount = account;
      selectedForm = null;
      tiktokForms = [];
      mappingData = [FieldMapping()];
    });

    _fetchTiktokForms(account);
  }

  void _handleFormChange(dynamic form) {
    setState(() {
      selectedForm = form;
    });

    _getFormDetail(form);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Cấu hình Tiktok Form',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: Colors.black12),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chọn tài khoản Tiktok
                          _buildSectionTitle('Chọn tài khoản Tiktok'),

                          // Dropdown chọn tài khoản
                          _buildAccountDropdown(),

                          // Nút thêm tài khoản
                          _buildAddAccountButton(),

                          const SizedBox(height: 24),

                          // Chọn form
                          _buildSectionTitle('Chọn Form'),

                          // Dropdown chọn form
                          _buildFormDropdown(),

                          const SizedBox(height: 24),

                          // Phần cấu hình mapping
                          _buildSectionTitle('Cấu hình'),

                          const SizedBox(height: 12),

                          // Header cho mapping
                          _buildMappingHeader(),

                          const SizedBox(height: 8),

                          // Danh sách trường mapping
                          ...mappingData
                              .asMap()
                              .entries
                              .map((entry) => _buildMappingRow(entry.key)),

                          const SizedBox(height: 16),

                          // Nút thêm trường mapping
                          _buildAddFieldButton(),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isLoading || isSubmitting
          ? null
          : FloatingActionButton.extended(
              onPressed: _handleSubmitTiktok,
              backgroundColor: AppColors.primary,
              label: const Text(
                "Lưu",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.save, color: Colors.white),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 48),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Text(
          '*',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          isExpanded: true,
          hint: const Text('Chọn tài khoản'),
          value: selectedAccount,
          items: tiktokAccounts.map<DropdownMenuItem<dynamic>>((account) {
            return DropdownMenuItem<dynamic>(
              value: account,
              child: Text(account['name'] ?? 'Tài khoản không có tên'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _handleAccountChange(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAddAccountButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: _openTiktokAuthWindow,
          icon: SvgPicture.asset(
            'assets/icons/tiktok.svg',
            width: 18,
            height: 18,
          ),
          label: const Text('Thêm tài khoản'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black87,
            side: const BorderSide(color: Colors.black26),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildFormDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          isExpanded: true,
          hint: const Text('Chọn form kết nối'),
          value: selectedForm,
          items: tiktokForms.map<DropdownMenuItem<dynamic>>((form) {
            return DropdownMenuItem<dynamic>(
              value: form,
              child: Text(form['title'] ?? 'Form không có tên'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _handleFormChange(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildMappingHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: const Text(
              "Tiktok field",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Container(
          width: 30,
          alignment: Alignment.center,
        ),
        Expanded(
          child: Container(
            alignment: Alignment.centerLeft,
            child: const Text(
              "Coka field",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMappingRow(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Tiktok field input
          Expanded(
            child: TextFormField(
              initialValue: mappingData[index].tiktokFieldTitle,
              decoration: InputDecoration(
                hintText: "Tiktok field",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) => _handleUpdateTiktokField(index, value),
            ),
          ),

          // Đường nối
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Container(
              height: 1,
              color: Colors.black26,
            ),
          ),

          // Coka field dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text('Coka field'),
                  ),
                  value: mappingData[index].cokaField,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: cokaFieldMenu.map<DropdownMenuItem<String>>((value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _handleUpdateCokaField(index, value);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFieldButton() {
    return InkWell(
      onTap: _addNewField,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Thêm trường',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpdateTiktokField(int index, String value) {
    setState(() {
      // Nếu chưa có tiktokFieldId, sử dụng tiktokFieldTitle làm id
      if (mappingData[index].tiktokFieldId == null || mappingData[index].tiktokFieldId!.isEmpty) {
        mappingData[index].tiktokFieldId = value;
      }
      mappingData[index].tiktokFieldTitle = value;
    });
  }

  void _handleUpdateCokaField(int index, String value) {
    setState(() {
      mappingData[index].cokaField = value;
    });
  }

  void _addNewField() {
    setState(() {
      mappingData.add(FieldMapping(
          tiktokFieldId: "field_${DateTime.now().millisecondsSinceEpoch}",
          tiktokFieldTitle: "",
          cokaField: null));
    });
  }
}

// Lớp FieldMapping để quản lý mapping giữa trường Tiktok và trường Coka
class FieldMapping {
  String? tiktokFieldId;
  String? tiktokFieldTitle;
  String? cokaField;

  FieldMapping({this.tiktokFieldId, this.tiktokFieldTitle, this.cokaField});

  factory FieldMapping.fromJson(Map<String, dynamic> json) {
    return FieldMapping(
      tiktokFieldId: json['tiktokFieldId'],
      tiktokFieldTitle: json['tiktokFieldTitle'],
      cokaField: json['cokaField'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tiktokFieldId': tiktokFieldId,
      'tiktokFieldTitle': tiktokFieldTitle,
      'cokaField': cokaField,
    };
  }
}
