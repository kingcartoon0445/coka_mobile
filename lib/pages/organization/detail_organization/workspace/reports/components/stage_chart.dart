import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../shared/widgets/elevated_btn.dart';
import '../../../../../../shared/widgets/custom_switch.dart';
import 'report_providers.dart';

class StageChart extends ConsumerWidget {
  final Map<String, dynamic> data;
  final List<String> chartTypes;
  final String currentChartType;
  final Function(String) onChartTypeChanged;
  final bool isLoading;

  const StageChart({
    super.key,
    required this.data,
    required this.chartTypes,
    required this.currentChartType,
    required this.onChartTypeChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPercentShow = ref.watch(reportsIsPercentShowProvider);

    try {
      final List<dynamic> stages = data['content'] ?? [];
      final Map<String, dynamic> metadata = data['metadata'] ?? {};

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
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
            ]),
        child: Wrap(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Trạng thái khách hàng",
                      style: TextStyle(
                          color: Color(0XFF595A5C),
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    MenuAnchor(
                      menuChildren: [
                        ...chartTypes.map((e) => MenuItemButton(
                              child: Text(
                                style: const TextStyle(fontSize: 14),
                                e,
                              ),
                              onPressed: () {
                                onChartTypeChanged(e);
                              },
                            ))
                      ],
                      style: const MenuStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.white),
                          padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 12))),
                      builder: (context, controller, child) => ElevatedBtn(
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          circular: 12,
                          paddingAllValue: 0,
                          child: FittedBox(
                            child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3DFFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      currentChartType,
                                      style: const TextStyle(
                                          color: Color(0xFF2C160C),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      width: 4,
                                    ),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                    ),
                                  ],
                                )),
                          )),
                    ),
                    const SizedBox(
                      width: 8,
                    )
                  ],
                ),
                const SizedBox(
                  height: 14,
                ),
                _buildSourceLegend(metadata, isPercentShow),
                const SizedBox(
                  height: 5,
                ),
                isLoading
                    ? _buildChartFetching(100.0)
                    : stages.isEmpty
                        ? const Center(
                            child: Text(
                              "Chưa có dữ liệu nào",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xB2000000),
                                  fontWeight: FontWeight.w500),
                            ),
                          )
                        : Column(
                            children: [
                              ...stages.map((element) {
                                if (element is! Map<String, dynamic>) {
                                  return const SizedBox.shrink();
                                }

                                final name =
                                    element["name"]?.toString() ?? 'Unknown';
                                final Map<String, dynamic> stageData =
                                    element["data"] ?? {};

                                num totalPercentage = 0;
                                final chartWidth =
                                    MediaQuery.of(context).size.width - 100;

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Tooltip(
                                      message: _capitalize(name),
                                      triggerMode: TooltipTriggerMode.tap,
                                      child: SizedBox(
                                          width: 70,
                                          child: Text(
                                            _capitalize(name),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          )),
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    SizedBox(
                                      width: chartWidth,
                                      child: Row(
                                        children: [
                                          ...stageData.entries.map((e) {
                                            final stageName = e.key;
                                            final stageInfo = metadata[stageName];
                                            
                                            // Lấy màu từ metadata nếu có
                                            String hexColor = "#9F87FF"; // Màu mặc định
                                            
                                            if (stageInfo != null && stageInfo is Map<String, dynamic> && stageInfo.containsKey("hex")) {
                                              hexColor = stageInfo["hex"];
                                            }
                                            
                                            // Chuyển đổi hex thành Color
                                            final bgColor = Color(int.parse(
                                                "0xFF${hexColor.substring(1)}"));
                                                
                                            final isLastIndex = _isLastElement(
                                                stageData, e.key);
                                            final percent = isLastIndex
                                                ? (100 - totalPercentage).clamp(0, 100).toInt()
                                                : _getRoundedPercentage(
                                                    stageData, e.key);

                                            totalPercentage += percent;
                                            return percent <= 0
                                                ? const SizedBox.shrink()
                                                : Column(
                                                    children: [
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      SizedOverflowBox(
                                                        size: const Size(0, 16),
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                                e.value
                                                                    .toString(),
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            if (isPercentShow)
                                                              Text(
                                                                  "($percent%)",
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Color(
                                                                          0xFF646A73),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal)),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 3,
                                                      ),
                                                      Container(
                                                        width: chartWidth *
                                                            percent /
                                                            100,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        35),
                                                            color: bgColor),
                                                      ),
                                                      const SizedBox(
                                                        height: 2,
                                                      )
                                                    ],
                                                  );
                                          }),
                                        ],
                                      ),
                                    )
                                  ],
                                );
                              }),
                            ],
                          ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                    const Spacer(),
                    SwitchRow(
                      initialValue: isPercentShow,
                      onChanged: (value) {
                        ref.read(reportsIsPercentShowProvider.notifier).state =
                            value;
                      },
                    ),
                    const SizedBox(
                      width: 4,
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error in StageChart: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildSourceLegend(Map<String, dynamic> metadata, bool isPercentShow) {
    return Builder(builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      
      // Lọc các mục thực sự chứa thông tin trạng thái (các key có giá trị là Map và chứa hex + count)
      final legendEntries = metadata.entries.where((entry) => 
        entry.value is Map<String, dynamic> && 
        entry.value.containsKey("hex")
      ).toList();
      
      // Nếu không có phần tử nào, trả về widget trống
      if (legendEntries.isEmpty) {
        return const SizedBox.shrink();
      }
      
      final int itemsPerRow = legendEntries.length > 4 ? 2 : legendEntries.length;
      // Đảm bảo itemsPerRow không bị 0
      final int safeItemsPerRow = itemsPerRow > 0 ? itemsPerRow : 1;
      // Tính số hàng cần thiết, đảm bảo không chia cho 0
      final int rows = ((legendEntries.length + safeItemsPerRow - 1) / safeItemsPerRow).floor();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(rows, (rowIndex) {
          final startIndex = rowIndex * safeItemsPerRow;
          final endIndex = (startIndex + safeItemsPerRow <= legendEntries.length) 
              ? startIndex + safeItemsPerRow 
              : legendEntries.length;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                ...List.generate(endIndex - startIndex, (index) {
                  final itemIndex = startIndex + index;
                  // Kiểm tra chỉ số có hợp lệ không
                  if (itemIndex < 0 || itemIndex >= legendEntries.length) {
                    return const SizedBox.shrink();
                  }
                  
                  final entry = legendEntries[itemIndex];
                  final key = entry.key;
                  final Map<String, dynamic> value = entry.value as Map<String, dynamic>;
                  
                  final String hexColor = value["hex"] as String? ?? "#9F87FF";
                  final String name = value["name"] as String? ?? key;
                  final int count = value["count"] as int? ?? 0;
                  
                  // Chuyển đổi hex sang color một cách an toàn
                  Color color;
                  try {
                    color = Color(int.parse("0xFF${hexColor.substring(1)}"));
                  } catch (e) {
                    color = const Color(0xFF9F87FF); // Màu mặc định nếu chuyển đổi thất bại
                  }
                  
                  // Tính toán chiều rộng an toàn
                  final double itemWidth = (screenWidth - 32) / safeItemsPerRow;
                  
                  return Container(
                    width: itemWidth,
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: color,
                          size: 13,
                        ),
                        const SizedBox(
                          width: 3,
                        ),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                                color: Color(0xB2000000),
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          "$count",
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        if (isPercentShow)
                          Text(
                              "(${_getMetadataPercentage(metadata, key)}%)",
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xB2000000))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _buildChartFetching(double height) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  bool _isLastElement(Map<String, dynamic> data, String key) {
    List keys = data.keys.toList();
    int index = keys.indexOf(key);
    return index == keys.length - 1;
  }

  // Tính phần trăm cho dữ liệu trong stage
  int _getRoundedPercentage(Map<String, dynamic> data, String key) {
    try {
      if (data.containsKey(key)) {
        num total = 0;
        data.forEach((_, value) {
          if (value is num) {
            total += value;
          } else if (value is Map<String, dynamic> && value.containsKey("count")) {
            total += (value["count"] as num? ?? 0);
          }
        });
        
        if (total <= 0) {
          return 0;
        }
        
        num itemValue = 0;
        if (data[key] is num) {
          itemValue = data[key] as num;
        } else if (data[key] is Map<String, dynamic> && data[key].containsKey("count")) {
          itemValue = (data[key]["count"] as num? ?? 0);
        }
        
        double percentage = (itemValue / total) * 100.0;
        if (percentage.isNaN || percentage.isInfinite) {
          return 0;
        }
        return percentage.round();
      }
    } catch (e) {
      print("Error calculating percentage: $e");
    }
    return 0;
  }
  
  // Tính phần trăm riêng cho metadata
  int _getMetadataPercentage(Map<String, dynamic> metadata, String key) {
    try {
      int total = 0;
      
      // Tính tổng số lượng từ tất cả các trạng thái
      metadata.forEach((_, value) {
        if (value is Map<String, dynamic> && value.containsKey("count")) {
          total += (value["count"] as int? ?? 0);
        }
      });
      
      if (total <= 0) {
        return 0;
      }
      
      // Lấy số lượng cho trạng thái hiện tại
      final Map<String, dynamic>? stageInfo = metadata[key] as Map<String, dynamic>?;
      final int count = stageInfo != null ? (stageInfo["count"] as int? ?? 0) : 0;
      
      // Tính phần trăm
      final double percentage = (count / total) * 100;
      if (percentage.isNaN || percentage.isInfinite) {
        return 0;
      }
      return percentage.round();
    } catch (e) {
      print("Error calculating metadata percentage: $e");
      return 0;
    }
  }
}
