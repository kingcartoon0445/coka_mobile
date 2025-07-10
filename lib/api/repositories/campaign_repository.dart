import 'package:coka/api/api_path.dart';

import '../api_client.dart';

class CampaignRepository {
  final ApiClient _apiClient;

  CampaignRepository(this._apiClient);

  Future<Map<String, dynamic>> getCampaigns(
    String organizationId, {
    Map<String, String>? queryParameters,
  }) async {
    return await _apiClient.get(
      ApiPath.campaignBase,
      headers: {'organizationId': organizationId},
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> getCampaignDetail(
    String organizationId,
    String campaignId,
  ) async {
    return await _apiClient.get(
      '${ApiPath.campaignBase}/$campaignId',
      headers: {'organizationId': organizationId},
    );
  }

  Future<Map<String, dynamic>> createCampaign(
    String organizationId,
    Map<String, dynamic> campaignData,
  ) async {
    return await _apiClient.post(
      ApiPath.campaignBase,
      data: campaignData,
      headers: {'organizationId': organizationId},
    );
  }

  Future<Map<String, dynamic>> updateCampaign(
    String organizationId,
    String campaignId,
    Map<String, dynamic> campaignData,
  ) async {
    return await _apiClient.put(
      '${ApiPath.campaignBase}/$campaignId',
      data: campaignData,
      headers: {'organizationId': organizationId},
    );
  }

  Future<Map<String, dynamic>> deleteCampaign(
    String organizationId,
    String campaignId,
  ) async {
    return await _apiClient.delete(
      '${ApiPath.campaignBase}/$campaignId',
      headers: {'organizationId': organizationId},
    );
  }

  Future<Map<String, dynamic>> assignUsersToCampaign(
    String organizationId,
    String campaignId,
    List<String> userIds,
  ) async {
    return await _apiClient.post(
      '${ApiPath.campaignBase}/$campaignId/users',
      data: {'userIds': userIds},
      headers: {'organizationId': organizationId},
    );
  }

  Future<Map<String, dynamic>> getCampaignUsers(
    String organizationId,
    String campaignId,
  ) async {
    return await _apiClient.get(
      '${ApiPath.campaignBase}/$campaignId/users',
      headers: {'organizationId': organizationId},
    );
  }

  Future<Map<String, dynamic>> removeUserFromCampaign(
    String organizationId,
    String campaignId,
    String userId,
  ) async {
    return await _apiClient.delete(
      '${ApiPath.campaignBase}/$campaignId/users/$userId',
      headers: {'organizationId': organizationId},
    );
  }

  Future<Map<String, dynamic>> getCampaignsPaging(
    String organizationId, {
    int? page,
    int? size,
    String? search,
    Map<String, String>? additionalParams,
  }) async {
    Map<String, dynamic> queryParams = {};
    if (page != null) queryParams['page'] = page;
    if (size != null) queryParams['size'] = size;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (additionalParams != null) queryParams.addAll(additionalParams);

    return await _apiClient.get(
      ApiPath.campaignPaging,
      headers: {
        'organizationId': organizationId,
        'Accept-Language': 'vi-VN,vi;q=0.9,en-VN;q=0.8,en;q=0.7,fr-FR;q=0.6,fr;q=0.5,en-US;q=0.4',
        'Connection': 'keep-alive',
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }
}
