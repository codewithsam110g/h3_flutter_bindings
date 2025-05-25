import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:h3_common_plus/h3_common_plus.dart';
import 'package:h3_ffi_plus/src/mappers/big_int.dart';

import 'generated/generated_bindings.dart' as c;
import 'mappers/native.dart';

/// Provides access to H3 functions through FFI.
///
/// You should not construct the class directly, use [H3Factory] instead.
class H3Ffi implements H3 {
  H3Ffi(this._h3c);

  final c.H3C _h3c;

  late final LatLngConverter _latLngConverter =
      LatLngConverter(H3AngleConverter(this));

  /// Determines if [h3Index] is a valid cell (hexagon or pentagon)
  @override
  bool isValidCell(BigInt h3Index) {
    return _h3c.isValidCell(h3Index.toInt()) == 1;
  }

  /// Determines if [h3Index] is a valid pentagon
  @override
  bool isPentagon(BigInt h3Index) {
    return _h3c.isPentagon(h3Index.toInt()) == 1;
  }

  /// Determines if [h3Index] is Class III (rotated versus
  /// the icosahedron and subject to shape distortion adding extra points on
  /// icosahedron edges, making them not true hexagons).
  @override
  bool isResClassIII(BigInt h3Index) {
    return _h3c.isResClassIII(h3Index.toInt()) == 1;
  }

  /// Returns the base cell "number" (0 to 121) of the provided H3 cell
  ///
  /// Note: Technically works on H3 edges, but will return base cell of the
  /// origin cell.
  @override
  int getBaseCellNumber(BigInt h3Index) {
    return _h3c.getBaseCellNumber(h3Index.toInt());
  }

  /// Find all icosahedron faces intersected by a given H3 index
  @override
  List<int> getIcosahedronFaces(BigInt h3Index) {
    final h3IndexInt = h3Index.toInt();

    return using((Arena arena) {
      final countOutputPtr = arena<Int32>();
      final h3ErrorMaxCount =
          _h3c.maxFaceCount(h3IndexInt, countOutputPtr.cast<Int>());
      if (h3ErrorMaxCount != c.H3ErrorCodes.E_SUCCESS) {
        throw Exception(
            'H3 maxFaceCount failed with error code: $h3ErrorMaxCount for H3Index: $h3Index');
      }
      final count = countOutputPtr.value;
      if (count <= 0) {
        return <int>[];
      }
      final facesArrayPtr = arena<Int32>(count);
      final h3ErrorGetFaces =
          _h3c.getIcosahedronFaces(h3IndexInt, facesArrayPtr.cast<Int>());
      if (h3ErrorGetFaces != c.H3ErrorCodes.E_SUCCESS) {
        throw Exception(
            'H3 getIcosahedronFaces failed with error code: $h3ErrorGetFaces for H3Index: $h3Index');
      }
      final facesList = facesArrayPtr.asTypedList(count);
      return facesList.where((face) => face != -1).toList();
    });
  }

  /// Returns the resolution of the provided H3 index
  ///
  /// Works on both cells and unidirectional edges.
  @override
  int getResolution(BigInt h3Index) {
    if (!isValidCell(h3Index)) {
      throw H3Exception('H3Index is not valid.');
    }
    return _h3c.getResolution(h3Index.toInt());
  }

