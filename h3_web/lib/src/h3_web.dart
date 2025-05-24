import 'package:h3_common/h3_common.dart';
import 'package:h3_web/src/generated/types.dart' as h3_js;
import 'package:h3_web/src/mappers/big_int.dart';
import 'package:h3_web/src/mappers/units.dart';
import 'package:h3_web/src/mappers/js_error.dart';

class H3Web implements H3 {
  const H3Web();

  @override
  bool isValidCell(BigInt h3Index) {
    return h3_js.isValidCell(h3Index.toH3JS());
  }

  @override
  bool isPentagon(BigInt h3Index) {
    return h3_js.isPentagon(h3Index.toH3JS());
  }

  @override
  bool isResClassIII(BigInt h3Index) {
    return h3_js.isResClassIII(h3Index.toH3JS());
  }

  @override
  int getBaseCellNumber(BigInt h3Index) {
    return h3_js.getBaseCellNumber(h3Index.toH3JS()).toInt();
  }

  @override
  List<int> getIcosahedronFaces(BigInt h3Index) {
    return h3_js.getIcosahedronFaces(h3Index.toH3JS()).cast<int>();
  }

  @override
  int getResolution(BigInt h3Index) {
    if (!isValidCell(h3Index)) {
      throw H3Exception('H3Index is not valid.');
    }
    return h3_js.getResolution(h3Index.toH3JS()).toInt();
  }

