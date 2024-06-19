// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:epub_reader_highlight/data/models/selected_text_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:universal_file/universal_file.dart';

import '../data/epub_cfi_reader.dart';
import '../data/epub_parser.dart';
import '../data/models/chapter.dart';
import '../data/models/chapter_view_value.dart';
import '../data/models/paragraph.dart';
import 'css/html_stylist.dart';

export 'package:epubx/epubx.dart' hide Image;

part '../helpers/epub_view_builders.dart';
part 'controller/epub_controller.dart';

const _minTrailingEdge = 0.55;
const _minLeadingEdge = -0.05;

typedef ExternalLinkPressed = void Function(String href);

class EpubView extends StatefulWidget {
  const EpubView({
    required this.controller,
    this.onHighlightTap,
    this.paragraphIndexOnDispose,
    this.onExternalLinkPressed,
    this.onChapterChanged,
    this.onDocumentLoaded,
    this.onDocumentError,
    this.builders = const EpubViewBuilders<DefaultBuilderOptions>(
      options: DefaultBuilderOptions(),
    ),
    this.shrinkWrap = false,
    super.key,
  });

  final EpubController controller;
  final ExternalLinkPressed? onExternalLinkPressed;
  final bool shrinkWrap;
  final void Function(EpubChapterViewValue? value)? onChapterChanged;
  final void Function(EpubBook document)? onDocumentLoaded;
  final void Function(Exception? error)? onDocumentError;
  final EpubViewBuilders builders;
  final Function(SelectedTextModel selectedTextModel)? onHighlightTap;
  final Function(int paragraphIndex)? paragraphIndexOnDispose;

  @override
  State<EpubView> createState() => _EpubViewState();
}

class _EpubViewState extends State<EpubView> {
  Exception? _loadingError;
  ItemScrollController? _itemScrollController;
  ItemPositionsListener? _itemPositionListener;
  List<EpubChapter> _chapters = [];
  List<Paragraph> _paragraphs = [];
  EpubCfiReader? _epubCfiReader;
  EpubChapterViewValue? _currentValue;
  final _chapterIndexes = <int>[];
  static final highlightedStream = ValueNotifier<SelectedTextModel?>(null);
  static final paragraphList = ValueNotifier<List<String>>([]);

