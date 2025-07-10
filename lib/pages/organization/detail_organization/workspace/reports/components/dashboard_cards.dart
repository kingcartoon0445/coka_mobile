import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardCards extends StatelessWidget {
  final Map<String, dynamic> data;
  final String organizationId;
  final String workspaceId;

  const DashboardCards({
    super.key,
    required this.data,
    required this.organizationId,
    required this.workspaceId,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Lấy dữ liệu từ content nếu có, nếu không thì sử dụng data
      final contentData = data['content'] as Map<String, dynamic>? ?? data;

      final cards = {
        "customer": {
          "name": "Khách hàng",
          "icon": const Icon(Icons.person_outline, size: 22),
          "value": (contentData['totalContact'] as num?)?.toInt() ?? 0,
          "color": const Color(0xFFE3DFFF),
          "onPressed": () {
            context.go(
                '/organization/$organizationId/workspace/$workspaceId/customers');
          }
        },
        "demand": {
          "name": "Nhu cầu",
          "icon": const Icon(Icons.assignment_outlined, size: 22),
          "value": (contentData['totalDemand'] as num?)?.toInt() ?? 0,
          "color": const Color(0xFFE3DFFF),
          "onPressed": () {
            context.go(
                '/organization/$organizationId/workspace/$workspaceId/customers');
          }
        },
        "product": {
          "name": "Sản phẩm",
          "icon": const Icon(Icons.shopping_bag_outlined, size: 22),
          "value": (contentData['totalProduct'] as num?)?.toInt() ?? 0,
          "color": const Color(0xFFE3DFFF),
          "onPressed": () {
            context.go(
                '/organization/$organizationId/workspace/$workspaceId/customers');
          }
        },
        "member": {
          "name": "Sales",
          "icon": const Icon(Icons.people_outline, size: 22),
          "value": (contentData['totalMember'] as num?)?.toInt() ?? 0,
          "color": const Color(0xFFE3DFFF),
          "onPressed": () {
            context.go(
                '/organization/$organizationId/workspace/$workspaceId/teams');
          }
        },
      };

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.15,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: cards.entries.map((e) => _buildCard(e.value)).toList(),
      );
    } catch (e) {
      print('Error in DashboardCards: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildCard(Map<String, dynamic> card) {
    return GestureDetector(
      onTap: card["onPressed"] as Function(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: card['icon'] as Widget,
                ),
                const SizedBox(width: 4),
                Text(
                  card['value'].toString(),
                  style: const TextStyle(
                    color: Color(0xFF5A48F1),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Text(
              card['name'] as String,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
