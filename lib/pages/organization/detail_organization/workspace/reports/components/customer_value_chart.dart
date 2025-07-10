import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chart_model.dart';
import 'report_providers.dart';
import '../../../../../../providers/report_provider.dart';

// Provider để cache params cho biểu đồ khách hàng
final customerValueChartParamsProvider =
    Provider.family<ReportOverTimeParams, ReportParams>((ref, params) {
  final timeType = ref.watch(reportsTimeTypeProvider);
  return ReportOverTimeParams(
    organizationId: params.organizationId,
    workspaceId: params.workspaceId,
    startDate: params.startDate,
    endDate: params.endDate,
    type: timeType,
  );
});

class CustomerValueChart extends ConsumerWidget {
  final Map<String, dynamic> data;

  const CustomerValueChart({
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
    final overTimeParams = ref.watch(customerValueChartParamsProvider(params));

    // Chỉ fetch dữ liệu khi shouldLoad là true
    final shouldLoad = ref.watch(reportsPageShouldLoadProvider);

    // Sử dụng select để chỉ lắng nghe thay đổi của timeType
    final timeType = ref.watch(reportsTimeTypeProvider);

    return Container(
      width: double.infinity,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Phân loại khách hàng',
              style: TextStyle(
                color: Color(0xFF595A5C),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              const Icon(
                Icons.circle,
                color: Color(0xFF9B8CF7),
                size: 13,
              ),
              const SizedBox(width: 5),
              const Text(
                'Form',
                style: TextStyle(
                  color: Color(0xB2000000),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.circle,
                color: Color(0xFFA5F2AA),
                size: 13,
              ),
              const SizedBox(width: 5),
              const Text(
                'Import',
                style: TextStyle(
                  color: Color(0xB2000000),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.circle,
                color: Color(0xFFF5C19E),
                size: 13,
              ),
              const SizedBox(width: 5),
              const Text(
                'Khác',
                style: TextStyle(
                  color: Color(0xB2000000),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    child: const Text('Ngày', style: TextStyle(fontSize: 14)),
                    onPressed: () {
                      if (timeType != 'Day') {
                        ref.read(reportsTimeTypeProvider.notifier).state =
                            'Day';
                        ref
                            .read(reportsCacheKeyProvider.notifier)
                            .update((state) => state + 1);
                      }
                    },
                  ),
                  MenuItemButton(
                    child: const Text('Tháng', style: TextStyle(fontSize: 14)),
                    onPressed: () {
                      if (timeType != 'Month') {
                        ref.read(reportsTimeTypeProvider.notifier).state =
                            'Month';
                        ref
                            .read(reportsCacheKeyProvider.notifier)
                            .update((state) => state + 1);
                      }
                    },
                  ),
                  MenuItemButton(
                    child: const Text('Năm', style: TextStyle(fontSize: 14)),
                    onPressed: () {
                      if (timeType != 'Year') {
                        ref.read(reportsTimeTypeProvider.notifier).state =
                            'Year';
                        ref
                            .read(reportsCacheKeyProvider.notifier)
                            .update((state) => state + 1);
                      }
                    },
                  ),
                ],
                style: const MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.white),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                builder: (context, controller, child) => InkWell(
                  onTap: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3DFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_sharp,
                          color: Color(0xFF5C33F0),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeTypeName(timeType),
                          style: const TextStyle(
                            color: Color(0xFF2C160C),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 10),
          if (shouldLoad)
            Consumer(
              builder: (context, ref, child) {
                final chartDataAsync =
                    ref.watch(reportChartByOverTimeProvider(overTimeParams));
                return chartDataAsync.when(
                  data: (chartData) => _buildChart(chartData, timeType),
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
        ],
      ),
    );
  }

  String _getTimeTypeName(String timeType) {
    switch (timeType) {
      case 'Day':
        return 'Ngày';
      case 'Month':
        return 'Tháng';
      case 'Year':
        return 'Năm';
      default:
        return 'Ngày';
    }
  }

  Widget _buildChart(Map<String, dynamic> data, String timeType) {
    try {
      final chartData = (data['content'] as List?) ?? [];

      if (chartData.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: Text(
              'Không có dữ liệu phân loại khách hàng',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        );
      }

      final formData = <ChartModel>[];
      final importData = <ChartModel>[];
      final otherData = <ChartModel>[];

      for (var item in chartData) {
        if (item is Map<String, dynamic>) {
          final date = item['date']?.toString() ?? '';
          final form = (item['form'] as num?) ?? 0;
          final import = (item['import'] as num?) ?? 0;
          // Tính giá trị "other" bằng cách lấy total trừ đi form và import
          final total = (item['total'] as num?) ?? 0;
          final other = total - form - import;

          formData.add(ChartModel(date, form));
          importData.add(ChartModel(date, import));
          otherData.add(ChartModel(date, other > 0 ? other : 0));
        }
      }

      return SizedBox(
        height: 300,
        child: SfCartesianChart(
          enableSideBySideSeriesPlacement: false,
          trackballBehavior: TrackballBehavior(
            enable: true,
            activationMode: ActivationMode.singleTap,
            hideDelay: 2 * 1000,
            lineColor: Colors.transparent,
            tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
          ),
          zoomPanBehavior: ZoomPanBehavior(
            enablePanning: true,
            zoomMode: ZoomMode.x,
            enableMouseWheelZooming: true,
            enablePinching: true,
          ),
          primaryXAxis: CategoryAxis(
            axisLabelFormatter: (axisLabelRenderArgs) {
              return ChartAxisLabel(
                  axisLabelRenderArgs.text, const TextStyle());
            },
            labelStyle: const TextStyle(
              fontSize: 11,
              color: Colors.black,
              fontStyle: FontStyle.italic,
            ),
            labelRotation: 312,
          ),
          primaryYAxis: NumericAxis(
            numberFormat: NumberFormat.compact(),
          ),
          series: <CartesianSeries<ChartModel, String>>[
            StackedColumnSeries<ChartModel, String>(
              dataSource: formData,
              xValueMapper: (ChartModel data, _) => data.name,
              yValueMapper: (ChartModel data, _) => data.value,
              name: 'Form',
              width: 0.4,
              color: const Color(0xFF9B8CF7),
            ),
            StackedColumnSeries<ChartModel, String>(
              dataSource: importData,
              xValueMapper: (ChartModel data, _) => data.name,
              yValueMapper: (ChartModel data, _) => data.value,
              name: 'Import',
              width: 0.4,
              color: const Color(0xFFA5F2AA),
            ),
            StackedColumnSeries<ChartModel, String>(
              dataSource: otherData,
              xValueMapper: (ChartModel data, _) => data.name,
              yValueMapper: (ChartModel data, _) => data.value,
              name: 'Khác',
              width: 0.4,
              color: const Color(0xFFF5C19E),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error in CustomerValueChart: $e');
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
