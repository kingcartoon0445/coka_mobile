import 'dart:io' show Platform;

import 'package:coka/api/api_client.dart';
import 'package:coka/api/repositories/auth_repository.dart';
import 'package:coka/core/constants/app_constants.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/core/theme/text_styles.dart';
import 'package:coka/core/utils/helpers.dart';
import 'package:coka/pages/auth/verify_otp_page.dart';
import 'package:coka/shared/widgets/loading_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

List<String> apiBaseOptions = ['https://api.coka.ai', 'https://dev.coka.ai'];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool isFacebookLoading = false;
  final _authRepository = AuthRepository(ApiClient());

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await _authRepository.login(emailController.text);

      if (!mounted) return;

      if (response['content']?['otpId'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpPage(
              email: emailController.text,
              otpId: response['content']['otpId'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Đã có lỗi xảy ra'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể kết nối tới server'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => isGoogleLoading = true);

    try {
      final response = await _authRepository.loginWithGoogle(forceNewAccount: true);

      if (!mounted) return;

      if (Helpers.isResponseSuccess(response)) {
        // Lưu token vào secure storage
        await ApiClient.storage.write(
          key: 'access_token',
          value: response['content']['accessToken'],
        );
        await ApiClient.storage.write(
          key: 'refresh_token',
          value: response['content']['refreshToken'],
        );

        if (!mounted) return;
        context.go('/organization/default');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Đăng nhập không thành công'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => isGoogleLoading = false);
    }
  }

  Future<void> _handleFacebookLogin() async {
    setState(() => isFacebookLoading = true);

    try {
      final response = await _authRepository.loginWithFacebook();

      if (!mounted) return;

      if (Helpers.isResponseSuccess(response)) {
        // Lưu token vào secure storage
        await ApiClient.storage.write(
          key: 'access_token',
          value: response['content']['accessToken'],
        );
        await ApiClient.storage.write(
          key: 'refresh_token',
          value: response['content']['refreshToken'],
        );

        if (!mounted) return;
        context.go('/organization/default');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Đăng nhập không thành công'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => isFacebookLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0, left: 16, right: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                PopupMenuButton<String>(
                  enabled: kDebugMode,
                  color: Colors.white,
                  onSelected: (value) async {
                    await ApiClient().setBaseUrl(value);
                    // ApiClient().baseUrl = value;

                    //  final baseUrl = await getBaseUrl();
                  },
                  itemBuilder: (context) {
                    return apiBaseOptions.map((base) {
                      return PopupMenuItem<String>(
                        value: base,
                        child: Row(
                          children: [
                            Icon(
                              base == ApiClient.baseUrl
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: base == ApiClient.baseUrl ? Colors.blueAccent : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                base,
                                style: TextStyle(
                                  fontWeight: base == ApiClient.baseUrl
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: base == ApiClient.baseUrl
                                      ? Colors.blueAccent
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Image.asset(
                    '${AppConstants.imagePath}/coka_login.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đăng nhập',
                  style: TextStyles.heading1,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chào mừng đến với ứng dụng COKA',
                  style: TextStyles.body,
                ),
                const SizedBox(height: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyles.label,
                        children: [
                          TextSpan(
                            text: 'Email ',
                          ),
                          TextSpan(
                            text: '*',
                            style: TextStyle(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Nhập Email của bạn',
                        filled: true,
                        fillColor: AppColors.backgroundSecondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LoadingButton(
                  text: 'Đăng nhập',
                  onPressed:
                      // () {
                      //   print("api: ${ApiClient.baseUrl}");
                      // },
                      _handleLogin,
                  isLoading: isLoading,
                  width: double.infinity,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Hoặc đăng nhập bằng',
                        style: TextStyles.body.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSocialButton(
                      'google_icon.png',
                      'Google',
                      onPressed: _handleGoogleLogin,
                      isLoading: isGoogleLoading,
                    ),
                    const SizedBox(height: 14),
                    _buildSocialButton(
                      'facebook_icon.png',
                      'Facebook',
                      onPressed: _handleFacebookLogin,
                      isLoading: isFacebookLoading,
                    ),
                    const SizedBox(height: 14),
                    if (Platform.isIOS) _buildSocialButton('apple_icon.png', 'Apple'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String iconName, String label,
      {VoidCallback? onPressed, bool isLoading = false}) {
    return FilledButton.tonal(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          else
            Image.asset(
              '${AppConstants.imagePath}/$iconName',
              height: 24,
              width: 24,
            ),
          Expanded(
            child: Text(
              'Đăng nhập bằng $label',
              style: TextStyles.body,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
