import 'package:flutter/material.dart';

import 'colors.dart';

class TextGenUtils {
  static String strip(String text) {
    var hasSpaceAfter = false;
    var hasSpaceBefore = false;
    if (text.startsWith(" ")) {
      hasSpaceBefore = true;
    }
    if (text.endsWith(" ")) {
      hasSpaceAfter = true;
    }
    text = text.trim();
    if (hasSpaceBefore) text = " " + text;
    if (hasSpaceAfter) text = text + " ";
    return text;
  }

  /// Returns the link of an anchor tag
  static String getLink(String value) {
    return value.replaceAll(r"__#COLON#__", ":");
  }
}

class StyleGenUtils {
  static TextStyle addFontWeight(TextStyle textStyle, String value) {
    final List<String> _supportedNumValues = [
      "100",
      "200",
      "300",
      "400",
      "500",
      "600",
      "700",
      "800",
      "900"
    ];
    if (_supportedNumValues.contains(value)) {
      return textStyle.copyWith(
          fontWeight: FontWeight.values[_supportedNumValues.indexOf(value)]);
    }
    switch (value) {
      case "normal":
        textStyle = textStyle.copyWith(fontWeight: FontWeight.normal);
        break;
      case "bold":
        textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
        break;
      default:
        textStyle = textStyle;
    }
    return textStyle;
  }

  static int _convertColor(String value) {
    var colorHex = 0xff000000;
    if (value.startsWith("#")) {
      if (value.length == 7)
        colorHex = int.parse(value.replaceAll(r"#", "0xff"));
      else if (value.length == 9)
        colorHex = int.parse(value.replaceAll(r"#", "0x"));
      else if (value.length == 4) {
        value = value.replaceFirst(r"#", "");
        value = value.split("").map((c) => "$c$c").join();
        colorHex = int.parse("0xff$value");
      }
    } else {
      value = value.toLowerCase();
      if (CSSColors.values.containsKey(value) &&
          CSSColors.values[value] != null) {
        return CSSColors.values[value] ?? colorHex;
      }
    }
    return colorHex;
  }

  /// Creates a [TextStyle] to handle CSS color
  static TextStyle addFontColor(TextStyle textStyle, String value) {
    return textStyle.copyWith(color: Color(_convertColor(value)));
  }

  /// Creates a [TextStyle] to handle CSS background
  static TextStyle addBgColor(TextStyle textStyle, String value) {
    Paint p = Paint();
    p.color = Color(_convertColor(value));
    return textStyle.copyWith(background: p);
  }

  static TextStyle addFontStyle(TextStyle textStyle, String value) {
    if (value == "italic") {
      textStyle = textStyle.copyWith(fontStyle: FontStyle.italic);
    } else if (value == "normal") {
      textStyle = textStyle.copyWith(fontStyle: FontStyle.normal);
    }
    return textStyle;
  }

  /// Creates a [TextStyle] to handle CSS font-family
  static TextStyle addFontFamily(TextStyle textStyle, String value) {
    return textStyle.copyWith(fontFamily: value);
  }

  /// Creates a [TextStyle] to handle CSS font-size
  static TextStyle addFontSize(TextStyle textStyle, String value) {
    double number = 14.0;
    if (value.endsWith("px")) {
      number = double.parse(value.replaceAll("px", "").trim());
    } else if (value.endsWith("em")) {
      number *= double.parse(value.replaceAll("em", "").trim());
    }
    return textStyle.copyWith(fontSize: number);
  }

  /// Creates a [TextStyle] to handle CSS text-decoration
  static TextStyle addTextDecoration(TextStyle textStyle, String value) {
    if (value.contains("underline")) {
      textStyle = textStyle.copyWith(decoration: TextDecoration.underline);
    }
    if (value.contains("overline")) {
      textStyle = textStyle.copyWith(decoration: TextDecoration.overline);
    }
    if (value.contains("none")) {
      return textStyle.copyWith(decoration: TextDecoration.none);
    }
    if (value.contains("line-through")) {
      textStyle = textStyle.copyWith(decoration: TextDecoration.lineThrough);
    }
    if (value.contains("dotted")) {
      textStyle =
          textStyle.copyWith(decorationStyle: TextDecorationStyle.dotted);
    } else if (value.contains("dashed")) {
      textStyle =
          textStyle.copyWith(decorationStyle: TextDecorationStyle.dashed);
    } else if (value.contains("wavy")) {
      textStyle = textStyle.copyWith(decorationStyle: TextDecorationStyle.wavy);
    }
    return textStyle;
  }
}