  EpubController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionListener = ItemPositionsListener.create();
    _controller._attach(this);
    highlightedStream.addListener(() {
      if (widget.onHighlightTap != null && highlightedStream.value != null) {
        widget.onHighlightTap!(highlightedStream.value!);
      }
    });
    _controller.loadingState.addListener(() {
      switch (_controller.loadingState.value) {
        case EpubViewLoadingState.loading:
          break;
        case EpubViewLoadingState.success:
          widget.onDocumentLoaded?.call(_controller._document!);
          break;
        case EpubViewLoadingState.error:
          widget.onDocumentError?.call(_loadingError);
          break;
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _itemPositionListener!.itemPositions.removeListener(_changeListener);
    _controller._detach();
    if (widget.paragraphIndexOnDispose != null) {
      widget.paragraphIndexOnDispose!(
        _controller.currentValue!.paragraphNumber,
      );
    }
    super.dispose();
  }

  Future<bool> _init() async {
    if (_controller.isBookLoaded.value) {
      return true;
    }
    _chapters = parseChapters(_controller._document!);

    final parseParagraphsResult =
        parseParagraphs(_chapters, _controller._document!.Content);
    _paragraphs = parseParagraphsResult.flatParagraphs;
    _chapterIndexes.addAll(parseParagraphsResult.chapterIndexes);

    paragraphList.value = _paragraphs.map((e) => e.element.outerHtml).toList();

    _epubCfiReader = EpubCfiReader.parser(
      cfiInput: _controller.epubCfi,
      chapters: _chapters,
      paragraphs: _paragraphs,
    );
    _itemPositionListener!.itemPositions.addListener(_changeListener);
    _controller.isBookLoaded.value = true;

    return true;
  }

  void _changeListener() {
    if (_paragraphs.isEmpty ||
        _itemPositionListener!.itemPositions.value.isEmpty) {
      return;
    }
    final position = _itemPositionListener!.itemPositions.value.first;
    final chapterIndex = _getChapterIndexBy(
      positionIndex: position.index,
      trailingEdge: position.itemTrailingEdge,
      leadingEdge: position.itemLeadingEdge,
    );
    final paragraphIndex = _getParagraphIndexBy(
      positionIndex: position.index,
      trailingEdge: position.itemTrailingEdge,
      leadingEdge: position.itemLeadingEdge,
    );
    _currentValue = EpubChapterViewValue(
      chapter: chapterIndex >= 0 ? _chapters[chapterIndex] : null,
      chapterNumber: chapterIndex + 1,
      paragraphNumber: paragraphIndex + 1,
      position: position,
    );
    _controller.currentValueListenable.value = _currentValue;
    widget.onChapterChanged?.call(_currentValue);
  }

  void _gotoEpubCfi(
    String? epubCfi, {
    double alignment = 0,
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.linear,
  }) {
    _epubCfiReader?.epubCfi = epubCfi;
    final index = _epubCfiReader?.paragraphIndexByCfiFragment;

    if (index == null) {
      return;
    }

    _itemScrollController?.scrollTo(
      index: index,
      duration: duration,
      alignment: alignment,
      curve: curve,
    );
  }

  void _onLinkPressed(String href) {
    if (href.contains('://')) {
      widget.onExternalLinkPressed?.call(href);
      return;
    }

    String? hrefIdRef;
    String? hrefFileName;

    if (href.contains('#')) {
      final dividedHref = href.split('#');
      if (dividedHref.length == 1) {
        hrefIdRef = href;
      } else {
        hrefFileName = dividedHref[0];
        hrefIdRef = dividedHref[1];
      }
    } else {
      hrefFileName = href;
    }

    if (hrefIdRef == null) {
      final chapter = _chapterByFileName(hrefFileName);
      if (chapter != null) {
        final cfi = _epubCfiReader?.generateCfiChapter(
          book: _controller._document,
          chapter: chapter,
          additional: ['/4/2'],
        );

        _gotoEpubCfi(cfi as String?);
      }
      return;
    } else {
      final paragraph = _paragraphByIdRef(hrefIdRef);
      final chapter =
          paragraph != null ? _chapters[paragraph.chapterIndex] : null;

      if (chapter != null && paragraph != null) {
        final paragraphIndex =
            _epubCfiReader?.getParagraphIndexByElement(paragraph.element);
        final cfi = _epubCfiReader?.generateCfi(
          book: _controller._document,
          chapter: chapter,
          paragraphIndex: paragraphIndex,
        );

        _gotoEpubCfi(cfi as String?);
      }

      return;
    }
  }

  Paragraph? _paragraphByIdRef(String idRef) =>
      _paragraphs.firstWhereOrNull((paragraph) {
        if (paragraph.element.id == idRef) {
          return true;
        }

        return paragraph.element.children.isNotEmpty &&
            paragraph.element.children[0].id == idRef;
      });

  EpubChapter? _chapterByFileName(String? fileName) =>
      _chapters.firstWhereOrNull((chapter) {
        if (fileName != null) {
          if (chapter.ContentFileName!.contains(fileName)) {
            return true;
          } else {
            return false;
          }
        }
        return false;
      });

  int _getChapterIndexBy({
    required int positionIndex,
    double? trailingEdge,
    double? leadingEdge,
  }) {
    final posIndex = _getAbsParagraphIndexBy(
      positionIndex: positionIndex,
      trailingEdge: trailingEdge,
      leadingEdge: leadingEdge,
    );
    final index = posIndex >= _chapterIndexes.last
        ? _chapterIndexes.length
        : _chapterIndexes.indexWhere((chapterIndex) {
            if (posIndex < chapterIndex) {
              return true;
            }
            return false;
          });

    return index - 1;
  }

  int _getParagraphIndexBy({
    required int positionIndex,
    double? trailingEdge,
    double? leadingEdge,
  }) {
    final posIndex = _getAbsParagraphIndexBy(
      positionIndex: positionIndex,
      trailingEdge: trailingEdge,
      leadingEdge: leadingEdge,
    );

    final index = _getChapterIndexBy(positionIndex: posIndex);

    if (index == -1) {
      return posIndex;
    }

    return posIndex - _chapterIndexes[index];
  }

  int _getAbsParagraphIndexBy({
    required int positionIndex,
    double? trailingEdge,
    double? leadingEdge,
  }) {
    int posIndex = positionIndex;
    if (trailingEdge != null &&
        leadingEdge != null &&
        trailingEdge < _minTrailingEdge &&
        leadingEdge < _minLeadingEdge) {
      posIndex += 1;
    }

    return posIndex;
  }

  static Widget _chapterDividerBuilder(EpubChapter chapter) => Container(
        height: 56,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0x24000000),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          chapter.Title ?? '',
        ),
      );

