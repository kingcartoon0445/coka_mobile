import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../api/repositories/organization_repository.dart';
import '../../../../api/api_client.dart';

class OrganizationDetailCard extends StatefulWidget {
  final String organizationId;

  const OrganizationDetailCard({
    super.key,
    required this.organizationId,
  });

  @override
  State<OrganizationDetailCard> createState() => _OrganizationDetailCardState();
}

class _OrganizationDetailCardState extends State<OrganizationDetailCard> {
  late final OrganizationRepository _organizationRepository;
  Map<String, dynamic>? _organizationDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _organizationRepository = OrganizationRepository(ApiClient());
    _fetchOrganizationDetail();
  }

  @override
  void didUpdateWidget(OrganizationDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationId != widget.organizationId) {
      setState(() {
        _isLoading = true;
        _organizationDetail = null;
      });
      _fetchOrganizationDetail();
    }
  }

  Future<void> _fetchOrganizationDetail() async {
    if (widget.organizationId == 'default') {
      return;
    }
    try {
      final response = await _organizationRepository
          .getOrganizationDetail(widget.organizationId);
      if (mounted) {
        setState(() {
          _organizationDetail = response['content'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Có lỗi xảy ra khi tải thông tin tổ chức')),
        );
      }
    }
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 150,
                        height: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_organizationDetail == null) {
      return const Center(child: Text('Không tìm thấy thông tin tổ chức'));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 12),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppAvatar(
                size: 60,
                shape: AvatarShape.rectangle,
                borderRadius: 16,
                fallbackText: _organizationDetail!['name'],
                imageUrl: _organizationDetail!['avatar'],
                outline: Border.all(
                  color: const Color(0xFFE3DFFF),
                  width: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _organizationDetail!['name'],
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Doanh nghiệp',
                      style: TextStyles.title,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_organizationDetail!['memberCount']} Thành Viên',
                      style: TextStyles.body.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? _buildShimmerLoading() : _buildContent();
  }
}
