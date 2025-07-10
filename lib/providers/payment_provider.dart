import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/api/repositories/payment_repository.dart';
import 'package:coka/models/wallet_info.dart';
import 'package:coka/models/package_data.dart';
import 'package:coka/providers/app_providers.dart';

// State class for Payment
class PaymentState {
  final WalletInfo? walletInfo;
  final List<PackageData> packages;
  final PackageData? selectedPackage;
  final bool isLoading;
  final String? error;

  const PaymentState({
    this.walletInfo,
    this.packages = const [],
    this.selectedPackage,
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    WalletInfo? walletInfo,
    List<PackageData>? packages,
    PackageData? selectedPackage,
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      walletInfo: walletInfo ?? this.walletInfo,
      packages: packages ?? this.packages,
      selectedPackage: selectedPackage ?? this.selectedPackage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Helper method to check if payment is possible
  bool get canPay {
    if (walletInfo == null || selectedPackage == null) return false;
    return walletInfo!.credit >= selectedPackage!.totalCost;
  }
}

// Note: PaymentRepository provider is now defined in app_providers.dart

// Provider for Payment State
class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRepository _repository;

  PaymentNotifier(this._repository) : super(const PaymentState());

  /// Tải dữ liệu thanh toán (ví và gói)
  Future<void> loadPaymentData(String orgId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Tải thông tin ví và danh sách gói song song
      final walletResponse = _repository.getWalletDetail(orgId);
      final packagesResponse = _repository.getFeaturePackages(orgId);

      final results = await Future.wait([walletResponse, packagesResponse]);
      
      WalletInfo? walletInfo;
      List<PackageData> packages = [];

      // Xử lý kết quả ví
      if (results[0].isSuccess) {
        walletInfo = results[0].data as WalletInfo?;
      } else {
        _showErrorToast('Lỗi khi tải thông tin ví: ${results[0].message}');
      }

      // Xử lý kết quả gói
      if (results[1].isSuccess) {
        packages = (results[1].data as List<PackageData>?) ?? [];
        // Sắp xếp gói theo giá tăng dần
        packages.sort((a, b) => a.value.compareTo(b.value));
      } else {
        _showErrorToast('Lỗi khi tải danh sách gói: ${results[1].message}');
      }

      state = state.copyWith(
        walletInfo: walletInfo,
        packages: packages,
        selectedPackage: packages.isNotEmpty ? packages.first : null,
        isLoading: false,
      );
    } catch (error) {
      final errorMessage = 'Có lỗi xảy ra khi tải dữ liệu thanh toán: $error';
      state = state.copyWith(
        error: errorMessage,
        isLoading: false,
      );
      _showErrorToast(errorMessage);
    }
  }

  /// Chọn gói
  void selectPackage(PackageData package) {
    state = state.copyWith(selectedPackage: package);
  }

  /// Thực hiện thanh toán
  Future<bool> processPayment(String orgId, String workspaceId) async {
    if (state.selectedPackage == null) return false;

    try {
      final response = await _repository.orderAndPayPackage(
        orgId: orgId,
        packageId: state.selectedPackage!.id,
        workspaceId: workspaceId,
      );

      if (response.isSuccess) {
        // TODO: Show success message
        print('Thanh toán thành công');
        return true;
      } else {
        _showErrorToast(response.message);
        return false;
      }
    } catch (error) {
      _showErrorToast('Có lỗi xảy ra khi thực hiện thanh toán: $error');
      return false;
    }
  }

  void _showErrorToast(String message) {
    // TODO: Implement toast/snackbar showing using your preferred method
    print('Error: $message');
  }
}

// Provider cho Payment State Notifier
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final repository = ref.read(paymentRepositoryProvider);
  return PaymentNotifier(repository);
}); 