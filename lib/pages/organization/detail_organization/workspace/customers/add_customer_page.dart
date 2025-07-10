import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../../api/repositories/customer_repository.dart';
import '../../../../../api/repositories/workspace_repository.dart';
import '../../../../../api/api_client.dart';
import '../../../../../providers/customer_provider.dart';
import '../../../../../shared/widgets/chip_input.dart';
import '../../../../../shared/widgets/radio_gender.dart';
import '../../../../../shared/widgets/border_textfield.dart';
import '../../../../../shared/widgets/awesome_textfield.dart';
import '../../../../../shared/widgets/avatar_widget.dart';
import '../../../../../core/utils/helpers.dart';

class AddCustomerPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;

  const AddCustomerPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
  });

  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerRepository = CustomerRepository(ApiClient());
  final _workspaceRepository = WorkspaceRepository(ApiClient());

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _workController = TextEditingController();
  final _addressController = TextEditingController();
  final _physicalIdController = TextEditingController();
  final _customerSourceController = TextEditingController();
  final _fbController = TextEditingController();
  final _zaloController = TextEditingController();

  final List<Map<String, dynamic>> _subPhoneList = [];
  final List<Map<String, dynamic>> _subEmailList = [];
  final List<Map<String, dynamic>> _jsonAdditionalList = [];
  final List<Map<String, dynamic>> _jsonSocialList = [];
  final List<ChipData> _tagList = [];

  String _dateString = "";
  int? _gender;
  final _picker = ImagePicker();
  XFile? _pickedImage;

  // Add state for API data
  List<String> _customerSourceList = [];
  List<ChipData> _tagMenu = [];
  bool _isLoadingSources = true;
  bool _isLoadingTags = true;
  
  // Default fallback data
  static const List<String> _defaultSources = [
    "Khách cũ",
    "Được giới thiệu", 
    "Trực tiếp",
    "Hotline",
    "Google",
    "Facebook",
    "Zalo",
    "Tiktok",
    "Khác"
  ];
  
  static const List<ChipData> _defaultTags = [
    ChipData('Mua để ở', 'Mua để ở'),
    ChipData('Mua đầu tư', 'Mua đầu tư'),
    ChipData('Cho thuê', 'Cho thuê'),
    ChipData('Cần thuê', 'Cần thuê'),
    ChipData('Cần bán', 'Cần bán'),
    ChipData('Chuyển nhượng', 'Chuyển nhượng'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSourcesAndTags();
  }

  // Add method to load sources and tags from API
  Future<void> _loadSourcesAndTags() async {
    try {
      // Load sources
      final sourcesResponse = await _workspaceRepository.getSourceList(
        widget.organizationId,
        widget.workspaceId,
      );
      
      // Load tags
      final tagsResponse = await _workspaceRepository.getTagList(
        widget.organizationId,
        widget.workspaceId,
      );

      if (mounted) {
        setState(() {
          // Handle sources response
          if (Helpers.isResponseSuccess(sourcesResponse) && sourcesResponse['content'] != null) {
            final apiSources = (sourcesResponse['content'] as List)
                .map((source) {
                  if (source is Map<String, dynamic>) {
                    return source['name']?.toString() ?? source['utmSource']?.toString() ?? '';
                  } else {
                    return source.toString();
                  }
                })
                .where((source) => source.isNotEmpty)
                .toList();
            _customerSourceList = apiSources.isNotEmpty ? apiSources : _defaultSources;
          } else {
            _customerSourceList = _defaultSources;
          }
          
          // Handle tags response
          if (Helpers.isResponseSuccess(tagsResponse) && tagsResponse['content'] != null) {
            final apiTags = (tagsResponse['content'] as List)
                .map((tag) {
                  String tagName = '';
                  if (tag is Map<String, dynamic>) {
                    tagName = tag['name']?.toString() ?? tag['tagName']?.toString() ?? '';
                  } else {
                    tagName = tag.toString();
                  }
                  return tagName.isNotEmpty ? ChipData(tagName, tagName) : null;
                })
                .where((chipData) => chipData != null)
                .cast<ChipData>()
                .toList();
            _tagMenu = apiTags.isNotEmpty ? apiTags : _defaultTags;
          } else {
            _tagMenu = _defaultTags;
          }
          
          _isLoadingSources = false;
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      print('Error loading sources and tags: $e');
      if (mounted) {
        setState(() {
          // Use fallback data when API fails
          _customerSourceList = _defaultSources;
          _tagMenu = _defaultTags;
          _isLoadingSources = false;
          _isLoadingTags = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh sách từ server, sử dụng dữ liệu mặc định')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _workController.dispose();
    _addressController.dispose();
    _physicalIdController.dispose();
    _customerSourceController.dispose();
    _fbController.dispose();
    _zaloController.dispose();

    // Dispose additional phone controllers
    for (var phone in _subPhoneList) {
      phone['controller'].dispose();
    }

    // Dispose additional email controllers
    for (var email in _subEmailList) {
      email['controller'].dispose();
    }

    super.dispose();
  }

  Future<void> _openImagePicker() async {
    final pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );
    if (pickedImage != null) {
      setState(() {
        _pickedImage = pickedImage;
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Prepare additional contacts
      if (_subPhoneList.isNotEmpty || _subEmailList.isNotEmpty) {
        _jsonAdditionalList.clear();
        for (var phone in _subPhoneList) {
          _jsonAdditionalList.add({
            "key": "phone",
            "name": phone["category"],
            "value": phone["controller"].text
          });
        }
        for (var email in _subEmailList) {
          _jsonAdditionalList.add({
            "key": "email",
            "name": email["category"],
            "value": email["controller"].text
          });
        }
      }

      // Prepare social media data
      if (_fbController.text.isNotEmpty) {
        _jsonSocialList.add({
          "Provider": "FACEBOOK",
          "ProfileUrl": _fbController.text,
          "Phone": _phoneController.text,
          "FullName": _nameController.text
        });
      }
      if (_zaloController.text.isNotEmpty) {
        _jsonSocialList.add({
          "Provider": "ZALO",
          "ProfileUrl": _zaloController.text,
          "Phone": _phoneController.text,
          "FullName": _nameController.text
        });
      }

      // Prepare form data
      final formData = FormData.fromMap({
        if (_pickedImage != null)
          'Avatar': await MultipartFile.fromFile(
            _pickedImage!.path,
            filename: _pickedImage!.path.split('/').last,
            contentType: MediaType("image", "jpg"),
          ),
        "FullName": _nameController.text,
        "Phone": _phoneController.text,
        "SourceId": "ce7f42cf-f10f-49d2-b57e-0c75f8463c82",
        if (_physicalIdController.text.isNotEmpty)
          "PhysicalId": _physicalIdController.text,
        if (_customerSourceController.text.isNotEmpty)
          "UtmSource": _customerSourceController.text,
        if (_emailController.text.isNotEmpty) "Email": _emailController.text,
        if (_dateString.isNotEmpty) "Dob": _dateString,
        if (_gender != null) "Gender": _gender,
        if (_addressController.text.isNotEmpty)
          "Address": _addressController.text,
        if (_workController.text.isNotEmpty) "Work": _workController.text,
        if (_jsonAdditionalList.isNotEmpty)
          "JsonAdditional": jsonEncode(_jsonAdditionalList),
        if (_jsonSocialList.isNotEmpty)
          "JsonSocial": jsonEncode(_jsonSocialList),
        if (_tagList.isNotEmpty)
          "JsonTags": jsonEncode(_tagList.map((e) => e.id).toList()),
      });

      // Create customer
      final response = await _customerRepository.createCustomer(
        widget.organizationId,
        widget.workspaceId,
        formData,
      );

      // Check for success using helper function
      if (Helpers.isResponseSuccess(response) && response['content'] != null) {
        if (!mounted) return;

        // Add customer to provider
        ref
            .read(customerListProvider.notifier)
            .addCustomer(response['content']);

        // Trigger refresh cho customers list
        ref
            .read(customerListRefreshProvider.notifier)
            .notifyCustomerListChanged();

        // Navigate back
        context.pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo khách hàng thành công')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Có lỗi xảy ra')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi tạo khách hàng')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Thêm khách hàng",
          style: TextStyle(
            color: Color(0xFF1F2329),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar picker
              Center(
                child: GestureDetector(
                  onTap: _openImagePicker,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: _pickedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  File(_pickedImage!.path),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : AppAvatar(
                                fallbackText: _nameController.text,
                                size: 90,
                              ),
                      ),
                      if (_pickedImage == null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Name field
              BorderTextField(
                controller: _nameController,
                name: "Họ và tên",
                nameHolder: "Họ và tên khách hàng",
                isRequire: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Hãy điền tên khách hàng';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Phone field
              BorderTextField(
                controller: _phoneController,
                textInputType: TextInputType.phone,
                name: "Số điện thoại",
                nameHolder: "Số điện thoại",
                isRequire: true,
                preIcon: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Liên hệ chính",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        width: 1,
                        color: const Color(0x00000000).withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Hãy điền số điện thoại khách hàng';
                  }
                  return null;
                },
              ),

              // Additional phone numbers
              AwesomeTextField(
                dataList: _subPhoneList,
                holderName: "Số điện thoại",
                textInputType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Hãy điền số điện thoại';
                  }
                  return null;
                },
                onAdded: () {
                  setState(() {
                    _subPhoneList.add({
                      'controller': TextEditingController(),
                      'category': 'Công việc',
                    });
                  });
                },
                onCategoryChanged: (e1, value) {
                  setState(() {
                    _subPhoneList.firstWhere((e2) => e2 == e1)["category"] =
                        value;
                  });
                },
                onDeleted: (e) {
                  setState(() {
                    _subPhoneList.remove(e);
                  });
                },
                buttonName: "Thêm số điện thoại",
              ),
              const SizedBox(height: 15),

              // Email field
              BorderTextField(
                controller: _emailController,
                textInputType: TextInputType.emailAddress,
                name: "Email",
                nameHolder: "Điền email",
                preIcon: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Email chính",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        width: 1,
                        color: const Color(0x00000000).withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Hãy điền email hợp lệ';
                  }
                  return null;
                },
              ),

              // Additional emails
              AwesomeTextField(
                dataList: _subEmailList,
                holderName: "Điền email",
                textInputType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null;
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Hãy điền email hợp lệ';
                  }
                  return null;
                },
                onAdded: () {
                  setState(() {
                    _subEmailList.add({
                      'controller': TextEditingController(),
                      'category': 'Công việc',
                    });
                  });
                },
                onCategoryChanged: (e1, value) {
                  setState(() {
                    _subEmailList.firstWhere((e2) => e2 == e1)["category"] =
                        value;
                  });
                },
                onDeleted: (e) {
                  setState(() {
                    _subEmailList.remove(e);
                  });
                },
                buttonName: "Thêm email",
              ),
              const SizedBox(height: 15),

              // Gender selection
              RadioGender(
                genderFunction: (g) => setState(() => _gender = g),
              ),
              const SizedBox(height: 15),

              // Tags
              const Row(
                children: [
                  Text(
                    "Nhãn",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 4),
                  Tooltip(
                    message: "Các nhãn ngăn cách nhau bởi dấu phẩy \",\"",
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: Duration(seconds: 5),
                    child: Icon(
                      Icons.help_outline,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _isLoadingTags
                  ? Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : ChipsInput<ChipData>(
                      initialValue: const [],
                      suggestionsBoxMaxHeight: 250,
                      decoration: InputDecoration(
                        hintText: "Hãy thêm nhãn",
                        hintStyle: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      suggestions: _tagMenu,
                      findSuggestions: (String query) {
                        if (query.isEmpty) {
                          return _tagMenu;
                        }
                        return _tagMenu
                            .where((tag) =>
                                tag.name.toLowerCase().contains(query.toLowerCase()))
                            .toList();
                      },
                      onChanged: (List<ChipData> data) {
                        setState(() {
                          _tagList.clear();
                          _tagList.addAll(data);
                        });
                      },
                      chipBuilder: (context, state, ChipData data) {
                        return Chip(
                          label: Text(data.name),
                          onDeleted: () => state.deleteChip(data),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: const Color(0xFFEAECF0),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelStyle: const TextStyle(
                            color: Color(0xFF1A1C1E),
                            fontSize: 14,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        );
                      },
                      suggestionBuilder: (context, state, ChipData data) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: InkWell(
                            onTap: () => state.selectSuggestion(data),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                data.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1A1C1E),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 15),

              // Birthday field
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _dobController.text =
                          DateFormat("dd/MM/yyyy").format(date);
                      _dateString = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                          .format(date);
                    });
                  }
                },
                child: BorderTextField(
                  controller: _dobController,
                  name: "Ngày Sinh",
                  nameHolder: "DD/MM/YYYY",
                  isEditAble: false,
                ),
              ),
              const SizedBox(height: 15),

              // Work field
              BorderTextField(
                controller: _workController,
                name: "Nghề nghiệp",
                nameHolder: "Nghề nghiệp của khách hàng",
              ),
              const SizedBox(height: 15),

              // Address field
              BorderTextField(
                controller: _addressController,
                name: "Nơi ở",
                nameHolder: "Nhập nơi ở khách hàng",
              ),
              const SizedBox(height: 15),

              // ID field
              BorderTextField(
                controller: _physicalIdController,
                name: "CMND/CCCD",
                nameHolder: "Nhập CMND/CCCD",
              ),
              const SizedBox(height: 15),

              // Customer source field
              InkWell(
                onTap: _isLoadingSources ? null : () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.8,
                      minChildSize: 0.8,
                      maxChildSize: 0.8,
                      expand: false,
                      builder: (context, scrollController) => Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                                top: 16.0,
                                bottom: 0.0,
                                right: 16.0,
                                left: 16.0),
                            child: const Center(
                              child: Text(
                                "Nguồn khách hàng",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _isLoadingSources
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : SingleChildScrollView(
                                    controller: scrollController,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 0.0,
                                          bottom: 16.0,
                                          right: 16.0,
                                          left: 16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ..._customerSourceList.map(
                                            (source) => Column(
                                              children: [
                                                ListTile(
                                                  title: Text(source),
                                                  onTap: () {
                                                    setState(() {
                                                      _customerSourceController.text =
                                                          source;
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                                const Divider(height: 1),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: AbsorbPointer(
                  child: BorderTextField(
                    controller: _customerSourceController,
                    name: "Nguồn khách hàng",
                    nameHolder: _isLoadingSources ? "Đang tải..." : "Chọn nguồn",
                    isEditAble: false,
                    suffixIcon: _isLoadingSources
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.keyboard_arrow_down, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Social media fields
              BorderTextField(
                controller: _fbController,
                name: "Mạng xã hội",
                nameHolder: "Nhập đường dẫn",
                preIcon: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Facebook",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 20,
                        width: 1,
                        color: const Color(0x00000000).withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  bool isValid = Uri.tryParse(value)?.hasAbsolutePath ?? false;
                  if (!isValid ||
                      (!value.contains("fb") && !value.contains("facebook"))) {
                    return 'Hãy nhập URL hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              BorderTextField(
                controller: _zaloController,
                name: "",
                nameHolder: "Nhập đường dẫn",
                preIcon: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Zalo",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Container(
                        height: 20,
                        width: 1,
                        color: const Color(0x00000000).withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  bool isValid = Uri.tryParse(value)?.hasAbsolutePath ?? false;
                  if (!isValid) {
                    return 'Hãy nhập URL hợp lệ';
                  }
                  return null;
                },
              ),
              // Extra bottom padding to ensure button is visible
              SizedBox(height: 120 + safeAreaBottom),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 24 + (bottomPadding > 0 ? 8 : 0),
            top: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: bottomPadding > 0 ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5c33f0),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              "Tiếp tục",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
