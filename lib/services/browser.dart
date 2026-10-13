import 'browser_stub.dart' if (dart.library.js_interop) 'browser_web.dart' as impl;

/// One reading from the device's location sensor.
typedef GeoFix = ({double lat, double lon, double accuracy, double? heading});

/// Browser-only features (URL query, new tabs, live location). On other
/// platforms these are safe no-ops.
class Browser {
  const Browser._();

  static bool get supportsLocation => impl.supportsLocation;

  /// Value of `?name=` in the page URL.
  static String? queryParam(String name) => impl.queryParam(name);

  /// Updates `?name=value` in the address bar without reloading.
  static void setQueryParam(String name, String value) => impl.setQueryParam(name, value);

  static void openInNewTab(String url) => impl.openInNewTab(url);

  /// Starts live location updates. Returns a watch id, or null if unavailable.
  static int? watchLocation(void Function(GeoFix fix) onFix, void Function(String message) onError) =>
      impl.watchLocation(onFix, onError);

  static void stopWatching(int id) => impl.stopWatching(id);

  /// Opens the file / camera picker for an image. Null if cancelled or
  /// unsupported on this platform.
  static Future<List<int>?> pickImage() => impl.pickImage();
}
