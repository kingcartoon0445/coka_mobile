import '../api_client.dart';
import 'package:dio/dio.dart';

class ReportRepository {
  final ApiClient _apiClient;
  static const String _baseUrl = '/api/v1';

  ReportRepository(this._apiClient);

  Future<Map<String, dynamic>> getSummaryData(
    String organizationId,
    String workspaceId,
    String startDate,
    String endDate,
  ) async {
    final queryParams = {
      'workspaceId': workspaceId,
      'startDate': startDate,
      'endDate': endDate,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/workspace/report/summary',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getStatisticsByUtmSource(
    String organizationId,
    String workspaceId,
    String startDate,
    String endDate,
  ) async {
    final queryParams = {
      'workspaceId': workspaceId,
      'startDate': startDate,
      'endDate': endDate,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/crm/report/getstatisticsbyutmsource',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getStatisticsByDataSource(
    String organizationId,
    String workspaceId,
    String startDate,
    String endDate,
  ) async {
    final queryParams = {
      'workspaceId': workspaceId,
      'startDate': startDate,
      'endDate': endDate,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/crm/report/getstatisticsbydatasource',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getStatisticsByTag(
    String organizationId,
    String workspaceId,
    String startDate,
    String endDate,
  ) async {
    final queryParams = {
      'workspaceId': workspaceId,
      'startDate': startDate,
      'endDate': endDate,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/crm/report/getstatisticsbytag',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getChartByOverTime(
    String organizationId,
    String workspaceId,
    String startDate,
    String endDate,
    String type,
  ) async {
    final queryParams = {
      'workspaceId': workspaceId,
      'startDate': startDate,
      'endDate': endDate,
      'type': type,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/crm/report/getstatisticsovertime',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getChartByRating(
    String organizationId,
    String workspaceId,
    String startDate,
    String endDate,
  ) async {
    final queryParams = {
      'workspaceId': workspaceId,
      'startDate': startDate,
      'endDate': endDate,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/crm/report/getstatisticsbyrating',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getStatisticsByUser(
    String organizationId,
    String workspaceId,
    String startDate,
    String endDate,
  ) async {
    final queryParams = {
      'workspaceId': workspaceId,
      'startDate': startDate,
      'endDate': endDate,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/crm/report/getstatisticsbyuser',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getStatisticsByStageGroup(
    String organizationId,
    String workspaceId, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _apiClient.dio.get(
      '$_baseUrl/crm/report/getstatisticsbystagegroup',
      queryParameters: queryParameters,
      options: Options(headers: {
        'organizationId': organizationId,
      }),
    );
    return response.data;
  }
}
