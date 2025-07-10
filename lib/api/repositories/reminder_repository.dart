import 'package:dio/dio.dart';
import 'package:coka/models/reminder.dart';
import 'package:coka/constants/reminder_constants.dart';
import 'package:coka/api/api_client.dart';

class ReminderRepository {
  final ApiClient _apiClient;
  final Dio _calendarDio;

  ReminderRepository(this._apiClient) : _calendarDio = _createCalendarDio();

  static Dio _createCalendarDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ReminderConstants.calendarBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
    ));

    // Thêm interceptor để có token từ ApiClient
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Lấy token từ secure storage giống như ApiClient
          final token = await ApiClient.storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }

  Future<List<Reminder>> getScheduleList({
    required String organizationId,
    String? workspaceId,
    String? contactId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'organizationId': organizationId,
        if (workspaceId != null) 'workspaceId': workspaceId,
        if (contactId != null) 'contactId': contactId,
      };

      final response = await _calendarDio.get(
        ReminderConstants.scheduleEndpoint,
        queryParameters: queryParams,
      );

      if (response.data['Status'] == 'Success') {
        final List<dynamic> data = response.data['Data'] ?? [];
        return data.map((json) => Reminder.fromJson(json)).toList();
      }
      throw Exception(response.data['Message'] ?? 'Unknown error');
    } catch (e) {
      if (e is DioException) {
        throw Exception('Error fetching reminders: ${e.message}');
      }
      throw Exception('Error fetching reminders: $e');
    }
  }

  Future<Reminder> getScheduleDetail(String id) async {
    try {
      final response = await _calendarDio.get(
        '${ReminderConstants.scheduleEndpoint}/$id',
      );

      if (response.data['Status'] == 'Success') {
        return Reminder.fromJson(response.data['Data']);
      }
      throw Exception(response.data['Message'] ?? 'Unknown error');
    } catch (e) {
      if (e is DioException) {
        throw Exception('Error fetching reminder detail: ${e.message}');
      }
      throw Exception('Error fetching reminder detail: $e');
    }
  }

  Future<bool> createSchedule(Map<String, dynamic> data) async {
    try {
      final response = await _calendarDio.post(
        ReminderConstants.scheduleEndpoint,
        data: data,
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Error creating reminder: ${e.message}');
      }
      throw Exception('Error creating reminder: $e');
    }
  }

  Future<bool> updateSchedule(Map<String, dynamic> data) async {
    try {
      final response = await _calendarDio.put(
        ReminderConstants.scheduleEndpoint,
        data: data,
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Error updating reminder: ${e.message}');
      }
      throw Exception('Error updating reminder: $e');
    }
  }

  Future<bool> deleteSchedule(String id) async {
    try {
      final response = await _calendarDio.delete(
        '${ReminderConstants.scheduleEndpoint}/$id',
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Error deleting reminder: ${e.message}');
      }
      throw Exception('Error deleting reminder: $e');
    }
  }

  Future<bool> markScheduleAsDone({
    required String id,
    required bool isDone,
  }) async {
    try {
      final response = await _calendarDio.patch(
        '${ReminderConstants.scheduleEndpoint}/mark-as-done',
        data: {
          'ScheduleId': id,
          'IsDone': isDone,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        throw Exception('Error marking reminder as done: ${e.message}');
      }
      throw Exception('Error marking reminder as done: $e');
    }
  }
} 