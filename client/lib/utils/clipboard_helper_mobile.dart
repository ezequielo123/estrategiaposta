import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ClipboardHelper {
  static Future<bool> copy(String text, {BuildContext? context}) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Código copiado: $text')),
        );
      }
      return true;
    } catch (_) {
      if (context != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('No se pudo copiar')),
        );
      }
      return false;
    }
  }
}
