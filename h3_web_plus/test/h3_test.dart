@TestOn('browser')
library h3_web.test.web.h3_test;
import 'dart:math';

import 'package:test/test.dart';
import 'package:h3_web/h3_web.dart';
import 'package:collection/collection.dart';

import 'common.dart';
import 'h3_js_injector.dart';

void main() async {
  await inject('https://unpkg.com/h3-js@4.2.1');

  final h3 = H3Web();

  test('isValidCell', () async {
    expect(
      h3.isValidCell(BigInt.parse('0x85283473fffffff')),
      true,
      reason: 'H3 index is considered an index',
    );
    expect(
      h3.isValidCell(BigInt.parse('0x821C37FFFFFFFFF')),
      true,
      reason: 'H3 index in upper case is considered an index',
    );
    expect(
      h3.isValidCell(BigInt.parse('0x085283473fffffff')),
      true,
      reason: 'H3 index with leading zero is considered an index',
    );
    expect(
      !h3.isValidCell(BigInt.parse('0xff283473fffffff')),
      true,
      reason: 'Hexidecimal string with incorrect bits is not valid',
    );
    for (var res = 0; res < 16; res++) {
      expect(
        h3.isValidCell(h3.latLngToCell(const LatLng(lat: 37, lng: -122), res)),
        true,
        reason: 'H3 index is considered an index',
      );
    }
  });
  test('latLngToCell', () async {
    expect(
      h3.latLngToCell(const LatLng(lat: 37.3615593, lng: -122.0553238), 5),
      BigInt.parse('0x85283473fffffff'),
      reason: 'Got the expected H3 index back',
    );
    expect(
      h3.latLngToCell(const LatLng(lat: 30.943387, lng: -164.991559), 5),
      BigInt.parse('0x8547732ffffffff'),
      reason: 'Properly handle 8 Fs',
    );
    expect(
      h3.latLngToCell(
          const LatLng(lat: 46.04189431883772, lng: 71.52790329909925), 15),
      BigInt.parse('0x8f2000000000000'),
      reason: 'Properly handle leading zeros',
    );
    expect(
      h3.latLngToCell(
          const LatLng(lat: 37.3615593, lng: -122.0553238 + 360), 5),
      BigInt.parse('0x85283473fffffff'),
      reason: 'world-wrapping lng accepted',
    );
    expect(
      h3.latLngToCell(
          const LatLng(lat: 37.3615593, lng: -122.0553238 + 720), 5),
      BigInt.parse('0x85283473fffffff'),
      reason: '2 times world-wrapping lng accepted',
    );
    expect(
      h3.latLngToCell(
        const LatLng(lat: 37.3615593 + 180, lng: -122.0553238 + 360),
        5,
      ),
      BigInt.parse('0x85283473fffffff'),
      reason: 'world-wrapping lat & lng accepted',
    );
    expect(
      h3.latLngToCell(
        const LatLng(lat: 37.3615593 - 180, lng: -122.0553238 - 360),
        5,
      ),
      BigInt.parse('0x85283473fffffff'),
      reason: 'world-wrapping lat & lng accepted 2',
    );
  });
  test('getResolution', () async {
    expect(
      () => h3.getResolution(BigInt.parse('-1')),
      throwsA(isA<H3Exception>()),
      reason: 'Throws error when an invalid index is passed',
    );
    for (var res = 0; res < 16; res++) {
      final h3Index = h3.latLngToCell(
        const LatLng(lat: 37.3615593, lng: -122.0553238),
        res,
      );
      expect(
        h3.getResolution(h3Index),
        res,
        reason: 'Got the expected resolution back',
      );
    }
  });
  test('cellToLatLng', () async {
    expect(
      ComparableLatLng.fromGeoCoord(
          h3.cellToLatLng(BigInt.parse('0x85283473fffffff'))),
      ComparableLatLng.fromLatLon(
        lat: 37.34579337536848,
        lng: -121.97637597255124,
      ),
      reason: 'lat/lng matches expected',
    );
  });

  group('gridDisk', () {
    test('k = 1', () async {
      expect(
        const DeepCollectionEquality.unordered().equals(
          h3.gridDisk(BigInt.parse('0x8928308280fffff'), 1),
          [
            BigInt.parse('0x8928308280fffff'),
            BigInt.parse('0x8928308280bffff'),
            BigInt.parse('0x89283082807ffff'),
            BigInt.parse('0x89283082877ffff'),
            BigInt.parse('0x89283082803ffff'),
            BigInt.parse('0x89283082873ffff'),
            BigInt.parse('0x8928308283bffff'),
          ],
        ),
        true,
      );
    });
    test('k = 2', () async {
      expect(
        const DeepCollectionEquality.unordered().equals(
          h3.gridDisk(BigInt.parse('0x8928308280fffff'), 2),
          [
            BigInt.parse('0x89283082813ffff'),
            BigInt.parse('0x89283082817ffff'),
            BigInt.parse('0x8928308281bffff'),
            BigInt.parse('0x89283082863ffff'),
            BigInt.parse('0x89283082823ffff'),
            BigInt.parse('0x89283082873ffff'),
            BigInt.parse('0x89283082877ffff'),
            BigInt.parse('0x8928308287bffff'),
            BigInt.parse('0x89283082833ffff'),
            BigInt.parse('0x8928308282bffff'),
            BigInt.parse('0x8928308283bffff'),
            BigInt.parse('0x89283082857ffff'),
            BigInt.parse('0x892830828abffff'),
            BigInt.parse('0x89283082847ffff'),
            BigInt.parse('0x89283082867ffff'),
            BigInt.parse('0x89283082803ffff'),
            BigInt.parse('0x89283082807ffff'),
            BigInt.parse('0x8928308280bffff'),
            BigInt.parse('0x8928308280fffff')
          ],
        ),
        true,
      );
    });
    test('Bad Radius', () async {
      expect(
        const DeepCollectionEquality.unordered().equals(
          h3.gridDisk(BigInt.parse('0x8928308280fffff'), -7),
          [BigInt.parse('0x8928308280fffff')],
        ),
        true,
      );
    });
    test('Pentagon', () async {
      expect(
        const DeepCollectionEquality.unordered().equals(
          h3.gridDisk(BigInt.parse('0x821c07fffffffff'), 1),
          [
            BigInt.parse('0x821c2ffffffffff'),
            BigInt.parse('0x821c27fffffffff'),
            BigInt.parse('0x821c07fffffffff'),
            BigInt.parse('0x821c17fffffffff'),
            BigInt.parse('0x821c1ffffffffff'),
            BigInt.parse('0x821c37fffffffff'),
          ],
        ),
        true,
      );
    });
    test('Edge case', () async {
      // In H3-JS there was an issue reading particular 64-bit integers correctly,
      // this gridDisk ran into it.
      // Check it just in case
      expect(
        const DeepCollectionEquality.unordered().equals(
          h3.gridDisk(BigInt.parse('0x8928308324bffff'), 1),
          [
            BigInt.parse('0x8928308324bffff'),
            BigInt.parse('0x892830989b3ffff'),
            BigInt.parse('0x89283098987ffff'),
            BigInt.parse('0x89283098997ffff'),
            BigInt.parse('0x8928308325bffff'),
            BigInt.parse('0x89283083243ffff'),
            BigInt.parse('0x8928308324fffff'),
          ],
        ),
        true,
      );
    });
  });

  group('gridRingUnsafe', () {
    test('ringSize = 1', () async {
      expect(
        const DeepCollectionEquality.unordered().equals(
          h3.gridRingUnsafe(BigInt.parse('0x8928308280fffff'), 1),
          [
            BigInt.parse('0x8928308280bffff'),
            BigInt.parse('0x89283082807ffff'),
            BigInt.parse('0x89283082877ffff'),
            BigInt.parse('0x89283082803ffff'),
            BigInt.parse('0x89283082873ffff'),
            BigInt.parse('0x8928308283bffff'),
          ],
        ),
        true,
      );
    });
    test('ringSize = 2', () async {
      expect(
        const DeepCollectionEquality.unordered().equals(
          h3.gridRingUnsafe(BigInt.parse('0x8928308280fffff'), 2),
          [
            BigInt.parse('0x89283082813ffff'),
            BigInt.parse('0x89283082817ffff'),
            BigInt.parse('0x8928308281bffff'),
            BigInt.parse('0x89283082863ffff'),
            BigInt.parse('0x89283082823ffff'),
            BigInt.parse('0x8928308287bffff'),
            BigInt.parse('0x89283082833ffff'),
            BigInt.parse('0x8928308282bffff'),
            BigInt.parse('0x89283082857ffff'),
            BigInt.parse('0x892830828abffff'),
            BigInt.parse('0x89283082847ffff'),
            BigInt.parse('0x89283082867ffff'),
          ],
        ),
        true,
      );
    });
    test('ringSize = 0', () async {
      expect(
        const DeepCollectionEquality.unordered().equals(
          h3.gridRingUnsafe(BigInt.parse('0x8928308280fffff'), 0),
          [BigInt.parse('0x8928308280fffff')],
        ),
        true,
      );
    });
    test('Pentagon', () async {
      expect(
        () => h3.gridRingUnsafe(BigInt.parse('0x821c07fffffffff'), 2),
        throwsA(isA<H3Exception>()),
        reason: 'Throws with a pentagon origin',
      );
      expect(
        () => h3.gridRingUnsafe(BigInt.parse('0x821c2ffffffffff'), 1),
        throwsA(isA<H3Exception>()),
        reason: 'Throws with a pentagon in the ring itself',
      );
      expect(
        () => h3.gridRingUnsafe(BigInt.parse('0x821c2ffffffffff'), 5),
        throwsA(isA<H3Exception>()),
        reason: 'Throws with a pentagon inside the ring',
      );
    });
  });
  test('radsToDegs', () async {
    expect(h3.radsToDegs(pi / 2), 90);
    expect(h3.radsToDegs(pi), 180);
    expect(h3.radsToDegs(pi * 2), 360);
    expect(h3.radsToDegs(pi * 4), 720);
  });
  test('degsToRads', () async {
    expect(h3.degsToRads(90), pi / 2);
    expect(h3.degsToRads(180), pi);
    expect(h3.degsToRads(360), pi * 2);
    expect(h3.degsToRads(720), pi * 4);
  });
  group('cellToBoundary', () {
    test('Hexagon', () async {
      final coordinates = h3.cellToBoundary(BigInt.parse('0x85283473fffffff'));
      const expectedCoordinates = [
        LatLng(lat: 37.271355866731895, lng: -121.91508032705622),
        LatLng(lat: 37.353926450852256, lng: -121.86222328902491),
        LatLng(lat: 37.42834118609435, lng: -121.9235499963016),
        LatLng(lat: 37.42012867767778, lng: -122.0377349642703),
        LatLng(lat: 37.33755608435298, lng: -122.09042892904395),
        LatLng(lat: 37.26319797461824, lng: -122.02910130919)
      ];
      expect(
        coordinates.map((e) => ComparableLatLng.fromGeoCoord(e)).toList(),
        expectedCoordinates
            .map((e) => ComparableLatLng.fromGeoCoord(e))
            .toList(),
      );
    });

    test('10-Vertex Pentagon', () async {
      final coordinates = h3.cellToBoundary(BigInt.parse('0x81623ffffffffff'));
      const expectedCoordinates = [
        LatLng(lat: 12.754829243237463, lng: 55.94007484027043),
        LatLng(lat: 10.2969712272183, lng: 55.17817579309866),
        LatLng(lat: 9.092686031788567, lng: 55.25056228923791),
        LatLng(lat: 7.616228142303126, lng: 57.375161319501046),
        LatLng(lat: 7.3020872486093165, lng: 58.549882762724735),
        LatLng(lat: 8.825639135958125, lng: 60.638711994711066),
        LatLng(lat: 9.83036925628956, lng: 61.315435771664625),
        LatLng(lat: 12.271971829831212, lng: 60.50225323351279),
        LatLng(lat: 13.216340916028164, lng: 59.73257508857316),
        LatLng(lat: 13.191260466758202, lng: 57.09422507335292),
      ];
      expect(
        coordinates.map((e) => ComparableLatLng.fromGeoCoord(e)).toList(),
        expectedCoordinates
            .map((e) => ComparableLatLng.fromGeoCoord(e))
            .toList(),
      );
    });
  });
  group('polygonToCells', () {
    test('Hexagon', () async {
      final hexagons = h3.polygonToCells(
        coordinates: const [
          LatLng(lat: 37.813318999983238, lng: -122.4089866999972145),
          LatLng(lat: 37.7866302000007224, lng: -122.3805436999997056),
          LatLng(lat: 37.7198061999978478, lng: -122.3544736999993603),
          LatLng(lat: 37.7076131999975672, lng: -122.5123436999983966),
          LatLng(lat: 37.7835871999971715, lng: -122.5247187000021967),
          LatLng(lat: 37.8151571999998453, lng: -122.4798767000009008),
        ],
        resolution: 9,
      );
      expect(
        hexagons.length,
        1253,
      );
    });

    test('Hexagon with holes', () async {
      final resolution = 5;
      // wkt: POLYGON ((35 10, 45 45, 15 40, 10 20, 35 10),(20 30, 35 35, 30 20, 20 30))
      final hexagons = h3.polygonToCells(
        coordinates: const [
          LatLng(lng: 35, lat: 10),
          LatLng(lng: 45, lat: 45),
          LatLng(lng: 15, lat: 40),
          LatLng(lng: 10, lat: 20),
          LatLng(lng: 35, lat: 10)
        ],
        holes: const [
          [
            LatLng(lng: 20, lat: 30),
            LatLng(lng: 35, lat: 35),
            LatLng(lng: 30, lat: 20),
            LatLng(lng: 20, lat: 30)
          ]
        ],
        resolution: resolution,
      );

      // point inside the hole 28.037109375000004 28.84467368077179 (this should be classified as outside)
      //point inside 18.45703125 21.616579336740614
      //point outside (far away) 52.55859375 23.48340065432562

      final insideHoleIndex = h3.latLngToCell(
          LatLng(lng: 28.037109375000004, lat: 28.84467368077179), resolution);
      expect(hexagons.contains(insideHoleIndex), false);

      final insideIndex = h3.latLngToCell(
          LatLng(lng: 18.45703125, lat: 21.616579336740614), resolution);
      expect(hexagons.contains(insideIndex), true);

      final outsideIndex = h3.latLngToCell(
          LatLng(lng: 52.55859375, lat: 23.48340065432562), resolution);
      expect(hexagons.contains(outsideIndex), false);
    });

    test('Transmeridian', () async {
      final hexagons = h3.polygonToCells(
        coordinates: const [
          LatLng(lat: 0.5729577951308232, lng: -179.4270422048692),
          LatLng(lat: 0.5729577951308232, lng: 179.4270422048692),
          LatLng(lat: -0.5729577951308232, lng: 179.4270422048692),
          LatLng(lat: -0.5729577951308232, lng: -179.4270422048692),
        ],
        resolution: 7,
      );
      expect(
        hexagons.length,
        4238,
      );
    });

    test('Empty', () async {
      final hexagons = h3.polygonToCells(
        coordinates: const [],
        resolution: 9,
      );
      expect(
        hexagons.length,
        0,
      );
    });

    test('Negative resolution', () async {
      expect(
        () => h3.polygonToCells(
          coordinates: const [
            LatLng(lat: 0.5729577951308232, lng: -179.4270422048692),
            LatLng(lat: 0.5729577951308232, lng: 179.4270422048692),
            LatLng(lat: -0.5729577951308232, lng: 179.4270422048692),
            LatLng(lat: -0.5729577951308232, lng: -179.4270422048692),
          ],
          resolution: -9,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('compactCells and uncompactCells', () {
    test('Basic', () async {
      final hexagons = h3.polygonToCells(
        coordinates: [
          const LatLng(lat: 37.813318999983238, lng: -122.4089866999972145),
          const LatLng(lat: 37.7866302000007224, lng: -122.3805436999997056),
          const LatLng(lat: 37.7198061999978478, lng: -122.3544736999993603),
          const LatLng(lat: 37.7076131999975672, lng: -122.5123436999983966),
          const LatLng(lat: 37.7835871999971715, lng: -122.5247187000021967),
          const LatLng(lat: 37.8151571999998453, lng: -122.4798767000009008),
        ],
        resolution: 9,
      );
      final compactedHexagons = h3.compactCells(hexagons);
      expect(compactedHexagons.length, 209);
      final uncompactedHexagons = h3.uncompactCells(
        compactedHexagons,
        resolution: 9,
      );
      expect(uncompactedHexagons.length, 1253);
    });

    test('Compact - Empty', () async {
      expect(h3.compactCells([]).length, 0);
    });

    test('Uncompact - Empty', () async {
      expect(h3.uncompactCells([], resolution: 9).length, 0);
    });

    test('Ignore duplicates', () async {
      final hexagons = h3.polygonToCells(
        coordinates: [
          const LatLng(lat: 37.813318999983238, lng: -122.4089866999972145),
          const LatLng(lat: 37.813318999983238, lng: -122.4089866999972145),
          const LatLng(lat: 37.813318999983238, lng: -122.4089866999972145),
          const LatLng(lat: 37.7866302000007224, lng: -122.3805436999997056),
          const LatLng(lat: 37.7198061999978478, lng: -122.3544736999993603),
          const LatLng(lat: 37.7076131999975672, lng: -122.5123436999983966),
          const LatLng(lat: 37.7835871999971715, lng: -122.5247187000021967),
          const LatLng(lat: 37.8151571999998453, lng: -122.4798767000009008),
        ],
        resolution: 9,
      );
      final compactedHexagons = h3.compactCells(hexagons);
      expect(compactedHexagons.length, 209);
      final uncompactedHexagons = h3.uncompactCells(
        compactedHexagons,
        resolution: 9,
      );
      expect(uncompactedHexagons.length, 1253);
    });

    test('Uncompact - Invalid', () async {
      expect(
        () => h3.uncompactCells(
          [
            h3.latLngToCell(
                const LatLng(lat: 37.3615593, lng: -122.0553238), 10)
          ],
          resolution: 5,
        ),
        throwsA(isA<H3Exception>()),
      );
    });
  });
  test('isPentagon', () async {
    expect(
      h3.isPentagon(BigInt.parse('0x8928308280fffff')),
      false,
    );
    expect(
      h3.isPentagon(BigInt.parse('0x821c07fffffffff')),
      true,
    );
    expect(
      h3.isPentagon(BigInt.parse('0x0')),
      false,
    );
  });
  test('isResClassIII', () async {
    // Test all even indexes
    for (var i = 0; i < 15; i += 2) {
      final h3Index = h3.latLngToCell(
        const LatLng(lat: 37.3615593, lng: -122.0553238),
        i,
      );
      expect(h3.isResClassIII(h3Index), false);
    }
    // Test all odd indexes
    for (var i = 1; i < 15; i += 2) {
      final h3Index = h3.latLngToCell(
        const LatLng(lat: 37.3615593, lng: -122.0553238),
        i,
      );
      expect(h3.isResClassIII(h3Index), true);
    }
  });
  test('getIcosahedronFaces', () async {
    void testFace(String name, BigInt h3Index, int expected) {
      final faces = h3.getIcosahedronFaces(h3Index);

      expect(
        faces.length,
        expected,
        reason: 'Got expected face count for $name',
      );
      expect(
        faces.toSet().length,
        expected,
        reason: 'Faces are unique for $name',
      );
      expect(
        faces.every((e) => e >= 0 && e < 20),
        true,
        reason: ' face indexes in expected range for $name',
      );
    }

    testFace('single face', BigInt.parse('0x85283473fffffff'), 1);
    testFace('edge adjacent', BigInt.parse('0x821c37fffffffff'), 1);
    testFace('edge crossing, distorted', BigInt.parse('0x831c06fffffffff'), 2);
    testFace('edge crossing, aligned', BigInt.parse('0x821ce7fffffffff'), 2);
    testFace('class II pentagon', BigInt.parse('0x84a6001ffffffff'), 5);
    testFace('class III pentagon', BigInt.parse('0x85a60003fffffff'), 5);
  });

  test('getBaseCellNumber', () async {
    expect(h3.getBaseCellNumber(BigInt.parse('0x8928308280fffff')), 20);
  });

  group('cellToParent', () {
    test('Basic', () async {
      // NB: This test will not work with every hexagon, it has to be a location
      // that does not fall in the margin of error between the 7 children and
      // the parent's true boundaries at every resolution
      const lat = 37.81331899988944;
      const lng = -122.409290778685;
      for (var res = 1; res < 10; res++) {
        for (var step = 0; step < res; step++) {
          final child = h3.latLngToCell(const LatLng(lat: lat, lng: lng), res);

          final comparisonParent =
              h3.latLngToCell(const LatLng(lat: lat, lng: lng), res - step);

          final parent = h3.cellToParent(child, res - step);
          expect(
            parent,
            comparisonParent,
            reason: 'Got expected parent for $res:${res - step}',
          );
        }
      }
    });
    test('Invalid', () async {
      final h3Index = BigInt.parse('0x8928308280fffff');

      expect(
        h3.cellToParent(h3Index, 10),
        BigInt.zero,
        reason: 'Finer resolution returns zero',
      );

      expect(
        h3.cellToParent(h3Index, -1),
        BigInt.zero,
        reason: 'Invalid resolution returns zero',
      );
    });
  });

  test('cellToChildren', () async {
    const lat = 37.81331899988944;
    const lng = -122.409290778685;
    final h3Index = h3.latLngToCell(const LatLng(lat: lat, lng: lng), 7);

    expect(h3.cellToChildren(h3Index, 8).length, 7,
        reason: 'Immediate child count correct');

    expect(h3.cellToChildren(h3Index, 9).length, 49,
        reason: 'Grandchild count correct');

    expect(h3.cellToChildren(h3Index, 7), [h3Index],
        reason: 'Same resolution returns self');

    expect(h3.cellToChildren(h3Index, 6), [],
        reason: 'Coarser resolution returns empty array');

    expect(h3.cellToChildren(h3Index, -1), [],
        reason: 'Invalid resolution returns empty array');
  });

  group('cellToCenterChild', () {
    test('Basic', () async {
      final baseIndex = BigInt.parse('0x8029fffffffffff');
      final geo = h3.cellToLatLng(baseIndex);
      for (var res = 0; res < 14; res++) {
        for (var childRes = res; childRes < 15; childRes++) {
          final parent = h3.latLngToCell(geo, res);
          final comparisonChild = h3.latLngToCell(geo, childRes);
          final child = h3.cellToCenterChild(parent, childRes);

          expect(
            child,
            comparisonChild,
            reason: 'Got expected center child for $res:$childRes',
          );
        }
      }
    });
    test('Invalid', () async {
      final h3Index = BigInt.parse('0x8928308280fffff');

      expect(h3.cellToCenterChild(h3Index, 5), BigInt.zero,
          reason: 'Coarser resolution returns zero');

      expect(h3.cellToCenterChild(h3Index, -1), BigInt.zero,
          reason: 'Invalid resolution returns zero');
    });
  });

  test('areNeighborCells', () async {
    final origin = BigInt.parse('0x891ea6d6533ffff');
    final adjacent = BigInt.parse('0x891ea6d65afffff');
    final notAdjacent = BigInt.parse('0x891ea6992dbffff');

    expect(
      h3.areNeighborCells(origin, adjacent),
      true,
      reason: 'Adjacent hexagons are neighbors',
    );

    expect(
      h3.areNeighborCells(adjacent, origin),
      true,
      reason: 'Adjacent hexagons are neighbors',
    );

    expect(
      h3.areNeighborCells(origin, notAdjacent),
      false,
      reason: 'Non-adjacent hexagons are not neighbors',
    );

    expect(
      h3.areNeighborCells(origin, origin),
      false,
      reason: 'A hexagon is not a neighbor to itself',
    );

    expect(
      h3.areNeighborCells(origin, BigInt.parse('-1')),
      false,
      reason: 'A hexagon is not a neighbor to an invalid index',
    );

    expect(
      h3.areNeighborCells(origin, BigInt.parse('42')),
      false,
      reason: 'A hexagon is not a neighbor to an invalid index',
    );

    expect(
      h3.areNeighborCells(BigInt.parse('-1'), BigInt.parse('-1')),
      false,
      reason: 'Two invalid indexes are not neighbors',
    );
  });

  test('cellsToDirectedEdge', () async {
    final origin = BigInt.parse('0x891ea6d6533ffff');
    final destination = BigInt.parse('0x891ea6d65afffff');
    final edge = BigInt.parse('0x1591ea6d6533ffff');
    final notAdjacent = BigInt.parse('0x891ea6992dbffff');

    expect(
      h3.cellsToDirectedEdge(origin, destination),
      edge,
      reason: 'Got expected edge for adjacent hexagons',
    );

    expect(
      h3.cellsToDirectedEdge(origin, notAdjacent),
      BigInt.zero,
      reason: 'Got 0 for non-adjacent hexagons',
    );

    expect(
      h3.cellsToDirectedEdge(origin, origin),
      BigInt.zero,
      reason: 'Got 0 for same hexagons',
    );

    expect(
      h3.cellsToDirectedEdge(origin, BigInt.parse('-1')),
      BigInt.zero,
      reason: 'Got 0 for invalid destination',
    );

    expect(
      h3.cellsToDirectedEdge(BigInt.parse('-1'), BigInt.parse('-1')),
      BigInt.zero,
      reason: 'Got 0 for invalid hexagons',
    );
  });

  test('getDirectedEdgeOrigin', () async {
    final origin = BigInt.parse('0x891ea6d6533ffff');
    final edge = BigInt.parse('0x1591ea6d6533ffff');

    expect(
      h3.getDirectedEdgeOrigin(edge),
      origin,
      reason: 'Got expected origin for edge',
    );

    expect(
      h3.getDirectedEdgeOrigin(origin),
      BigInt.zero,
      reason: 'Got 0 for non-edge hexagon',
    );

    expect(
      h3.getDirectedEdgeOrigin(BigInt.parse('-1')),
      BigInt.zero,
      reason: 'Got 0 for non-valid hexagon',
    );
  });

  test('getDirectedEdgeDestination', () async {
    final destination = BigInt.parse('0x891ea6d65afffff');
    final edge = BigInt.parse('0x1591ea6d6533ffff');

    expect(
      h3.getDirectedEdgeDestination(edge),
      destination,
      reason: 'Got expected origin for edge',
    );

    expect(
      h3.getDirectedEdgeDestination(destination),
      BigInt.zero,
      reason: 'Got 0 for non-edge hexagon',
    );

    expect(
      h3.getDirectedEdgeDestination(BigInt.parse('-1')),
      BigInt.zero,
      reason: 'Got 0 for non-valid hexagon',
    );
  });

  test('isValidDirectedEdge', () async {
    final origin = BigInt.parse('0x891ea6d6533ffff');
    final destination = BigInt.parse('0x891ea6d65afffff');

    expect(
      h3.isValidDirectedEdge(BigInt.parse('0x1591ea6d6533ffff')),
      true,
      reason: 'Edge index is valid',
    );

    expect(
      h3.isValidDirectedEdge(
        h3.cellsToDirectedEdge(origin, destination),
      ),
      true,
      reason: 'Output of cellsToDirectedEdge is valid',
    );

    expect(
      h3.isValidDirectedEdge(BigInt.parse('-1')),
      false,
      reason: '-1 is not valid',
    );
  });

  test('directedEdgeToCells', () async {
    final origin = BigInt.parse('0x891ea6d6533ffff');
    final destination = BigInt.parse('0x891ea6d65afffff');
    final edge = BigInt.parse('0x1591ea6d6533ffff');

    expect(
      h3.directedEdgeToCells(edge),
      [origin, destination],
      reason: 'Got expected origin, destination from edge',
    );

    expect(
      h3.directedEdgeToCells(h3.cellsToDirectedEdge(origin, destination)),
      [origin, destination],
      reason:
          'Got expected origin, destination from cellsToDirectedEdge output',
    );
  });

  group('originToDirectedEdges', () {
    test('Basic', () async {
      final origin = BigInt.parse('0x8928308280fffff');
      final edges = h3.originToDirectedEdges(origin);

      expect(
        edges.length,
        6,
        reason: 'got expected edge count',
      );

      final neighbours = h3.gridRingUnsafe(origin, 1);
      for (final neighbour in neighbours) {
        final edge = h3.cellsToDirectedEdge(origin, neighbour);
        expect(
          edges.contains(edge),
          true,
          reason: 'found edge to neighbor',
        );
      }
    });

    test('Pentagon', () async {
      final origin = BigInt.parse('0x81623ffffffffff');
      final edges = h3.originToDirectedEdges(origin);

      expect(
        edges.length,
        5,
        reason: 'got expected edge count',
      );

      final neighbours =
          h3.gridDisk(origin, 1).where((e) => e != origin).toList();

      for (final neighbour in neighbours) {
        final edge = h3.cellsToDirectedEdge(origin, neighbour);
        expect(
          edges.contains(edge),
          true,
          reason: 'found edge to neighbor',
        );
      }
    });
  });

  group('directedEdgeToBoundary', () {
    test('Basic', () async {
      final origin = BigInt.parse('0x85283473fffffff');
      final edges = h3.originToDirectedEdges(origin);

      // GeoBoundary of the origin
      final originBoundary = h3.cellToBoundary(origin);

      final expectedEdges = [
        [originBoundary[3], originBoundary[4]],
        [originBoundary[1], originBoundary[2]],
        [originBoundary[2], originBoundary[3]],
        [originBoundary[5], originBoundary[0]],
        [originBoundary[4], originBoundary[5]],
        [originBoundary[0], originBoundary[1]]
      ];

      for (var i = 0; i < edges.length; i++) {
        final latlngs = h3.directedEdgeToBoundary(edges[i]);
        expect(
          latlngs.map((g) => ComparableLatLng.fromGeoCoord(g)),
          expectedEdges[i].map((g) => ComparableLatLng.fromGeoCoord(g)),
          reason: 'Coordinates match expected for edge $i',
        );
      }
    });

    test('10-vertex pentagon', () async {
      final origin = BigInt.parse('0x81623ffffffffff');
      final edges = h3.originToDirectedEdges(origin);

      // GeoBoundary of the origin
      final originBoundary = h3.cellToBoundary(origin);

      final expectedEdges = [
        [originBoundary[2], originBoundary[3], originBoundary[4]],
        [originBoundary[4], originBoundary[5], originBoundary[6]],
        [originBoundary[8], originBoundary[9], originBoundary[0]],
        [originBoundary[6], originBoundary[7], originBoundary[8]],
        [originBoundary[0], originBoundary[1], originBoundary[2]]
      ];

      for (var i = 0; i < edges.length; i++) {
        final latlngs = h3.directedEdgeToBoundary(edges[i]);
        expect(
          latlngs.map((g) => ComparableLatLng.fromGeoCoord(g)),
          expectedEdges[i].map((g) => ComparableLatLng.fromGeoCoord(g)),
          reason: 'Coordinates match expected for edge $i',
        );
      }
    });
  });

  group('gridDistance', () {
    test('Basic', () async {
      final origin = h3.latLngToCell(const LatLng(lat: 37.5, lng: -122), 9);
      for (var radius = 0; radius < 4; radius++) {
        final others = h3.gridRingUnsafe(origin, radius);
        for (var i = 0; i < others.length; i++) {
          expect(h3.gridDistance(origin, others[i]), radius,
              reason: 'Got distance $radius for ($origin, ${others[i]})');
        }
      }
    });

    test('Failure', () async {
      final origin = h3.latLngToCell(const LatLng(lat: 37.5, lng: -122), 9);
      final origin10 = h3.latLngToCell(const LatLng(lat: 37.5, lng: -122), 10);
      final edge = BigInt.parse('0x1591ea6d6533ffff');

      expect(
        h3.gridDistance(origin, origin10),
        -1,
        reason: 'Returned -1 for distance between different resolutions',
      );
      expect(
        h3.gridDistance(origin, edge),
        -1,
        reason: 'Returned -1 for distance between hexagon and edge',
      );      
    });
  });

  group('gridPathCells', () {
    test('Basic', () async {
      for (var res = 0; res < 12; res++) {
        final origin = h3.latLngToCell(const LatLng(lat: 37.5, lng: -122), res);
        final destination =
            h3.latLngToCell(const LatLng(lat: 25, lng: -120), res);
        final line = h3.gridPathCells(origin, destination);
        final distance = h3.gridDistance(origin, destination);
        expect(
          line.length,
          distance + 1,
          reason: 'distance matches expected: ${distance + 1}',
        );

        // property-based test for the line
        expect(
          line.asMap().entries.every(
                (e) =>
                    e.key == 0 ||
                    h3.areNeighborCells(
                      e.value,
                      line[e.key - 1],
                    ),
              ),
          true,
          reason: 'every index in the line is a neighbor of the previous',
        );
      }
    });

    test('Failure', () async {
      final origin = h3.latLngToCell(const LatLng(lat: 37.5, lng: -122), 9);
      final origin10 = h3.latLngToCell(const LatLng(lat: 37.5, lng: -122), 10);

      expect(
        () => h3.gridPathCells(origin, origin10),
        throwsA(isA<H3Exception>()),
        reason: 'got expected error for different resolutions',
      );
    });
  });

  group('cellToLocalIj / localIjToCell', () {
    test('Basic', () async {
      final origin = BigInt.parse('0x8828308281fffff');
      final testValues = {
        origin: const CoordIJ(i: 392, j: 336),
        BigInt.parse('0x882830828dfffff'): const CoordIJ(i: 393, j: 337),
        BigInt.parse('0x8828308285fffff'): const CoordIJ(i: 392, j: 337),
        BigInt.parse('0x8828308287fffff'): const CoordIJ(i: 391, j: 336),
        BigInt.parse('0x8828308283fffff'): const CoordIJ(i: 391, j: 335),
        BigInt.parse('0x882830828bfffff'): const CoordIJ(i: 392, j: 335),
        BigInt.parse('0x8828308289fffff'): const CoordIJ(i: 393, j: 336),
      };
      for (final testValue in testValues.entries) {
        final h3Index = testValue.key;
        final coord = testValue.value;
        expect(
          h3.cellToLocalIj(origin, h3Index),
          coord,
          reason: 'Got expected coordinates for $h3Index',
        );
        expect(
          h3.localIjToCell(origin, coord),
          h3Index,
          reason: 'Got expected H3 index for $coord',
        );
      }
    });
    test('Pentagon', () async {
      final origin = BigInt.parse('0x811c3ffffffffff');
      final testValues = {
        origin: const CoordIJ(i: 0, j: 0),
        BigInt.parse('0x811d3ffffffffff'): const CoordIJ(i: 1, j: 0),
        BigInt.parse('0x811cfffffffffff'): const CoordIJ(i: -1, j: 0),
      };

      for (final testValue in testValues.entries) {
        final h3Index = testValue.key;
        final coord = testValue.value;
        expect(
          h3.cellToLocalIj(origin, h3Index),
          coord,
          reason: 'Got expected coordinates for $h3Index',
        );
        expect(
          h3.localIjToCell(origin, coord),
          h3Index,
          reason: 'Got expected H3 index for $coord',
        );
      }
    });

    test('Failure', () async {
      // cellToLocalIj

      expect(
        () => h3.cellToLocalIj(BigInt.parse('0x832830fffffffff'),
            BigInt.parse('0x822837fffffffff')),
        throwsA(isA<H3Exception>()),
        reason: 'Got expected error',
      );
      expect(
        () => h3.cellToLocalIj(BigInt.parse('0x822a17fffffffff'),
            BigInt.parse('0x822837fffffffff')),
        throwsA(isA<H3Exception>()),
        reason: 'Got expected error',
      );
      expect(
        () => h3.cellToLocalIj(BigInt.parse('0x8828308281fffff'),
            BigInt.parse('0x8841492553fffff')),
        throwsA(isA<H3Exception>()),
        reason: 'Got expected error for opposite sides of the world',
      );
      expect(
        () => h3.cellToLocalIj(BigInt.parse('0x81283ffffffffff'),
            BigInt.parse('0x811cbffffffffff')),
        throwsA(isA<H3Exception>()),
        reason: 'Got expected error',
      );
      expect(
        () => h3.cellToLocalIj(BigInt.parse('0x811d3ffffffffff'),
            BigInt.parse('0x8122bffffffffff')),
        throwsA(isA<H3Exception>()),
        reason: 'Got expected error',
      );

      // localIjToCell

      expect(
        () => h3.localIjToCell(
          BigInt.parse('0x8049fffffffffff'),
          const CoordIJ(i: 2, j: 0),
        ),
        throwsA(isA<H3Exception>()),
        reason: 'Got expected error when index is not defined',
      );
    });
  });

  group('getHexagonAreaAvg', () {
    test('Basic', () async {
      var last = 1e14;
      for (var res = 0; res < 16; res++) {
        final result = h3.getHexagonAreaAvg(res, H3AreaUnits.m2);
        expect(
          result < last,
          true,
          reason: 'result < last result: $result, $last',
        );
        last = result;
      }

      last = 1e7;
      for (var res = 0; res < 16; res++) {
        final result = h3.getHexagonAreaAvg(res, H3AreaUnits.km2);
        expect(
          result < last,
          true,
          reason: 'result < last result: $result, $last',
        );
        last = result;
      }
    });
    test('Bad resolution', () async {
      expect(
        () => h3.getHexagonAreaAvg(42, H3AreaUnits.km2),
        throwsA(isA<AssertionError>()),
        reason: 'throws on invalid resolution',
      );
    });
  });

  group('getHexagonEdgeLengthAvg', () {
    test('Basic', () async {
      var last = 1e7;
      for (var res = 0; res < 16; res++) {
        final result = h3.getHexagonEdgeLengthAvg(res, H3EdgeLengthUnits.m);
        expect(
          result < last,
          true,
          reason: 'result < last result: $result, $last',
        );
        last = result;
      }

      last = 1e4;
      for (var res = 0; res < 16; res++) {
        final result = h3.getHexagonEdgeLengthAvg(res, H3EdgeLengthUnits.km);
        expect(
          result < last,
          true,
          reason: 'result < last result: $result, $last',
        );
        last = result;
      }
    });
    test('Bad resolution', () async {
      expect(
        () => h3.getHexagonEdgeLengthAvg(42, H3EdgeLengthUnits.km),
        throwsA(isA<AssertionError>()),
        reason: 'throws on invalid resolution',
      );
    });
  });
  test('cellArea', () async {
    const expectedAreas = [
      2.562182162955496e+06,
      4.476842018179411e+05,
      6.596162242711056e+04,
      9.228872919002590e+03,
      1.318694490797110e+03,
      1.879593512281298e+02,
      2.687164354763186e+01,
      3.840848847060638e+00,
      5.486939641329893e-01,
      7.838600808637444e-02,
      1.119834221989390e-02,
      1.599777169186614e-03,
      2.285390931423380e-04,
      3.264850232091780e-05,
      4.664070326136774e-06,
      6.662957615868888e-07
    ];

    for (var res = 0; res < 16; res++) {
      final h3Index = h3.latLngToCell(const LatLng(lat: 0, lng: 0), res);
      final cellAreaKm2 = h3.cellArea(h3Index, H3Units.km);
      expect(
        almostEqual(cellAreaKm2, expectedAreas[res]),
        true,
        reason: 'Area matches expected value at res $res',
      );
      final cellAreaM2 = h3.cellArea(h3Index, H3Units.m);
      if (res != 0) {
        // Property tests
        // res 0 has high distortion of average area due to high pentagon proportion
        expect(
          // This seems to be the lowest factor that works for other resolutions
          almostEqual(
              cellAreaKm2, h3.getHexagonAreaAvg(res, H3AreaUnits.km2), 0.4),
          true,
          reason: 'Area is close to average area at res $res, km2',
        );
        expect(
          // This seems to be the lowest factor that works for other resolutions
          almostEqual(
              cellAreaM2, h3.getHexagonAreaAvg(res, H3AreaUnits.m2), 0.4),
          true,
          reason: 'Area is close to average area at res $res, m2',
        );
      }

      expect(
        cellAreaM2 > cellAreaKm2,
        true,
        reason: 'm2 > Km2',
      );

      expect(
        cellAreaKm2 > h3.cellArea(h3Index, H3Units.rad),
        true,
        reason: 'Km2 > rads2',
      );
    }
  });

  test('greatCircleDistance', () async {
    expect(
      almostEqual(
        h3.greatCircleDistance(
          const LatLng(lat: -10, lng: 0),
          const LatLng(lat: 10, lng: 0),
          H3Units.rad,
        ),
        h3.degsToRads(20),
      ),
      true,
      reason: 'Got expected angular distance for latitude along the equator',
    );

    expect(
      almostEqual(
        h3.greatCircleDistance(
          const LatLng(lat: 0, lng: -10),
          const LatLng(lat: 0, lng: 10),
          H3Units.rad,
        ),
        h3.degsToRads(20),
      ),
      true,
      reason: 'Got expected angular distance for latitude along a meridian',
    );
    expect(
      h3.greatCircleDistance(
        const LatLng(lat: 23, lng: 23),
        const LatLng(lat: 23, lng: 23),
        H3Units.rad,
      ),
      0,
      reason: 'Got expected angular distance for same point',
    );

    // Just rough tests for the other units
    final distKm = h3.greatCircleDistance(const LatLng(lat: 0, lng: 0),
        const LatLng(lat: 39, lng: -122), H3Units.km);

    expect(
      distKm > 12e3 && distKm < 13e3,
      true,
      reason: 'has some reasonable distance in Km',
    );

    final distM = h3.greatCircleDistance(
      const LatLng(lat: 0, lng: 0),
      const LatLng(lat: 39, lng: -122),
      H3Units.m,
    );

    expect(
      distM > 12e6 && distM < 13e6,
      true,
      reason: 'has some reasonable distance in m',
    );
  });

  test('edgeLength', () async {
    for (var res = 0; res < 16; res++) {
      final h3Index = h3.latLngToCell(const LatLng(lat: 0, lng: 0), res);
      final edges = h3.originToDirectedEdges(h3Index);
      for (var i = 0; i < edges.length; i++) {
        final edge = edges[i];
        final lengthKm = h3.edgeLength(edge, H3Units.km);
        final lengthM = h3.edgeLength(edge, H3Units.m);
        final gotKm = h3.getHexagonEdgeLengthAvg(res, H3EdgeLengthUnits.km);
        final gotM = h3.getHexagonEdgeLengthAvg(res, H3EdgeLengthUnits.m);

        expect(lengthKm > 0, true, reason: 'Has some length');
        expect(lengthM > 0, true, reason: 'Has some length');
        expect(lengthKm * 1000, lengthM, reason: 'km * 1000 = m');
        double tolerance = 0.25;
        if (res == 2 || res == 3) {
          tolerance = 0.35;
        }

        if (res > 1) {
          // res 0 has high distortion of average edge length due to high pentagon proportion
          expect(
            almostEqual(
              lengthKm,
              gotKm,
              tolerance,
            ),
            true,
            reason:
                'Edge length is close to average edge length at res $res, km, the length is $lengthKm and got is: $gotKm',
          );
          expect(
            almostEqual(
              lengthM,
              gotM,
              tolerance,
            ),
            true,
            reason:
                'Edge length is close to average edge length at res $res, m, the length is $lengthM and got is: $gotM',
          );
        }

        expect(
          lengthM > lengthKm,
          true,
          reason: 'm > Km',
        );

        expect(
          lengthKm > h3.edgeLength(edge, H3Units.rad),
          true,
          reason: 'Km > rads',
        );
      }
    }
  });

  test('getNumCells', () async {
    var last = 0;
    for (var res = 0; res < 16; res++) {
      final result = h3.getNumCells(res);
      expect(
        result > last,
        true,
        reason: 'result > last result: $result, $last',
      );
      last = result;
    }

    expect(
      () => h3.getNumCells(42),
      throwsA(isA<AssertionError>()),
      reason: 'throws on invalid resolution',
    );
  });

  test('getRes0Cells', () async {
    final indexes = h3.getRes0Cells();
    expect(indexes.length, 122, reason: 'Got expected count');
    expect(indexes.every(h3.isValidCell), true,
        reason: 'All indexes are valid');
  });

  test('getPentagons', () async {
    for (var res = 0; res < 16; res++) {
      final indexes = h3.getPentagons(res);
      expect(
        indexes.length,
        12,
        reason: 'Got expected count',
      );
      expect(
        indexes.every(h3.isValidCell),
        true,
        reason: 'All indexes are valid',
      );
      expect(
        indexes.every(h3.isPentagon),
        true,
        reason: 'All indexes are pentagons',
      );
      expect(
        indexes.every((idx) => h3.getResolution(idx) == res),
        true,
        reason: 'All indexes have the right resolution',
      );
      expect(
        indexes.toSet().length,
        indexes.length,
        reason: 'All indexes are unique',
      );
    }

    expect(
      () => h3.getPentagons(42),
      throwsA(isA<AssertionError>()),
      reason: 'throws on invalid resolution',
    );
  });
}
