import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../shared/widgets/avatar_widget.dart';
import '../../../../../../shared/widgets/elevated_btn.dart';
import '../ranking_sale_page.dart';

class UserStatistics extends ConsumerWidget {
  final Map<String, dynamic> data;

  const UserStatistics({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = data['content'] as List? ?? [];
    final categories = ["Xếp hạng Sale", "Xếp hạng Sàn"];

    // Tính toán chiều cao tối đa dựa trên số lượng người dùng
    final maxHeight = users.isEmpty
        ? 100.0 // Chiều cao tối thiểu khi không có dữ liệu
        : users.length < 10
            ? users.length * 57.0 +
                120.0 // Thêm padding cho TabBar (48) và padding dưới (72)
            : 700.0; // Tăng chiều cao tối đa thêm 30px

    return DefaultTabController(
      length: 2,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
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
        child: Column(
          children: [
            TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                ...categories.map(
                  (e) {
                    return Tab(
                      child: Text(e,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: TabBarView(children: [
                users.isEmpty
                    ? const Center(
                        child: Text(
                        "Chưa có thông tin",
                        style: TextStyle(fontSize: 16),
                      ))
                    : Column(
                        children: [
                          ...users.take(10).map((userData) {
                            // Thêm index cho mỗi user nếu chưa có
                            final index = users.indexOf(userData) + 1;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Text(
                                    index.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  _buildAvatar(userData),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userData['fullName'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            (userData['total'] ?? 0).toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF29315F),
                                                fontSize: 11),
                                          ),
                                          const Text(
                                            " Khách hàng",
                                            style: TextStyle(
                                                color: Color(0xFF29315F),
                                                fontSize: 11),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Icon(
                                              Icons.circle,
                                              size: 3,
                                            ),
                                          ),
                                          Text(
                                            (userData['potential'] ?? 0)
                                                .toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF29315F),
                                                fontSize: 11),
                                          ),
                                          const Text(
                                            " Tiềm năng",
                                            style: TextStyle(
                                                color: Color(0xFF29315F),
                                                fontSize: 11),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${NumberFormat('#,###').format(userData['revenue'] ?? 0)} đ",
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2329)),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        "${userData['transactions'] ?? 0} Giao dịch",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF29315F)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          }),
                          if (users.length >= 10)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: ElevatedBtn(
                                paddingAllValue: 6,
                                circular: 50,
                                onPressed: () {
                                  // Điều hướng đến trang RankingSalePage
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => RankingSalePage(
                                        userList: users.map((user) {
                                          // Đảm bảo mỗi user có index
                                          final index = users.indexOf(user) + 1;
                                          return {
                                            ...user as Map<String, dynamic>,
                                            'index': index,
                                          };
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Xem thêm",
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xB2000000)),
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 13,
                                      color: Color(0xB2000000),
                                    )
                                  ],
                                ),
                              ),
                            )
                        ],
                      ),
                // Tab thứ hai - Xếp hạng Sàn (hiện tại để trống)
                Container()
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> userData) {
    return AppAvatar(
      imageUrl: userData['avatar'],
      size: 40,
      shape: AvatarShape.circle,
      fallbackText: userData['fullName'] ?? 'Unknown',
    );
  }
}
