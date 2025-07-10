import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/providers.dart';
import 'package:coka/api/repositories/fill_data_repository.dart';
import 'package:coka/api/repositories/payment_repository.dart';
import 'package:coka/api/repositories/reminder_repository.dart';
import 'package:coka/providers/multi_source_connection_provider.dart';

final multiSourceConnectionProvider = Provider<MultiSourceConnectionProvider>((ref) {
  final leadRepository = ref.read(leadRepositoryProvider);
  return MultiSourceConnectionProvider(leadRepository: leadRepository);
});

// Fill Data Repository Provider
final fillDataRepositoryProvider = Provider<FillDataRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return FillDataRepository(apiClient);
});

// Payment Repository Provider  
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return PaymentRepository(apiClient);
});

// Reminder Repository Provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ReminderRepository(apiClient);
}); 