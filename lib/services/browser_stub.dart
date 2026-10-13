import 'browser.dart';

bool get supportsLocation => false;

String? queryParam(String name) => null;

void setQueryParam(String name, String value) {}

void openInNewTab(String url) {}

int? watchLocation(void Function(GeoFix fix) onFix, void Function(String message) onError) => null;

void stopWatching(int id) {}

Future<List<int>?> pickImage() async => null;
