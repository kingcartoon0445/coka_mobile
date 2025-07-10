import 'package:dio/dio.dart';

import '../api_client.dart';

class CustomerRepository {
  final ApiClient _apiClient;

  CustomerRepository(this._apiClient);

  Future<dynamic> getCustomers(
    String organizationId,
    String workspaceId, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/v1/crm/contact/getlistpaging',
      queryParameters: queryParameters,
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> getCustomerDetail(
    String organizationId,
    String workspaceId,
    String customerId,
  ) async {
    final response = await _apiClient.dio.get(
      '/api/v1/crm/contact/getdetail/$customerId',
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> assignToCustomer(
    String organizationId,
    String workspaceId,
    String customerId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/crm/$customerId/assignto',
      data: body,
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> assignToCustomerV2(
    String organizationId,
    String workspaceId,
    String customerId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/crm/contact/$customerId/assigntov2',
      data: body,
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> updateCustomer(
    String organizationId,
    String workspaceId,
    String customerId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.put(
      '/api/v1/crm/$customerId',
      data: body,
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> deleteCustomer(
    String organizationId,
    String workspaceId,
    String customerId,
  ) async {
    final response = await _apiClient.dio.delete(
      '/api/v1/crm/$customerId',
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> createCustomer(
    String organizationId,
    String workspaceId,
    dynamic body,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/crm/contact/create',
      data: body,
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> checkPhone(
    String organizationId,
    String workspaceId,
    List<String> phones,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/crm/contact/check',
      data: {'phones': phones},
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> getJourneyList(
    String organizationId,
    String workspaceId,
    String customerId, {
    int page = 0,
    int limit = 20,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/v1/crm/contact/$customerId/journey',
      queryParameters: {
        'offset': page * 20,
        'limit': limit,
      },
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> updateJourney(
    String organizationId,
    String workspaceId,
    String customerId,
    String stageId,
    String note,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/crm/contact/$customerId/note',
      data: {
        'stageId': stageId,
        'note': note,
      },
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> createNote(
    String organizationId,
    String workspaceId,
    String customerId,
    String note,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/crm/contact/$customerId/note',
      data: {
        'note': note,
      },
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> updateRating(
    String organizationId,
    String workspaceId,
    String customerId,
    int star,
  ) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/crm/$customerId/rating',
      queryParameters: {'rating': star},
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> updateAvatar(
    String organizationId,
    String workspaceId,
    String customerId,
    FormData formData,
  ) async {
    final response = await _apiClient.dio.patch(
      '/api/v1/crm/$customerId/avatar',
      data: formData,
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> generateGoogleSheetMapping(
    String organizationId,
    String workspaceId,
    String formUrl,
    int targetRow,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/crm/googlesheet/mappinggenerator',
      data: {
        'formUrl': formUrl,
        'targetRow': targetRow,
      },
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }

  Future<dynamic> importGoogleSheet(
    String organizationId,
    String workspaceId,
    String formUrl,
    int targetRow,
    int rowCount,
    dynamic mappingField,
  ) async {
    final response = await _apiClient.dio.post(
      '/api/v1/crm/googlesheet/import',
      data: {
        'formUrl': formUrl,
        'targetRow': targetRow,
        'rowCount': rowCount,
        'mappingField': mappingField,
      },
      options: Options(
        headers: {
          'organizationId': organizationId,
          'workspaceId': workspaceId,
        },
      ),
    );
    return response.data;
  }
}
