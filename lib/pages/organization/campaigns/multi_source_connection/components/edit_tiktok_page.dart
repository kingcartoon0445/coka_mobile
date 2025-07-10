import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/models/lead/connection_model.dart';
import 'package:coka/api/providers.dart';
import 'package:coka/providers/app_providers.dart';
import 'package:coka/core/utils/helpers.dart';
class FieldMapping {
  String? tiktokFieldId;
  String? tiktokFieldTitle;
  String? cokaField;

  FieldMapping({
    this.tiktokFieldId,
    this.tiktokFieldTitle,
    this.cokaField
  });

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

class EditTiktokPage extends ConsumerStatefulWidget {
  final ConnectionModel data;

  const EditTiktokPage({
    super.key,
    required this.data,
  });

  @override
  ConsumerState<EditTiktokPage> createState() => _EditTiktokPageState();
}

class _EditTiktokPageState extends ConsumerState<EditTiktokPage> {
  bool isLoading = true;
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
    _loadFormDetails();
  }

  Future<void> _loadFormDetails() async {
    try {
      setState(() => isLoading = true);
      final leadRepository = ref.read(leadRepositoryProvider);
      
      // Debug: in ra toàn bộ thông tin ConnectionModel
      print("Tiktok ConnectionModel - id: ${widget.data.id}");
      print("Tiktok ConnectionModel - title: ${widget.data.title}");
      print("Tiktok ConnectionModel - organizationId: '${widget.data.organizationId}'");
      print("Tiktok ConnectionModel - workspaceId: '${widget.data.workspaceId}'");
      print("additionalData: ${widget.data.additionalData}");
      
      // Nếu organizationId trong model là rỗng, thử lấy từ additionalData
      String orgId = widget.data.organizationId;
      if (orgId.isEmpty && widget.data.additionalData != null && widget.data.additionalData!['organizationId'] != null) {
        orgId = widget.data.additionalData!['organizationId'];
        print("Sử dụng organizationId từ additionalData: $orgId");
      }
      
      // Kiểm tra nếu organizationId vẫn rỗng, lúc này ta cần lấy từ page trước truyền vào
      if (orgId.isEmpty) {
        // Lấy từ tham số route hoặc từ Provider, nếu có
        final multiSourceProvider = ref.read(multiSourceConnectionProvider);
        if (multiSourceProvider.connections.isNotEmpty) {
          // Lấy từ connection đầu tiên có cùng workspace
          final sameWorkspaceConn = multiSourceProvider.connections.firstWhere(
            (conn) => conn.workspaceId == widget.data.workspaceId,
            orElse: () => multiSourceProvider.connections.first,
          );
          orgId = sameWorkspaceConn.organizationId;
          print("Sử dụng organizationId từ Provider: $orgId");
        }
      }
      
      // Nếu vẫn không có organizationId, thử lấy từ multiSourceProvider
      if (orgId.isEmpty) {
        try {
          final multiSourceProvider = ref.read(multiSourceConnectionProvider);
          if (multiSourceProvider.connections.isNotEmpty) {
            // Lấy từ connection đầu tiên
            orgId = multiSourceProvider.connections.first.organizationId;
            print("Sử dụng organizationId từ multiSourceProvider.connections[0]: $orgId");
          }
        } catch (e) {
          print("Không thể lấy organizationId từ multiSourceProvider: $e");
        }
      }
      
      if (orgId.isEmpty) {
        throw Exception("organizationId rỗng, không thể lấy thông tin form");
      }
      
      // Kiểm tra dữ liệu additional có đủ thông tin không
      if (widget.data.additionalData == null) {
        throw Exception("Không có dữ liệu bổ sung (additionalData)");
      }
      
      // Thiết lập dữ liệu để lấy tiktok form
      String? subscribedId = widget.data.additionalData!['subscribedId'];
      String? pageId = widget.data.additionalData!['pageId'];
      
      // Sử dụng id chính nếu không có subscribedId
      if (subscribedId == null || subscribedId.isEmpty) {
        subscribedId = widget.data.id;
        print("Sử dụng id chính làm subscribedId: $subscribedId");
      }
      
      // Nếu không có pageId, sử dụng một giá trị mặc định hoặc thông báo lỗi
      if (pageId == null || pageId.isEmpty) {
        // Có thể lấy từ API khác hoặc sử dụng giá trị mặc định nếu có
        pageId = "0"; // Thử với giá trị mặc định là "0"
        print("WARNING: Thiếu pageId, sử dụng giá trị mặc định: $pageId");
      }
      
      print("Fetching TikTok details - orgId: $orgId, workspaceId: ${widget.data.workspaceId}, subscribedId: $subscribedId, pageId: $pageId");
      
      final response = await leadRepository.getTiktokFormDetail(
        orgId,
        widget.data.workspaceId,
        subscribedId,
        pageId
      );

      print("API response: $response");

      if (Helpers.isResponseSuccess(response) && response['content'] != null) {
        final content = response['content'];
        if (content['mappingField'] != null && content['mappingField'].isNotEmpty) {
          final List<dynamic> mappingFields = content['mappingField'];
          setState(() {
            mappingData = mappingFields
                .map((field) => FieldMapping.fromJson(field))
                .toList();
          });
          print("Loaded ${mappingData.length} mapping fields from API");
        } else {
          print("No mapping fields found in API response, initializing empty");
          setState(() {
            mappingData = [
              FieldMapping(
                tiktokFieldId: "name",
                tiktokFieldTitle: "name",
                cokaField: null
              )
            ];
          });
        }
      } else {
        throw Exception(response['message'] ?? "Không thể lấy thông tin form");
      }
    } catch (e) {
      print("Error loading tiktok form details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lấy thông tin chi tiết form: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        mappingData = [
          FieldMapping(
            tiktokFieldId: "name",
            tiktokFieldTitle: "name",
            cokaField: null
          )
        ];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _handleUpdateTiktokField(int index, String value) {
    setState(() {
      // Nếu chưa có tiktokFieldId, sử dụng tiktokFieldTitle làm id
      if (mappingData[index].tiktokFieldId == null || mappingData[index].tiktokFieldId!.isEmpty) {
        mappingData[index].tiktokFieldId = mappingData[index].tiktokFieldTitle;
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
        cokaField: null
      ));
    });
  }

  void _removeField(int index) {
    if (mappingData.length <= 1) return;
    setState(() {
      mappingData.removeAt(index);
    });
  }

  Future<void> _handleUpdateTiktokForm() async {
    if (widget.data.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật form: Thiếu thông tin form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      final leadRepository = ref.read(leadRepositoryProvider);
      
      // Lấy organizationId đã kiểm tra từ đầu
      String orgId = widget.data.organizationId;
      if (orgId.isEmpty && widget.data.additionalData != null && widget.data.additionalData!['organizationId'] != null) {
        orgId = widget.data.additionalData!['organizationId'];
      }
      
      if (orgId.isEmpty) {
        // Lấy từ Provider
        final multiSourceProvider = ref.read(multiSourceConnectionProvider);
        if (multiSourceProvider.connections.isNotEmpty) {
          final sameWorkspaceConn = multiSourceProvider.connections.firstWhere(
            (conn) => conn.workspaceId == widget.data.workspaceId,
            orElse: () => multiSourceProvider.connections.first,
          );
          orgId = sameWorkspaceConn.organizationId;
        }
      }
      
      if (orgId.isEmpty) {
        throw Exception("organizationId rỗng, không thể cập nhật form");
      }
      
      // Đảm bảo tất cả các trường mapping đều có tiktokFieldId
      // Nếu không có, gán giá trị từ tiktokFieldTitle hoặc tạo mới
      for (int i = 0; i < mappingData.length; i++) {
        if (mappingData[i].tiktokFieldId == null || mappingData[i].tiktokFieldId!.isEmpty) {
          if (mappingData[i].tiktokFieldTitle != null && mappingData[i].tiktokFieldTitle!.isNotEmpty) {
            mappingData[i].tiktokFieldId = mappingData[i].tiktokFieldTitle;
          } else {
            mappingData[i].tiktokFieldId = "field_${DateTime.now().millisecondsSinceEpoch}_$i";
          }
        }
      }
      
      // Chuyển đổi mappingData sang format API cần
      final formData = {
        ...widget.data.additionalData ?? {},
        'mappingField': mappingData.map((field) => field.toJson()).toList(),
      };
      
      print("Updating Tiktok form - orgId: $orgId, workspaceId: ${widget.data.workspaceId}, formId: ${widget.data.id}");
      print("formData: $formData");
      
      final response = await leadRepository.updateTiktokForm(
        orgId,
        widget.data.workspaceId,
        widget.data.id,
        formData,
      );

      print("Update API response: $response");

      if (Helpers.isResponseSuccess(response)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật cấu hình form thành công'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Trả về true để reload data
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Cập nhật cấu hình form thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Error updating tiktok form: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        title: const Text(
          'Cập nhật cấu hình Tiktok Form',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _handleUpdateTiktokForm,
              backgroundColor: AppColors.primary,
              label: const Text(
                "Cập nhật",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 100),
            ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
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
                          Text(
                            widget.data.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.data.connectionState != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Trạng thái: ${widget.data.connectionState}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getStateColor(widget.data.connectionState!),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Text(
                            "Cấu hình TikTok",
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
                    
                    Column(
                      children: List.generate(mappingData.length, (index) => _buildMappingRow(index)),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Add field button
                    TextButton.icon(
                      onPressed: _addNewField,
                      icon: Icon(Icons.add, size: 20, color: AppColors.primary),
                      label: Text(
                        'Thêm trường',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                    
                    const SizedBox(height: 80), // Space for floating button
                  ],
                ),
              ),
            ),
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
              "Tiktok Field",
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

  Widget _buildMappingRow(int index) {
    final currentValue = mappingData[index].cokaField;
    final bool isValidValue = currentValue == null || cokaFieldMenu.contains(currentValue);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // TikTok field input
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - 25,
            child: TextFormField(
              initialValue: mappingData[index].tiktokFieldTitle,
              decoration: InputDecoration(
                hintText: "Tiktok field",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) => _handleUpdateTiktokField(index, value),
            ),
          ),
          
          // Đường nối
          Expanded(
            child: Container(
              height: 1,
              color: Colors.black,
            ),
          ),
          
          // Coka field dropdown
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - 25,
            child: DropdownButtonFormField<String>(
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
              value: isValidValue ? currentValue : null,
              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              items: cokaFieldMenu.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  _handleUpdateCokaField(index, value);
                }
              },
            ),
          ),
        ],
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