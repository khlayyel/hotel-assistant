import 'dart:html' as html;

class WebUtils {
  static void navigateToUrl(String url) {
    html.window.location.href = url;
  }

  static void onBeforeUnload(Function(dynamic) callback) {
    html.window.onBeforeUnload.listen(callback);
  }
} 