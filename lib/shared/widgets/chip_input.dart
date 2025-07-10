import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'suggestions_box_controller.dart';
import 'text_cursor.dart';

class ChipData {
  final String id;
  final String name;

  const ChipData(this.id, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChipData &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    return name;
  }
}

typedef ChipsInputSuggestions<T> = FutureOr<List<T>> Function(String query);
typedef ChipSelected<T> = void Function(T data, bool selected);
typedef ChipsBuilder<T> = Widget Function(
    BuildContext context, ChipsInputState<T> state, T data);

const kObjectReplacementChar = 0xFFFD;

extension on TextEditingValue {
  String get normalCharactersText => String.fromCharCodes(
        text.codeUnits.where((ch) => ch != kObjectReplacementChar),
      );

  List<int> get replacementCharacters => text.codeUnits
      .where((ch) => ch == kObjectReplacementChar)
      .toList(growable: true);

  int get replacementCharactersCount => replacementCharacters.length;
}

class ChipsInput<T> extends StatefulWidget {
  const ChipsInput({
    super.key,
    this.initialValue = const [],
    this.decoration = const InputDecoration(),
    this.enabled = true,
    required this.chipBuilder,
    required this.suggestionBuilder,
    this.findSuggestions,
    this.suggestions,
    required this.onChanged,
    this.maxChips,
    this.textStyle,
    this.suggestionsBoxMaxHeight,
    this.inputType = TextInputType.text,
    this.textOverflow = TextOverflow.clip,
    this.obscureText = false,
    this.autocorrect = true,
    this.actionLabel,
    this.inputAction = TextInputAction.unspecified,
    this.keyboardAppearance = Brightness.light,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.allowChipEditing = false,
    this.allowInputText = true,
    this.focusNode,
    this.initialSuggestions,
  }) : assert(maxChips == null || initialValue.length <= maxChips);

  final InputDecoration decoration;
  final TextStyle? textStyle;
  final bool enabled;
  final ChipsInputSuggestions<T>? findSuggestions;
  final List<T>? suggestions;
  final ValueChanged<List<T>> onChanged;
  final ChipsBuilder<T> chipBuilder;
  final ChipsBuilder<T> suggestionBuilder;
  final List<T> initialValue;
  final int? maxChips;
  final double? suggestionsBoxMaxHeight;
  final TextInputType inputType;
  final TextOverflow textOverflow;
  final bool obscureText;
  final bool autocorrect;
  final String? actionLabel;
  final TextInputAction inputAction;
  final Brightness keyboardAppearance;
  final bool autofocus;
  final bool allowChipEditing;
  final bool allowInputText;
  final FocusNode? focusNode;
  final List<T>? initialSuggestions;

  final TextCapitalization textCapitalization;

  @override
  ChipsInputState<T> createState() => ChipsInputState<T>();
}

