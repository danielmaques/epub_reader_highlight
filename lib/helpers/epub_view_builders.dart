part of '../ui/epub_view.dart';

typedef EpubViewBuilder<T> = Widget Function(
  BuildContext context,

  EpubViewBuilders<T> builders,

  EpubViewLoadingState state,

  WidgetBuilder loadedBuilder,

  Exception? loadingError,
);

typedef ChaptersBuilder = Widget Function(
  BuildContext context,
  EpubViewBuilders builders,
  EpubBook document,
  List<EpubChapter> chapters,
  List<Paragraph> paragraphs,
  int index,
  int chapterIndex,
  int paragraphIndex,
  ExternalLinkPressed onExternalLinkPressed,
);

typedef ChapterDividerBuilder = Widget Function(EpubChapter value);

class EpubViewBuilders<T> {
  final EpubViewBuilder<T> builder;

  final ChaptersBuilder chapterBuilder;
  final ChapterDividerBuilder chapterDividerBuilder;

  final WidgetBuilder? loaderBuilder;

  final Widget Function(BuildContext, Exception error)? errorBuilder;

  final T options;

  const EpubViewBuilders({
    required this.options,
    this.builder = _EpubViewState._builder,
    this.chapterBuilder = _EpubViewState._chapterBuilder,
    this.chapterDividerBuilder = _EpubViewState._chapterDividerBuilder,
    this.loaderBuilder,
    this.errorBuilder,
  });
}

enum EpubViewLoadingState {
  loading,
  error,
  success,
}

class DefaultBuilderOptions {
  final Duration loaderSwitchDuration;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final EdgeInsetsGeometry chapterPadding;
  final EdgeInsetsGeometry paragraphPadding;
  final List<Color> toolbarSelectionActionsColor;
  final TextStyle textStyle;

  const DefaultBuilderOptions({
    this.loaderSwitchDuration = const Duration(seconds: 1),
    this.transitionBuilder = DefaultBuilderOptions._transitionBuilder,
    this.chapterPadding = const EdgeInsets.all(8),
    this.paragraphPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.textStyle = const TextStyle(
      height: 1.25,
      fontSize: 16,
    ),
    this.toolbarSelectionActionsColor = const [],
  });

  static Widget _transitionBuilder(Widget child, Animation<double> animation) =>
      FadeTransition(opacity: animation, child: child);
}
