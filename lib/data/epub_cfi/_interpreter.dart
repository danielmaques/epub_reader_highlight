import 'package:html/dom.dart';

import '_parser.dart';

class EpubCfiInterpreter {
  Element? searchLocalPathForHref(
      Element? htmlElement, CfiLocalPath localPathNode) {
    CfiStep nextStepNode;
    Element? currentElement = htmlElement;

    for (int stepNum = 1; stepNum < localPathNode.steps!.length; stepNum++) {
      nextStepNode = localPathNode.steps![stepNum];
      if (nextStepNode.type == 'indexStep') {
        currentElement = interpretIndexStepNode(nextStepNode, currentElement);
      } else if (nextStepNode.type == 'indirectionStep') {
        currentElement =
            interpretIndirectionStepNode(nextStepNode, currentElement);
      }
    }

    return currentElement;
  }

  Element? interpretIndexStepNode(
      CfiStep? indexStepNode, Element? currentElement) {
    if (indexStepNode == null || indexStepNode.type != 'indexStep') {
      throw Exception('$indexStepNode: expected index step node');
    }

    // Index step
    final stepTarget = _getNextNode(indexStepNode.stepLength, currentElement);

    if ((indexStepNode.idAssertion ?? '').isNotEmpty) {
      if (!_targetIdMatchesIdAssertion(
          stepTarget!, indexStepNode.idAssertion)) {
        throw Exception(
            '${indexStepNode.idAssertion}: ${stepTarget.attributes['id']} Id assertion failed');
      }
    }

    return stepTarget;
  }

  Element? interpretIndirectionStepNode(
      CfiStep? indirectionStepNode, Element? currentElement) {
    if (indirectionStepNode == null ||
        indirectionStepNode.type != 'indirectionStep') {
      throw Exception('$indirectionStepNode: expected indirection step node');
    }

    final stepTarget =
        _getNextNode(indirectionStepNode.stepLength, currentElement);

    if (indirectionStepNode.idAssertion != null) {
      if (!_targetIdMatchesIdAssertion(
          stepTarget!, indirectionStepNode.idAssertion)) {
        throw Exception(
            '${indirectionStepNode.idAssertion}: ${stepTarget.attributes['id']} Id assertion failed');
      }
    }

    return stepTarget;
  }

  bool _targetIdMatchesIdAssertion(Element foundNode, String? idAssertion) =>
      foundNode.attributes.containsKey('id') &&
      foundNode.attributes['id'] == idAssertion;

  Element? _getNextNode(int cfiStepValue, Element? currentNode) {
    if (cfiStepValue % 2 == 0) {
      return _elementNodeStep(cfiStepValue, currentNode!);
    }

    return null;
  }

  Element _elementNodeStep(int cfiStepValue, Element currentNode) {
    final int targetNodeIndex = ((cfiStepValue / 2) - 1).toInt();
    final int numElements = currentNode.children.length;

    if (targetNodeIndex > numElements) {
      throw RangeError.range(targetNodeIndex, 0, numElements - 1);
    }

    return currentNode.children[targetNodeIndex];
  }
}
