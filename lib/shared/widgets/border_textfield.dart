import 'package:flutter/material.dart';

class BorderTextField extends StatelessWidget {
  final String name, nameHolder;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool? isRequire, isEditAble, enable;
  final TextInputType? textInputType;
  final Widget? preIcon, suffixIcon;
  final TextEditingController controller;
  final Color? fillColor;
  final double? borderRadius;
  final Function? onTooltipClick;
  const BorderTextField(
      {super.key,
      required this.name,
      required this.nameHolder,
      this.isRequire = false,
      this.preIcon,
      required this.controller,
      this.validator,
      this.isEditAble = true,
      this.maxLines,
      this.textInputType,
      this.suffixIcon,
      this.fillColor = const Color(0xFFF8F8F8),
      this.borderRadius = 18,
      this.onTooltipClick,
      this.enable});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name != "")
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        color: Color(0xFF1F2329),
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  isRequire ?? false
                      ? const Text(
                          "*",
                          style:
                              TextStyle(color: Color(0xFFFB0038), fontSize: 20),
                        )
                      : onTooltipClick != null
                          ? Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: InkWell(
                                child: const Icon(Icons.help_outline),
                                onTap: () {
                                  onTooltipClick!();
                                },
                              ),
                            )
                          : Container()
                ],
              ),
            ),
          AbsorbPointer(
            absorbing: !(isEditAble ?? true),
            child: TextFormField(
              validator: validator,
              controller: controller,
              cursorColor: Colors.black,
              keyboardType: textInputType,
              enabled: enable,
              maxLines: maxLines ?? 1,
              decoration: InputDecoration(
                  prefixIcon: preIcon,
                  suffixIcon: suffixIcon,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  hintText: nameHolder,
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius ?? 18),
                      borderSide: BorderSide.none)),
            ),
          )
        ],
      ),
    );
  }
}
