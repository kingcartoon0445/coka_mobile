// lib/pages/auth/login_screen.dart

import 'dart:io' show Platform;

import 'package:coka/api/api_client.dart';
import 'package:coka/bloc/login/login_cubit.dart';
import 'package:coka/bloc/login/login_state.dart';
import 'package:coka/core/constants/app_constants.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/core/theme/text_styles.dart';
import 'package:coka/pages/auth/verify_otp_page.dart';
import 'package:coka/shared/widgets/loading_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginPage> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String baseUrl = ApiClient.baseUrl;
  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Email không hợp lệ';
    return null;
  }

  Future<void> _handleSubmit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginCubit>().login(emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.status == LoginStatus.success && state.organizationId != null) {
          context.go('/organization/${state.organizationId}');
        }

        if (state.status == LoginStatus.otpRequired && state.otpId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyOtpPage(
                email: state.email!,
                otpId: state.otpId!,
              ),
            ),
          );
        }

        if (state.status == LoginStatus.error && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == LoginStatus.loading;

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
                    // 👇 Popup menu debug chọn baseURL
                    PopupMenuButton<String>(
                      enabled: kDebugMode,
                      color: Colors.white,
                      onSelected: (value) async {
                        await ApiClient().setBaseUrl(value);
                        setState(() {
                          baseUrl = value;
                        });
                      },
                      itemBuilder: (context) {
                        return ['https://api.coka.ai', 'https://dev.coka.ai'].map((base) {
                          return PopupMenuItem<String>(
                            value: base,
                            child: Row(
                              children: [
                                Icon(
                                  base == baseUrl
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: base == baseUrl ? Colors.blueAccent : Colors.grey,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    base,
                                    style: TextStyle(
                                      fontWeight:
                                          base == baseUrl ? FontWeight.bold : FontWeight.normal,
                                      color: base == baseUrl ? Colors.blueAccent : Colors.black87,
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
                    const Text('Đăng nhập', style: TextStyles.heading1),
                    const SizedBox(height: 8),
                    const Text('Chào mừng đến với ứng dụng COKA', style: TextStyles.body),
                    const SizedBox(height: 28),

                    // Input Email
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyles.label,
                            children: [
                              TextSpan(text: 'Email '),
                              TextSpan(text: '*', style: TextStyle(color: AppColors.error)),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    LoadingButton(
                      text: 'Đăng nhập',
                      onPressed: () => _handleSubmit(context),
                      isLoading: isLoading,
                      width: double.infinity,
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Hoặc đăng nhập bằng',
                            style: TextStyles.body.copyWith(color: Colors.grey.shade700),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildSocialButton(
                      context,
                      'google_icon.png',
                      'Google',
                      onPressed: () => context.read<LoginCubit>().loginWithGoogle(),
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 14),
                    _buildSocialButton(
                      context,
                      'facebook_icon.png',
                      'Facebook',
                      onPressed: () => context.read<LoginCubit>().loginWithFacebook(),
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 14),
                    if (Platform.isIOS) _buildSocialButton(context, 'apple_icon.png', 'Apple'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    String iconName,
    String label, {
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
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
