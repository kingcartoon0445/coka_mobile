import '../api_client.dart';
import 'package:dio/dio.dart';

class TeamRepository {
  final ApiClient _apiClient;
  static const String _baseUrl = '/api/v1/crm';

  TeamRepository(this._apiClient);

  Future<Map<String, dynamic>> getTeamMemberList(
    String organizationId,
    String workspaceId, {
    String? searchText,
  }) async {
    final queryParams = {
      if (searchText != null) 'searchText': searchText,
      'Fields': 'FULLNAME',
      'limit': 1000,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/team/user/getlistpaging',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getMemberListFromTeamId(
    String organizationId,
    String workspaceId,
    String teamId,
  ) async {
    final queryParams = {
      'Fields': 'FULLNAME',
      'limit': 1000,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/team/$teamId/user/getlistpaging',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getTeamList(
    String organizationId,
    String workspaceId, {
    bool? isTreeView,
    String? fields,
  }) async {
    final queryParams = {
      'fields': 'FULLNAME',
      'limit': 1000,
      'status': 1,
      'sort': '[{ "Column": "Name", "Dir": "ASC" }]',
      if (fields != null) 'fields': fields,
      if (isTreeView != null) 'isTreeView': isTreeView,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/team/getlistpaging',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createTeam(
    String organizationId,
    String workspaceId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.post(
      '$_baseUrl/team/create',
      data: body,
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateTeam(
    String organizationId,
    String workspaceId,
    String teamId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.put(
      '$_baseUrl/team/update/$teamId',
      data: body,
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteTeam(
    String organizationId,
    String workspaceId,
    String teamId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.delete(
      '$_baseUrl/team/delete/$teamId',
      data: body,
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addMember2Team(
    String organizationId,
    String workspaceId,
    String teamId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.post(
      '$_baseUrl/team/$teamId/user/add',
      data: body,
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteMemberFromTeam(
    String organizationId,
    String workspaceId,
    String teamId,
    String profileId,
  ) async {
    final response = await _apiClient.dio.delete(
      '$_baseUrl/team/$teamId/user/$profileId',
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateMemberRole(
    String organizationId,
    String workspaceId,
    String teamId,
    String profileId,
    String role,
  ) async {
    final response = await _apiClient.dio.post(
      '$_baseUrl/team/$teamId/user/role',
      data: {
        'profileId': profileId,
        'role': role,
      },
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> deleteLeader(
    String organizationId,
    String workspaceId,
    String teamId,
    String profileId,
  ) async {
    final response = await _apiClient.dio.delete(
      '$_baseUrl/team/$teamId/user/role',
      data: {
        'profileId': profileId,
      },
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getRecall(
    String organizationId,
    String workspaceId,
    String? teamId,
  ) async {
    final response = await _apiClient.dio.get(
      '$_baseUrl/recall/detail',
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
        if (teamId != null) 'teamId': teamId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateRouting(
    String organizationId,
    String workspaceId,
    String teamId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.put(
      '$_baseUrl/routing',
      data: body,
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
        'teamId': teamId,
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getUserCurrentManagerList(
    String organizationId,
    String workspaceId, {
    String? searchText,
    bool? withManager=false,
  }) async {
    final queryParams = {
      'Fields': 'FULLNAME',
      'limit': 1000,
      if (searchText != null) 'searchText': searchText,
      if (withManager != null) 'withManager': withManager,
    };

    final response = await _apiClient.dio.get(
      '$_baseUrl/team/user/current-managers',
      queryParameters: queryParams,
      options: Options(headers: {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
      }),
    );
    return response.data;
  }
}
