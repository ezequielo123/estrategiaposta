import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

class ClipboardHelper {
  static Future<bool> copy(String text, {BuildContext? context}) async {
    bool ok = false;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ok = true;
    } catch (_) {
      try {
        await html.window.navigator.clipboard?.writeText(text);
        ok = true;
      } catch (_) {
        try {
          final ta = html.TextAreaElement()..value = text;
          html.document.body!.append(ta);
          ta.focus();
          ta.select();
          ok = html.document.execCommand('copy');
          ta.remove();
        } catch (_) {}
      }
    }

    if (context != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Código copiado: $text'
              : 'No pude copiar automáticamente. Probá copiarlo manualmente.'),
        ),
      );
    }
    return ok;
  }
}
