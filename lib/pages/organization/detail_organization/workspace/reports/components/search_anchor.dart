import 'package:flutter/material.dart';

class CustomSearchAnchor extends StatefulWidget {
  final Widget Function(BuildContext, CustomSearchController) builder;
  final CustomSearchController searchController;
  final Function(String) onTextChanged;
  final bool isFullScreen;
  final BoxConstraints viewConstraints;
  final List<Widget> Function(BuildContext, CustomSearchController)
      suggestionsBuilder;

  const CustomSearchAnchor({
    super.key,
    required this.builder,
    required this.searchController,
    required this.onTextChanged,
    required this.isFullScreen,
    required this.viewConstraints,
    required this.suggestionsBuilder,
  });

  @override
  State<CustomSearchAnchor> createState() => _CustomSearchAnchorState();
}

class _CustomSearchAnchorState extends State<CustomSearchAnchor> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      widget.searchController.text = _textController.text;
      widget.onTextChanged(_textController.text);
      setState(() {});
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _overlayEntry != null) {
        _closeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _closeOverlay();
    super.dispose();
  }

  void _openOverlay() {
    widget.searchController.isOpen = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _focusNode.requestFocus();
  }

  void _closeOverlay() {
    widget.searchController.isOpen = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: widget.viewConstraints.maxWidth,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height),
          child: Material(
            elevation: 4.0,
            child: Container(
              constraints: widget.viewConstraints,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _textController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _textController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: widget.suggestionsBuilder(
                          context, widget.searchController),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.builder(
          context,
          _CustomSearchControllerImpl(
            _textController,
            openViewCallback: _openOverlay,
            closeViewCallback: (text) {
              _textController.text = text;
              _closeOverlay();
            },
            clearCallback: () {
              _textController.clear();
            },
            isOpenValue: widget.searchController.isOpen,
          )),
    );
  }
}

class CustomSearchController {
  String text = '';
  bool isOpen = false;

  void openView() {}
  void closeView(String text) {}
  void clear() {}
}

class _CustomSearchControllerImpl extends CustomSearchController {
  final TextEditingController _textController;
  final VoidCallback openViewCallback;
  final Function(String) closeViewCallback;
  final VoidCallback clearCallback;

  _CustomSearchControllerImpl(
    this._textController, {
    required this.openViewCallback,
    required this.closeViewCallback,
    required this.clearCallback,
    required bool isOpenValue,
  }) {
    text = _textController.text;
    isOpen = isOpenValue;
  }

  @override
  void openView() {
    openViewCallback();
  }

  @override
  void closeView(String text) {
    closeViewCallback(text);
  }

  @override
  void clear() {
    clearCallback();
  }
}

// Badge widget để hiển thị trạng thái tìm kiếm
class Badge extends StatelessWidget {
  final Widget child;
  final bool isLabelVisible;

  const Badge({
    super.key,
    required this.child,
    this.isLabelVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (isLabelVisible)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
