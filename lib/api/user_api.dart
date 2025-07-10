import 'api_client.dart';
import 'repositories/user_repository.dart';

class UserApi {
  final UserRepository _userRepository;

  UserApi() : _userRepository = UserRepository(ApiClient());

  Future updateFcmToken(data) async {
    return await _userRepository.updateFcmToken(
      deviceId: data['deviceId'],
      fcmToken: data['fcmToken'],
      status: data['status'],
    );
  }

  Future<String> getDeviceId() async {
    return await _userRepository.getDeviceId();
  }
}
