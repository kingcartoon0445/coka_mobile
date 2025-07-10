import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chart_model.dart';
import 'report_providers.dart';
import '../../../../../../providers/report_provider.dart';

// Provider để cache params cho biểu đồ đánh giá
final ratingChartParamsProvider =
    Provider.family<ReportParams, ReportParams>((ref, params) {
  return params;
});

class RatingChart extends ConsumerWidget {
  final Map<String, dynamic> data;

  const RatingChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(reportParamsProvider);

    if (params == null) {
      return const SizedBox.shrink();
    }

    // Sử dụng provider để cache params
    final ratingParams = ref.watch(ratingChartParamsProvider(params));

    // Chỉ fetch dữ liệu khi shouldLoad là true
    final shouldLoad = ref.watch(reportsPageShouldLoadProvider);

    // Lấy tổng số khách hàng từ data
    final totalCustomers = _getTotalCustomers(data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Đánh giá khách hàng',
            style: TextStyle(
              color: Color(0xFF595A5C),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (shouldLoad)
            Consumer(
              builder: (context, ref, child) {
                final ratingDataAsync =
                    ref.watch(reportChartByRatingProvider(ratingParams));
                return ratingDataAsync.when(
                  data: (ratingData) => _buildRatingContent(ratingData,
                      totalCustomers, MediaQuery.of(context).size.width),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Text(
                        'Lỗi khi tải dữ liệu: ${error.toString()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Text(
                  'Đang chờ tải dữ liệu...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  int _getTotalCustomers(Map<String, dynamic> data) {
    try {
      // Tính tổng số khách hàng từ dữ liệu đánh giá
      final ratings = (data['content'] as List?) ?? [];
      int total = 0;

      for (var rating in ratings) {
        if (rating is Map<String, dynamic>) {
          final count = (rating['count'] as num?)?.toInt() ?? 0;
          total += count;
        }
      }

      return total;
    } catch (e) {
      print('Error getting total customers: $e');
      return 0;
    }
  }

  Widget _buildRatingContent(
      Map<String, dynamic> data, int totalCustomers, double screenWidth) {
    try {
      final List<ChartModel> chartData = [];
      final ratings = (data['content'] as List?) ?? [];

      if (ratings.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: Text(
              'Không có dữ liệu đánh giá',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        );
      }

      // Tạo map để lưu trữ dữ liệu theo rating
      final Map<int, Map<String, dynamic>> ratingMap = {};

      for (var rating in ratings) {
        if (rating is Map<String, dynamic>) {
          final ratingValue = (rating['rating'] as num?)?.toInt() ?? 0;
          final count = (rating['count'] as num?)?.toInt() ?? 0;
          final name = ratingValue == 0 ? 'Chưa đánh giá' : '$ratingValue sao';
          final color = {
                5: const Color(0xff9B8CF7),
                4: const Color(0xFFB6F1FD),
                3: const Color(0xffA5F2AA),
                2: const Color(0xffF0D5FC),
                1: const Color(0xffF5C19E),
                0: const Color(0xff554FE8),
              }[ratingValue] ??
              Colors.grey;

          ratingMap[ratingValue] = {
            'name': name,
            'count': count,
            'color': color,
          };
        }
      }

      // Sắp xếp theo thứ tự từ 5 sao xuống 0 sao
      final sortedRatings = [5, 4, 3, 2, 1, 0];

      for (var rating in sortedRatings) {
        if (ratingMap.containsKey(rating)) {
          final item = ratingMap[rating]!;
          chartData.add(ChartModel(item['name'] as String, item['count'] as int,
              color: item['color'] as Color));
        }
      }

      return Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...chartData.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 15,
                          color: e.color,
                        ),
                        const SizedBox(width: 3),
                        SizedBox(
                          width: 85,
                          child: Text(
                            e.name,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        const Icon(
                          Icons.circle,
                          size: 5,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          e.value.toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ))
            ],
          ),
          const Spacer(),
          ClipRect(
            child: Align(
              heightFactor: 0.7,
              widthFactor: 1,
              child: SizedBox(
                width: screenWidth / 2,
                child: SfCircularChart(
                  margin: EdgeInsets.zero,
                  tooltipBehavior: TooltipBehavior(enable: true),
                  annotations: <CircularChartAnnotation>[
                    CircularChartAnnotation(
                      widget: Wrap(
                        children: [
                          Column(
                            children: [
                              const Text(
                                "Tổng số khách hàng",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                totalCustomers.toString(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  series: <CircularSeries<ChartModel, String>>[
                    DoughnutSeries<ChartModel, String>(
                      dataSource: chartData,
                      xValueMapper: (ChartModel data, _) => data.name,
                      yValueMapper: (ChartModel data, _) => data.value,
                      pointColorMapper: (ChartModel data, _) => data.color,
                      strokeWidth: 1,
                      strokeColor: const Color(0xFFFAFEFF),
                      explode: true,
                      innerRadius: '70%',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      print('Error in RatingChart: $e');
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Lỗi khi hiển thị biểu đồ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ),
      );
    }
  }
}
