import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:coka/providers/report_provider.dart';
import 'report_providers.dart';

class DatePickerButton extends ConsumerWidget {
  final String organizationId;
  final String workspaceId;
  final bool isExpanded;
  final bool hideBg;

  const DatePickerButton({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    this.isExpanded = false,
    this.hideBg = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRange = ref.watch(reportsDateRangeProvider);
    final dateString = ref.watch(reportsDateStringProvider);

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        maximumSize: WidgetStatePropertyAll(
            Size(MediaQuery.of(context).size.width - 32, 350)),
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 30)),
      ),
      menuChildren: [
        MenuItemButton(
          child: const Text("Hôm nay",
              style: TextStyle(color: Colors.black, fontSize: 14)),
          onPressed: () {
            final now = DateTime.now();
            final fromDate = DateTime(now.year, now.month, now.day);
            final toDate = fromDate.add(const Duration(days: 1));

            ref.read(reportsDateRangeProvider.notifier).state = DateTimeRange(
              start: fromDate,
              end: toDate,
            );
            ref.read(reportsDateStringProvider.notifier).state = "Hôm nay";

            ref.read(reportParamsProvider.notifier).state = ReportParams(
              organizationId: organizationId,
              workspaceId: workspaceId,
              startDate: DateFormat('yyyy-MM-dd').format(fromDate),
              endDate: DateFormat('yyyy-MM-dd').format(toDate),
            );
          },
        ),
        MenuItemButton(
          child: const Text("Hôm qua",
              style: TextStyle(color: Colors.black, fontSize: 14)),
          onPressed: () {
            final now = DateTime.now();
            final fromDate = DateTime(now.year, now.month, now.day)
                .subtract(const Duration(days: 1));
            final toDate = DateTime(now.year, now.month, now.day);

            ref.read(reportsDateRangeProvider.notifier).state = DateTimeRange(
              start: fromDate,
              end: toDate,
            );
            ref.read(reportsDateStringProvider.notifier).state = "Hôm qua";

            ref.read(reportParamsProvider.notifier).state = ReportParams(
              organizationId: organizationId,
              workspaceId: workspaceId,
              startDate: DateFormat('yyyy-MM-dd').format(fromDate),
              endDate: DateFormat('yyyy-MM-dd').format(toDate),
            );
          },
        ),
        MenuItemButton(
          child: const Text("7 ngày qua",
              style: TextStyle(color: Colors.black, fontSize: 14)),
          onPressed: () {
            final now = DateTime.now();
            final fromDate = now.subtract(const Duration(days: 7));
            final toDate = now.add(const Duration(days: 1));

            ref.read(reportsDateRangeProvider.notifier).state = DateTimeRange(
              start: fromDate,
              end: toDate,
            );
            ref.read(reportsDateStringProvider.notifier).state = "7 ngày qua";

            ref.read(reportParamsProvider.notifier).state = ReportParams(
              organizationId: organizationId,
              workspaceId: workspaceId,
              startDate: DateFormat('yyyy-MM-dd').format(fromDate),
              endDate: DateFormat('yyyy-MM-dd').format(toDate),
            );
          },
        ),
        MenuItemButton(
          child: const Text("30 ngày qua",
              style: TextStyle(color: Colors.black, fontSize: 14)),
          onPressed: () {
            final now = DateTime.now();
            final fromDate = now.subtract(const Duration(days: 30));
            final toDate = now.add(const Duration(days: 1));

            ref.read(reportsDateRangeProvider.notifier).state = DateTimeRange(
              start: fromDate,
              end: toDate,
            );
            ref.read(reportsDateStringProvider.notifier).state = "30 ngày qua";

            ref.read(reportParamsProvider.notifier).state = ReportParams(
              organizationId: organizationId,
              workspaceId: workspaceId,
              startDate: DateFormat('yyyy-MM-dd').format(fromDate),
              endDate: DateFormat('yyyy-MM-dd').format(toDate),
            );
          },
        ),
        MenuItemButton(
          child: const Text("Năm nay",
              style: TextStyle(color: Colors.black, fontSize: 14)),
          onPressed: () {
            final now = DateTime.now();
            final fromDate = now.subtract(const Duration(days: 365));
            final toDate = now.add(const Duration(days: 1));

            ref.read(reportsDateRangeProvider.notifier).state = DateTimeRange(
              start: fromDate,
              end: toDate,
            );
            ref.read(reportsDateStringProvider.notifier).state = "Năm nay";

            ref.read(reportParamsProvider.notifier).state = ReportParams(
              organizationId: organizationId,
              workspaceId: workspaceId,
              startDate: DateFormat('yyyy-MM-dd').format(fromDate),
              endDate: DateFormat('yyyy-MM-dd').format(toDate),
            );
          },
        ),
        MenuItemButton(
          child: const Text("Toàn bộ thời gian",
              style: TextStyle(color: Colors.black, fontSize: 14)),
          onPressed: () {
            final now = DateTime.now();
            final fromDate = now.subtract(const Duration(days: 10000));
            final toDate = now.add(const Duration(days: 10000));

            ref.read(reportsDateRangeProvider.notifier).state = DateTimeRange(
              start: fromDate,
              end: toDate,
            );
            ref.read(reportsDateStringProvider.notifier).state =
                "Toàn bộ thời gian";

            ref.read(reportParamsProvider.notifier).state = ReportParams(
              organizationId: organizationId,
              workspaceId: workspaceId,
              startDate: DateFormat('yyyy-MM-dd').format(fromDate),
              endDate: DateFormat('yyyy-MM-dd').format(toDate),
            );
          },
        ),
        MenuItemButton(
          child: Text(
              "Phạm vị ngày tùy chỉnh${isExpanded ? "         "
                  ""
                  "                                               " : ""}",
              style: const TextStyle(color: Colors.black, fontSize: 14)),
          onPressed: () {
            showDateRangePicker(
                    context: context,
                    initialDateRange: dateRange,
                    firstDate: DateTime(2018),
                    lastDate: DateTime(2030))
                .then((newDateRange) {
              if (newDateRange != null) {
                ref.read(reportsDateRangeProvider.notifier).state =
                    newDateRange;
                ref.read(reportsDateStringProvider.notifier).state =
                    "${DateFormat("dd-MM-yyyy").format(newDateRange.start)} đến ${DateFormat("dd-MM-yyyy").format(newDateRange.end)}";

                ref.read(reportParamsProvider.notifier).state = ReportParams(
                  organizationId: organizationId,
                  workspaceId: workspaceId,
                  startDate:
                      DateFormat('yyyy-MM-dd').format(newDateRange.start),
                  endDate: DateFormat('yyyy-MM-dd').format(newDateRange.end),
                );
              }
            });
          },
        )
      ],
      builder: (context, controller, child) => InkWell(
        onTap: () {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        },
        borderRadius: BorderRadius.circular(isExpanded ? 16 : 12),
        child: Container(
          width: isExpanded ? MediaQuery.of(context).size.width - 32 : null,
          padding: isExpanded
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
              : const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hideBg ? null : const Color(0xFFE3DFFF),
            borderRadius: BorderRadius.circular(isExpanded ? 16 : 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month,
                color: Color(0xFF5C33F0),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                dateString,
                style: const TextStyle(
                  color: Color(0xFF2C160C),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