  static Widget _chapterBuilder(
    BuildContext context,
    EpubViewBuilders builders,
    EpubBook document,
    List<EpubChapter> chapters,
    List<Paragraph> paragraphs,
    int index,
    int chapterIndex,
    int paragraphIndex,
    ExternalLinkPressed onExternalLinkPressed,
  ) {
    if (paragraphs.isEmpty) {
      return Container();
    }

    final defaultBuilder = builders as EpubViewBuilders<DefaultBuilderOptions>;
    final options = defaultBuilder.options;

    final paragraph = paragraphs[index];
    final hasText = paragraph.element.text.isNotEmpty;
    final hasImage = paragraph.element.outerHtml.contains('<img');

    List<Widget> toolbarSelectionActions(
        EditableTextState state, List<Color> options) {
      return [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Material(
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    applyHighlight(
                      state: state,
                      index: index,
                      tag: 'tgYellow',
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFF00),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    applyHighlight(
                      state: state,
                      index: index,
                      tag: 'tgCyan',
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00FFFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    applyHighlight(
                      state: state,
                      index: index,
                      tag: 'tgPink',
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF69B4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    applyHighlight(
                      state: state,
                      index: index,
                      tag: 'tgGreen',
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF90EE90),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    applyHighlight(
                      state: state,
                      index: index,
                      tag: 'tgOrange',
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA07A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    applyHighlight(
                      state: state,
                      index: index,
                      tag: 'tgLilac',
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDDA0DD),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(50),
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    applyHighlight(
                      state: state,
                      index: index,
                      tag: null,
                    );
                  },
                  child: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (chapterIndex >= 0 && paragraphIndex == 0)
          builders.chapterDividerBuilder(chapters[chapterIndex]),
        if (hasText && !hasImage)
          Padding(
            padding: options.paragraphPadding as EdgeInsets? ?? EdgeInsets.zero,
            child: Stack(
              children: [
                ValueListenableBuilder(
                    valueListenable: paragraphList,
                    builder: (context, value, child) {
                      var htmlText = HTML.toRichText(
                        context,
                        value.elementAt(index),
                      );
                      return SelectableText.rich(
                        TextSpan(
                          children: [htmlText.text],
                          style: options.textStyle,
                        ),
                        contextMenuBuilder: (_, EditableTextState state) {
                          return AdaptiveTextSelectionToolbar(
                            anchors: state.contextMenuAnchors,
                            children:
                                (!state.textEditingValue.selection.isCollapsed)
                                    ? toolbarSelectionActions(
                                        state,
                                        options.toolbarSelectionActionsColor,
                                      )
                                    : _toolbarActions(state),
                          );
                        },
                      );
                    }),
              ],
            ),
          )
        else
          Html(
            data: paragraphs[index].element.outerHtml,
            onLinkTap: (href, _, __) => onExternalLinkPressed(href!),
            style: {
              'html': Style(
                padding: HtmlPaddings.only(
                  top: (options.paragraphPadding as EdgeInsets?)?.top,
                  right: (options.paragraphPadding as EdgeInsets?)?.right,
                  bottom: (options.paragraphPadding as EdgeInsets?)?.bottom,
                  left: (options.paragraphPadding as EdgeInsets?)?.left,
                ),
              ),
            },
            extensions: [
              TagExtension(
                tagsToExtend: {"img"},
                builder: (imageContext) {
                  final url =
                      imageContext.attributes['src']!.replaceAll('../', '');
                  final content = Uint8List.fromList(
                      document.Content!.Images![url]!.Content!);
                  return Image(
                    image: MemoryImage(content),
                  );
                },
              ),
            ],
          ),
        if (index < paragraphs.length - 1) const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoaded(BuildContext context) => ScrollablePositionedList.builder(
        shrinkWrap: widget.shrinkWrap,
        initialScrollIndex: _epubCfiReader!.paragraphIndexByCfiFragment ?? 0,
        itemCount: _paragraphs.length,
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionListener,
        itemBuilder: (BuildContext context, int index) =>
            widget.builders.chapterBuilder(
          context,
          widget.builders,
          widget.controller._document!,
          _chapters,
          _paragraphs,
          index,
          _getChapterIndexBy(positionIndex: index),
          _getParagraphIndexBy(positionIndex: index),
          _onLinkPressed,
        ),
      );

  static Widget _builder(
    BuildContext context,
    EpubViewBuilders builders,
    EpubViewLoadingState state,
    WidgetBuilder loadedBuilder,
    Exception? loadingError,
  ) {
    final Widget content = () {
      switch (state) {
        case EpubViewLoadingState.loading:
          return KeyedSubtree(
            key: const Key('epubx.root.loading'),
            child: builders.loaderBuilder?.call(context) ?? const SizedBox(),
          );
        case EpubViewLoadingState.error:
          return KeyedSubtree(
            key: const Key('epubx.root.error'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: builders.errorBuilder?.call(context, loadingError!) ??
                  Center(child: Text(loadingError.toString())),
            ),
          );
        case EpubViewLoadingState.success:
          return KeyedSubtree(
            key: const Key('epubx.root.success'),
            child: loadedBuilder(context),
          );
      }
    }();

    final defaultBuilder = builders as EpubViewBuilders<DefaultBuilderOptions>;
    final options = defaultBuilder.options;

    return AnimatedSwitcher(
      duration: options.loaderSwitchDuration,
      transitionBuilder: options.transitionBuilder,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) => widget.builders.builder(
        context,
        widget.builders,
        _controller.loadingState.value,
        _buildLoaded,
        _loadingError,
      );

  static List<Widget> _toolbarActions(EditableTextState state) {
    return [
      const Material(
        color: Colors.transparent,
      ),
    ];
  }

  static void applyHighlight({
    required EditableTextState state,
    required String? tag,
    required int index,
  }) {
    String paragraphText = paragraphList.value[index];
    final selectedStartIndex = state.textEditingValue.selection.start;
    final selectedEndIndex = state.textEditingValue.selection.end;

    final initialTagRegExp = RegExp(r'^<[^>]+>');
    final lastTagRegExp = RegExp(r'</[^>]+>$');

    final initialTagMatch = initialTagRegExp.firstMatch(paragraphText);
    final lastTagMatch = lastTagRegExp.firstMatch(paragraphText);

    final initialTag = initialTagMatch != null ? initialTagMatch.group(0)! : '';
    final lastTag = lastTagMatch != null ? lastTagMatch.group(0)! : '';

    paragraphText =
        paragraphText.replaceAll(initialTag, '').replaceAll(lastTag, '');

    final spanStartTagRegExp = RegExp(r'^<span [^>]+>');
    final spanEndTagRegExp = RegExp(r'</span>$');

    final spanStartTagMatch = spanStartTagRegExp.firstMatch(paragraphText);
    final spanEndTagMatch = spanEndTagRegExp.firstMatch(paragraphText);

    final spanStartTag =
        spanStartTagMatch != null ? spanStartTagMatch.group(0)! : '';
    final spanEndTag = spanEndTagMatch != null ? spanEndTagMatch.group(0)! : '';

    paragraphText =
        paragraphText.replaceAll(spanStartTag, '').replaceAll(spanEndTag, '');

    final htmlStartIndex = mapPlainTextIndexToHtmlIndex(
      paragraphText,
      selectedStartIndex,
    );
    final htmlEndIndex = mapPlainTextIndexToHtmlIndex(
      paragraphText,
      selectedEndIndex,
    );

    final formattedText = existingColorTagFormat(
      beforeSelectedText: paragraphText.substring(0, htmlStartIndex),
      selectedText: paragraphText.substring(htmlStartIndex, htmlEndIndex),
      afterSelectedText: paragraphText.substring(htmlEndIndex),
      tag: tag,
    );

    final formattedParagraph = '$initialTag'
        '$spanStartTag'
        '$formattedText'
        '$spanEndTag'
        '$lastTag';

    if (html_parser.parse(formattedParagraph).outerHtml.isNotEmpty) {
      paragraphList.value[index] = formattedParagraph;
      highlightedStream.value = SelectedTextModel(
        paragraphIndex: index,
        tag: tag,
        paragraphText: formattedParagraph,
        selectedText: state.textEditingValue.selection.textInside(
          state.textEditingValue.text,
        ),
      );
      highlightedStream.notifyListeners();
      paragraphList.notifyListeners();
    }
  }

  static int mapPlainTextIndexToHtmlIndex(String html, int plainTextIndex) {
    int plainIndex = 0;
    int htmlIndex = 0;

    while (htmlIndex < html.length && plainIndex < plainTextIndex) {
      if (html[htmlIndex] == '<') {
        while (html[htmlIndex] != '>') {
          htmlIndex++;
        }
        htmlIndex++;
      } else {
        plainIndex++;
        htmlIndex++;
      }
    }

    return htmlIndex;
  }

  static String existingColorTagFormat({
    required String beforeSelectedText,
    required String selectedText,
    required String afterSelectedText,
    required String? tag,
  }) {
    String before = beforeSelectedText;
    String selected = selectedText;
    String after = afterSelectedText;

    final openTagRegExp =
        RegExp(r'<(tg(?:Yellow|Cyan|Pink|Green|Orange|Lilac))>');
    final closeTagRegExp =
        RegExp(r'</(tg(?:Yellow|Cyan|Pink|Green|Orange|Lilac))>');
    final fullTagRegExp =
        RegExp(r'<(tg(?:Yellow|Cyan|Pink|Green|Orange|Lilac))>(.*?)</\1>');

    while (after.startsWith(closeTagRegExp)) {
      final match = closeTagRegExp.firstMatch(after);
      if (match != null) {
        final tag = match.group(1);
        if (tag != null) {
          final closingTag = '</$tag>';
          after = after.substring(closingTag.length);
          selected = '$selected$closingTag';
        }
      }
    }

    while (fullTagRegExp.hasMatch(selected)) {
      final match = openTagRegExp.allMatches(selected).toList();
      for (var element in match) {
        final tag = element.group(1);
        if (tag != null) {
          selected =
              selected.replaceAll('<$tag>', '').replaceAll('</$tag>', '');
        }
      }
    }

    if (openTagRegExp.hasMatch(selected)) {
      final match = openTagRegExp.firstMatch(selected);
      final tag = match?.group(1);
      if (tag != null) {
        after = '<$tag>$after';
        selected = selected.replaceAll(match?.group(0) ?? '', '');
      }
    }

    if (closeTagRegExp.hasMatch(selected)) {
      final match = closeTagRegExp.firstMatch(selected);
      final tag = match?.group(1);
      if (tag != null) {
        before = '$before</$tag>';
        selected = selected.replaceAll(match?.group(0) ?? '', '');
      }
    }

    return tag != null
        ? '$before<$tag>$selected</$tag>$after'
        : '$before$selected$after';
  }
}
