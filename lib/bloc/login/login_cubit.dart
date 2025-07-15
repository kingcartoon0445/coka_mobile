// lib/state/login/login_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/api/repositories/auth_repository.dart';
import 'package:coka/bloc/login/login_state.dart';
import 'package:coka/core/utils/helpers.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;

  LoginCubit()
      : _authRepository = AuthRepository(ApiClient()),
        super(const LoginState());

  void initialize() async {
    // Nếu cần khởi tạo gì thêm trước khi login
  }

  Future<void> login(String email) async {
    emit(state.copyWith(status: LoginStatus.loading, error: null));

    try {
      final response = await _authRepository.login(email);

      if (response['content']?['otpId'] != null) {
        emit(state.copyWith(
          status: LoginStatus.otpRequired,
          email: email,
          otpId: response['content']['otpId'],
        ));
      } else {
        emit(state.copyWith(
          status: LoginStatus.error,
          error: response['message'] ?? 'Đăng nhập thất bại',
        ));
      }
    } catch (_) {
      emit(state.copyWith(status: LoginStatus.error, error: 'Không thể kết nối đến server'));
    }
  }

  Future<void> loginWithGoogle() async {
    emit(state.copyWith(status: LoginStatus.loading, error: null));

    try {
      final response = await _authRepository.loginWithGoogle(forceNewAccount: true);

      if (Helpers.isResponseSuccess(response)) {
        await ApiClient.storage
            .write(key: 'access_token', value: response['content']['accessToken']);
        await ApiClient.storage
            .write(key: 'refresh_token', value: response['content']['refreshToken']);
        await ApiClient.storage
            .write(key: 'default_organization_id', value: response['content']['organizationId']);

        emit(state.copyWith(
          status: LoginStatus.success,
          organizationId: response['content']['organizationId'],
        ));
      } else {
        emit(state.copyWith(status: LoginStatus.error, error: response['message']));
      }
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.error, error: e.toString()));
    }
  }

  Future<void> loginWithFacebook() async {
    emit(state.copyWith(status: LoginStatus.loading, error: null));

    try {
      final response = await _authRepository.loginWithFacebook();

      if (Helpers.isResponseSuccess(response)) {
        await ApiClient.storage
            .write(key: 'access_token', value: response['content']['accessToken']);
        await ApiClient.storage
            .write(key: 'refresh_token', value: response['content']['refreshToken']);
        await ApiClient.storage
            .write(key: 'default_organization_id', value: response['content']['organizationId']);

        emit(state.copyWith(
          status: LoginStatus.success,
          organizationId: response['content']['organizationId'],
        ));
      } else {
        emit(state.copyWith(status: LoginStatus.error, error: response['message']));
      }
    } catch (e) {
      emit(state.copyWith(status: LoginStatus.error, error: e.toString()));
    }
  }
}
