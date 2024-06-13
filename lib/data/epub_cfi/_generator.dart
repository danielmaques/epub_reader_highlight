import 'package:epubx/epubx.dart';
import 'package:html/dom.dart';

class EpubCfiGenerator {
  const EpubCfiGenerator();

  String generateCompleteCFI(List<String?> entries) =>
      'epubcfi(${entries.join()})';

  Future<String> generatePackageDocumentCFIComponent(
      EpubChapter chapter, EpubPackage? packageDocument) async {
    validatePackageDocument(packageDocument, chapter.Anchor);

    final index = getIdRefIndex(chapter, packageDocument!);
    final pos = getIdRefPosition(index);
    final spineIdRef = index >= 0
        ? packageDocument.Spine!.Items![index].IdRef
        : chapter.Anchor;

    return '/6/$pos[$spineIdRef]!';
  }

  String generateElementCFIComponent(Node? startElement) {
    validateStartElement(startElement);

    final contentDocCFI =
        createCFIElementSteps(startElement as Element, 'html');

    return contentDocCFI.substring(1, contentDocCFI.length);
  }

  String createCFIElementSteps(Element currentNode, String topLevelElement) {
    int currentNodePosition = 0;
    String elementStep = '';

    int index = 0;
    for (var node in currentNode.parent!.children) {
      if (node == currentNode) {
        currentNodePosition = index;
      }
      index++;
    }

    final int cfiPosition = (currentNodePosition + 1) * 2;

    if (currentNode.attributes.containsKey('id')) {
      elementStep = '/$cfiPosition[${currentNode.attributes['id']!}]';
    } else {
      elementStep = '/$cfiPosition';
    }

    final parentNode = currentNode.parent!;
    if (parentNode.localName == topLevelElement ||
        currentNode.localName == topLevelElement) {
      if (topLevelElement == 'html') {
        return '!$elementStep';
      } else {
        return elementStep;
      }
    } else {
      return createCFIElementSteps(parentNode, topLevelElement) + elementStep;
    }
  }

  int getIdRefIndex(EpubChapter chapter, EpubPackage packageDocument) {
    final items = packageDocument.Spine!.Items!;
    int index = -1;
    int partIndex = -1;
    String? edRef = chapter.Anchor;

    if (chapter.Anchor == null) {
      // filename w/o extension
      edRef = _fileNameAsChapterName(chapter.ContentFileName!);
    }

    for (var i = 0; i < items.length; i++) {
      if (edRef == items[i].IdRef) {
        index = i;
        break;
      }
      if (items[i].IdRef!.contains(edRef!)) {
        partIndex = i;
      }
    }

    return index >= 0 ? index : partIndex;
  }

  int getIdRefPosition(int idRefIndex) => (idRefIndex + 1) * 2;

  void validatePackageDocument(EpubPackage? packageDocument, String? idRef) {
    if (packageDocument == null) {
      throw Exception('A package document must be supplied to generate a CFI');
    }
  }

  void validateStartElement(Node? startElement) {
    if (startElement == null) {
      throw Exception('$startElement: CFI target element is null');
    }

    if (startElement.nodeType != Node.ELEMENT_NODE) {
      throw Exception(
          '$startElement: CFI target element is not an HTML element');
    }
  }

  String _fileNameAsChapterName(String path) =>
      path.split('/').last.replaceFirst(RegExp(r'\.[^.]+$'), '');
}
