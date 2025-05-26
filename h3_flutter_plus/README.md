## H3 Flutter Plus

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

`h3_flutter_plus` is the official Flutter package in the modern Dart/Flutter H3 ecosystem. It provides seamless support for Uber’s [H3 library](https://github.com/uber/h3) across all platforms including mobile, desktop, and web.

This package is built on top of [h3\_dart\_plus](https://pub.dev/packages/h3_dart_plus), using [h3\_ffi\_plus](https://pub.dev/packages/h3_ffi_plus) and [h3\_web\_plus](https://pub.dev/packages/h3_web_plus) under the hood.

### Example

```dart
import 'package:h3_flutter_plus/h3_flutter_plus.dart';

final h3 = const H3Factory().load();
final hexagons = h3.polygonToCells(
  resolution: 6,
  coordinates: [
    LatLng(lat:37.775, lng:-122.418),
    LatLng(lat:37.776, lng:-122.419),
    LatLng(lat:37.777, lng:-122.417),
  ],
);

final geojson2h3 = Geojson2H3(h3);
```

## Setup

### Mobile / Desktop

Simply add `h3_flutter_plus` to your `pubspec.yaml`, import it, and call `H3Factory().load()`.

```dart
import 'package:h3_flutter_plus/h3_flutter_plus.dart';

final h3 = const H3Factory().load();
```

### Web

Web support is based on `h3-js` v4.2.1. You must include the script manually in your `index.html`:

```html
<script defer src="https://unpkg.com/h3-js@4.2.1"></script>
```

**Make sure this comes before your `main.dart.js` script.**

```dart
final h3 = const H3Factory().load();
```

> ⚠️ **Web Notice**: When using on web, always null-check the output of H3 methods even if the Dart analyzer marks them as safe. This is due to an issue in Dart's JS interop FFI generator affecting null safety. This will be improved in future releases.

## Geojson2H3 Support

Basic GeoJSON utilities from [geojson2h3](https://github.com/uber/geojson2h3) are supported via the `Geojson2H3` class. It is a drop-in replacement provided via [geojson2h3\_plus](https://pub.dev/packages/geojson2h3_plus).

```dart
final geojson = const Geojson2H3(h3);
```

## History & Migration

This package is the successor of the original [`h3_flutter`](https://pub.dev/packages/h3_flutter) package. The original was based on H3 v3.7.2 and used legacy Dart FFI and JS bindings.

The new `h3_flutter_plus` package is part of a full rewrite of the Dart H3 bindings ecosystem for H3 **v4.2.1**, introducing:

* Updated C bindings via `h3_ffi_plus`
* Web support with `h3-js@4.2.1` via `h3_web_plus`
* Exception-safe, null-safe Dart wrappers
* Vertex mode and experimental feature support

All packages in the `*_plus` family are actively maintained and provide a clean, consistent API surface across platforms.