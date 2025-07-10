import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/core/theme/text_styles.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';
import 'package:coka/shared/widgets/awesome_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/providers.dart';

class ProfileRequestItem extends ConsumerWidget {
  final Map<String, dynamic> dataItem;
  final Function onReload;

  const ProfileRequestItem({
    super.key,
    required this.dataItem,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        leading: AppAvatar(
          size: 36,
          shape: AvatarShape.circle,
          imageUrl: dataItem['organization']['avatar'],
          fallbackText: dataItem['organization']['name'],
        ),
        title: Text(
          dataItem['organization']['name'] ?? '',
          style: TextStyles.heading3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Yêu cầu tham gia',
          style: TextStyles.subtitle1,
        ),
        trailing: SizedBox(
          height: 28,
          child: ElevatedButton(
            onPressed: () => _cancelRequest(context, ref),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: Size.zero,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _cancelRequest(BuildContext context, WidgetRef ref) {
    showAwesomeAlert(
      context: context,
      title: 'Xác nhận',
      description: 'Bạn có chắc muốn hủy yêu cầu tham gia tổ chức này?',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
      isWarning: true,
      icon: Icons.help_outline,
      onConfirm: () async {
        try {
          final repository = ref.read(organizationRepositoryProvider);
          final result = await repository.cancelJoinRequest(dataItem['id']);
          
          if (result['code'] == 0) {
            showAwesomeAlert(
              context: context,
              title: 'Thành công',
              description: 'Đã hủy yêu cầu tham gia tổ chức',
              confirmText: 'Đóng',
              icon: Icons.check_circle_outline,
            );
            onReload();
          } else {
            showAwesomeAlert(
              context: context,
              title: 'Thất bại',
              description: result['message'] ?? 'Có lỗi xảy ra',
              confirmText: 'Đóng',
              icon: Icons.error_outline,
              isWarning: true,
              iconColor: const Color(0xFFFFE9E9),
            );
          }
        } catch (e) {
          showAwesomeAlert(
            context: context,
            title: 'Thất bại',
            description: 'Có lỗi xảy ra',
            confirmText: 'Đóng',
            icon: Icons.error_outline,
            isWarning: true,
            iconColor: const Color(0xFFFFE9E9),
          );
        }
      },
    );
  }
}

class ProfileInviteItem extends ConsumerWidget {
  final Map<String, dynamic> dataItem;
  final Function onReload;

  const ProfileInviteItem({
    super.key,
    required this.dataItem,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        leading: AppAvatar(
          size: 36,
          shape: AvatarShape.circle,
          imageUrl: dataItem['organization']['avatar'],
          fallbackText: dataItem['organization']['name'],
        ),
        title: Text(
          dataItem['organization']['name'] ?? '',
          style: TextStyles.heading3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Mời bạn tham gia',
          style: TextStyles.subtitle1,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: () => _acceptInvitation(context, ref, true),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: Size.zero,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Đồng ý',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: () => _acceptInvitation(context, ref, false),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: Size.zero,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  'Từ chối',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptInvitation(BuildContext context, WidgetRef ref, bool isAccept) {
    final action = isAccept ? 'đồng ý' : 'từ chối';
    final successMessage = isAccept ? 'Đã chấp nhận lời mời tham gia tổ chức' : 'Đã từ chối lời mời tham gia tổ chức';
    
    showAwesomeAlert(
      context: context,
      title: 'Xác nhận',
      description: 'Bạn có chắc muốn $action lời mời này?',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
      isWarning: true,
      icon: Icons.help_outline,
      onConfirm: () async {
        try {
          final repository = ref.read(organizationRepositoryProvider);
          final result = await repository.acceptOrRejectJoinRequest(
            dataItem['organizationId'],
            dataItem['id'],
            isAccept,
          );
          
          if (result['code'] == 0) {
            showAwesomeAlert(
              context: context,
              title: 'Thành công',
              description: successMessage,
              confirmText: 'Đóng',
              icon: Icons.check_circle_outline,
            );
            onReload();
          } else {
            showAwesomeAlert(
              context: context,
              title: 'Thất bại',
              description: result['message'] ?? 'Có lỗi xảy ra',
              confirmText: 'Đóng',
              icon: Icons.error_outline,
              isWarning: true,
              iconColor: const Color(0xFFFFE9E9),
            );
          }
        } catch (e) {
          showAwesomeAlert(
            context: context,
            title: 'Thất bại',
            description: 'Có lỗi xảy ra',
            confirmText: 'Đóng',
            icon: Icons.error_outline,
            isWarning: true,
            iconColor: const Color(0xFFFFE9E9),
          );
        }
      },
    );
  }
} 