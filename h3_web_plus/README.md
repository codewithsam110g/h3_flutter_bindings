## h3\_web\_plus

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

`h3_web_plus` provides a low-level web implementation of [H3](https://github.com/uber/h3) bindings via JavaScript interop (JS FFI) using the `h3-js` library.

⚠️ **This package is not intended for direct use.** Instead, use one of the higher-level packages:

* [`h3_dart_plus`](https://pub.dev/packages/h3_dart_plus) — For general Dart apps.
* [`h3_flutter_plus`](https://pub.dev/packages/h3_flutter_plus) — For Flutter apps on Android, desktop, and web.

### History & Migration

`h3_web_plus` is part of a complete rework of the Dart and Flutter bindings for Uber's H3 library, modernizing the unmaintained [`h3_web`](https://pub.dev/packages/h3_web) by [festelo](https://github.com/festelo), which was based on **H3 v3.7.2**.

The migration includes:

* Full update to H3 **v4.2.1**, supporting all stable functions.
* Inclusion of **vertex mode** and **experimental** APIs.
* A restructured ecosystem with a clear separation of platform-specific implementations.

See the [Changelog](https://pub.dev/packages/h3_web_plus/changelog) for detailed update notes and migration guidance.

### ⚠️ Web Null Safety Warning

**Due to limitations in the JS FFI tooling, any value returned from ********`h3_web_plus`******** should be treated as nullable, even if Dart’s analyzer marks it as non-nullable.**

This affects *all* consumers of the web implementation. If you’re using `h3_dart_plus` or `h3_flutter_plus` on the web, the issue is contained internally—but you may still want to verify that outputs are not null before using them in production code.

Examples of safe casting:

```dart
final result = h3_js.h3ToCenterChild(index, res) as String?;
final list = h3_js.polyfill([...], 5).cast<String>();
```

Null safety will be improved in future updates once better tooling or custom bindings are introduced.

### Setup

To use this package in a web environment, you must include the `h3-js` JavaScript library manually. Add the following line to your HTML file **before** your compiled Dart script (`main.dart.js`):

```html
<script defer src="https://unpkg.com/h3-js@4.2.1"></script>
```

### Example (Direct Use)

```dart
final h3 = const H3Web();
final hexagons = h3.polygonToCells(
  resolution: 6,
  coordinates: [
    LatLng(lat:37.775, lng:-122.418),
    LatLng(lat:37.776, lng:-122.419),
    LatLng(lat:37.777, lng:-122.417),
  ],
);
```

### License

This project is licensed under the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).