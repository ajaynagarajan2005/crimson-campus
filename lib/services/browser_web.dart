import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'browser.dart';

bool get supportsLocation => true;

String? queryParam(String name) => Uri.base.queryParameters[name];

void setQueryParam(String name, String value) {
  final next = Uri.base.replace(
    queryParameters: {...Uri.base.queryParameters, name: value},
  );
  web.window.history.replaceState(null, '', next.toString());
}

void openInNewTab(String url) {
  web.window.open(url, '_blank');
}

int? watchLocation(void Function(GeoFix fix) onFix, void Function(String message) onError) {
  try {
    return web.window.navigator.geolocation.watchPosition(
      ((web.GeolocationPosition position) {
        final c = position.coords;
        onFix((lat: c.latitude, lon: c.longitude, accuracy: c.accuracy, heading: c.heading));
      }).toJS,
      ((web.GeolocationPositionError error) {
        onError(switch (error.code) {
          1 => 'Location permission was denied. Allow location for this site to see where you are.',
          2 => 'Your position is unavailable right now. Try moving to an open area.',
          3 => 'Finding your position took too long. Try again.',
          _ => error.message,
        });
      }).toJS,
      web.PositionOptions(enableHighAccuracy: true, maximumAge: 5000, timeout: 20000),
    );
  } catch (_) {
    onError('Live location needs a secure page (https:// or localhost).');
    return null;
  }
}

void stopWatching(int id) => web.window.navigator.geolocation.clearWatch(id);

Future<List<int>?> pickImage() {
  final done = Completer<List<int>?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/jpeg,image/png,image/webp';
  input.onchange = ((web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      if (!done.isCompleted) done.complete(null);
      return;
    }
    file.arrayBuffer().toDart.then((buffer) {
      if (!done.isCompleted) done.complete(buffer.toDart.asUint8List());
    });
  }).toJS;
  input.addEventListener(
    'cancel',
    ((web.Event _) {
      if (!done.isCompleted) done.complete(null);
    }).toJS,
  );
  input.click();
  return done.future;
}
