import 'package:flutter/material.dart';

class AwesomeTextField extends StatelessWidget {
  final List dataList;
  final String? Function(String?)? validator;
  final TextInputType? textInputType;
  final int? maxLines;
  final String holderName, buttonName;
  final Function onAdded, onDeleted, onCategoryChanged;
  const AwesomeTextField(
      {super.key,
      required this.dataList,
      this.validator,
      this.textInputType,
      this.maxLines,
      required this.holderName,
      required this.onAdded,
      required this.onDeleted,
      required this.buttonName,
      required this.onCategoryChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...dataList.map((e) {
          final controller = e["controller"];
          var selectedMenu = e["category"];
          final isDelete = e["isDelete"] ?? false;

          return isDelete
              ? Container()
              : Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    validator: validator,
                    controller: controller,
                    cursorColor: Colors.black,
                    keyboardType: textInputType,
                    maxLines: maxLines ?? 1,
                    decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: PopupMenuButton(
                            initialValue: selectedMenu,
                            onSelected: (value) {
                              onCategoryChanged(e, value);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(selectedMenu,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1A1C1E))),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 16),
                                Container(
                                  height: 20,
                                  width: 1,
                                  color:
                                      const Color(0x00000000).withValues(alpha: 0.12),
                                )
                              ],
                            ),
                            itemBuilder: (context) {
                              return [
                                const PopupMenuItem(
                                  value: "Công việc",
                                  child: Text('Công việc'),
                                ),
                                const PopupMenuItem(
                                  value: "Cá nhân",
                                  child: Text('Cá nhân'),
                                ),
                              ];
                            },
                          ),
                        ),
                        suffixIcon: GestureDetector(
                            onTap: () {
                              onDeleted(e);
                            },
                            child: const Icon(Icons.remove_circle,
                                color: Color(0xFFC70000))),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        hintText: holderName,
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none)),
                  ),
                );
        }),
        TextButton.icon(
            onPressed: () {
              onAdded();
            },
            icon: const Icon(Icons.add),
            label: Text(
              buttonName,
            ))
      ],
    );
  }
}
