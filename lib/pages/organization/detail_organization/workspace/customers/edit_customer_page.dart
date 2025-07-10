import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../../providers/customer_provider.dart';
import '../../../../../shared/widgets/chip_input.dart';
import '../../../../../shared/widgets/radio_gender.dart';
import '../../../../../shared/widgets/border_textfield.dart';
import '../../../../../shared/widgets/awesome_textfield.dart';
import '../../../../../shared/widgets/avatar_widget.dart';
import '../../../../../core/utils/helpers.dart';

const customerSourceList = [
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

const tagMenu = <ChipData>[
  ChipData('Mua để ở', 'Mua để ở'),
  ChipData('Mua đầu tư', 'Mua đầu tư'),
  ChipData('Cho thuê', 'Cho thuê'),
  ChipData('Cần thuê', 'Cần thuê'),
  ChipData('Cần bán', 'Cần bán'),
  ChipData('Chuyển nhượng', 'Chuyển nhượng'),
];

class EditCustomerPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final String customerId;
  final Map<String, dynamic> customerData;

  const EditCustomerPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.customerId,
    required this.customerData,
  });

  @override
  ConsumerState<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends ConsumerState<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();

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
  String? _avatarCacheKey; // Thêm cache key cho avatar

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final data = widget.customerData;
    _nameController.text = data['fullName'] ?? '';
    _emailController.text = data['email'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _workController.text = data['work'] ?? '';
    _addressController.text = data['address'] ?? '';
    _physicalIdController.text = data['physicalId'] ?? '';
    _customerSourceController.text =
        data['source']?.last?['utmSource'] ?? data['utmSource'] ?? '';
    _gender = data['gender'];

    if (data['dob'] != null) {
      final date = DateTime.parse(data['dob']);
      _dobController.text = DateFormat("dd/MM/yyyy").format(date);
      _dateString = data['dob'];
    }

    // Initialize additional contacts
    if (data['additional'] != null) {
      final additionalContacts = data['additional'] as List;
      for (var contact in additionalContacts) {
        if (contact['key'] == 'phone') {
          _subPhoneList.add({
            'controller': TextEditingController(text: contact['value']),
            'category': contact['name'],
            'id': contact['id']
          });
        } else if (contact['key'] == 'email') {
          _subEmailList.add({
            'controller': TextEditingController(text: contact['value']),
            'category': contact['name'],
            'id': contact['id']
          });
        }
      }
    } else if (data['jsonAdditional'] != null) {
      final additionalContacts = jsonDecode(data['jsonAdditional']) as List;
      for (var contact in additionalContacts) {
        if (contact['key'] == 'phone') {
          _subPhoneList.add({
            'controller': TextEditingController(text: contact['value']),
            'category': contact['name']
          });
        } else if (contact['key'] == 'email') {
          _subEmailList.add({
            'controller': TextEditingController(text: contact['value']),
            'category': contact['name']
          });
        }
      }
    }

    // Initialize social media
    if (data['social'] != null) {
      final socialMedia = data['social'] as List;
      for (var social in socialMedia) {
        if (social['provider'] == 'FACEBOOK') {
          _fbController.text = social['profileUrl'] ?? '';
        } else if (social['provider'] == 'ZALO') {
          _zaloController.text = social['profileUrl'] ?? '';
        }
      }
    } else if (data['jsonSocial'] != null) {
      final socialMedia = jsonDecode(data['jsonSocial']) as List;
      for (var social in socialMedia) {
        if (social['Provider'] == 'FACEBOOK') {
          _fbController.text = social['ProfileUrl'] ?? '';
        } else if (social['Provider'] == 'ZALO') {
          _zaloController.text = social['ProfileUrl'] ?? '';
        }
      }
    }

    // Initialize tags
    if (data['tags'] != null) {
      final tags = data['tags'] as List;
      _tagList.addAll(tags.map((tag) => ChipData(tag, tag)).toList());
    } else if (data['jsonTags'] != null) {
      final tags = jsonDecode(data['jsonTags']) as List;
      _tagList.addAll(tags.map((tag) => ChipData(tag, tag)).toList());
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

    for (var phone in _subPhoneList) {
      phone['controller'].dispose();
    }

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
      _jsonAdditionalList.clear();
      for (var phone in _subPhoneList) {
        if (!(phone['isDelete'] ?? false)) {
          _jsonAdditionalList.add({
            "id": phone["id"],
            "key": "phone",
            "name": phone["category"],
            "value": phone["controller"].text
          });
        }
      }
      for (var email in _subEmailList) {
        if (!(email['isDelete'] ?? false)) {
          _jsonAdditionalList.add({
            "id": email["id"],
            "key": "email",
            "name": email["category"],
            "value": email["controller"].text
          });
        }
      }

      // Prepare social media data
      _jsonSocialList.clear();
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

      // Update customer
      await ref
          .read(customerDetailProvider(widget.customerId).notifier)
          .updateCustomer(
            widget.organizationId,
            widget.workspaceId,
            formData,
          );

      if (!mounted) return;

      // Xóa cache avatar cũ và cập nhật cache key nếu có avatar mới
      if (_pickedImage != null) {
        await Helpers.clearImageCache(widget.customerData['avatar']);
        setState(() {
          _avatarCacheKey = DateTime.now().millisecondsSinceEpoch.toString();
        });
      }

      // Trigger refresh cho customers list
      ref
          .read(customerListRefreshProvider.notifier)
          .notifyCustomerListChanged();

      // Navigate back
      context.pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật khách hàng thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Chỉnh sửa khách hàng",
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
                                fallbackText: widget.customerData['name'] ?? _nameController.text,
                                imageUrl: widget.customerData['avatar'],
                                size: 90,
                                cacheKey: _avatarCacheKey,
                              ),
                      ),
                      if (_pickedImage == null && widget.customerData['avatar'] == null)
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
                initGender: _gender,
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
              ChipsInput<ChipData>(
                initialValue: _tagList,
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
                suggestions: tagMenu,
                findSuggestions: (String query) {
                  if (query.isEmpty) {
                    return tagMenu;
                  }
                  return tagMenu
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
                  return ListTile(
                    key: ObjectKey(data),
                    title: Text(data.name),
                    onTap: () => state.selectSuggestion(data),
                  );
                },
              ),
              const SizedBox(height: 15),

              // Birthday field
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateString.isNotEmpty
                        ? DateTime.parse(_dateString)
                        : DateTime.now(),
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
                onTap: () {
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
                            child: SingleChildScrollView(
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
                                    ...customerSourceList.map(
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
                    nameHolder: "Chọn nguồn",
                    isEditAble: false,
                    suffixIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
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
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          onPressed: _onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5c33f0),
            minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 42),
            maximumSize: Size(MediaQuery.of(context).size.width * 0.7, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "Cập nhật",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
