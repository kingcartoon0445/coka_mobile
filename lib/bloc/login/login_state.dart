// lib/state/login/login_state.dart

import 'package:equatable/equatable.dart';

enum LoginStatus { initial, loading, success, otpRequired, error }

class LoginState extends Equatable {
  final LoginStatus status;
  final String? email;
  final String? otpId;
  final String? error;
  final String? organizationId;

  const LoginState({
    this.status = LoginStatus.initial,
    this.email,
    this.otpId,
    this.error,
    this.organizationId,
  });

  LoginState copyWith({
    LoginStatus? status,
    String? email,
    String? otpId,
    String? error,
    String? organizationId,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      otpId: otpId ?? this.otpId,
      error: error ?? this.error,
      organizationId: organizationId ?? this.organizationId,
    );
  }

  @override
  List<Object?> get props => [status, email, otpId, error, organizationId];
}
