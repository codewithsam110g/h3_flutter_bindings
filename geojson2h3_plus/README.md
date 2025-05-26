## geojson2h3\_plus

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

`geojson2h3_plus` is a Dart/Flutter library for converting between GeoJSON polygons and H3 hexagon indexes, using either:

* [`h3_dart_plus`](https://pub.dev/packages/h3_dart_plus)
* [`h3_flutter_plus`](https://pub.dev/packages/h3_flutter_plus)

### Status & Roadmap

This package is based on a handwritten implementation originally created by [festelo](https://github.com/festelo), which included only two methods without using any JavaScript dependencies. This version simply updates that work to be compatible with the H3 v4 bindings—no new functionality has been added yet.

Future updates aim to implement the full set of features from Uber's original [geojson2h3](https://github.com/uber/geojson2h3) JavaScript library, continuing the same Dart-first, dependency-free approach.

### Example

```dart
// h3_flutter_plus example
import 'package:h3_flutter_plus/h3_flutter_plus.dart';

final h3Factory = const H3Factory();
final h3 = h3Factory.load();
final geojson2h3 = Geojson2H3(h3);

final hexagon = BigInt.from(0x89283082837ffff);
final hexagonFeature = geojson2h3.h3ToFeature(hexagon);
```

### Currently Supported Methods

```dart
geojson2h3.h3ToFeature()
geojson2h3.h3SetToFeatureCollection()
```

More information on the original functionality can be found here:
[geojson2h3 by Uber](https://github.com/uber/geojson2h3)

---

### Notes

* This package is part of the H3 v4 Dart/Flutter bindings ecosystem maintained at [codewithsam110g/h3\_flutter\_bindings](https://github.com/codewithsam110g/h3_flutter_bindings).
* It is a drop-in replacement for users of the older, unmaintained `geojson2h3` Dart packages.

---

### License

This project is licensed under the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0).
