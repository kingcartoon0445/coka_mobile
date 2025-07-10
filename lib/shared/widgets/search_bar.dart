import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({
    super.key,
    required this.hintText,
    this.showSelectIcon = false,
    this.onSelectAll,
    required this.onQueryChanged,
    required this.width,
  });
  final String? hintText;
  final bool showSelectIcon;
  final double width;
  final Function(bool)? onSelectAll;
  final Function(String) onQueryChanged;

  @override
  State<CustomSearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<CustomSearchBar> {
  final TextEditingController _textController = TextEditingController();
  bool _toggleSelectAll = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(48),
        color: const Color(0xFFF2F3F5),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextFormField(
              onChanged: widget.onQueryChanged,
              controller: _textController,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF2F3F5),
                contentPadding: const EdgeInsets.all(12.0),
                hintText: widget.hintText,
                prefixIcon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textController.clear();
                          widget.onQueryChanged('');
                        },
                      )
                    : widget.showSelectIcon
                        ? IconButton(
                            icon: _toggleSelectAll
                                ? const Icon(Icons.deselect)
                                : const Icon(Icons.select_all),
                            onPressed: widget.onSelectAll != null
                                ? () {
                                    setState(() {
                                      _toggleSelectAll = !_toggleSelectAll;
                                    });
                                    widget.onSelectAll!(_toggleSelectAll);
                                  }
                                : () => {},
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
