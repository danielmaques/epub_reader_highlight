import 'package:flutter/material.dart';
import 'package:universal_file/universal_file.dart';

import '../helpers/epub_document.dart';
import 'epub_view.dart';

class EpubPage extends StatefulWidget {
  const EpubPage({
    super.key,
    required this.epubPath,
  });

  final File epubPath;

  @override
  State<EpubPage> createState() => _EpubPageState();
}

class _EpubPageState extends State<EpubPage> {
  late EpubController _epubReaderController;
  final _isAppBarVisible = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _epubReaderController = EpubController(
      document: EpubDocument.openFile(widget.epubPath),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              _isAppBarVisible.value = !_isAppBarVisible.value;
            },
            child: EpubView(
              builders: EpubViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                chapterDividerBuilder: (_) => Container(),
              ),
              controller: _epubReaderController,
            ),
          ),
        ],
      ),
    );
  }
}
