import 'package:flutter/material.dart' hide Image;
import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/utils/helpers.dart';
import '../../../../../../../shared/widgets/custom_container.dart';
import '../../../../../../../shared/widgets/awesome_alert.dart';
import '../../../../../../../shared/widgets/image_viewer_page.dart';
import '../../../../../../../providers/customer_provider.dart';
import '../../../../../../../api/repositories/customer_repository.dart';
import '../../../../../../../api/api_client.dart';
import '../widgets/assign_to_bottomsheet.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';


final customerRepositoryProvider = Provider((ref) {
  return CustomerRepository(ApiClient());
});

class CustomerBasicInfoPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> customerDetail;

  const CustomerBasicInfoPage({
    super.key,
    required this.customerDetail,
  });

  @override
  ConsumerState<CustomerBasicInfoPage> createState() =>
      _CustomerBasicInfoPageState();
}

class _CustomerBasicInfoPageState extends ConsumerState<CustomerBasicInfoPage> {
  SMIInput<double>? _rating;
  List<Map<String, dynamic>> subPhoneList = [];
  List<Map<String, dynamic>> subEmailList = [];
  String? fbUrl, zaloUrl;
  final _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isUploadingAvatar = false;
  String? _avatarCacheKey; // Thêm cache key cho avatar

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(customerDetailProvider(widget.customerDetail['id']).notifier)
          .state = AsyncValue.data(widget.customerDetail);
    });
    _initializeData();
  }

  void _initializeData() {
    final customerDetail = widget.customerDetail;

    // Initialize sub phone and email lists
    if (customerDetail["additional"]?.isNotEmpty ?? false) {
      for (var x in customerDetail["additional"]) {
        if (x["key"] == "phone") {
          subPhoneList.add({"value": x["value"], "name": x["name"]});
        } else if (x["key"] == "email") {
          subEmailList.add({"value": x["value"], "name": x["name"]});
        }
      }
    }

    // Initialize social links
    if (customerDetail["social"]?.isNotEmpty ?? false) {
      for (var x in customerDetail["social"]) {
        if (x["provider"] == "FACEBOOK") {
          fbUrl = x["profileUrl"];
        }
      }
    }

    // Generate Zalo URL from phone number
    if (customerDetail["phone"] != null) {
      zaloUrl = "https://zalo.me/${customerDetail["phone"]}";
    }


  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
      onStateChange: (stateMachineName, stateName) {
        if (_rating?.value !=
            ((widget.customerDetail["rating"] ?? 0).toDouble())) {
          onRatingUpdate(_rating?.value);
        }
      },
    );
    artboard.addController(controller!);
    _rating = controller.findInput<double>('rating') as SMINumber;
    _rating?.value = (widget.customerDetail["rating"] ?? 0).toDouble();
  }

  Future<void> onRatingUpdate(double? rating) async {
    if (rating == null) return;

    try {
      final params = GoRouterState.of(context).pathParameters;
      final organizationId = params['organizationId']!;
      final workspaceId = params['workspaceId']!;
      final customerId = widget.customerDetail['id'];

      await ref.read(customerRepositoryProvider).updateRating(
            organizationId,
            workspaceId,
            customerId,
            rating.toInt(),
          );

      if (mounted) {
        ref
            .read(customerDetailProvider(widget.customerDetail['id']).notifier)
            .state = AsyncValue.data({
          ...widget.customerDetail,
          'rating': rating.toInt(),
        });

        ref.invalidate(customerJourneyProvider(customerId));
        
        await ref
            .read(customerJourneyProvider(customerId).notifier)
            .loadJourneyList(organizationId, workspaceId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật đánh giá'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      errorAlert(
        title: "Lỗi",
        desc: "Không thể thực hiện cuộc gọi",
      );
    }
  }

  Future<void> _sendSms(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      errorAlert(
        title: "Lỗi",
        desc: "Không thể gửi tin nhắn",
      );
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      errorAlert(
        title: "Lỗi",
        desc: "Không thể gửi email",
      );
    }
  }

  Future<void> _openImagePicker() async {
    if (_isUploadingAvatar) return; // Prevent multiple uploads
    
    final pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 85,
    );
    if (pickedImage != null) {
      setState(() {
        _pickedImage = pickedImage;
      });
      // Upload in background after UI update
      _updateAvatar();
    }
  }

  /// Reset picked image về null để hiển thị avatar từ server
  void _resetPickedImage() {
    setState(() {
      _pickedImage = null;
    });
  }

  Future<void> _updateAvatar() async {
    if (_pickedImage == null) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final params = GoRouterState.of(context).pathParameters;
      final organizationId = params['organizationId']!;
      final workspaceId = params['workspaceId']!;
      final customerId = widget.customerDetail['id'];

      // Prepare form data with avatar file - using correct field name 'file' according to API
      final formData = FormData();
      formData.files.add(
        MapEntry(
          'file',
          await MultipartFile.fromFile(
            _pickedImage!.path,
            filename: _pickedImage!.path.split('/').last,
            contentType: MediaType("image", "jpeg"),
          ),
        ),
      );

      // Update customer avatar using dedicated API
      await ref.read(customerRepositoryProvider).updateAvatar(
        organizationId,
        workspaceId,
        customerId,
        formData,
      );

      if (mounted) {
        // Clear cache cũ cho avatar
        await Helpers.clearImageCache(widget.customerDetail['avatar']);
        
        // Refresh customer detail
        await ref
            .read(customerDetailProvider(widget.customerDetail['id']).notifier)
            .loadCustomerDetail(organizationId, workspaceId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật avatar thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Giữ nguyên picked image để hiển thị, không reset về null
        // Chỉ cập nhật cache key để force refresh khi cần
        setState(() {
          _avatarCacheKey = DateTime.now().millisecondsSinceEpoch.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể cập nhật avatar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Reset picked image on error
        _resetPickedImage();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildDetailProfileList(Map<String, dynamic> customerData) {
    return [
      {
        "name": "Giới tính",
        "value": customerData["gender"] != null
            ? (customerData["gender"] == 1
                ? "Nam"
                : customerData["gender"] == 0
                    ? "Nữ"
                    : "Khác")
            : ""
      },
      {
        "name": "Sinh nhật",
        "value": customerData["dob"] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(customerData["dob"]))
            : ""
      },
      {
        "name": "Nghề nghiệp",
        "value": customerData["work"] ?? ""
      },
      {
        "name": "Nơi ở",
        "value": customerData["address"] ?? ""
      },
      {
        "name": "CMND/CCCD",
        "value": customerData["physicalId"] ?? ""
      },
      {
        "name": "Phân loại khách hàng",
        "value": customerData["source"]?.isNotEmpty == true
            ? (customerData["source"]?.last["sourceName"] ?? "")
            : ""
      },
      {
        "name": "Nguồn khách hàng",
        "value": customerData["source"]?.isNotEmpty == true
            ? (customerData["source"]?.last["utmSource"] ?? "")
            : ""
      },
    ];
  }

  Widget _buildTagsSection(Map<String, dynamic> customerData) {
    final tags = customerData["tags"] as List<dynamic>? ?? [];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: CustomContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nhãn",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2329),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            tags.isEmpty
                ? const Text(
                    "Chưa có nhãn phân loại",
                    style: TextStyle(
                      color: Color(0xB2000000),
                      fontSize: 14,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map<Widget>((tag) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          tag.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2329),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerDetail =
        ref.watch(customerDetailProvider(widget.customerDetail['id']));

    final customerData = customerDetail.value ?? {};
    final mainIcons = [
      {
        "id": "phone",
        "icon": const Icon(Icons.phone, color: Color(0xFF554FE8), size: 25),
        "onTap": () async {
          if (customerData["phone"] != null) {
            await _makePhoneCall(customerData["phone"]);
          }
        }
      },
      {
        "id": "sms",
        "icon": const Icon(Icons.chat, color: Color(0xFF554FE8), size: 25),
        "onTap": () async {
          if (customerData["phone"] != null) {
            await _sendSms(customerData["phone"]);
          }
        }
      },
      {
        "id": "mail",
        "icon": customerData["email"] != null
            ? const Icon(Icons.mail, color: Color(0xFF554FE8), size: 25)
            : const Icon(Icons.mail, color: Color(0xFFF8F8F8), size: 25),
        "onTap": () async {
          if (customerData["email"] != null) {
            await _sendEmail(customerData["email"]);
          }
        }
      },
      {
        "id": "facebook",
        "icon": fbUrl != null
            ? const Icon(Icons.facebook, color: Color(0xFF554FE8), size: 25)
            : const Icon(Icons.facebook, color: Color(0xFFF8F8F8), size: 25),
        "onTap": () async {
          if (fbUrl != null) {
            final Uri url = Uri.parse(fbUrl!);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          }
        }
      },
      {
        "id": "zalo",
        "icon": SvgPicture.asset(
          'assets/icons/zalo_icon.svg',
          width: 25,
          height: 25,
        ),
        "onTap": () async {
          if (zaloUrl != null) {
            final Uri url = Uri.parse(zaloUrl!);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          }
        }
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Chi tiết khách hàng',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          MenuAnchor(
            style: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              elevation: const WidgetStatePropertyAll(4),
              shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.08)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: Color(0xFFE4E7EC),
                    width: 1,
                  ),
                ),
              ),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
            ),
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
            menuChildren: [
              MenuItemButton(
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  minimumSize: WidgetStatePropertyAll(Size.zero),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                leadingIcon: const Icon(
                  Icons.swap_horiz,
                  size: 20,
                  color: Color(0xFF667085),
                ),
                onPressed: () {
                  final params = GoRouterState.of(context).pathParameters;
                  final organizationId = params['organizationId']!;
                  final workspaceId = params['workspaceId']!;
                  final customerId = widget.customerDetail['id'];
                  
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AssignToBottomSheet(
                      organizationId: organizationId,
                      workspaceId: workspaceId,
                      customerId: customerId,
                      defaultAssignees: widget.customerDetail['assignToUsers'] != null 
                          ? List<Map<String, dynamic>>.from(widget.customerDetail['assignToUsers']) 
                          : [],
                      onSelected: (assignData) {
                        // Callback này không còn được sử dụng vì đã xử lý trực tiếp trong bottomsheet
                      },
                    ),
                  );
                },
                child: const Text(
                  'Chuyển phụ trách',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              MenuItemButton(
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  minimumSize: WidgetStatePropertyAll(Size.zero),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                leadingIcon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFF667085),
                ),
                onPressed: () {
                  final params = GoRouterState.of(context).pathParameters;
                  final organizationId = params['organizationId']!;
                  final workspaceId = params['workspaceId']!;
                  final customerId = widget.customerDetail['id'];
                  
                  context.push(
                    '/organization/$organizationId/workspace/$workspaceId/customers/$customerId/edit',
                    extra: widget.customerDetail,
                  );
                },
                child: const Text(
                  'Chỉnh sửa khách hàng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              MenuItemButton(
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                  minimumSize: WidgetStatePropertyAll(Size.zero),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                leadingIcon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.red,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa khách hàng?'),
                      content: const Text('Hành động này không thể hoàn tác.'),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              final params = GoRouterState.of(context).pathParameters;
                              final organizationId = params['organizationId']!;
                              final workspaceId = params['workspaceId']!;
                              final customerId = widget.customerDetail['id'];
                              
                              await ref.read(customerDetailProvider(customerId).notifier).deleteCustomer(organizationId, workspaceId);
                              ref.read(customerListProvider.notifier).removeCustomer(customerId);
                              if (!context.mounted) return;
                              context.pop();
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa khách hàng')));
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          },
                          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Xóa khách hàng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: CustomContainer(
                      child: Column(
                        children: [
                          const SizedBox(height: 50),
                          Text(
                            customerData['fullName'] ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF171A1F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (customerData['work'] != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              customerData['work'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: 0.35,
                              child: RiveAnimation.asset(
                                'assets/animations/rating_animation.riv',
                                onInit: _onRiveInit,
                                stateMachines: const ["State Machine 1"],
                                useArtboardSize: true,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: mainIcons
                                  .map((e) => _buildCircleIcon(
                                        icon: e["icon"] as Widget,
                                        onTap: e["onTap"] as Function(),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: GestureDetector(
                            onTap: () {
                              // Ưu tiên hiển thị picked image trước
                              if (_pickedImage != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageViewerPage(
                                      imageFile: File(_pickedImage!.path),
                                    ),
                                  ),
                                );
                              } else if (customerData['avatar'] != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageViewerPage(
                                      imageUrl: customerData['avatar'],
                                    ),
                                  ),
                                );
                              }
                            },
                            child: _pickedImage != null
                                ? ClipOval(
                                    child: widgets.Image.file(
                                      File(_pickedImage!.path),
                                      width: 68,
                                      height: 68,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : AppAvatar(
                                    imageUrl: customerData['avatar'],
                                    fallbackText: customerData['fullName'] ?? '',
                                    size: 68,
                                    shape: AvatarShape.circle,
                                    cacheKey: _avatarCacheKey,
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _isUploadingAvatar ? null : () {
                              _openImagePicker();
                            },
                            child: Container(
                              height: 30,
                              width: 30,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isUploadingAvatar 
                                    ? Colors.grey[300] 
                                    : const Color(0xFFe5f4ff),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: _isUploadingAvatar
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.black,
                                      size: 18,
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
            const Gap(18),
            _buildTagsSection(customerData),
            const Gap(18),
            _buildInfoSection(
              title: "Số điện thoại",
              mainValue: customerData["rawPhone"],
              subValues: subPhoneList,
            ),
            const Gap(18),
            _buildInfoSection(
              title: "Email",
              mainValue: customerData["email"],
              subValues: subEmailList,
            ),
            const Gap(18),
            _buildInfoSection(
              title: "Thông tin khách hàng",
              items: _buildDetailProfileList(customerData),
              showMainLabel: false,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIcon({
    required Widget icon,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFE3DFFF),
          shape: BoxShape.circle,
        ),
        child: icon,
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    String? mainValue,
    List<Map<String, dynamic>>? subValues,
    List<Map<String, dynamic>>? items,
    bool showMainLabel = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: CustomContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2329),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (mainValue != null && showMainLabel)
              _buildInfoRow(name: "Chính", value: mainValue),
            if (subValues != null)
              ...subValues.map((e) => _buildInfoRow(
                    name: e["name"],
                    value: e["value"],
                  )),
            if (items != null)
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    _buildInfoRow(
                      name: item["name"],
                      value: item["value"] ?? "",
                    ),
                    if (index < items.length - 1)
                      const Divider(
                        color: Color(0x33000000),
                        height: 6,
                        thickness: 0,
                      ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String name,
    required String value,
  }) {
    final displayValue = value.isEmpty ? "" : value;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(color: Color(0xB2000000)),
          ),
          const Spacer(),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 165,
            ),
            child: SelectableText(
              displayValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: displayValue.isEmpty ? const Color(0xB2000000) : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
