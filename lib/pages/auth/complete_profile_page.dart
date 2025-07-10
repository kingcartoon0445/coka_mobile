import 'package:flutter/material.dart';
import 'package:coka/core/theme/text_styles.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/shared/widgets/loading_button.dart';
import 'package:coka/api/repositories/auth_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:coka/core/utils/helpers.dart';
import 'package:dio/dio.dart';
import 'package:coka/shared/widgets/custom_alert_dialog.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _workplaceController = TextEditingController();
  String _selectedGender = 'Nam';
  bool _isLoading = false;
  final _authRepository = AuthRepository(ApiClient());
  File? _selectedAvatar;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final response = await _authRepository.getUserInfo();
      if (Helpers.isResponseSuccess(response)) {
        final metadata = response['content'];
        setState(() {
          _nameController.text = metadata['fullName'] ?? '';
          _emailController.text = metadata['email'] ?? '';
          _phoneController.text = metadata['phone'] ?? '';
          if (metadata['dob'] != null) {
            final DateTime dob = DateTime.parse(metadata['dob']);
            _birthdayController.text = "${dob.day}/${dob.month}/${dob.year}";
          }
          _workplaceController.text = metadata['address'] ?? '';
          
          // Cập nhật avatar hiện tại
          _currentAvatarUrl = metadata['avatar'];
          
          // Cập nhật giới tính
          if (metadata['gender'] != null) {
            switch (metadata['gender']) {
              case 0:
                _selectedGender = 'Nữ';
                break;
              case 1:
                _selectedGender = 'Nam';
                break;
              default:
                _selectedGender = 'Khác';
                break;
            }
          }
        });
      }
    } catch (e) {
      // Xử lý lỗi nếu cần
      print('Lỗi khi tải thông tin người dùng: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải thông tin người dùng')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authRepository.updateProfile({
        'fullName': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'dob': _birthdayController.text.isNotEmpty
            ? Helpers.convertToISOString(_birthdayController.text)
            : null,
        'gender': _selectedGender == "Nam"
            ? 1
            : _selectedGender == "Nữ"
                ? 0
                : 2,
        'address': _workplaceController.text,
      }, avatar: _selectedAvatar);

      if (!mounted) return;
      
      if (Helpers.isResponseSuccess(response)) {
        showCustomAlert(
          context: context,
          title: 'Thành công',
          message: 'Thông tin của bạn đã được cập nhật thành công.',
          confirmText: 'Đóng',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          showCancelButton: false,
          onConfirm: () {
            Navigator.of(context).pop(); // Quay lại trang trước đó
          },
        );
      } else {
        Helpers.showErrorSnackBar(context, response['message'] ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      if (!mounted) return;

      final message = e is DioException ? e.errorMessage : e.toString();
      Helpers.showErrorSnackBar(context, message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedAvatar = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      print('Lỗi chọn ảnh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể chọn ảnh, vui lòng thử lại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Cập nhật thông tin',
          style: TextStyles.heading1,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.backgroundSecondary,
                            shape: BoxShape.circle,
                          ),
                          child: _selectedAvatar != null
                              ? ClipOval(
                                  child: Image.file(
                                    _selectedAvatar!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        _currentAvatarUrl!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person_outline,
                                            size: 40,
                                            color: AppColors.text,
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const CircularProgressIndicator(
                                            strokeWidth: 2,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_outline,
                                      size: 40,
                                      color: AppColors.text,
                                    ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 20,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên*',
                    hintText: 'Họ và tên',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Email*',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: 'Nhập số điện thoại',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthdayController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: 'Ngày sinh',
                    hintText: 'DD/MM/YYYY',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Giới Tính',
                  style: TextStyles.body,
                ),
                Row(
                  children: [
                    Radio(
                      value: 'Nam',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value.toString());
                      },
                    ),
                    const Text('Nam'),
                    const SizedBox(width: 16),
                    Radio(
                      value: 'Nữ',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value.toString());
                      },
                    ),
                    const Text('Nữ'),
                    const SizedBox(width: 16),
                    Radio(
                      value: 'Khác',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() => _selectedGender = value.toString());
                      },
                    ),
                    const Text('Khác'),
                  ],
                ),
                TextFormField(
                  controller: _workplaceController,
                  decoration: InputDecoration(
                    labelText: 'Nơi làm việc',
                    hintText: 'Chọn địa chỉ',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                LoadingButton(
                  text: 'Cập nhật',
                  onPressed: _updateProfile,
                  isLoading: _isLoading,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
