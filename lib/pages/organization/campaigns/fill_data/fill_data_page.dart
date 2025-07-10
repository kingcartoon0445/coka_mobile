import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/providers/fill_data_provider.dart';
import 'package:coka/providers/payment_provider.dart';
import 'package:coka/models/workspace_data.dart';
import 'package:coka/models/package_data.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';
import 'package:coka/core/theme/app_colors.dart';
import 'package:coka/shared/widgets/awesome_alert.dart';

class FillDataPage extends ConsumerStatefulWidget {
  final String organizationId;

  const FillDataPage({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<FillDataPage> createState() => _FillDataPageState();
}

class _FillDataPageState extends ConsumerState<FillDataPage> {
  @override
  void initState() {
    super.initState();
    // Tải dữ liệu khi trang được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fillDataProvider.notifier).loadWorkspaces(widget.organizationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fillDataState = ref.watch(fillDataProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Làm đầy dữ liệu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(fillDataProvider.notifier).refresh(widget.organizationId);
            },
          ),
        ],
      ),
      body: _buildBody(fillDataState),
    );
  }

  Widget _buildBody(FillDataState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Đã xảy ra lỗi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(fillDataProvider.notifier).refresh(widget.organizationId);
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.workspaces.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Chưa có workspace nào được tạo',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.workspaces.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WorkspaceItemCard(
            data: state.workspaces[index],
            organizationId: widget.organizationId,
          ),
        );
      },
    );
  }
}

class WorkspaceItemCard extends ConsumerWidget {
  final WorkspaceData data;
  final String organizationId;

