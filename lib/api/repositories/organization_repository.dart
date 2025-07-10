import '../api_client.dart';
import 'package:dio/dio.dart';

class OrganizationRepository {
  final ApiClient _apiClient;

  OrganizationRepository(this._apiClient);

  Future<Map<String, dynamic>> getOrganizations({
    int limit = 1000,
    int offset = 0,
    String? searchText,
  }) async {
    final queryParams = {
      'limit': limit,
      'offset': offset,
      if (searchText != null) 'searchText': searchText,
    };
    final response = await _apiClient.dio.get(
        '/api/v1/organization/getlistpaging',
        queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> getOrganizationDetail(String id) async {
    final response =
        await _apiClient.dio.get('/api/v1/organization/getdetail/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> getOrganizationMembers(
    String organizationId, {
    int limit = 20,
    int offset = 0,
    String? searchText,
    int status = 1,
  }) async {
    final queryParams = {
      'limit': limit,
      'offset': offset,
      'status': status,
      if (searchText != null) 'searchText': searchText,
    };
    final response = await _apiClient.dio.get(
      '/api/v1/organization/member/getlistpaging',
      queryParameters: queryParams,
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getMemberDetail(
    String profileId,
    String organizationId,
  ) async {
    final response = await _apiClient.dio.get(
      '/api/v1/user/profile/getdetail/$profileId',
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> searchMembersToInvite(
    String organizationId, {
    String? searchText,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = {
      'limit': limit,
      'offset': offset,
      if (searchText != null) 'searchText': searchText,
    };
    final response = await _apiClient.dio.get(
      '/api/v1/organization/member/searchprofile',
      queryParameters: queryParams,
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> inviteMember(
    String organizationId,
    String profileId,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/organization/member/invite',
      data: {'profileId': profileId},
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createOrganization(FormData formData) async {
    final response = await _apiClient.dio.post(
      '/api/v1/organization/create',
      data: formData,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateOrganization(
    String organizationId,
    FormData formData,
  ) async {
    final response = await _apiClient.dio.put(
      '/api/v1/organization/update/$organizationId',
      data: formData,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateOrganizationAvatar(
    String organizationId,
    FormData formData,
  ) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/organization/updateavatar/$organizationId',
      data: formData,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getUsageStatistics(String organizationId) async {
    final response = await _apiClient.dio.get(
      '/api/v1/workspace/report/getusagestatistics',
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> searchOrganizationsToJoin({
    String? searchText,
    int limit = 1000,
    int offset = 0,
  }) async {
    final queryParams = {
      'limit': limit,
      'offset': offset,
      if (searchText != null) 'searchText': searchText,
    };
    final response = await _apiClient.dio.get(
      '/api/v1/organization/member/request/searchorganization',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> requestToJoinOrganization(
    String organizationId,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/organization/member/request/requestinvite',
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> acceptOrRejectJoinRequest(
    String organizationId,
    String inviteId,
    bool isAccept,
  ) async {
    final queryParams = {
      'InviteId': inviteId,
      'IsAccept': isAccept,
    };
    final response = await _apiClient.dio.post(
      '/api/v1/organization/member/request/accept',
      queryParameters: queryParams,
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> cancelJoinRequest(String inviteId) async {
    final response = await _apiClient.dio.post(
      '/api/v1/organization/member/request/cancel/$inviteId',
    );
    return response.data;
  }

  Future<Map<String, dynamic>> cancelInvitation(
    String organizationId,
    String inviteId,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/organization/member/invite/cancel/$inviteId',
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> acceptOrRejectInvitation(
    String organizationId,
    String inviteId,
    bool isAccept,
  ) async {
    final queryParams = {
      'InviteId': inviteId,
      'IsAccept': isAccept,
    };
    final response = await _apiClient.dio.post(
      '/api/v1/organization/member/invite/accept',
      queryParameters: queryParams,
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getInvitedOrganizations({
    String type = 'INVITE',
    int limit = 1000,
    int offset = 0,
    int status = 2,
  }) async {
    final queryParams = {
      'type': type,
      'limit': limit,
      'offset': offset,
      'status': status,
    };
    final response = await _apiClient.dio.get(
      '/api/v1/organization/member/request/getlistpaging',
      queryParameters: queryParams,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getOrganizationRequests(
    String organizationId, {
    String type = 'REQUEST',
    int limit = 1000,
    int offset = 0,
    int status = 2,
  }) async {
    final queryParams = {
      'type': type,
      'limit': limit,
      'offset': offset,
      'status': status,
    };
    final response = await _apiClient.dio.get(
      '/api/v1/organization/member/invite/getlistpaging',
      queryParameters: queryParams,
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> changeMemberRole(
    String organizationId,
    String profileMemberId,
    String role,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/organization/member/grantrole',
      data: {
        'profileMemberId': profileMemberId,
        'role': role,
      },
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> removeMember(
    String organizationId,
    String profileId,
  ) async {
    final response = await _apiClient.dio.delete(
      '/api/v1/organization/member/$profileId',
      options: Options(headers: {'organizationId': organizationId}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getOrgMembers(
    String organizationId, {
    int offset = 0,
    String? searchText,
    String? workspaceId,
  }) async {
    final queryParams = {
      'offset': offset,
      'limit': 1000,
      if (searchText != null) 'searchText': searchText,
    };
    
    final headers = <String, String>{
      'organizationId': organizationId,
      if (workspaceId != null) 'workspaceId': workspaceId,
    };

    final response = await _apiClient.dio.get(
      '/api/v1/organization/member/getlistpaging',
      queryParameters: queryParams,
      options: Options(headers: headers),
    );
    return response.data;
  }
}
