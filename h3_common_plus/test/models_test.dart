import 'dart:math';

import 'package:test/test.dart';
import 'package:h3_common/h3_common.dart';

void main() {
  test('CoordIJ', () async {
    CoordIJ buildA() => const CoordIJ(i: 13, j: 12);
    CoordIJ buildB() => const CoordIJ(i: 12, j: 13);
    testHashCode(buildA, buildB);
    testEquals(buildA, buildB);
    expect(
      buildA().toString(),
      'CoordIJ(i: 13, j: 12)',
      reason: 'CoordIJ.toString() works fine',
    );
  });

  test('GeoCoord', () async {
    const double latA = 13, lngA = 12;
    const double latB = 12, lngB = 13;
    const latLngConverter = LatLngConverter(NativeAngleConverter());

    LatLng buildA() => const LatLng(lat: latA, lng: lngA);
    LatLng buildB() => const LatLng(lat: latB, lng: lngB);
    testHashCode(buildA, buildB);
    testEquals(buildA, buildB);
    expect(
      buildA().toString(),
      allOf(contains(latA.toString()), contains(latA.toString())),
      reason: 'GeoCoord.toString() works fine',
    );
    expect(
      // ignore: unrelated_type_equality_checks
      const LatLng(lat: latA, lng: latA) ==
          const LatLngRadians(lat: latA, lng: lngA),
      false,
      reason:
          'GeoCoord should not be equal to GeoCoordRadians if lat and lon are equal',
    );
    expect(
      // ignore: unrelated_type_equality_checks
      buildA() == buildA().toRadians(latLngConverter),
      false,
      reason: 'GeoCoord should never be equal to GeoCoordRadians for safety',
    );
    expect(
      const LatLng(lat: latA + 180, lng: lngA + 360),
      const LatLng(lat: latA, lng: lngA),
      reason: 'World-Wrapping +',
    );
    expect(
      const LatLng(lat: latA - 180, lng: lngA - 360),
      const LatLng(lat: latA, lng: lngA),
      reason: 'World-Wrapping -',
    );
  });

  test('LatLngRadians', () async {
    const latA = 0.3 * pi, lngA = 0.2 * pi;
    const latB = 0.2 * pi, lngB = 0.3 * pi;
    const latLngConverter = LatLngConverter(NativeAngleConverter());

    LatLngRadians buildA() => const LatLngRadians(lat: latA, lng: lngA);
    LatLngRadians buildB() =>
        const LatLngRadians(lat: latB * pi, lng: lngB);

    testHashCode(buildA, buildB);
    testEquals(buildA, buildB);
    testEquals(buildA, buildB);

    expect(
      buildA().toString(),
      allOf(contains(latA.toString()), contains(latA.toString())),
      reason: 'GeoCoordRadians.toString() works fine',
    );
    expect(
      // ignore: unrelated_type_equality_checks
      const LatLngRadians(lat: latA, lng: latA) ==
          const LatLng(lat: latA, lng: lngA),
      false,
      reason:
          'GeoCoordRadians should not be equal to GeoCoord if lat and lon are equal',
    );
    expect(
      // ignore: unrelated_type_equality_checks
      buildA() == buildA().toDegrees(latLngConverter),
      false,
      reason: 'GeoCoordRadians should never be equal to GeoCoord for safety',
    );
    expect(
      const LatLngRadians(lat: latA + pi, lng: lngA + 2 * pi),
      const LatLngRadians(lat: latA, lng: lngA),
      reason: 'World-Wrapping +',
    );
    expect(
      const LatLngRadians(lat: latA - pi, lng: lngA - 2 * pi),
      const LatLngRadians(lat: latA, lng: lngA),
      reason: 'World-Wrapping -',
    );
  });

  test('H3Exception', () async {
    const testMessage = 'some message 123';
    expect(
      H3Exception(testMessage).toString(),
      contains(testMessage),
      reason: 'H3Exception.toString() shows message',
    );
  });
}

/// Test T.hashCode function
void testHashCode<T>(T Function() buildA, T Function() buildB) {
  expect(
    buildA().hashCode,
    buildA().hashCode,
    reason: 'hashCode is the same for the same $T',
  );

  expect(
    buildB().hashCode,
    isNot(buildA().hashCode),
    reason: 'hashCode is different for different $T',
  );
}

/// Test T.== operator
void testEquals<T>(T Function() buildA, T Function() buildB) {
  expect(
    buildA() == buildA(),
    true,
    reason: '== is true when $T are equal',
  );

  expect(
    buildA() == buildB(),
    false,
    reason: '== is false when $T are not equal',
  );
}
