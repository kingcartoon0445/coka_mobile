import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../../../shared/widgets/avatar_widget.dart';
import 'package:coka/api/repositories/customer_repository.dart';
import 'package:coka/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../providers/customer_provider.dart';
import 'package:coka/core/utils/helpers.dart';
class ImportContactBottomSheet extends ConsumerStatefulWidget {
  final String organizationId;
  final String workspaceId;
  final VoidCallback onCustomerImported;

  const ImportContactBottomSheet({
    super.key,
    required this.organizationId,
    required this.workspaceId,
    required this.onCustomerImported,
  });

  @override
  ConsumerState<ImportContactBottomSheet> createState() =>
      _ImportContactBottomSheetState();
}

class _ImportContactBottomSheetState
    extends ConsumerState<ImportContactBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final CustomerRepository _customerRepository =
      CustomerRepository(ApiClient());

  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  List<String> _importedPhones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        // Lấy danh sách số điện thoại để check
        final phoneStringList =
            contacts.where((x) => x.phones.isNotEmpty).map((x) {
          String phone =
              x.phones.first.number.replaceAll(" ", "").replaceAll("-", "");
          if (phone.startsWith('+84')) {
            phone = '84${phone.substring(3)}';
          } else if (phone.startsWith('0')) {
            phone = '84${phone.substring(1)}';
          }
          return phone;
        }).toList();

        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
        });

        if (phoneStringList.isNotEmpty) {
          try {
            final response = await _customerRepository.checkPhone(
              widget.organizationId,
              widget.workspaceId,
              phoneStringList,
            );

            if (response != null && Helpers.isResponseSuccess(response)) {
              final phones = response['content']?['phones'] as List?;

              if (phones != null) {
                final existingPhones = phones.map((x) => x.toString()).toList();

                if (mounted) {
                  setState(() {
                    _importedPhones = existingPhones;
                  });
                }
              }
            }
          } catch (e) {
            print("Error checking phones: $e");
          }
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading contacts: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts
            .where((contact) =>
                contact.displayName.toLowerCase().contains(value.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _importContact(Contact contact) async {
    try {
      final phoneNumber =
          contact.phones.first.number.replaceAll(" ", "").replaceAll("-", "");
      String formattedPhone = phoneNumber;
      if (formattedPhone.startsWith('+84')) {
        formattedPhone = '84${formattedPhone.substring(3)}';
      } else if (formattedPhone.startsWith('0')) {
        formattedPhone = '84${formattedPhone.substring(1)}';
      }

      final formData = FormData();
      formData.fields.addAll([
        MapEntry("fullName", contact.displayName),
        MapEntry("phone", formattedPhone),
        const MapEntry("sourceId", "ce7f42cf-f10f-49d2-b57e-0c75f8463c82"),
      ]);

      final response = await _customerRepository.createCustomer(
        widget.organizationId,
        widget.workspaceId,
        formData,
      );

      ref.read(customerListProvider.notifier).addCustomer(response['content']);

      if (!mounted) return;

      setState(() {
        _importedPhones.add(formattedPhone);
      });

      widget.onCustomerImported();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm liên hệ thành công')),
      );
    } catch (e) {
      if (!mounted) return;

      if (e is DioException) {
        print("Error response data: ${e.response?.data}");
      }

      String errorMessage = 'Có lỗi xảy ra khi thêm liên hệ';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Widget _buildGroupHeader(String letter) {
    return Container(
      width: double.infinity,
      height: 32,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFFF3F4F6),
      child: Text(
        letter.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    if (contact.phones.isEmpty) return const SizedBox.shrink();

    final phoneNumber =
        contact.phones.first.number.replaceAll(" ", "").replaceAll("-", "");
    String formattedPhone = phoneNumber;
    if (formattedPhone.startsWith('+84')) {
      formattedPhone = '84${formattedPhone.substring(3)}';
    } else if (formattedPhone.startsWith('0')) {
      formattedPhone = '84${formattedPhone.substring(1)}';
    }

    print(
        "Checking phone: $formattedPhone against _importedPhones: $_importedPhones");
    final isImported = _importedPhones.contains(formattedPhone);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
          child: Row(
            children: [
              AppAvatar(
                fallbackText: contact.displayName,
                size: 40,
                shape: AvatarShape.circle,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.displayName,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(phoneNumber),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 9),
                decoration: BoxDecoration(
                  color: isImported
                      ? const Color(0xfffc6d72)
                      : const Color(0xFFfef0f1),
                  borderRadius: BorderRadius.circular(14),
                  border: isImported
                      ? null
                      : Border.all(color: const Color(0xFFf22128)),
                ),
                child: InkWell(
                  onTap: isImported ? null : () => _importContact(contact),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isImported ? 'Đã thêm' : 'Thêm',
                        style: TextStyle(
                          color: isImported
                              ? Colors.white
                              : const Color(0xFFf22128),
                          fontSize: 13,
                          fontWeight:
                              isImported ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (isImported) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 1,
          color: const Color(0xFFF3F4F6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Nhập từ danh bạ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 0.2,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Color(0xFFf3f4f6),
                          hintText: "Tìm kiếm",
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        final firstLetter = contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : '#';

                        final bool showHeader = index == 0 ||
                            _filteredContacts[index - 1]
                                    .displayName
                                    .toUpperCase()[0] !=
                                firstLetter;

                        return Column(
                          children: [
                            if (showHeader) _buildGroupHeader(firstLetter),
                            _buildContactItem(contact),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
