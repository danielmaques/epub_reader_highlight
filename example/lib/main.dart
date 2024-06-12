import 'package:epub_reader_highlight/epub_reader_highlight.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late EpubController _epubReaderController;

  @override
  void initState() {
    super.initState();
    _epubReaderController = EpubController(
      document: EpubDocument.openAsset('assets/gentle-green-obooko.epub'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: EpubView(
              builders: EpubViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(
                  textStyle: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.amber,
                  ),
                ),
                chapterDividerBuilder: (_) => Container(),
              ),
              controller: _epubReaderController,
            ),
          ),
        ),
      ),
    );
  }
}
