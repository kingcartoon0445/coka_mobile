import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider để kiểm soát việc load dữ liệu
final reportsPageShouldLoadProvider = StateProvider<bool>((ref) => false);

// Cache key provider
final reportsCacheKeyProvider = StateProvider<int>((ref) => 0);

// Provider cho DateRange
final reportsDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: now.subtract(const Duration(days: 10000)),
    end: now.add(const Duration(days: 10000)),
  );
});

// Provider cho DateString
final reportsDateStringProvider =
    StateProvider<String>((ref) => "Toàn bộ thời gian");

// Provider cho loại thời gian
final reportsTimeTypeProvider = StateProvider<String>((ref) => 'Day');

// Provider cho loại biểu đồ khách hàng theo giai đoạn
final reportsStageCustomerChartTypeProvider =
    StateProvider<String>((ref) => 'Phân loại');

// Provider cho hiển thị phần trăm
final reportsIsPercentShowProvider = StateProvider<bool>((ref) => true);
