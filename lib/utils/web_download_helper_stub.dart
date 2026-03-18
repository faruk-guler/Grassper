import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class WebDownloadHelper {
  static void download(String content, String fileName) {
    final bytes = utf8.encode(content);
    final jsArray = bytes.toJS;
    final blob = web.Blob([jsArray].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
