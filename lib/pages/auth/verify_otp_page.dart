import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:coka/core/theme/text_styles.dart';
import 'package:coka/core/constants/app_constants.dart';
import 'package:coka/shared/widgets/loading_button.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/api/repositories/auth_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/helpers.dart';
class VerifyOtpPage extends StatefulWidget {
  final String email;
  final String otpId;

  const VerifyOtpPage({
    super.key,
    required this.email,
    required this.otpId,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final otpController = TextEditingController();
  bool isLoading = false;
  final _authRepository = AuthRepository(ApiClient());

  Future<void> _verifyOtp() async {
    setState(() => isLoading = true);

    try {
      final response = await _authRepository.verifyOtp(
        widget.otpId,
        otpController.text,
      );

      if (!mounted) return;

      if (Helpers.isResponseSuccess(response)) {
        // Lưu token vào secure storage
        await ApiClient.storage.write(
          key: 'access_token',
          value: response['metadata']['accessToken'],
        );
        await ApiClient.storage.write(
          key: 'refresh_token',
          value: response['metadata']['refreshToken'],
        );

        if (!mounted) return;

        // Kiểm tra nếu fullName trùng với email thì chuyển đến trang hoàn tất đăng ký
        if (response['metadata']['fullName'] == response['metadata']['email']) {
          context.go('/complete-profile');
        } else {
          // Chuyển đến trang chủ và xóa stack điều hướng
          context.go('/organization/default');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Mã OTP không hợp lệ'),
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

  Future<void> _resendOtp() async {
    try {
      final response = await _authRepository.resendOtp(widget.otpId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Helpers.isResponseSuccess(response)
                ? 'Đã gửi lại mã OTP'
                : (response['message'] ?? 'Không thể gửi lại mã OTP'),
          ),
          backgroundColor:
              response['success'] == true ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể kết nối tới server'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Image.asset(
                '${AppConstants.imagePath}/verify_icon.png',
                height: 80,
              ),
              const SizedBox(height: 14),
              const Text(
                'Đăng nhập bằng Email',
                style: TextStyles.heading1,
              ),
              const SizedBox(height: 6),
              Text(
                'Vui lòng kiểm tra mail để điền mã xác thực',
                style: TextStyles.title.copyWith(
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: otpController,
                autoFocus: true,
                keyboardType: TextInputType.number,
                cursorColor: AppColors.primary,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 50,
                  fieldWidth: 45,
                  activeFillColor: AppColors.backgroundSecondary,
                  selectedFillColor: AppColors.backgroundSecondary,
                  inactiveFillColor: AppColors.backgroundSecondary,
                  activeColor: Colors.transparent,
                  inactiveColor: Colors.transparent,
                  selectedColor: AppColors.primary,
                  borderWidth: 1,
                ),
                enableActiveFill: true,
                onCompleted: (value) {
                  if (!isLoading) {
                    _verifyOtp();
                  }
                },
                onChanged: (value) {},
                boxShadows: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LoadingButton(
                text: 'Tiếp tục',
                onPressed: _verifyOtp,
                isLoading: isLoading,
                width: double.infinity,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _resendOtp,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Chưa nhận được mail? ',
                        style: TextStyles.body.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      TextSpan(
                        text: 'Ấn vào để gửi lại',
                        style: TextStyles.body.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  // Xử lý quay lại trang đăng nhập
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: AppColors.text,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Trở lại trang đăng nhập',
                      style: TextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
