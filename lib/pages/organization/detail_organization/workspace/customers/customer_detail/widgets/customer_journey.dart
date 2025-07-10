import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../providers/customer_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import './stage_select.dart';
import './journey_item.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../../../models/stage.dart';
import '../../../../../../../widgets/reminder/customer_reminder_card.dart';

class CustomerJourney extends ConsumerStatefulWidget {
  const CustomerJourney({super.key});

  @override
  ConsumerState<CustomerJourney> createState() => _CustomerJourneyState();
}

class _CustomerJourneyState extends ConsumerState<CustomerJourney>
    with SingleTickerProviderStateMixin {
  final TextEditingController chatController = TextEditingController();
  Stage? selectedStage;
  final _focusNode = FocusNode();
  bool _isInputFocused = false;
  late AnimationController _iconAnimationController;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _iconAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    Future(() {
      if (!mounted) return;
      final params = GoRouterState.of(context).pathParameters;
      final organizationId = params['organizationId']!;
      final workspaceId = params['workspaceId']!;
      final customerId = params['customerId']!;

      ref
          .read(customerJourneyProvider(customerId).notifier)
          .loadJourneyList(organizationId, workspaceId);
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  // Hàm nhóm các journey theo ngày
  Map<String, List<dynamic>> _groupJourneysByDate(List<dynamic> journeys) {
    final Map<String, List<dynamic>> groupedJourneys = {};
    
    for (final journey in journeys) {
      if (journey['date'] == null) continue;
      
      final date = DateTime.parse(journey['date']);
      final dateKey = DateTime(date.year, date.month, date.day).toIso8601String();
      
      if (!groupedJourneys.containsKey(dateKey)) {
        groupedJourneys[dateKey] = [];
      }
      groupedJourneys[dateKey]!.add(journey);
    }
    
    return groupedJourneys;
  }

  // Hàm tạo title cho ngày
  String _getDateTitle(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date.isAtSameMomentAs(today)) {
      return "Hôm nay";
    } else if (date.isAtSameMomentAs(yesterday)) {
      return "Hôm qua";
    } else {
      final weekDays = [
        "Chủ nhật", "Thứ hai", "Thứ ba", "Thứ tư", 
        "Thứ năm", "Thứ sáu", "Thứ bảy"
      ];
      final weekDay = weekDays[date.weekday % 7];
      return "$weekDay, ${date.day}/${date.month}/${date.year}";
    }
  }

  // Widget tạo divider với time title
  Widget _buildDateDivider(String dateTitle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12), // Divider trải rộng toàn màn hình
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE8E8E8),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12), // Giảm margin
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Giảm padding
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8), // Giảm border radius
            ),
            child: Text(
              dateTitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE8E8E8),
            ),
          ),
        ],
      ),
    );
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && selectedStage == null) {
      setState(() {
        // selectedStage sẽ được set khi user chọn trong StageSelect
        _isInputFocused = true;
      });
      _iconAnimationController.forward();
    } else {
      setState(() {
        _isInputFocused = _focusNode.hasFocus;
      });
      if (!_focusNode.hasFocus) {
        _iconAnimationController.reverse();
      }
    }
  }

  void _showCallMethodBottomSheet() {
    final params = GoRouterState.of(context).pathParameters;
    final customerId = params['customerId']!;
    final customerState = ref.watch(customerDetailProvider(customerId));

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) => Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 60, // Đưa menu cao hơn
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Tăng padding
          child: Wrap(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Phương thức gọi",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20), // Tăng khoảng cách
                  // Chỉ hiển thị gọi mặc định, ẩn tổng đài Coka
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final customerData = customerState.value;
                        if (customerData != null) {
                          final phone = customerData['phone'] as String?;
                          if (phone != null) {
                            final phoneNumber = phone.startsWith("84")
                                ? phone.replaceFirst("84", "0")
                                : phone;
                            final url = Uri.parse("tel:$phoneNumber");
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          }
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF43B41F),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.call,
                                  color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Gọi điện",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // Thêm khoảng cách cuối
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final params = GoRouterState.of(context).pathParameters;
    final customerId = params['customerId']!;
    final journeyState = ref.watch(customerJourneyProvider(customerId));
    final customerDetailState = ref.watch(customerDetailProvider(customerId));
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardVisible = viewInsets.bottom > 0;

    return Container(
      color: const Color(0xFFF8F8F8),
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: RefreshIndicator(
              onRefresh: () async {
                final params = GoRouterState.of(context).pathParameters;
                final organizationId = params['organizationId']!;
                final workspaceId = params['workspaceId']!;
                
                // Invalidate trước khi gọi để đảm bảo refresh
                ref.invalidate(customerJourneyProvider(customerId));
                
                await ref
                    .read(customerJourneyProvider(customerId).notifier)
                    .loadJourneyList(
                      organizationId,
                      workspaceId,
                    );
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: _isInputFocused 
                    ? 240  // Để đủ space cho stage select + input + keyboard
                    : 140, // Để đủ space cho input khi không focus (tăng lên để input cao hơn)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    journeyState.when(
                      loading: () => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Column(
                          children: List.generate(
                            6, // Tăng số lượng items
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 200,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 140,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Text(
                          'Có lỗi xảy ra: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      data: (journeyList) => journeyList.isEmpty
                          ? const Center(
                              child: Text('Chưa có hành trình nào'),
                            )
                          : Column(
                              children: () {
                                final groupedJourneys = _groupJourneysByDate(journeyList);
                                final sortedKeys = groupedJourneys.keys.toList()
                                  ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));
                                
                                List<Widget> widgets = [];
                                
                                // Thêm reminder card ở đầu
                                final params = GoRouterState.of(context).pathParameters;
                                final organizationId = params['organizationId']!;
                                final workspaceId = params['workspaceId']!;
                                
                                widgets.add(
                                  CustomerReminderCard(
                                    organizationId: organizationId,
                                    workspaceId: workspaceId,
                                    customerId: customerId,
                                    customerData: customerDetailState.value,
                                    onAddReminder: () {
                                      // Có thể thêm logic để scroll đến reminder section hoặc highlight
                                    },
                                  ),
                                );
                                
                                // Thêm header "Lịch sử" nếu có journey
                                if (sortedKeys.isNotEmpty) {
                                  widgets.add(
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF5C33F0).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.history,
                                              size: 16,
                                              color: Color(0xFF5C33F0),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Lịch sử',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1F2329),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                
                                for (int i = 0; i < sortedKeys.length; i++) {
                                  final dateKey = sortedKeys[i];
                                  final journeys = groupedJourneys[dateKey]!;
                                  final dateTitle = _getDateTitle(dateKey);
                                  
                                  // Thêm divider với time title
                                  widgets.add(_buildDateDivider(dateTitle));
                                  
                                  // Thêm các journey items của ngày đó
                                  for (int j = 0; j < journeys.length; j++) {
                                    final isLastItemOfDay = j == journeys.length - 1;
                                    final isLastItemOverall = i == sortedKeys.length - 1 && isLastItemOfDay;
                                    
                                    widgets.add(
                                      JourneyItem(
                                        dataItem: journeys[j],
                                        isLast: isLastItemOverall,
                                      ),
                                    );
                                  }
                                }
                                
                                return widgets;
                              }(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Background trắng che phần trống 20px ở dưới
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: viewInsets.bottom + 20,
            child: Container(
              color: Colors.white,
            ),
          ),
          Positioned(
            bottom: viewInsets.bottom + 20, // Đưa input lên cao hơn 20px
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isInputFocused)
                  GestureDetector(
                    onTap: () {
                      // Ngăn chặn sự kiện tap truyền xuống GestureDetector bên dưới
                    },
                    child: StageSelect(
                      stage: selectedStage,
                      setStage: (stage) {
                        setState(() {
                          selectedStage = stage;
                        });
                      },
                      orgId: GoRouterState.of(context).pathParameters['organizationId']!,
                      workspaceId: GoRouterState.of(context).pathParameters['workspaceId']!,
                    ),
                  ),
                if (!_isInputFocused)
                  Divider(height: 1, color: Colors.black.withValues(alpha: 0.1)),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(top: 8, bottom: 12, left: 16, right: 8), // Điều chỉnh padding
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          focusNode: _focusNode,
                          cursorColor: Colors.black,
                          controller: chatController,
                          maxLines: 5,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          onTap: () {
                            setState(() {
                              _isInputFocused = true;
                              // selectedStage sẽ được set khi user chọn trong StageSelect
                            });
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0x66F3EEEE),
                            hintText: "Nhập nội dung ghi chú",
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 8, right: 8), // Thêm margin để cách lề phải
                        child: IconButton(
                          padding: const EdgeInsets.all(8), // Giảm padding để nút gọn hơn
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ), // Giảm kích thước tối thiểu
                          onPressed: () async {
                          if (!_isInputFocused) {
                            _showCallMethodBottomSheet();
                          } else {
                            // Kiểm tra xem có chọn stage hoặc có nội dung ghi chú không
                            if (selectedStage == null && chatController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng chọn trạng thái hoặc nhập nội dung ghi chú'),
                                ),
                              );
                              return;
                            }

                            final params =
                                GoRouterState.of(context).pathParameters;
                            final organizationId = params['organizationId']!;
                            final workspaceId = params['workspaceId']!;
                            final customerId = params['customerId']!;

                            try {
                              final noteContent = chatController.text.trim();
                              final stageId = selectedStage?.id ?? '';
                              
                              print('Sending journey update with stageId: $stageId, note: $noteContent');
                              
                              await ref
                                  .read(customerJourneyProvider(customerId)
                                      .notifier)
                                  .updateJourney(
                                    organizationId,
                                    workspaceId,
                                    stageId,
                                    noteContent,
                                  );
                              chatController.clear();
                              setState(() {
                                selectedStage = null;
                                _isInputFocused = false;
                              });
                              _iconAnimationController.reverse();
                              FocusScope.of(context).unfocus();
                            } catch (e) {
                              print('Error sending journey update: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Có lỗi xảy ra khi gửi ghi chú: $e'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: !_isInputFocused
                              ? const Icon(
                                  Icons.phone_outlined,
                                  key: ValueKey('phone'),
                                  color: Color(0xFF5C33F0),
                                  size: 24,
                                )
                              : SvgPicture.asset(
                                  "assets/icons/send_1_icon.svg",
                                  key: const ValueKey('send'),
                                  color: const Color(0xFF5C33F0),
                                ),
                        ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
