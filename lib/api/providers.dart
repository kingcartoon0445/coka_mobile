import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/api/repositories/organization_repository.dart';
import 'package:coka/api/repositories/lead_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(ref.read(apiClientProvider));
});

final leadRepositoryProvider = Provider<LeadRepository>((ref) {
  return LeadRepository(apiClient: ref.read(apiClientProvider));
}); 