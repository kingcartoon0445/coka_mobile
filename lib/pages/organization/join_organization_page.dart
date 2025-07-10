import 'dart:async';
import '../../core/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:coka/api/repositories/organization_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:coka/shared/widgets/search_bar.dart';
import 'package:coka/shared/widgets/loading_indicator.dart';
import 'package:coka/shared/widgets/avatar_widget.dart';
import 'package:coka/shared/widgets/loading_dialog.dart';
import 'package:coka/core/theme/text_styles.dart';
import 'package:coka/core/theme/app_colors.dart';
class JoinOrganizationPage extends StatefulWidget {
  const JoinOrganizationPage({super.key});

  @override
  State<JoinOrganizationPage> createState() => _JoinOrganizationPageState();
}

class _JoinOrganizationPageState extends State<JoinOrganizationPage> {
  List<dynamic> orgList = [];
  bool isFetching = false;

  Timer? _debounce;
  TextEditingController searchController = TextEditingController();
  final OrganizationRepository _organizationRepository = OrganizationRepository(ApiClient());

  @override
  void initState() {
    super.initState();
    fetchListOrg('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchListOrg(String searchText) async {
    setState(() {
      isFetching = true;
    });
    
    try {
      final response = await _organizationRepository.searchOrganizationsToJoin(
        searchText: searchText,
      );
      
      setState(() {
        isFetching = false;
        
        if (Helpers.isResponseSuccess(response)) {
          orgList = response['content'] ?? [];
        } else {
          // Hiển thị lỗi nếu cần
        }
      });
    } catch (e) {
      setState(() {
        isFetching = false;
      });
      // Xử lý lỗi
    }
  }

  void onDebounce(Function(String) searchFunction, int debounceTime) {
    // Hủy bỏ bất kỳ timer nào nếu có
    _debounce?.cancel();

    // Tạo mới timer với thời gian debounce
    _debounce = Timer(Duration(milliseconds: debounceTime), () {
      // Lấy dữ liệu từ trường văn bản và gọi hàm tìm kiếm
      searchFunction(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8FD),
        title: const Text(
          "Tham gia tổ chức",
          style: TextStyle(
              color: Color(0xFF1F2329),
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
              child: CustomSearchBar(
                width: double.infinity,
                hintText: "Nhập tên tổ chức",
                onQueryChanged: (value) {
                  onDebounce((v) {
                    fetchListOrg(value);
                  }, 800);
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: isFetching
                  ? const Center(child: LoadingIndicator())
                  : orgList.isEmpty
                      ? const Center(
                          child: Text('Hãy tìm tổ chức mà bạn muốn tham gia', 
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        )
                      : ListView.builder(
                          itemBuilder: (context, index) {
                            return JoinOrgItem(
                              dataItem: orgList[index],
                              organizationRepository: _organizationRepository,
                            );
                          },
                          itemCount: orgList.length,
                          shrinkWrap: true,
                        ),
            )
          ],
        ),
      ),
    );
  }
}

class JoinOrgItem extends StatefulWidget {
  final Map<String, dynamic> dataItem;
  final OrganizationRepository organizationRepository;
  
  const JoinOrgItem({
    super.key,
    required this.dataItem,
    required this.organizationRepository,
  });

  @override
  State<JoinOrgItem> createState() => _JoinOrgItemState();
}

class _JoinOrgItemState extends State<JoinOrgItem> {
  int stageBtn = 0;
  
  @override
  void initState() {
    super.initState();
    // Kiểm tra nếu đã gửi yêu cầu
    if (widget.dataItem['isRequest'] == true) {
      stageBtn = 1;
    }
  }

  Future<void> sendJoinRequest() async {
    if (widget.dataItem["isRequest"] == true || stageBtn == 1) {
      return;
    }
    
    showLoadingDialog(context);
    
    try {
      final response = await widget.organizationRepository.requestToJoinOrganization(
        widget.dataItem["organizationId"],
      );
      
      Navigator.of(context).pop(); // Đóng dialog
      
      if (Helpers.isResponseSuccess(response)) {
        setState(() {
          stageBtn = 1;
        });
      }
    } catch (e) {
      Navigator.of(context).pop(); // Đóng dialog khi có lỗi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        leading: widget.dataItem['avatar'] == null
            ? AppAvatar(
                fallbackText: widget.dataItem['name'],
                size: 36,
              )
            : AppAvatar(
                imageUrl: widget.dataItem["avatar"],
                size: 36,
              ),
        title: Text(
          widget.dataItem["name"],
          style: TextStyles.heading3,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          widget.dataItem["subscription"] == "PERSONAL"
              ? "Cá nhân"
              : "Doanh nghiệp",
          style: TextStyles.subtitle1,
        ),
        trailing: SizedBox(
          height: 28,
          child: ElevatedButton(
            onPressed: sendJoinRequest,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: Size.zero,
              backgroundColor: stageBtn == 1 || widget.dataItem["isRequest"] == true
                  ? Colors.white
                  : AppColors.primary.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: stageBtn == 1 || widget.dataItem["isRequest"] == true
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              stageBtn != 0 || widget.dataItem["isRequest"] == true
                  ? "Đã gửi"
                  : "Tham gia",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: stageBtn != 0 || widget.dataItem["isRequest"] == true
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 