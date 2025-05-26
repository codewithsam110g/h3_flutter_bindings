## h3\_ffi\_plus

<p>
<a href="https://github.com/codewithsam110g/h3_flutter_bindings/actions">
  <img src="https://github.com/codewithsam110g/h3_flutter_bindings/actions/workflows/tests.yml/badge.svg" alt="Build & Test">
</a>
<a href="https://codecov.io/gh/codewithsam110g/h3_flutter_bindings">
  <img src="https://codecov.io/gh/codewithsam110g/h3_flutter_bindings/graph/badge.svg?token=OEV650UZW3" alt="codecov">
</a>
<a href="https://opensource.org/licenses/Apache-2.0">
  <img src="https://img.shields.io/badge/License-Apache_2.0-blue.svg" alt="License: Apache 2.0">
</a>
</p>

`h3_ffi_plus` is a low-level Dart library that provides [H3](https://github.com/uber/h3) bindings for native (non-web) platforms using Dart's [FFI](https://pub.dev/packages/ffi) and [ffigen](https://pub.dev/packages/ffigen).

⚠️ **This package is not intended for direct use.** Instead, use one of the higher-level packages:

* [`h3_dart_plus`](https://pub.dev/packages/h3_dart_plus) — For general Dart apps. Requires manual linking of the native H3 C library (`libh3.so`, `h3.dll`, etc.).
* [`h3_flutter_plus`](https://pub.dev/packages/h3_flutter_plus) — For Flutter apps on Android, desktop, and web. Native linking is handled automatically by the build system.

### About This Package

This package provides one of the internal implementations of the abstract `H3` interface defined in [`h3_common_plus`](https://pub.dev/packages/h3_common_plus). It leverages native C bindings through Dart FFI to provide a performant, native-backed H3 API.

Although it can technically be used directly by instantiating an `H3FfiFactory` and loading a dynamic library, **this is not recommended** unless you know what you're doing. You’ll need to handle:

* Dynamic library loading
* FFI-native data types and memory management
* Potential cross-platform inconsistencies

### Example (Direct Use)

```dart
import 'package:h3_ffi_plus/h3_ffi_plus.dart';

final h3 = const H3FfiFactory().byPath('path/to/libh3.so');
final indexes = h3.polygonToCells(
  resolution: 6,
  coordinates: [
    LatLng(lat:37.775, lng:-122.418),
    LatLng(lat:37.776, lng:-122.419),
    LatLng(lat:37.777, lng:-122.417),
  ],
);
```

### History & Migration

This library is a modernized and rewritten successor to the original [`h3_ffi`](https://pub.dev/packages/h3_ffi) package created by [festelo](https://github.com/festelo), which was based on H3 v3.7.2.

The current implementation supports H3 v4.2.1 and forms part of a complete rework of the Dart/Flutter H3 bindings ecosystem, including:

* Migration from H3 v3 to v4
* Inclusion of vertex mode functions and experimental functions
* Check the Changelogs for more details

This package exists primarily to support other public-facing packages, not for end-user consumption.

### License

This project is licensed under the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
