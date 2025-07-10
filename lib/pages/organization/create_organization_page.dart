import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:coka/api/repositories/organization_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/shared/widgets/custom_input.dart';
import 'package:coka/shared/widgets/avatar_picker_widget.dart';
import 'package:coka/core/utils/helpers.dart';
import 'dart:io';

class CreateOrganizationPage extends StatefulWidget {
  const CreateOrganizationPage({super.key});

  @override
  State<CreateOrganizationPage> createState() => _CreateOrganizationPageState();
}

class _CreateOrganizationPageState extends State<CreateOrganizationPage> {
  final _organizationRepository = OrganizationRepository(ApiClient());
  bool _isLoading = false;
  
  // Form fields
  File? _avatarFile;
  String _name = '';
  String _description = '';
  String _website = '';
  String _address = '';
  String _companyName = '';
  String _field = '';
  String _hotline = '';

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_name.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập tên tổ chức');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final formData = FormData();
      
      // Add avatar if selected
      if (_avatarFile != null) {
        formData.files.add(
          MapEntry(
            'Avatar',
            await MultipartFile.fromFile(_avatarFile!.path, filename: 'avatar.jpg'),
          ),
        );
      }

      // Add form data
      final data = {
        'Name': _name.trim(),
        'Description': _description.trim(),
        'Website': _website.trim(),
        'Address': _address.trim(),
        'CompanyName': _companyName.trim(),
        'FieldOfActivity': _field.trim(),
        'Hotline': _hotline.trim(),
      };

      data.forEach((key, value) {
        if (value.isNotEmpty) {
          formData.fields.add(MapEntry(key, value));
        }
      });

      final response = await _organizationRepository.createOrganization(formData);

      if (!mounted) return;

      print('Create organization response: $response');

      if (Helpers.isResponseSuccess(response)) {
        final organizationId = response['content']['id'];
        _showSnackBar('Bạn đã tạo tổ chức $_name thành công');
        
        // Navigate to the new organization
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.go('/organization/$organizationId');
          }
        });
      } else {
        // Hiển thị thông báo lỗi từ API
        final errorMessage = response['message'] ?? 'Tạo tổ chức thất bại';
        _showSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Có lỗi xảy ra khi tạo tổ chức';
        
        // Xử lý DioException để lấy response error
        if (e is DioException && e.response != null) {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic> && responseData['message'] != null) {
            errorMessage = responseData['message'];
          }
        }
        
        _showSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tạo tổ chức',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE4E7EC),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Section
            Center(
              child: AvatarPickerWidget(
                avatarFile: _avatarFile,
                onAvatarSelected: (file) => setState(() => _avatarFile = file),
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields
            CustomInput(
              label: 'Tên tổ chức',
              placeholder: 'Tên tổ chức',
              value: _name,
              onChanged: (value) => setState(() => _name = value),
              isRequired: true,
            ),
            const SizedBox(height: 16),

            CustomInput(
              label: 'Mô tả',
              placeholder: 'Mô tả',
              value: _description,
              onChanged: (value) => setState(() => _description = value),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            CustomInput(
              label: 'Trang web',
              placeholder: 'Nhập website',
              value: _website,
              onChanged: (value) => setState(() => _website = value),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            CustomInput(
              label: 'Địa chỉ',
              placeholder: 'Nhập địa chỉ',
              value: _address,
              onChanged: (value) => setState(() => _address = value),
            ),
            const SizedBox(height: 16),

            CustomInput(
              label: 'Tên công ty',
              placeholder: 'Nhập tên công ty',
              value: _companyName,
              onChanged: (value) => setState(() => _companyName = value),
            ),
            const SizedBox(height: 16),

            CustomInput(
              label: 'Lĩnh vực hoạt động',
              placeholder: 'Lĩnh vực hoạt động',
              value: _field,
              onChanged: (value) => setState(() => _field = value),
            ),
            const SizedBox(height: 16),

            CustomInput(
              label: 'Hotline',
              placeholder: 'Hotline',
              value: _hotline,
              onChanged: (value) => setState(() => _hotline = value),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Hoàn thành',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 