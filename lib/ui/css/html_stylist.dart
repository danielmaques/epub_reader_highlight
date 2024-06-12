import 'package:flutter/material.dart';

import './internals.dart';

class HTML {
  static TextSpan toTextSpan(BuildContext context, String htmlContent,
      {Function linksCallback = defaultLinksCallback}) {
    Parser p = Parser(context, htmlContent, linksCallback: linksCallback);
    return TextSpan(text: "", children: p.parse());
  }

  static RichText toRichText(BuildContext context, String htmlContent,
      {Function linksCallback = defaultLinksCallback}) {
    return RichText(
        text: toTextSpan(context, htmlContent, linksCallback: linksCallback));
  }
}