class ChipsInputState<T> extends State<ChipsInput<T>>
    implements TextInputClient {
  Set<T> _chips = <T>{};
  List<T?>? _suggestions;
  final StreamController<List<T?>?> _suggestionsStreamController =
      StreamController<List<T>?>.broadcast();
  int _searchId = 0;
  TextEditingValue _value = const TextEditingValue();
  TextInputConnection? _textInputConnection;
  final _layerLink = LayerLink();
  final Map<T?, String> _enteredTexts = <T, String>{};

  TextInputConfiguration get textInputConfiguration => TextInputConfiguration(
        inputType: widget.inputType,
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        actionLabel: widget.actionLabel,
        inputAction: widget.inputAction,
        keyboardAppearance: widget.keyboardAppearance,
        textCapitalization: widget.textCapitalization,
      );

  bool get _hasInputConnection =>
      _textInputConnection != null && _textInputConnection!.attached;

  bool get _hasReachedMaxChips =>
      widget.maxChips != null && _chips.length >= widget.maxChips!;

  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode());
  late FocusAttachment _nodeAttachment;
  late SuggestionsBoxController suggestionsBoxController;

  RenderBox? get renderBox => context.findRenderObject() as RenderBox?;

  bool get _canRequestFocus => widget.enabled;

  @override
  void initState() {
    super.initState();
    _chips.addAll(widget.initialValue);
    suggestionsBoxController = SuggestionsBoxController(context);

    _suggestions = widget.initialSuggestions ??
        widget.suggestions
            ?.where((r) => !_chips.contains(r))
            .toList(growable: true);
    _effectiveFocusNode.addListener(_handleFocusChanged);
    _nodeAttachment = _effectiveFocusNode.attach(context);
    _effectiveFocusNode.canRequestFocus = _canRequestFocus;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initOverlayEntry();
      if (mounted && widget.autofocus) {
        FocusScope.of(context).autofocus(_effectiveFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _closeInputConnectionIfNeeded();
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _focusNode?.dispose();
    _suggestionsStreamController.close();
    suggestionsBoxController.close();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_effectiveFocusNode.hasFocus) {
      _openInputConnection();
      if (!widget.allowInputText) {
        suggestionsBoxController.toggle();
      } else {
        suggestionsBoxController.open();
      }
    } else {
      _closeInputConnectionIfNeeded();
      suggestionsBoxController.close();
    }
    if (mounted) {
      setState(() {
        /*rebuild so that _TextCursor is hidden.*/
      });
    }
  }

  void requestKeyboard() {
    if (_effectiveFocusNode.hasFocus) {
      _openInputConnection();
      if (!widget.allowInputText) {
        suggestionsBoxController.toggle();
      }
    } else {
      FocusScope.of(context).requestFocus(_effectiveFocusNode);
    }
  }

  void _initOverlayEntry() {
    suggestionsBoxController.overlayEntry = OverlayEntry(
      builder: (context) {
        final size = renderBox!.size;
        final renderBoxOffset = renderBox!.localToGlobal(Offset.zero);
        final topAvailableSpace = renderBoxOffset.dy;
        final mq = MediaQuery.of(context);
        final bottomAvailableSpace = mq.size.height -
            mq.viewInsets.bottom -
            renderBoxOffset.dy -
            size.height;
        var suggestionBoxHeight = max(topAvailableSpace, bottomAvailableSpace);
        if (null != widget.suggestionsBoxMaxHeight) {
          suggestionBoxHeight =
              min(suggestionBoxHeight, widget.suggestionsBoxMaxHeight!);
        }
        final showTop = topAvailableSpace > bottomAvailableSpace;
        final compositedTransformFollowerOffset =
            showTop ? Offset(0, -size.height) : Offset.zero;

        return Stack(
          children: [
            if (suggestionsBoxController.isOpened)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    suggestionsBoxController.close();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
            StreamBuilder<List<T?>?>(
              stream: _suggestionsStreamController.stream,
              initialData: _suggestions,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final suggestionsListView = Material(
                    elevation: 2,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: suggestionBoxHeight,
                      ),
                      child: snapshot.data!.isEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              child: const Text(
                                'Không có dữ liệu',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF667085),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: snapshot.data!.length,
                              physics: const ClampingScrollPhysics(),
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                height: 1,
                                thickness: 0.2,
                              ),
                              itemBuilder: (BuildContext context, int index) {
                                return _suggestions != null
                                    ? widget.suggestionBuilder(
                                        context,
                                        this,
                                        _suggestions![index] as T,
                                      )
                                    : Container();
                              },
                            ),
                    ),
                  );
                  return Positioned(
                    width: size.width,
                    child: CompositedTransformFollower(
                      link: _layerLink,
                      showWhenUnlinked: false,
                      offset: compositedTransformFollowerOffset,
                      child: !showTop
                          ? suggestionsListView
                          : FractionalTranslation(
                              translation: const Offset(0, -1),
                              child: suggestionsListView,
                            ),
                    ),
                  );
                }
                return Container();
              },
            ),
          ],
        );
      },
    );
  }

  void selectSuggestion(T data) {
    if (!_hasReachedMaxChips) {
      setState(() => _chips = _chips..add(data));
      if (widget.allowChipEditing) {
        final enteredText = _value.normalCharactersText;
        if (enteredText.isNotEmpty) _enteredTexts[data] = enteredText;
      }
      _updateTextInputState(replaceText: true);
      _onSearchChanged("");

      _suggestionsStreamController.add(_suggestions);
      if (_hasReachedMaxChips) suggestionsBoxController.close();
      widget.onChanged(_chips.toList(growable: true));
    } else {
      suggestionsBoxController.close();
    }
  }

  void deleteChip(T data) {
    if (widget.enabled) {
      setState(() {
        _chips.remove(data);
        if (widget.suggestions != null) {
          _suggestions =
              widget.suggestions!.where((r) => !_chips.contains(r)).toList();
          _suggestionsStreamController.add(_suggestions);
        }
      });
      if (_enteredTexts.containsKey(data)) _enteredTexts.remove(data);
      _updateTextInputState();
      widget.onChanged(_chips.toList(growable: true));
    }
  }

  void _openInputConnection() {
    if (!_hasInputConnection && widget.allowInputText) {
      _textInputConnection = TextInput.attach(this, textInputConfiguration);
      _textInputConnection!.show();
      _updateTextInputState();
    } else {
      _textInputConnection?.show();
    }
  }

  void _onSearchChanged(String value) async {
    final localId = ++_searchId;
    List<T>? results;

    if (widget.findSuggestions != null) {
      results = await widget.findSuggestions!(value);
    } else if (widget.suggestions != null) {
      results = widget.suggestions!
          .where(
              (r) => r.toString().toLowerCase().contains(value.toLowerCase()))
          .where((r) => !_chips.contains(r))
          .toList();
    }

    if (_searchId == localId && mounted && results != null) {
      setState(() => _suggestions = results);
      _suggestionsStreamController.add(_suggestions);
    }
    if (!suggestionsBoxController.isOpened && !_hasReachedMaxChips) {
      suggestionsBoxController.open();
    }
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
    }
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    if (!widget.allowInputText) return;

    final oldTextEditingValue = _value;
    final text = value.text;

    // Check for comma to create new chip
    if (text.endsWith(',')) {
      final chipText = text.substring(0, text.length - 1).trim();
      if (chipText.isNotEmpty) {
        // Create new chip from text
        final newChip = ChipData(chipText, chipText);
        selectSuggestion(newChip as T);
        return;
      }
    }

    if (value.text != oldTextEditingValue.text) {
      setState(() => _value = value);
      if (value.replacementCharactersCount <
          oldTextEditingValue.replacementCharactersCount) {
        final removedChip = _chips.last;
        setState(() =>
            _chips = Set.of(_chips.take(value.replacementCharactersCount)));
        widget.onChanged(_chips.toList(growable: true));
        String? putText = '';
        if (widget.allowChipEditing && _enteredTexts.containsKey(removedChip)) {
          putText = _enteredTexts[removedChip]!;
          _enteredTexts.remove(removedChip);
        }
        _updateTextInputState(putText: putText);
      } else {
        _updateTextInputState();
      }
      _onSearchChanged(_value.normalCharactersText);
    }
  }

  void _updateTextInputState({replaceText = false, String putText = ''}) {
    if (!widget.allowInputText) return;

    if (replaceText ||
        putText != '' ||
        (_chips.isEmpty && _value.text.contains(""))) {
      final updatedText =
          String.fromCharCodes(_chips.map((_) => kObjectReplacementChar)) +
              (replaceText ? '' : _value.normalCharactersText) +
              putText;
      setState(() => _value = _value.copyWith(
            text: updatedText,
            selection: TextSelection.collapsed(offset: updatedText.length),
            composing: TextRange.empty,
          ));
    }

    _textInputConnection ??= TextInput.attach(this, textInputConfiguration);
    _textInputConnection?.setEditingState(_value);
  }

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.send:
      case TextInputAction.search:
        if (_suggestions?.isNotEmpty ?? false) {
          selectSuggestion(_suggestions!.first as T);
        } else {
          _effectiveFocusNode.unfocus();
        }
        break;
      default:
        _effectiveFocusNode.unfocus();
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _effectiveFocusNode.canRequestFocus = _canRequestFocus;
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    //TODO
  }

  @override
  void didUpdateWidget(covariant ChipsInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _effectiveFocusNode.canRequestFocus = _canRequestFocus;
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // print(point);
  }

  @override
  void connectionClosed() {
    //print('TextInputClient.connectionClosed()');
  }

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  Widget build(BuildContext context) {
    _nodeAttachment.reparent();
    final chipsChildren = _chips
        .map<Widget>((data) => widget.chipBuilder(context, this, data))
        .toList();
    final theme = Theme.of(context);

    if (widget.allowInputText) {
      chipsChildren.add(
        SizedBox(
          height: 30.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Flexible(
                flex: 1,
                child: Text(
                  _value.normalCharactersText,
                  maxLines: 1,
                  overflow: widget.textOverflow,
                  style: widget.textStyle ??
                      theme.textTheme.titleMedium!.copyWith(height: 1.5),
                ),
              ),
              Flexible(
                flex: 0,
                child: TextCursor(resumed: _effectiveFocusNode.hasFocus),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification val) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          suggestionsBoxController.overlayEntry?.markNeedsBuild();
        });
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: Column(
          children: <Widget>[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                requestKeyboard();
              },
              child: InputDecorator(
                decoration: widget.decoration.copyWith(
                  contentPadding: _chips.isNotEmpty
                      ? const EdgeInsets.symmetric(horizontal: 14, vertical: 4)
                      : widget.decoration.contentPadding,
                ),
                isFocused: _effectiveFocusNode.hasFocus,
                isEmpty: _value.text.isEmpty && _chips.isEmpty,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5.0,
                  runSpacing: -3,
                  children: chipsChildren,
                ),
              ),
            ),
            CompositedTransformTarget(
              link: _layerLink,
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void showToolbar() {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void didChangeInputControl(
      TextInputControl? oldControl, TextInputControl? newControl) {
    // TODO: implement didChangeInputControl
  }

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  void performSelector(String selectorName) {
    // TODO: implement performAction
  }
}