  const WorkspaceItemCard({
    super.key,
    required this.data,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workspace info với avatar
          _buildWorkspaceInfo(context, ref),
          const SizedBox(height: 12),
          // Progress bar
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildWorkspaceInfo(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        AppAvatar(
          size: 48,
          fallbackText: data.workspaceName,
          shape: AvatarShape.circle,
          fallbackTextColor: Colors.white,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.workspaceName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (data.packageName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3DFFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          data.packageName!,
                          style: const TextStyle(
                            color: Colors.purple,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(data.statusName),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data.statusName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
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
        ),
        const SizedBox(width: 8),
        Switch(
          value: data.isActive,
          onChanged: (checked) => _onSwitchChanged(context, ref, checked),
          activeColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Stack(
      children: [
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Container(
          height: 20,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: data.usagePercentage,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              '${data.usage}/${data.usageLimit}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String statusName) {
    switch (statusName) {
      case "Đang chạy":
        return const Color(0xFF5EB640);
      case "Hết hạn":
      case "Hết hạn mức":
        return const Color(0xFFFE7F09);
      case "Tạm dừng":
        return const Color(0xFFFF0707);
      default:
        return const Color(0xFF64D9FF);
    }
  }

  void _onSwitchChanged(BuildContext context, WidgetRef ref, bool checked) {
    if (data.isInactive || data.isExpired || data.id == null) {
      // Hiển thị dialog thanh toán
      showDialog(
        context: context,
        builder: (context) => PaymentDialog(
          workspaceId: data.workspaceId,
          organizationId: organizationId,
        ),
      );
    } else {
      // Cập nhật trạng thái
      ref.read(fillDataProvider.notifier).updateWorkspaceStatus(
        organizationId,
        data.id!,
        checked ? 1 : 0,
      );
    }
  }
}

class PaymentDialog extends ConsumerStatefulWidget {
  final String workspaceId;
  final String organizationId;

  const PaymentDialog({
    super.key,
    required this.workspaceId,
    required this.organizationId,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentProvider.notifier).loadPaymentData(widget.organizationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: isVerySmallScreen 
            ? screenSize.height * 0.85 
            : isSmallScreen 
              ? screenSize.height * 0.9 
              : 690,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kích hoạt workspace',
                      style: TextStyle(
                        fontSize: isVerySmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: _buildDialogContent(paymentState, isVerySmallScreen),
            ),
            // Footer
            Container(
              padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: isVerySmallScreen 
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: paymentState.canPay ? () => _processPayment() : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Hoàn tất thanh toán',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Hủy'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: paymentState.canPay ? () => _processPayment() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Hoàn tất thanh toán',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogContent(PaymentState state, bool isVerySmallScreen) {
    if (state.isLoading) {
      return Padding(
        padding: EdgeInsets.all(isVerySmallScreen ? 20 : 40),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package selection
          _buildPackageSelection(state, isVerySmallScreen),
          const SizedBox(height: 16),
          // Payment method
          _buildPaymentMethod(state, isVerySmallScreen),
          const SizedBox(height: 16),
          // Order summary
          _buildOrderSummary(state, isVerySmallScreen),
        ],
      ),
    );
  }

  Widget _buildPackageSelection(PaymentState state, bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chọn gói thuê bao',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          ...state.packages.map((package) => _buildPackageOption(package, isVerySmallScreen)),
        ],
      ),
    );
  }

  Widget _buildPackageOption(PackageData package, bool isVerySmallScreen) {
    final paymentState = ref.watch(paymentProvider);
    bool isSelected = paymentState.selectedPackage?.id == package.id;

    return Container(
      margin: EdgeInsets.only(bottom: isVerySmallScreen ? 8 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(paymentProvider.notifier).selectPackage(package),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.backgroundSecondary : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.description,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isVerySmallScreen ? 13 : 15,
                          color: isSelected ? AppColors.primary : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${package.formattedPrice} Coin',
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.grey[600],
                          fontSize: isVerySmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.verified,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(PaymentState state, bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.wallet,
                size: 18,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Phương thức thanh toán',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: isVerySmallScreen ? 36 : 40,
                  height: isVerySmallScreen ? 36 : 40,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: isVerySmallScreen ? 18 : 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ví coka',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 13 : 15, 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Số dư ví: ${state.walletInfo?.formattedCredit ?? '0'} Coin',
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 11 : 13, 
                          color: Colors.grey[600]
                        ),
                      ),
                    ],
                  ),
                ),
                if (!state.canPay)
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to deposit page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chức năng nạp tiền sẽ được triển khai sau')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmallScreen ? 12 : 16, 
                        vertical: isVerySmallScreen ? 6 : 8
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Nạp tiền', 
                      style: TextStyle(fontSize: isVerySmallScreen ? 11 : 12)
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(PaymentState state, bool isVerySmallScreen) {
    if (state.selectedPackage == null) return const SizedBox();

    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 18,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chi tiết đơn hàng',
                  style: TextStyle(
                    fontSize: isVerySmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          Container(
            padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Tên gói', state.selectedPackage!.description, isVerySmallScreen),
                _buildSummaryRow('Giá', '${state.selectedPackage!.formattedPrice} Coin', isVerySmallScreen),
                _buildSummaryRow('Phí', 'Miễn phí', isVerySmallScreen),
                Divider(color: Colors.grey[300], height: isVerySmallScreen ? 20 : 24),
                _buildSummaryRow('Tổng cộng', '${state.selectedPackage!.formattedPrice} Coin', isVerySmallScreen, isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isVerySmallScreen, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 4 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isVerySmallScreen 
                  ? (isTotal ? 14 : 12) 
                  : (isTotal ? 16 : 14),
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? Colors.black87 : Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isVerySmallScreen 
                ? (isTotal ? 14 : 12) 
                : (isTotal ? 16 : 14),
              fontWeight: FontWeight.w600,
              color: isTotal ? AppColors.primary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    final paymentDialogContext = context;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Xác nhận thanh toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn thực hiện giao dịch này không?',
          style: TextStyle(fontSize: 15),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(confirmContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xác nhận',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ref.read(paymentProvider.notifier).processPayment(
          widget.organizationId,
          widget.workspaceId,
        );

        if (mounted && success) {
          // Close payment dialog
          Navigator.pop(paymentDialogContext);
          
          // Refresh fill data list
          ref.read(fillDataProvider.notifier).refresh(widget.organizationId);
          
          // Show success message
          if (mounted) {
            showAwesomeAlert(
              context: paymentDialogContext,
              title: 'Thành công!',
              description: 'Workspace đã được kích hoạt thành công',
              confirmText: 'Đóng',
              icon: Icons.check_circle_outline,
              iconColor: AppColors.success,
            );
          }
        }
             } catch (e) {
         if (mounted) {
           showAwesomeAlert(
             context: paymentDialogContext,
             title: 'Thất bại',
             description: 'Có lỗi xảy ra khi thanh toán: $e',
             confirmText: 'Đóng',
             icon: Icons.error_outline,
             iconColor: Colors.red,
           );
         }
       }
    }
  }
} 