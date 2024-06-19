// ignore_for_file: prefer_typing_uninitialized_variables, depend_on_referenced_packages

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml_events.dart' as xmle;

import './utils.dart';

class _Tag {
  String name;
  String styles;

  _Tag(this.name, this.styles);
}

void defaultLinksCallback(String link) {}

class Parser {
  final _stack = [];
  var _events;
  late Function _linksCallback;

  Parser(BuildContext context, String data,
      {Function linksCallback = defaultLinksCallback}) {
    _events = xmle.parseEvents(data);
    _linksCallback = linksCallback;
  }

  TextSpan _getTextSpan(text, style) {
    var rules = style.split(";").where((item) => !item.trim().isEmpty);
    TextStyle textStyle = const TextStyle();
    textStyle = textStyle.apply(color: const Color(0xff000000));
    var isLink = false;
    var link = "";
    rules.forEach((String rule) {
      if (!rule.contains(":")) return;
      final parts = rule.split(":");
      String name = parts[0].trim();
      String value = parts[1].trim();
      switch (name) {
        case "color":
          textStyle = StyleGenUtils.addFontColor(textStyle, value);
          break;

        case "background":
          textStyle = StyleGenUtils.addBgColor(textStyle, value);
          break;

        case "font-weight":
          textStyle = StyleGenUtils.addFontWeight(textStyle, value);
          break;

        case "font-style":
          textStyle = StyleGenUtils.addFontStyle(textStyle, value);
          break;

        case "font-size":
          textStyle = StyleGenUtils.addFontSize(textStyle, value);
          break;

        case "text-decoration":
          textStyle = StyleGenUtils.addTextDecoration(textStyle, value);
          break;

        case "font-family":
          textStyle = StyleGenUtils.addFontFamily(textStyle, value);
          break;

        case "visit_link":
          isLink = true;
          link = TextGenUtils.getLink(value);
          break;
      }
    });
    if (isLink) {
      return TextSpan(
          style: textStyle,
          text: text,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _linksCallback(link);
            });
    }
    return TextSpan(style: textStyle, text: text);
  }

  TextSpan _handleText(String text) {
    text = TextGenUtils.strip(text);
    if (text.isEmpty) return const TextSpan(text: "");
    var style = "";
    for (var tag in _stack) {
      style += tag.styles + ";";
    }
    return _getTextSpan(text, style);
  }

  /// Converts HTML content to a list of [TextSpan] objects
  List<TextSpan> parse() {
    List<TextSpan> spans = List.empty(growable: true);
    _events.forEach((event) {
      if (event is xmle.XmlStartElementEvent) {
        if (!event.isSelfClosing) {
          var styles = "";
          if (event.name == 'b' || event.name == 'strong') {
            styles = "font-weight: bold;";
          } else if (event.name == 'i' || event.name == 'em') {
            styles = "font-style: italic;";
          } else if (event.name == 'u') {
            styles = "text-decoration: underline;";
          } else if (event.name == 'strike' ||
              event.name == 'del' ||
              event.name == 's') {
            styles = "text-decoration: line-through;";
          } else if (event.name == 'a') {
            styles = "visit_link:__#TO_GET#__;text-decoration: underline; color: #0000ff";
          }

          if (event.name == 'tgYellow') {
            styles = 'background:#FFFF00';
          } else if (event.name == 'tgCyan') {
            styles = 'background:#00FFFF';
          } else if (event.name == 'tgPink') {
            styles = 'background:#FF69B4';
          } else if (event.name == 'tgGreen') {
            styles = 'background:#90EE90';
          } else if (event.name == 'tgOrange') {
            styles = 'background:#FFA07A';
          } else if (event.name == 'tgLilac') {
            styles = 'background:#DDA0DD';
          }

          for (var attribute in event.attributes) {
            if (attribute.name == "style") {
              styles = "$styles;${attribute.value}";
            } else if (attribute.name == "href") {
              styles = styles.replaceFirst(r"__#TO_GET#__",
                  attribute.value.replaceAll(r":", "__#COLON#__"));
            }
          }

          _stack.add(_Tag(event.name, styles));
        } else {
          if (event.name == "br") {
            spans.add(const TextSpan(text: "\n"));
          }
        }
      }

      if (event is xmle.XmlEndElementEvent) {
        dynamic top;
        if (_stack.isNotEmpty) {
          top = _stack.removeLast();
        }
        if (top.name != event.name) {
          return;
        }
        if (event.name == "p") {
          spans.add(const TextSpan(text: "\n"));
        }
      }

      if (event is xmle.XmlTextEvent) {
        final currentSpan = _handleText(event.value);
        if (currentSpan.text!.isNotEmpty) {
          spans.add(currentSpan);
        }
      }
    });

    // for the last p tag
    // if (spans[spans.length - 1].text == '\n') {
    //   spans.removeLast();
    // }
    return spans;
  }
}
