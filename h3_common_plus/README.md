## h3_common_plus

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

`h3_common_plus` provides an abstract interface for Dart/Flutter H3 bindings and defines the shared base for all platform-specific implementations.

This package is **not intended for direct use**. Instead, use one of the higher-level interface packages built on top of these shared types:

* [`h3_dart_plus`](https://pub.dev/packages/h3_dart_plus) — For general Dart apps. Requires manually linking the appropriate native library (`libh3.so`, `h3.dll`, etc.).
* [`h3_flutter_plus`](https://pub.dev/packages/h3_flutter_plus) — For Flutter apps on Android, desktop, and web platforms.

> Internal packages like `h3_ffi_plus` and `h3_web_plus` rely on `h3_common_plus` and should not be used directly.

> macOS and iOS support is currently untested due to GitHub Actions limitations and lack of Apple hardware.

### Background

This package is part of a complete rework of the original Dart H3 bindings, originally created by [festelo](https://github.com/festelo) for H3 v3.x. That work has been fully updated for [Uber's H3 v4.2.1](https://github.com/uber/h3), including:

- New and renamed APIs
- Full support for `cellToVertex`, `polygonToCellsExperimental`, and more
- Check the Changelogs for more details

All code has been modernized and expanded for better performance, compatibility, and testability across platforms.

### License

This project is licensed under the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
