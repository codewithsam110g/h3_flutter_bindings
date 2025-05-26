## h3\_dart\_plus

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

**For Flutter development, use [h3\_flutter\_plus](https://pub.dev/packages/h3_flutter_plus) instead.**

`h3_dart_plus` is a pure Dart implementation of bindings to Uber’s [H3 library](https://github.com/uber/h3), now updated to **H3 v4.2.1**.

This package is a modern fork of the original [`h3_dart`](https://pub.dev/packages/h3_dart) by [festelo](https://github.com/festelo). It is actively maintained and part of a complete rewrite of the Dart H3 ecosystem for H3 v4.x.x.

### What's New

* **Upgraded to H3 v4.2.1**
* Added support for **vertex mode** and **experimental functions**
* More robust error handling and exception support
* Improved platform structure for better web and VM separation

### Example

```dart
final h3Factory = const H3Factory();
final h3 = kIsWeb
  ? h3Factory.web()
  : h3Factory.byPath('path/to/library.so');

final hexagons = h3.polyfill(
  resolution: 5,
  coordinates: [
    GeoCoord(20.4522, 54.7104),
    GeoCoord(37.6173, 55.7558),
    GeoCoord(39.7015, 47.2357),
  ],
);
```

### Setup

#### VM

To use on Dart VM (non-web platforms), compile the native H3 C library:

* Use the provided script: `scripts/build_h3.sh`

  * Output: `h3_ffi_plus/c/h3lib/build/h3.so`
* Or compile manually using the C code inside the `c/` folder
* Or use the official H3 C code from Uber's repo (ensure version is v4.2.1)

After compiling, load it in your Dart code:

```dart
final h3 = const H3Factory().byPath('path/to/library.so');
```

#### Web

On web, this package uses `h3-js`. Include the script manually in your `index.html`:

```html
<script defer src="https://unpkg.com/h3-js@4.2.1"></script>
```

**Make sure this comes before your `main.dart.js` script.**

Then instantiate H3 like so:

```dart
final h3 = const H3Factory().web();
```

> **Note**: Always null-check every output when using web, even if the Dart analyzer says it is safe. This is due to an issue with the Dart JS interop FFI gen package and its null safety guarantees. Improvements are planned for future versions.

### Geojson2H3 Support

Basic GeoJSON utilities from the JS library [geojson2h3](https://github.com/uber/geojson2h3) are supported via the `Geojson2H3` class.

To use:

```dart
final geojson = const Geojson2H3(h3);
```

This has been ported and renamed to `geojson2h3_plus`, a drop-in replacement requiring no code changes for existing users. It's compatible with the rest of the updated `*_plus` ecosystem.

### History & Migration

This package is a fork and successor of `h3_dart` by festelo. It has been upgraded to support H3 v4.2.1, with added features like vertex mode, experimental functions, and better exception handling. The package is now actively maintained as part of a modernized and fully integrated Dart/Flutter H3 bindings suite.
