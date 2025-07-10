import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coka/providers/report_provider.dart';
import 'components/index.dart';
import 'package:go_router/go_router.dart';

class ReportsPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;

  const ReportsPage({
    super.key,
    required this.organizationId,
    required this.workspaceId,
  });

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final ReportParams _initialParams;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 10000)),
      end: now.add(const Duration(days: 10000)),
    );
    _initialParams = ReportParams(
      organizationId: widget.organizationId,
      workspaceId: widget.workspaceId,
      startDate: DateFormat('yyyy-MM-dd').format(initialDateRange.start),
      endDate: DateFormat('yyyy-MM-dd').format(initialDateRange.end),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      Future.microtask(() {
        ref.read(reportParamsProvider.notifier).state = _initialParams;
        ref.read(reportsPageShouldLoadProvider.notifier).state = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final reportData = ref.watch(reportDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2329)),
          onPressed: () => context.go('/organization/${widget.organizationId}'),
        ),
        centerTitle: true,
        title: const Text(
          'Báo cáo',
          style: TextStyle(
            color: Color(0xFF1F2329),
            fontWeight: FontWeight.bold,
            fontSize: 18
          ),
        ),
        automaticallyImplyLeading: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportDataProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DatePickerButton(
                  organizationId: widget.organizationId,
                  workspaceId: widget.workspaceId,
                ),
              ),
              reportData.when(
                data: (data) => DashboardCards(
                  data: data['summary'],
                  organizationId: widget.organizationId,
                  workspaceId: widget.workspaceId,
                ),
                loading: () => const DashboardCardsSkeleton(),
                error: (error, stack) => Center(child: Text('Lỗi: $error')),
              ),
              const SizedBox(height: 30),
              reportData.when(
                data: (data) => CustomerValueChart(data: data['utmSource']),
                loading: () => const ChartSkeleton(),
                error: (error, stack) => Center(child: Text('Lỗi: $error')),
              ),
              const SizedBox(height: 30),
              reportData.when(
                data: (data) => RatingChart(data: data['rating']),
                loading: () => const ChartSkeleton(),
                error: (error, stack) => Center(child: Text('Lỗi: $error')),
              ),
              const SizedBox(height: 30),
              reportData.when(
                data: (data) => StageChart(
                  data: _getStageChartData(
                      data, ref.watch(reportsStageCustomerChartTypeProvider)),
                  chartTypes: const ['Phân loại', 'Nguồn', 'Thẻ'],
                  currentChartType:
                      ref.watch(reportsStageCustomerChartTypeProvider),
                  onChartTypeChanged: (type) {
                    ref
                        .read(reportsStageCustomerChartTypeProvider.notifier)
                        .state = type;
                  },
                  isLoading: false,
                ),
                loading: () => const ChartSkeleton(height: 400),
                error: (error, stack) => Center(child: Text('Lỗi: $error')),
              ),
              const SizedBox(height: 30),
              reportData.when(
                data: (data) => UserStatistics(data: data['user']),
                loading: () => const UserStatisticsSkeleton(),
                error: (error, stack) => Center(child: Text('Lỗi: $error')),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStageChartData(
      Map<String, dynamic> data, String chartType) {
    switch (chartType) {
      case 'Nguồn':
        return data['utmSource'] ?? {'content': [], 'metadata': {}};
      case 'Thẻ':
        return data['tag'] ?? {'content': [], 'metadata': {}};
      case 'Phân loại':
      default:
        return data['dataSource'] ?? {'content': [], 'metadata': {}};
    }
  }
}