  @override
  BigInt latLngToCell(LatLng latLng, int res) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return h3_js.latLngToCell(latLng.lat, latLng.lng, res).toBigInt();
  }

  @override
  LatLng cellToLatLng(BigInt h3Index) {
    final res = h3_js.cellToLatLng(h3Index.toH3JS());
    return LatLng(lat: res[0].toDouble(), lng: res[1].toDouble());
  }

  @override
  List<LatLng> cellToBoundary(BigInt h3Index) {
    return h3_js
        .cellToBoundary(h3Index.toH3JS())
        .cast<dynamic>()
        .map((e) => List<num>.from(e))
        .map((e) => LatLng(lat: e[0].toDouble(), lng: e[1].toDouble()))
        .toList();
  }

  @override
  BigInt cellToParent(BigInt h3Index, int resolution) {
    if (getResolution(h3Index) < resolution || resolution < 0) {
      return BigInt.zero;
    }
    // ignore: unnecessary_cast
    final res = h3_js.cellToParent(h3Index.toH3JS(), resolution) as String?;
    if (res == null) {
      return BigInt.zero;
    }
    return res.toBigInt();
  }

  @override
  List<BigInt> cellToChildren(BigInt h3Index, int resolution) {
    if (!isValidCell(h3Index)) {
      return [];
    }
    if (getResolution(h3Index) > resolution) {
      return [];
    }
    return h3_js
        .cellToChildren(h3Index.toH3JS(), resolution)
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  BigInt cellToCenterChild(BigInt h3Index, int resolution) {
    if (resolution < getResolution(h3Index) || resolution < 0) {
      return BigInt.zero;
    }
    // ignore: unnecessary_cast
    final res = h3_js.cellToCenterChild(
      h3Index.toH3JS(),
      resolution,
    ) as String?;
    if (res == null) {
      return BigInt.zero;
    }
    return res.toBigInt();
  }

  @override
  List<BigInt> gridDisk(BigInt h3Index, int ringSize) {
    if (ringSize < 0) {
      return [h3Index];
    }
    return h3_js
        .gridDisk(h3Index.toH3JS(), ringSize)
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  List<BigInt> gridRingUnsafe(BigInt h3Index, int ringSize) {
    try {
      return h3_js
          .gridRingUnsafe(h3Index.toH3JS(), ringSize)
          .cast<String>()
          .map((e) => e.toBigInt())
          .toList();
    } catch (e) {
      final message = getJsErrorMessage(e);
      throw H3Exception("JS Error: $message");
    }
  }

  @override
  List<BigInt> polygonToCells({
    required List<LatLng> coordinates,
    required int resolution,
    List<List<LatLng>> holes = const [],
  }) {
    assert(resolution >= 0 && resolution < 16,
        'Resolution must be in [0, 15] range');
    return h3_js
        .polygonToCells(
          [
            coordinates.map((e) => [e.lat, e.lng]).toList(),
            ...holes
                .map((arr) => arr.map((e) => [e.lat, e.lng]).toList())
                .toList(),
          ],
          resolution,
        )
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  List<BigInt> compactCells(List<BigInt> hexagons) {
    return h3_js
        .compactCells(hexagons.map((e) => e.toRadixString(16)).toList())
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  List<BigInt> uncompactCells(
    List<BigInt> compactedHexagons, {
    required int resolution,
  }) {
    try {
      assert(resolution >= 0 && resolution < 16,
          'Resolution must be in [0, 15] range');

      return h3_js
          .uncompactCells(
            compactedHexagons.map((e) => e.toRadixString(16)).toList(),
            resolution,
          )
          .cast<String>()
          .map((e) => e.toBigInt())
          .toList();
    } catch (e) {
      final message = getJsErrorMessage(e);
      throw H3Exception("JS Error: $message");
    }
  }

  @override
  bool areNeighborCells(BigInt origin, BigInt destination) {
    if (!isValidCell(origin) || !isValidCell(destination)) {
      return false;
    }
    return h3_js.areNeighborCells(
      origin.toRadixString(16),
      destination.toRadixString(16),
    );
  }

  @override
  BigInt cellsToDirectedEdge(BigInt origin, BigInt destination) {
    try {
      // ignore: unnecessary_cast
      final res = h3_js.cellsToDirectedEdge(
        origin.toRadixString(16),
        destination.toRadixString(16),
      ) as String?;
      if (res == null) {
        return BigInt.zero;
      }
      return res.toBigInt();
    } catch (e) {
      return BigInt.zero;
    }
  }

  @override
  BigInt getDirectedEdgeOrigin(BigInt edgeIndex) {
    // ignore: unnecessary_cast
    final res =
        h3_js.getDirectedEdgeOrigin(edgeIndex.toRadixString(16)) as String?;
    if (res == null) {
      return BigInt.zero;
    }
    return res.toBigInt();
  }

  @override
  BigInt getDirectedEdgeDestination(BigInt edgeIndex) {
    // ignore: unnecessary_cast
    final res = h3_js.getDirectedEdgeDestination(edgeIndex.toRadixString(16))
        as String?;
    if (res == null) {
      return BigInt.zero;
    }
    return res.toBigInt();
  }

  @override
  bool isValidDirectedEdge(BigInt edgeIndex) {
    return h3_js.isValidDirectedEdge(edgeIndex.toRadixString(16));
  }

  @override
  List<BigInt> directedEdgeToCells(BigInt edgeIndex) {
    return h3_js
        .directedEdgeToCells(edgeIndex.toRadixString(16))
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  List<BigInt> originToDirectedEdges(BigInt edgeIndex) {
    return h3_js
        .originToDirectedEdges(edgeIndex.toRadixString(16))
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  List<LatLng> directedEdgeToBoundary(BigInt edgeIndex) {
    return h3_js
        .directedEdgeToBoundary(edgeIndex.toRadixString(16))
        .cast<dynamic>()
        .map((e) => List<num>.from(e))
        .map((e) => LatLng(lat: e[0].toDouble(), lng: e[1].toDouble()))
        .toList();
  }

  @override
  int gridDistance(BigInt origin, BigInt destination) {
    return h3_js
        .gridDistance(origin.toRadixString(16), destination.toRadixString(16))
        .toInt();
  }

  @override
  List<BigInt> gridPathCells(BigInt origin, BigInt destination) {
    try {
      return h3_js
          .gridPathCells(
              origin.toRadixString(16), destination.toRadixString(16))
          .cast<String>()
          .map((e) => e.toBigInt())
          .toList();
    } catch (e) {
      final message = getJsErrorMessage(e);
      if (message == 'Line cannot be calculated') {
        throw H3Exception('Line cannot be calculated');
      }
      throw H3Exception("JS Error: $message");
    }
  }

  @override
  CoordIJ cellToLocalIj(BigInt origin, BigInt destination) {
    try {
      final res = h3_js.cellToLocalIj(
          origin.toRadixString(16), destination.toRadixString(16));
      return CoordIJ(
        i: res.i.toInt(),
        j: res.j.toInt(),
      );
    } catch (e) {
      final message = getJsErrorMessage(e);
      if (message == 'Incompatible origin and index.') {
        throw H3Exception('Incompatible origin and index.');
      }
      if (message ==
          'Local IJ coordinates undefined for this origin and index pair. '
              'The index may be too far from the origin.') {
        throw H3Exception(
            'Local IJ coordinates undefined for this origin and index pair. '
            'The index may be too far from the origin.');
      }
      if (message == 'Encountered possible pentagon distortion') {
        throw H3Exception('Encountered possible pentagon distortion');
      }
      throw H3Exception("JS Error: $message");
    }
  }

  @override
  BigInt localIjToCell(BigInt origin, CoordIJ coordinates) {
    try {
      return h3_js
          .localIjToCell(
            origin.toRadixString(16),
            h3_js.CoordIJ(
              i: coordinates.i,
              j: coordinates.j,
            ),
          )
          .toBigInt();
    } catch (e) {
      final message = getJsErrorMessage(e);
      if (message ==
          'Index not defined for this origin and IJ coordinates pair. '
              'IJ coordinates may be too far from origin, or '
              'a pentagon distortion was encountered.') {
        throw H3Exception(
          'Index not defined for this origin and IJ coordinates pair. '
          'IJ coordinates may be too far from origin, or '
          'a pentagon distortion was encountered.',
        );
      }
      rethrow;
    }
  }

  @override
  double greatCircleDistance(LatLng a, LatLng b, H3Units unit) {
    return h3_js.greatCircleDistance(
      [a.lat, a.lng],
      [b.lat, b.lng],
      unit.toH3JS(),
    ).toDouble();
  }

  @override
  double cellArea(BigInt h3Index, H3Units unit) {
    return h3_js
        .cellArea(
          h3Index.toH3JS(),
          unit.toH3JSSquare(),
        )
        .toDouble();
  }

  @override
  double edgeLength(BigInt edgeIndex, H3Units unit) {
    return h3_js
        .edgeLength(
          edgeIndex.toRadixString(16),
          unit.toH3JS(),
        )
        .toDouble();
  }

  @override
  double getHexagonAreaAvg(int res, H3AreaUnits unit) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return h3_js
        .getHexagonAreaAvg(
          res,
          unit.toH3JS(),
        )
        .toDouble();
  }

  @override
  double getHexagonEdgeLengthAvg(int res, H3EdgeLengthUnits unit) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return h3_js
        .getHexagonEdgeLengthAvg(
          res,
          unit.toH3JS(),
        )
        .toDouble();
  }

  @override
  int getNumCells(int res) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return h3_js.getNumCells(res).toInt();
  }

  @override
  List<BigInt> getRes0Cells() {
    return h3_js
        .getRes0Cells()
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  List<BigInt> getPentagons(int res) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return h3_js
        .getPentagons(res)
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  double radsToDegs(double val) => h3_js.radsToDegs(val).toDouble();

  @override
  double degsToRads(double val) => h3_js.degsToRads(val).toDouble();

  @override
  bool isValidVertex(BigInt h3Index) {
    return h3_js.isValidVertex(h3Index);
  }

  @override
  LatLng vertexToLatLng(BigInt vertex) {
    return LatLng(
        lat: h3_js.vertexToLatLng(vertex).cast<num>()[0].toDouble(),
        lng: h3_js.vertexToLatLng(vertex).cast<num>()[1].toDouble());
  }

  @override
  BigInt cellToVertex(BigInt origin, int vertexNum) {
    final out =
        h3_js.cellToVertex(origin.toRadixString(16), vertexNum) as String?;
    if (out == null) {
      return BigInt.zero;
    } else {
      return out.toBigInt();
    }
  }

  @override
  List<BigInt> cellToVertexes(BigInt origin) {
    return h3_js
        .cellToVertexes(origin.toRadixString(16))
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  int cellToChildPos(BigInt child, int parentRes) {
    return h3_js.cellToChildPos(child.toRadixString(16), parentRes).toInt();
  }

  @override
  BigInt childPosToCell(int childPos, BigInt parent, int childRes) {
    return h3_js
        .childPosToCell(childPos, parent.toRadixString(16), childRes)
        .toBigInt();
  }

  @override
  String describeH3Error(int err) {
    const Map<int, String> h3ErrorMessages = {
      0: "Success",
      1: "The operation failed but a more specific error is not available",
      2: "Argument was outside of acceptable range ",
      3: "Latitude or longitude arguments were outside of acceptable range",
      4: "Resolution argument was outside of acceptable range",
      5: "H3Index cell argument was not valid",
      6: "H3Index directed edge argument was not valid",
      7: "H3Index undirected edge argument was not valid",
      8: "H3Index vertex argument was not valid",
      9: "Pentagon distortion was encountered which the algorithm could not handle it",
      10: "Duplicate input was encountered in the arguments and the algorithm could not handle it",
      11: "H3Index cell arguments were not neighbors",
      12: "H3Index cell arguments had incompatible resolutions",
      13: "Necessary memory allocation failed",
      14: "Bounds of provided memory were not large enough",
      15: "Mode or flags argument was not valid"
    };

    return h3ErrorMessages[err] ?? "Unknown error code: $err";
  }

  @override
  List<BigInt> polygonToCellsExperimental({
    required List<LatLng> coordinates,
    required int resolution,
    List<List<LatLng>> holes = const [],
    required int flags,
  }) {
    final flagMap = {
      0: h3_js.containmentCenter,
      1: h3_js.containmentFull,
      2: h3_js.containmentOverlapping,
      3: h3_js.containmentOverlappingBbox,
    };
    final flag = flagMap[flags] ?? h3_js.containmentOverlappingBbox;
    assert(resolution >= 0 && resolution < 16,
        'Resolution must be in [0, 15] range');
    return h3_js
        .polygonToCellsExperimental([
          coordinates.map((e) => [e.lat, e.lng]).toList(),
          ...holes
              .map((arr) => arr.map((e) => [e.lat, e.lng]).toList())
              .toList(),
        ], resolution, flag)
        .cast<String>()
        .map((e) => e.toBigInt())
        .toList();
  }

  @override
  List<Polygon> cellsToMultiPolygon(List<BigInt> h3Set) {
    final out = h3_js.cellsToMultiPolygon(
      h3Set.map((e) => e.toRadixString(16)).toList(), 
      true
    );
    
    final result = <Polygon>[];
    
    for (final polygon in out) {
      final outer = <LatLng>[];
      final holes = <List<LatLng>>[];
      
      for (int i = 0; i < polygon.length; i++) {
        final ring = polygon[i] as List;
        final points = <LatLng>[];
        
        for (final coordinate in ring) {
          final coord = coordinate as List;
          // H3.js returns [lat, lng] format when formatAsGeoJSON is true
          points.add(LatLng(
            lat: (coord[0] as num).toDouble(),
            lng: (coord[1] as num).toDouble(),
          ));
        }
        
        if (i == 0) {
          // First ring is the outer boundary
          outer.addAll(points);
        } else {
          // Subsequent rings are holes
          holes.add(points);
        }
      }
      
      result.add(Polygon(outer: outer, holes: holes));
    }
    
    return result;
  }
}
