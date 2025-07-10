import 'dart:io';

import 'package:coka/api/api_path.dart';
import 'package:dio/dio.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http_parser/http_parser.dart';

import '../api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final _googleSignIn = GoogleSignIn();

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> login(String userName) async {
    return await _apiClient.post(
      ApiPath.login,
      data: {'userName': userName},
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String otpId, String code) async {
    return await _apiClient.post(
      ApiPath.verifyOtp,
      data: {'otpId': otpId, 'code': code},
    );
  }

  Future<Map<String, dynamic>> resendOtp(String otpId) async {
    return await _apiClient.post(
      ApiPath.resendOtp,
      data: {'otpId': otpId},
    );
  }

  Future<Map<String, dynamic>> socialLogin(String accessToken, String provider) async {
    return await _apiClient.post(
      ApiPath.socialLogin,
      data: {
        'accessToken': accessToken,
        'provider': provider,
      },
    );
  }

  Future<Map<String, dynamic>> loginWithGoogle({bool forceNewAccount = false}) async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      forceCodeForRefreshToken: true,
    );

    if (forceNewAccount) {
      await googleSignIn.signOut();
    }

    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Đăng nhập Google bị hủy');

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      if (accessToken == null) throw Exception('Không thể lấy token Google');

      return await socialLogin(accessToken, 'google');
    } catch (e) {
      print('Chi tiết lỗi Google Sign-In: $e');
      throw Exception('Lỗi đăng nhập Google: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> loginWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['pages_show_list'],
      );

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken?.tokenString;
        if (accessToken == null) {
          throw Exception('Không thể lấy token Facebook');
        }
        return await socialLogin(accessToken, 'facebook');
      } else if (result.status == LoginStatus.cancelled) {
        throw Exception('Đăng nhập Facebook bị hủy');
      } else {
        throw Exception('Đăng nhập Facebook thất bại');
      }
    } catch (e) {
      print('Chi tiết lỗi Facebook Sign-In: $e');
      throw Exception('Lỗi đăng nhập Facebook: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      return await _apiClient.get(ApiPath.profileDetail);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await _apiClient.get(ApiPath.profileDetail);
  }

  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data, {
    File? avatar,
  }) async {
    try {
      final formData = FormData();

      data.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      if (avatar != null) {
        final fileName = avatar.path.split('/').last;
        final mimeType = fileName.endsWith('.png')
            ? 'image/png'
            : fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')
                ? 'image/jpeg'
                : 'image/jpg';

        formData.files.add(MapEntry(
          'avatar',
          await MultipartFile.fromFile(
            avatar.path,
            filename: fileName,
            contentType: MediaType.parse(mimeType),
          ),
        ));
      }

      return await _apiClient.patch(
        ApiPath.profileUpdate,
        data: formData,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiClient.logout();
  }
}
