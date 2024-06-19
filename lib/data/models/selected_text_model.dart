class SelectedTextModel {
  const SelectedTextModel({
    required this.paragraphIndex,
    required this.tag,
    required this.selectedText,
    required this.paragraphText,
  });

  final int paragraphIndex;
  final String? tag;
  final String paragraphText;
  final String selectedText;

  @override
  String toString() {
    return 'SelectedTextModel{paragraphIndex: $paragraphIndex, tag: $tag, '
        'paragraphText: $paragraphText, selectedText: $selectedText}';
  }
}
