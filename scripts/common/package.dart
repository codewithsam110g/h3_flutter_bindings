enum Package {
  h3CommonPlus(name: 'h3_common_plus'),
  h3FfiPlus(name: 'h3_ffi_plus'),
  h3WebPlus(name: 'h3_web_plus'),
  geojson2h3Plus(name: 'geojson2h3_plus'),
  h3DartPlus(name: 'h3_dart_plus'),
  h3FlutterPlus(name: 'h3_flutter_plus');

  const Package({
    required this.name,
  });

  final String name;

  static Package? tryParse(String string) {
    for (final p in Package.values) {
      if (p.name == string) {
        return p;
      }
    }
    return null;
  }
}
