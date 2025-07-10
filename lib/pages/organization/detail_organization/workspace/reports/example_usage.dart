import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../providers/report_provider.dart';
import 'components/index.dart';

class ReportsExample extends ConsumerWidget {
  final String organizationId;
  final String workspaceId;

  const ReportsExample({
    super.key,
    required this.organizationId,
    required this.workspaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Thiết lập các tham số báo cáo
    final startDate = DateTime.now().subtract(const Duration(days: 30));
    final endDate = DateTime.now();

    // Thiết lập tham số cho báo cáo
    final params = ReportParams(
      organizationId: organizationId,
      workspaceId: workspaceId,
      startDate:
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
      endDate:
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
    );

    // Kích hoạt tải dữ liệu
    ref.read(reportsPageShouldLoadProvider.notifier).state = true;

    // Theo dõi dữ liệu từ các provider
    final utmSourceData =
        ref.watch(reportStatisticsByUtmSourceProvider(params));
    final dataSourceData =
        ref.watch(reportStatisticsByDataSourceProvider(params));
    final tagData = ref.watch(reportStatisticsByTagProvider(params));

    // Danh sách các loại biểu đồ
    final chartTypes = ['Phân loại', 'Nguồn', 'Thẻ'];

    // Loại biểu đồ hiện tại
    final currentChartType = ref.watch(reportsStageCustomerChartTypeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // DatePickerButton để chọn khoảng thời gian
            DatePickerButton(
              organizationId: organizationId,
              workspaceId: workspaceId,
            ),

            const SizedBox(height: 16),

            // Hiển thị biểu đồ trạng thái khách hàng dựa trên loại đã chọn
            utmSourceData.when(
              data: (data) {
                // Chọn dữ liệu dựa trên loại biểu đồ
                Map<String, dynamic> chartData;
                switch (currentChartType) {
                  case 'Nguồn':
                    chartData = data;
                    break;
                  case 'Thẻ':
                    chartData =
                        tagData.value ?? {'content': [], 'metadata': {}};
                    break;
                  case 'Phân loại':
                  default:
                    chartData =
                        dataSourceData.value ?? {'content': [], 'metadata': {}};
                    break;
                }

                return StageChart(
                  data: chartData,
                  chartTypes: chartTypes,
                  currentChartType: currentChartType,
                  onChartTypeChanged: (type) {
                    ref
                        .read(reportsStageCustomerChartTypeProvider.notifier)
                        .state = type;
                  },
                  isLoading: utmSourceData.isLoading ||
                      dataSourceData.isLoading ||
                      tagData.isLoading,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Đã xảy ra lỗi: $error'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
