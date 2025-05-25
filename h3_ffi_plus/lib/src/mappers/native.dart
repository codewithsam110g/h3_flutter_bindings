import 'dart:ffi';

import 'package:h3_common_plus/h3_common_plus.dart';
import 'package:h3_ffi_plus/src/generated/generated_bindings.dart' as c;

extension LatLngToNativeMapperExtension on LatLngRadians {
  /// Returns LatLng representation of LatLng class
  Pointer<c.LatLng> toNative(Allocator allocator) {
    final pointer = allocator<c.LatLng>();
    assignToNative(pointer.ref);
    return pointer;
  }

  void assignToNative(c.LatLng ref) {
    ref.lat = lat;
    ref.lng = lng;
  }
}

extension LatLngFromNativeMapperExtension on c.LatLng {
  /// Returns [LatLng] representation of native LatLng class
  LatLngRadians toPure() {
    return LatLngRadians(
      lat: lat,
      lng: lng,
    );
  }
}

extension CoordIJToNativeMapperExtension on CoordIJ {
  /// Returns native representation of CoordIJ class
  Pointer<c.CoordIJ> toNative(Allocator allocator) {
    final pointer = allocator<c.CoordIJ>();
    pointer.ref.i = i;
    pointer.ref.j = j;
    return pointer;
  }
}

extension CoordIJFromNativeMapperExtension on c.CoordIJ {
  /// Returns [CoordIJ] representation of native CoordIJ class
  CoordIJ toPure() {
    return CoordIJ(
      i: i,
      j: j,
    );
  }
}