  /// Find the H3 index of the resolution res cell containing the lat/lng
  @override
  BigInt latLngToCell(LatLng latLng, int res) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return using((arena) {
      final out = arena<Uint64>();
      _h3c.latLngToCell(
          latLng.toRadians(_latLngConverter).toNative(arena), res, out);
      return out.value.toBigInt();
    });
  }

  /// Find the lat/lon center point g of the cell h3
  @override
  LatLng cellToLatLng(BigInt h3Index) {
    return using((arena) {
      final latLngNative = arena<c.LatLng>();

      _h3c.cellToLatLng(h3Index.toInt(), latLngNative);
      return latLngNative.ref.toPure().toDegrees(_latLngConverter);
    });
  }

  /// Gives the cell boundary in lat/lon coordinates for the cell with index [h3Index]
  ///
  /// ```dart
  /// h3.h3ToGeoBoundary(0x85283473fffffff)
  /// h3.h3ToGeoBoundary(133)
  /// ```
  @override
  List<LatLng> cellToBoundary(BigInt h3Index) {
    return using((arena) {
      final geoBoundary = arena<c.CellBoundary>();
      _h3c.cellToBoundary(h3Index.toInt(), geoBoundary);
      final res = <LatLng>[];
      for (var i = 0; i < geoBoundary.ref.numVerts; i++) {
        final vert = geoBoundary.ref.verts[i];
        res.add(LatLng(lng: radsToDegs(vert.lng), lat: radsToDegs(vert.lat)));
      }
      return res;
    });
  }

  /// Get the parent of the given [h3Index] hexagon at a particular [resolution]
  ///
  /// Returns 0 when result can't be calculated
  @override
  BigInt cellToParent(BigInt h3Index, int resolution) {
    return using((arena) {
      final parent = arena<Uint64>();
      _h3c.cellToParent(h3Index.toInt(), resolution, parent);
      return parent.value.toBigInt();
    });
  }

  /// Get the children/descendents of the given [h3Index] hexagon at a particular [resolution]
  @override
  List<BigInt> cellToChildren(BigInt h3Index, int resolution) {
    // Bad input in this case can potentially result in high computation volume
    // using the current C algorithm. Validate and return an empty array on failure.
    if (!isValidCell(h3Index)) {
      return [];
    }
    final h3IndexInt = h3Index.toInt();
    return using((arena) {
      final maxSize = arena<Int64>();
      _h3c.cellToChildrenSize(h3IndexInt, resolution, maxSize);
      final out = arena<Uint64>(maxSize.value);
      _h3c.cellToChildren(h3IndexInt, resolution, out);
      final list = out.asTypedList(maxSize.value).toList();
      return list.where((e) => e != 0).map((e) => e.toBigInt()).toList();
    });
  }

  /// Get the center child of the given [h3Index] hexagon at a particular [resolution]
  ///
  /// Returns 0 when result can't be calculated
  @override
  BigInt cellToCenterChild(BigInt h3Index, int resolution) {
    return using((arena) {
      final child = arena<Uint64>();
      _h3c.cellToCenterChild(h3Index.toInt(), resolution, child);
      return child.value.toBigInt();
    });
  }

  /// Maximum number of hexagons in k-ring
  @override
  List<BigInt> gridDisk(BigInt h3Index, int ringSize) {
    if (ringSize < 0) {
      return [h3Index];
    }
    return using((arena) {
      final kIndex = arena<Int64>();
      _h3c.maxGridDiskSize(ringSize, kIndex);
      final out = arena<Uint64>(kIndex.value);
      _h3c.gridDisk(h3Index.toInt(), ringSize, out);
      final list = out.asTypedList(kIndex.value).toList();
      return list.where((e) => e != 0).map((e) => e.toBigInt()).toList();
    });
  }

  /// Hollow hexagon ring at some origin
  @override
  List<BigInt> gridRingUnsafe(BigInt h3Index, int ringSize) {
    return using((arena) {
      final kIndex = ringSize == 0 ? 1 : 6 * ringSize;
      final out = arena<Uint64>(kIndex);
      final resultCode = _h3c.gridRingUnsafe(h3Index.toInt(), ringSize, out);
      if (resultCode != 0) {
        throw H3Exception(
            'Failed to get gridRingUnsafe (encountered a pentagon?)');
      }
      final list = out.asTypedList(kIndex).toList();
      return list.where((e) => e != 0).map((e) => e.toBigInt()).toList();
    });
  }

  /// Takes a given [coordinates] and [resolution] and returns hexagons that
  /// are contained by them.
  ///
  /// [resolution] must be in the range [0, 15].
  ///
  /// This implementation traces the GeoJSON geofence(s) in cartesian space with
  /// hexagons, tests them and their neighbors to be contained by the geofence(s),
  /// and then any newly found hexagons are used to test again until no new
  /// hexagons are found.
  ///
  /// ```dart
  /// final hexagons = h3.polyfill(
  ///   coordinates: const [
  ///     GeoCoord(lat: 37.813318999983238, lon: -122.4089866999972145),
  ///     GeoCoord(lat: 37.7866302000007224, lon: -122.3805436999997056),
  ///     GeoCoord(lat: 37.7198061999978478, lon: -122.3544736999993603),
  ///     GeoCoord(lat: 37.7076131999975672, lon: -122.5123436999983966),
  ///     GeoCoord(lat: 37.7835871999971715, lon: -122.5247187000021967),
  ///     GeoCoord(lat: 37.8151571999998453, lon: -122.4798767000009008),
  ///   ],
  ///   resolution: 9,
  /// )
  /// ```
  @override
  List<BigInt> polygonToCells({
    required List<LatLng> coordinates,
    required int resolution,
    List<List<LatLng>> holes = const [],
  }) {
    assert(resolution >= 0 && resolution < 16,
        'Resolution must be in [0, 15] range');
    return using((arena) {
      // polygon outer boundary
      final nativeCoordinatesPointer = arena<c.LatLng>(coordinates.length);
      for (var i = 0; i < coordinates.length; i++) {
        final pointer = Pointer<c.LatLng>.fromAddress(
          nativeCoordinatesPointer.address + sizeOf<c.LatLng>() * i,
        );
        coordinates[i].toRadians(_latLngConverter).assignToNative(pointer.ref);
      }

      final polygon = arena<c.GeoPolygon>();
      final outergeoloop = arena<c.GeoLoop>();

      // outer boundary
      polygon.ref.geoloop = outergeoloop.ref;
      polygon.ref.geoloop.verts = nativeCoordinatesPointer;
      polygon.ref.geoloop.numVerts = coordinates.length;

      // polygon holes
      if (holes.isNotEmpty) {
        final holesgeoloopPointer = arena<c.GeoLoop>(holes.length);
        for (var h = 0; h < holes.length; h++) {
          final holeCoords = holes[h];

          final singleHoleGLoopPointer = Pointer<c.GeoLoop>.fromAddress(
            holesgeoloopPointer.address + sizeOf<c.GeoLoop>() * h,
          );

          final holeNativeCoordinatesPointer =
              arena<c.LatLng>(holeCoords.length);

          // assign the hole coord to holeptr
          for (var i = 0; i < holeCoords.length; i++) {
            final coordPointer = Pointer<c.LatLng>.fromAddress(
                holeNativeCoordinatesPointer.address + sizeOf<c.LatLng>() * i);
            holeCoords[i]
                .toRadians(_latLngConverter)
                .assignToNative(coordPointer.ref);
          }

          singleHoleGLoopPointer.ref.numVerts = holeCoords.length;
          singleHoleGLoopPointer.ref.verts = holeNativeCoordinatesPointer;
        }

        polygon.ref.numHoles = holes.length;
        polygon.ref.holes = holesgeoloopPointer;
      } else {
        polygon.ref.numHoles = 0;
        polygon.ref.holes = Pointer.fromAddress(0);
      }

      final nbIndex = arena<Int64>();
      _h3c.maxPolygonToCellsSize(polygon, resolution, 0, nbIndex);
      // Todo Expose The Containment Struct or Atleast the param
      final out = arena<Uint64>(nbIndex.value);
      _h3c.polygonToCells(polygon, resolution, 0, out);
      final list = out.asTypedList(nbIndex.value).toList();
      return list.where((e) => e != 0).map((e) => e.toBigInt()).toList();
    });
  }

  /// Compact a set of hexagons of the same resolution into a set of hexagons
  /// across multiple levels that represents the same area.
  @override
  List<BigInt> compactCells(List<BigInt> hexagons) {
    return using((arena) {
      hexagons = hexagons.toSet().toList(); // remove duplicates
      final hexagonsPointer = arena<Uint64>(hexagons.length);
      for (var i = 0; i < hexagons.length; i++) {
        final pointer = Pointer<Uint64>.fromAddress(
          hexagonsPointer.address + sizeOf<Uint64>() * i,
        );
        pointer.value = hexagons[i].toInt();
      }

      final out = arena<Uint64>(hexagons.length);
      final resultCode =
          _h3c.compactCells(hexagonsPointer, out, hexagons.length);
      if (resultCode != 0) {
        throw H3Exception(
          'Failed to compact, malformed input data',
        );
      }
      final list = out.asTypedList(hexagons.length).toList();
      return list.where((e) => e != 0).map((e) => e.toBigInt()).toList();
    });
  }

  /// Uncompact a compacted set of hexagons to hexagons of the same resolution
  @override
  List<BigInt> uncompactCells(
    List<BigInt> compactedHexagons, {
    required int resolution,
  }) {
    assert(resolution >= 0 && resolution < 16,
        'Resolution must be in [0, 15] range');

    return using((arena) {
      final compactedHexagonsPointer = arena<Uint64>(compactedHexagons.length);
      for (var i = 0; i < compactedHexagons.length; i++) {
        final pointer = Pointer<Uint64>.fromAddress(
          compactedHexagonsPointer.address + sizeOf<Uint64>() * i,
        );
        pointer.value = compactedHexagons[i].toInt();
      }

      final maxUncompactSize = arena<Int64>();

      _h3c.uncompactCellsSize(compactedHexagonsPointer,
          compactedHexagons.length, resolution, maxUncompactSize);

      if (maxUncompactSize.value < 0) {
        throw H3Exception('Failed to uncompact');
      }

      final out = arena<Uint64>(maxUncompactSize.value);
      final resultCode = _h3c.uncompactCells(
        compactedHexagonsPointer,
        compactedHexagons.length,
        out,
        maxUncompactSize.value,
        resolution,
      );
      if (resultCode != 0) {
        throw H3Exception('Failed to uncompact');
      }

      final list = out.asTypedList(maxUncompactSize.value).toList();
      return list.where((e) => e != 0).map((e) => e.toBigInt()).toList();
    });
  }

  /// Returns whether or not two H3 indexes are neighbors (share an edge)
  @override
  bool areNeighborCells(BigInt origin, BigInt destination) {
    return using((arena) {
      final out = arena<Int>();
      _h3c.areNeighborCells(origin.toInt(), destination.toInt(), out);
      return out.value == 1;
    });
  }

  /// Get an H3 index representing a unidirectional edge for a given origin and
  /// destination
  ///
  /// Returns 0 when result can't be calculated
  @override
  BigInt cellsToDirectedEdge(BigInt origin, BigInt destination) {
    return using((arena) {
      final out = arena<Uint64>();
      _h3c.cellsToDirectedEdge(origin.toInt(), destination.toInt(), out);
      return out.value.toBigInt();
    });
  }

  /// Get the origin hexagon from an H3 index representing a unidirectional edge
  ///
  /// Returns 0 when result can't be calculated
  @override
  BigInt getDirectedEdgeOrigin(BigInt edgeIndex) {
    return using((arena) {
      final out = arena<Uint64>();
      _h3c.getDirectedEdgeOrigin(edgeIndex.toInt(), out);
      return out.value.toBigInt();
    });
  }

  /// Get the destination hexagon from an H3 index representing a unidirectional edge
  ///
  /// Returns 0 when result can't be calculated
  @override
  BigInt getDirectedEdgeDestination(BigInt edgeIndex) {
    return using((arena) {
      final out = arena<Uint64>();
      _h3c.getDirectedEdgeDestination(edgeIndex.toInt(), out);
      return out.value.toBigInt();
    });
  }

  /// Returns whether or not the input is a valid unidirectional edge
  @override
  bool isValidDirectedEdge(BigInt edgeIndex) {
    return _h3c.isValidDirectedEdge(edgeIndex.toInt()) == 1;
  }

  /// Get the [origin, destination] pair represented by a unidirectional edge
  @override
  List<BigInt> directedEdgeToCells(BigInt edgeIndex) {
    return using((arena) {
      final out = arena<Uint64>(2);
      _h3c.directedEdgeToCells(edgeIndex.toInt(), out);
      return out.asTypedList(2).map((e) => e.toBigInt()).toList();
    });
  }

  /// Get all of the unidirectional edges with the given H3 index as the origin
  /// (i.e. an edge to every neighbor)
  @override
  List<BigInt> originToDirectedEdges(BigInt edgeIndex) {
    return using((arena) {
      final out = arena<Uint64>(6);
      _h3c.originToDirectedEdges(edgeIndex.toInt(), out);
      return out
          .asTypedList(6)
          .toList()
          .where((i) => i != 0)
          .map((e) => e.toBigInt())
          .toList();
    });
  }

  /// Get the vertices of a given edge as an array of [lat, lng] points. Note
  /// that for edges that cross the edge of an icosahedron face, this may return
  /// 3 coordinates.
  @override
  List<LatLng> directedEdgeToBoundary(BigInt edgeIndex) {
    return using((arena) {
      final out = arena<c.CellBoundary>();
      _h3c.directedEdgeToBoundary(edgeIndex.toInt(), out);
      final coordinates = <LatLng>[];
      for (var i = 0; i < out.ref.numVerts; i++) {
        coordinates.add(out.ref.verts[i].toPure().toDegrees(_latLngConverter));
      }
      return coordinates;
    });
  }

  /// Get the grid distance between two hex indexes. This function may fail
  /// to find the distance between two indexes if they are very far apart or
  /// on opposite sides of a pentagon.
  ///
  /// Returns -1 when result can't be calculated
  @override
  int gridDistance(BigInt origin, BigInt destination) {
    if (isValidDirectedEdge(origin) || isValidDirectedEdge(destination)) {
      return -1;
    }

    // Then check if both are valid cells
    if (!isValidCell(origin) || !isValidCell(destination)) {
      return -1;
    }

    // Finally check if resolutions match
    if (getResolution(origin) != getResolution(destination)) {
      return -1;
    }
    
    return using((arena) {
      final distance = arena<Int64>();
      _h3c.gridDistance(origin.toInt(), destination.toInt(), distance);
      return distance.value;
    });
  }

  /// Given two H3 indexes, return the line of indexes between them (inclusive).
  ///
  /// This function may fail to find the line between two indexes, for
  /// example if they are very far apart. It may also fail when finding
  /// distances for indexes on opposite sides of a pentagon.
  ///
  /// Notes:
  ///
  ///  - The specific output of this function should not be considered stable
  ///    across library versions. The only guarantees the library provides are
  ///    that the line length will be `h3Distance(start, end) + 1` and that
  ///    every index in the line will be a neighbor of the preceding index.
  ///  - Lines are drawn in grid space, and may not correspond exactly to either
  ///    Cartesian lines or great arcs.
  @override
  List<BigInt> gridPathCells(BigInt origin, BigInt destination) {
    final originInt = origin.toInt();
    final destinationInt = destination.toInt();
    return using((arena) {
      final size = arena<Int64>();
      _h3c.gridPathCellsSize(originInt, destinationInt, size);
      if (size.value < 0) throw H3Exception('Line cannot be calculated');
      final out = arena<Uint64>(size.value);
      final resultCode = _h3c.gridPathCells(originInt, destinationInt, out);
      if (resultCode != 0) throw H3Exception('Line cannot be calculated');
      final list = out.asTypedList(size.value).toList();
      return list.where((e) => e != 0).map((e) => e.toBigInt()).toList();
    });
  }

  /// Produces IJ coordinates for an H3 index anchored by an origin.
  ///
  /// - The coordinate space used by this function may have deleted
  /// regions or warping due to pentagonal distortion.
  /// - Coordinates are only comparable if they come from the same
  /// origin index.
  /// - Failure may occur if the index is too far away from the origin
  /// or if the index is on the other side of a pentagon.
  /// - This function is experimental, and its output is not guaranteed
  /// to be compatible across different versions of H3.
  @override
  CoordIJ cellToLocalIj(BigInt origin, BigInt destination) {
    return using((arena) {
      final out = arena<c.CoordIJ>();
      final resultCode = _h3c.cellToLocalIj(
        origin.toInt(),
        destination.toInt(),
        0,
        out,
      );

      // Switch statement and error codes cribbed from h3-js's implementation.
      switch (resultCode) {
        case 0:
          return out.ref.toPure();
        case 1:
          throw H3Exception('Incompatible origin and index.');
        case 2:
          throw H3Exception(
              'Local IJ coordinates undefined for this origin and index pair. '
              'The index may be too far from the origin.');
        case 3:
        case 4:
        case 5:
          throw H3Exception('Encountered possible pentagon distortion');
        default:
          throw H3Exception(
              'Local IJ coordinates undefined for this origin and index pair. '
              'The index may be too far from the origin.');
      }
    });
  }

  /// Produces an H3 index for IJ coordinates anchored by an origin.
  ///
  /// - The coordinate space used by this function may have deleted
  /// regions or warping due to pentagonal distortion.
  /// - Coordinates are only comparable if they come from the same
  /// origin index.
  /// - Failure may occur if the index is too far away from the origin
  /// or if the index is on the other side of a pentagon.
  /// - This function is experimental, and its output is not guaranteed
  /// to be compatible across different versions of H3.
  @override
  BigInt localIjToCell(BigInt origin, CoordIJ coordinates) {
    return using((arena) {
      final out = arena<Uint64>();
      final resultCode = _h3c.localIjToCell(
        origin.toInt(),
        coordinates.toNative(arena),
        0,
        out,
      );
      if (resultCode != 0) {
        throw H3Exception(
          'Index not defined for this origin and IJ coordinates pair. '
          'IJ coordinates may be too far from origin, or '
          'a pentagon distortion was encountered.',
        );
      }
      return out.value.toBigInt();
    });
  }

  /// Calculates great circle distance between two geo points.
  @override
  double greatCircleDistance(LatLng a, LatLng b, H3Units unit) {
    return using((arena) {
      switch (unit) {
        case H3Units.m:
          return _h3c.greatCircleDistanceM(
            a.toRadians(_latLngConverter).toNative(arena),
            b.toRadians(_latLngConverter).toNative(arena),
          );
        case H3Units.km:
          return _h3c.greatCircleDistanceKm(
            a.toRadians(_latLngConverter).toNative(arena),
            b.toRadians(_latLngConverter).toNative(arena),
          );
        case H3Units.rad:
          return _h3c.greatCircleDistanceRads(
            a.toRadians(_latLngConverter).toNative(arena),
            b.toRadians(_latLngConverter).toNative(arena),
          );
      }
    });
  }

  /// Calculates exact area of a given cell in square [unit]s (e.g. m^2)
  @override
  double cellArea(BigInt h3Index, H3Units unit) {
    return using((arena) {
      final out = arena<Double>();
      switch (unit) {
        case H3Units.m:
          _h3c.cellAreaM2(h3Index.toInt(), out);
          break;
        case H3Units.km:
          _h3c.cellAreaKm2(h3Index.toInt(), out);
          break;
        case H3Units.rad:
          _h3c.cellAreaRads2(h3Index.toInt(), out);
          break;
      }
      return out.value;
    });
  }

  /// Calculates exact length of a given unidirectional edge in [unit]s
  @override
  double edgeLength(BigInt edgeIndex, H3Units unit) {
    return using((arena) {
      final out = arena<Double>();
      switch (unit) {
        case H3Units.m:
          _h3c.edgeLengthM(edgeIndex.toInt(), out);
          break;
        case H3Units.km:
          _h3c.edgeLengthKm(edgeIndex.toInt(), out);
          break;
        case H3Units.rad:
          _h3c.edgeLengthRads(edgeIndex.toInt(), out);
          break;
      }
      return out.value;
    });
  }

  /// Calculates average hexagon area at a given resolution in [unit]s
  @override
  double getHexagonAreaAvg(int res, H3AreaUnits unit) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return using((arena) {
      final out = arena<Double>();
      switch (unit) {
        case H3AreaUnits.m2:
          _h3c.getHexagonAreaAvgM2(res, out);
          break;
        case H3AreaUnits.km2:
          _h3c.getHexagonAreaAvgKm2(res, out);
          break;
      }
      return out.value;
    });
  }

  /// Calculates average hexagon edge length at a given resolution in [unit]s
  @override
  double getHexagonEdgeLengthAvg(int res, H3EdgeLengthUnits unit) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return using((arena) {
      final out = arena<Double>();
      switch (unit) {
        case H3EdgeLengthUnits.m:
          _h3c.getHexagonEdgeLengthAvgM(res, out);
          break;
        case H3EdgeLengthUnits.km:
          _h3c.getHexagonEdgeLengthAvgKm(res, out);
          break;
      }
      return out.value;
    });
  }

  /// Returns the total count of hexagons in the world at a given resolution.
  ///
  /// If the library compiled to JS - note that above
  /// resolution 8 the exact count cannot be represented in a JavaScript 32-bit number,
  /// so consumers should use caution when applying further operations to the output.
  @override
  int getNumCells(int res) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return using((arena) {
      final out = arena<Int64>();
      _h3c.getNumCells(res, out);
      return out.value;
    });
  }

  /// Returns all H3 indexes at resolution 0. As every index at every resolution > 0 is
  /// the descendant of a res 0 index, this can be used with h3ToChildren to iterate
  /// over H3 indexes at any resolution.
  @override
  List<BigInt> getRes0Cells() {
    return using((arena) {
      final size = _h3c.res0CellCount();
      final out = arena<Uint64>(size);
      _h3c.getRes0Cells(out);
      return out.asTypedList(size).map((e) => e.toBigInt()).toList();
    });
  }

  /// Get the twelve pentagon indexes at a given resolution.
  @override
  List<BigInt> getPentagons(int res) {
    assert(res >= 0 && res < 16, 'Resolution must be in [0, 15] range');
    return using((arena) {
      final size = _h3c.pentagonCount();
      final out = arena<Uint64>(size);
      _h3c.getPentagons(res, out);
      return out.asTypedList(size).map((e) => e.toBigInt()).toList();
    });
  }

  /// Converts radians to degrees
  @override
  double radsToDegs(double val) => _h3c.radsToDegs(val);

  /// Converts degrees to radians
  @override
  double degsToRads(double val) => _h3c.degsToRads(val);

  // New Funcs

  /// Determines if the given H3 index represents a valid H3 vertex.
  @override
  bool isValidVertex(BigInt h3Index) {
    return _h3c.isValidVertex(h3Index.toInt()) == 1;
  }

  /// Returns the latitude and longitude coordinates of the given vertex.
  @override
  LatLng vertexToLatLng(BigInt vertex) {
    return using((arena) {
      final latLngNative = arena<c.LatLng>();

      _h3c.vertexToLatLng(vertex.toInt(), latLngNative);
      return latLngNative.ref.toPure().toDegrees(_latLngConverter);
    });
  }

  /// Returns the index for the specified cell vertex.
  /// Valid vertex numbers are between 0 and 5 (inclusive) for hexagonal cells, and 0 and 4 (inclusive) for pentagonal cells.
  @override
  BigInt cellToVertex(BigInt origin, int vertexNum) {
    return using((arena) {
      final out = arena<Uint64>();
      _h3c.cellToVertex(origin.toInt(), vertexNum, out);
      return out.value.toBigInt();
    });
  }

  /// Returns the indexes for all vertexes of the given cell.
  /// Length will always be 6. if the given cell is pentagon,
  /// one member of the array will be set to 0.
  @override
  List<BigInt> cellToVertexes(BigInt origin) {
    return using((arena) {
      final out = arena<Uint64>(6);
      _h3c.cellToVertexes(origin.toInt(), out);
      return out.asTypedList(6).map((x) => x.toBigInt()).toList();
    });
  }

  /// Provides the position of the child cell within an ordered list of
  /// all children of the cell's parent at the specified resolution parentRes.
  /// The order of the ordered list is the same as that returned by cellToChildren.
  @override
  int cellToChildPos(BigInt child, int parentRes) {
    return using((arena) {
      final pos = arena<Int64>();
      _h3c.cellToChildPos(child.toInt(), parentRes, pos);
      return pos.value;
    });
  }

  /// Provides the child cell at a given position within an ordered list of
  /// all children of parent at the specified resolution childRes.
  /// The order of the ordered list is the same as that returned by cellToChildren.
  @override
  BigInt childPosToCell(int childPos, BigInt parent, int childRes) {
    return using((arena) {
      final child = arena<Uint64>();
      _h3c.childPosToCell(childPos, parent.toInt(), childRes, child);
      return child.value.toBigInt();
    });
  }

  /// Provides a human-readable description of an H3Error error code.
  @override
  String describeH3Error(int err) {
    final Pointer<Utf8> cStr = _h3c.describeH3Error(err).cast<Utf8>();
    return cStr.toDartString();
  }

  @override
  List<BigInt> polygonToCellsExperimental({
    required List<LatLng> coordinates,
    required int resolution,
    List<List<LatLng>> holes = const [],
    required int flags,
  }) {
    assert(resolution >= 0 && resolution < 16,
        'Resolution must be in [0, 15] range');
    return using((arena) {
      // polygon outer boundary
      final nativeCoordinatesPointer = arena<c.LatLng>(coordinates.length);
      for (var i = 0; i < coordinates.length; i++) {
        final pointer = Pointer<c.LatLng>.fromAddress(
          nativeCoordinatesPointer.address + sizeOf<c.LatLng>() * i,
        );
        coordinates[i].toRadians(_latLngConverter).assignToNative(pointer.ref);
      }

      final polygon = arena<c.GeoPolygon>();
      final outergeoloop = arena<c.GeoLoop>();

      // outer boundary
      polygon.ref.geoloop = outergeoloop.ref;
      polygon.ref.geoloop.verts = nativeCoordinatesPointer;
      polygon.ref.geoloop.numVerts = coordinates.length;

      // polygon holes
      if (holes.isNotEmpty) {
        final holesgeoloopPointer = arena<c.GeoLoop>(holes.length);
        for (var h = 0; h < holes.length; h++) {
          final holeCoords = holes[h];

          final singleHoleGLoopPointer = Pointer<c.GeoLoop>.fromAddress(
            holesgeoloopPointer.address + sizeOf<c.GeoLoop>() * h,
          );

          final holeNativeCoordinatesPointer =
              arena<c.LatLng>(holeCoords.length);

          // assign the hole coord to holeptr
          for (var i = 0; i < holeCoords.length; i++) {
            final coordPointer = Pointer<c.LatLng>.fromAddress(
                holeNativeCoordinatesPointer.address + sizeOf<c.LatLng>() * i);
            holeCoords[i]
                .toRadians(_latLngConverter)
                .assignToNative(coordPointer.ref);
          }

          singleHoleGLoopPointer.ref.numVerts = holeCoords.length;
          singleHoleGLoopPointer.ref.verts = holeNativeCoordinatesPointer;
        }

        polygon.ref.numHoles = holes.length;
        polygon.ref.holes = holesgeoloopPointer;
      } else {
        polygon.ref.numHoles = 0;
        polygon.ref.holes = Pointer.fromAddress(0);
      }
      final nbIndex = arena<Int64>();
      _h3c.maxPolygonToCellsSizeExperimental(
          polygon, resolution, flags, nbIndex);
      final out = arena<Uint64>(nbIndex.value);
      _h3c.polygonToCellsExperimental(
          polygon, resolution, 0, nbIndex.value, out);
      final list = out.asTypedList(nbIndex.value).toList();
      return list.where((e) => e != 0).map((e) => e.toBigInt()).toList();
    });
  }

  @override
  List<Polygon> cellsToMultiPolygon(List<BigInt> h3Set) {
    return using((arena) {
      final h3s = arena<Uint64>(h3Set.length);
      for (var i = 0; i < h3Set.length; i++) {
        h3s[i] = h3Set[i].toInt();
      }

      final outPtr = arena<c.LinkedGeoPolygon>();

      final err = _h3c.cellsToLinkedMultiPolygon(
        h3s,
        h3Set.length,
        outPtr,
      );

      if (err != 0) {
        throw Exception('H3 error code: $err');
      }

      final result = <Polygon>[];
      var polyPtr = outPtr;

      while (polyPtr != nullptr) {
        final outer = <LatLng>[];
        final holes = <List<LatLng>>[];
        var loopPtr = polyPtr.ref.first;

        while (loopPtr != nullptr) {
          final points = <LatLng>[];
          var latLngPtr = loopPtr.ref.first;

          while (latLngPtr != nullptr) {
            final vtx = latLngPtr.ref.vertex;
            points.add(LatLng(
                lat: _h3c.radsToDegs(vtx.lat), lng: _h3c.radsToDegs(vtx.lng)));
            latLngPtr = latLngPtr.ref.next;
          }

          if (outer.isEmpty) {
            outer.addAll(points);
          } else {
            holes.add(points);
          }

          loopPtr = loopPtr.ref.next;
        }

        result.add(Polygon(outer: outer, holes: holes));
        polyPtr = polyPtr.ref.next;
      }

      _h3c.destroyLinkedMultiPolygon(outPtr);
      return result;
    });
  }

  @override
  String h3ToString(BigInt h3) {
    return using((arena) {
      final out = arena<Char>(17);
      _h3c.h3ToString(h3.toInt(), out, 17);
      return out.cast<Utf8>().toDartString();
    });
  }

  @override
  BigInt stringToH3(String h3Str) {
    return using((arena) {
      final out = arena<Uint64>();
      _h3c.stringToH3(h3Str.toNativeUtf8(allocator: arena).cast<Char>(), out);
      return out.value.toBigInt();
    });
  }
}
