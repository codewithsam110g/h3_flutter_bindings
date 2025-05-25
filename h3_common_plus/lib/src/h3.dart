import 'package:h3_common_plus/h3_common.dart';

/// Provides access to H3 functions.
abstract class H3 {
  /// Determines if [h3Index] is a valid cell (hexagon or pentagon)
  bool isValidCell(BigInt h3Index);

  /// Determines if [h3Index] is a valid pentagon
  bool isPentagon(BigInt h3Index);

  /// Determines if [h3Index] Resolution is Class III (Rotated ~19.1 deg or not)
  bool isResClassIII(BigInt h3Index);

  /// Returns the base cell "number" (0 to 121) of the provided H3 cell
  ///
  /// Note: Technically works on H3 edges, but will return base cell of the
  /// origin cell.
  int getBaseCellNumber(BigInt h3Index);

  /// Find all icosahedron faces intersected by a given H3 index
  List<int> getIcosahedronFaces(BigInt h3Index);

  /// Returns the resolution of the index.
  ///
  /// Works for cells, edges, and vertexes
  int getResolution(BigInt h3Index);

  /// Finds the Cell based on the [latLng] coordinates at the specified resolution level [res]
  BigInt latLngToCell(LatLng latLng, int res);

  /// Gives the Coordinates [LatLng] based on the center of the given cell
  LatLng cellToLatLng(BigInt h3Index);

  /// Gives the cell boundary in lat/lng coordinates for the cell with index [h3Index]
  ///
  /// ```dart
  /// h3.h3ToGeoBoundary(0x85283473fffffff)
  /// h3.h3ToGeoBoundary(133)
  /// ```
  List<LatLng> cellToBoundary(BigInt h3Index);

  /// Get the parent of the given [h3Index] hexagon at a particular [resolution]
  ///
  /// Returns 0 when result can't be calculated
  BigInt cellToParent(BigInt h3Index, int resolution);

  /// Get the children/descendents of the given [h3Index] hexagon at a particular [resolution]
  List<BigInt> cellToChildren(BigInt h3Index, int resolution);

  /// Get the center child of the given [h3Index] hexagon at a particular [resolution]
  ///
  /// Returns 0 when result can't be calculated
  BigInt cellToCenterChild(BigInt h3Index, int resolution);

  /// Produces the "filled-in disk" of cells which are at most grid distance `k`
  /// from the origin cell. This includes the origin cell itself.
  ///
  /// - [h3Index]: The origin cell index.
  /// - [ringSize]: The maximum grid distance (k).
  ///
  /// Returns a list of cell indexes covering the disk-shaped area.
  List<BigInt> gridDisk(BigInt h3Index, int ringSize);

  /// Produces the "How Ring" of cells which are at most grid distance `k`
  /// from the origin cell. This includes the origin cell itself.
  ///
  /// - [h3Index]: The origin cell index.
  /// - [ringSize]: The maximum grid distance (k).
  ///
  /// Returns a list of cell indexes covering the Hollow Ring.
  List<BigInt> gridRingUnsafe(BigInt h3Index, int ringSize);

  /// Takes a given [coordinates] and [resolution] and returns hexagons that
  /// are contained by them.
  ///
  /// It also accepts an optional [holes] parameter to specify any interior loops (holes) within the polygon.
  ///
  /// [resolution] must be in the range [0, 15].
  ///
  /// This implementation traces the GeoJSON geofence(s) in cartesian space with
  /// hexagons, tests them and their neighbors to be contained by the geofence(s),
  /// and then any newly found hexagons are used to test again until no new
  /// hexagons are found.
  ///
  /// ```dart
  /// final hexagons = h3.polygonToCells(
  ///   coordinates: const [
  ///     LatLng(lat: 37.813318999983238, lng: -122.4089866999972145),
  ///     LatLng(lat: 37.7866302000007224, lng: -122.3805436999997056),
  ///     LatLng(lat: 37.7198061999978478, lng: -122.3544736999993603),
  ///     LatLng(lat: 37.7076131999975672, lng: -122.5123436999983966),
  ///     LatLng(lat: 37.7835871999971715, lng: -122.5247187000021967),
  ///     LatLng(lat: 37.8151571999998453, lng: -122.4798767000009008),
  ///   ],
  ///   resolution: 9,
  /// )
  /// ```
  List<BigInt> polygonToCells({
    required List<LatLng> coordinates,
    required int resolution,
    List<List<LatLng>> holes,
  });

  /// Compact a set of H3 Cells of the same resolution into a set of H3 Cells
  /// across multiple levels that represents the same area.
  /// Note: Input cells must all share the same resolution
  List<BigInt> compactCells(List<BigInt> hexagons);

  /// Uncompact a compacted set of hexagons to hexagons of the same resolution
  List<BigInt> uncompactCells(
    List<BigInt> compactedHexagons, {
    required int resolution,
  });

  /// Determines whether or not the provided H3 cells are neighbors.
  bool areNeighborCells(BigInt origin, BigInt destination);

  /// Provides a directed edge H3 index based on the provided origin and destination.
  BigInt cellsToDirectedEdge(BigInt origin, BigInt destination);

  /// Provides the origin hexagon from the directed edge H3Index.
  BigInt getDirectedEdgeOrigin(BigInt edgeIndex);

  /// Provides the destination hexagon from the directed edge H3Index.
  BigInt getDirectedEdgeDestination(BigInt edgeIndex);

  /// Determines if the provided H3Index is a valid directed edge index
  bool isValidDirectedEdge(BigInt edgeIndex);

  /// Get the [origin, destination] pair represented by a directed edge
  List<BigInt> directedEdgeToCells(BigInt edgeIndex);

  /// Provides all of the directed edges from the current cell.
  /// (i.e. an edge to every neighbor)
  List<BigInt> originToDirectedEdges(BigInt edgeIndex);

  /// Get the vertices of a given edge as an array of [lat, lng] points. Note
  /// that for edges that cross the edge of an icosahedron face, this may return
  /// 3 coordinates.
  List<LatLng> directedEdgeToBoundary(BigInt edgeIndex);

  /// Provides the grid distance between two cells,
  /// which is defined as the minimum number of "hops"
  /// needed across adjacent cells to get from one cell to the other.
  ///
  /// Returns -1 when result can't be calculated
  int gridDistance(BigInt origin, BigInt destination);

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
  ///    that the line length will be `gridDistance(start, end) + 1` and that
  ///    every index in the line will be a neighbor of the preceding index.
  ///  - Lines are drawn in grid space, and may not correspond exactly to either
  ///    Cartesian lines or great arcs.
  List<BigInt> gridPathCells(BigInt origin, BigInt destination);

  /// Produces IJ coordinates for an H3 cell anchored by an origin.
  ///
  /// - The coordinate space used by this function may have deleted
  /// regions or warping due to pentagonal distortion.
  /// - Coordinates are only comparable if they come from the same
  /// origin index.
  /// - Failure may occur if the index is too far away from the origin
  /// or if the index is on the other side of a pentagon.
  /// - This function is experimental, and its output is not guaranteed
  /// to be compatible across different versions of H3.
  CoordIJ cellToLocalIj(BigInt origin, BigInt destination);

  /// Produces an H3 cell for IJ coordinates anchored by an origin.
  ///
  /// - The coordinate space used by this function may have deleted
  /// regions or warping due to pentagonal distortion.
  /// - Coordinates are only comparable if they come from the same
  /// origin index.
  /// - Failure may occur if the index is too far away from the origin
  /// or if the index is on the other side of a pentagon.
  /// - This function is experimental, and its output is not guaranteed
  /// to be compatible across different versions of H3.
  BigInt localIjToCell(BigInt origin, CoordIJ coordinates);

  /// Calculates great circle or haversine distance between two geo points.
  double greatCircleDistance(LatLng a, LatLng b, H3Units unit);

  /// Calculates exact area of a given cell in square [unit]s (e.g. m^2)
  double cellArea(BigInt h3Index, H3Units unit);

  /// Calculates exact length of a given unidirectional edge in [unit]s
  double edgeLength(BigInt edgeIndex, H3Units unit);

  /// Calculates average hexagon area at a given resolution in [unit]s
  double getHexagonAreaAvg(int res, H3AreaUnits unit);

  /// Calculates average hexagon edge length at a given resolution in [unit]s
  double getHexagonEdgeLengthAvg(int res, H3EdgeLengthUnits unit);

  /// Returns the total count of hexagons in the world at a given resolution.
  ///
  /// If the library compiled to JS - note that above
  /// resolution 8 the exact count cannot be represented in a JavaScript 32-bit number,
  /// so consumers should use caution when applying further operations to the output.
  int getNumCells(int res);

  /// Returns all H3 indexes at resolution 0. As every index at every resolution > 0 is
  /// the descendant of a res 0 index, this can be used with cellToChildren to iterate
  /// over H3 indexes at any resolution.
  List<BigInt> getRes0Cells();

  /// Get the twelve pentagon indexes at a given resolution.
  List<BigInt> getPentagons(int res);

  /// Converts radians to degrees
  double radsToDegs(double val);

  /// Converts degrees to radians
  double degsToRads(double val);

  // maxPolygonToCellsSizeExperimental is the correct one not maxPolygonToCellsExperimentalSize

  /// Create a GeoJSON-like multi-polygon describing the outline(s) of a set of cells.
  /// Polygon outlines will follow GeoJSON MultiPolygon order:
  /// Each polygon will have one outer loop, which is first in the list,
  /// followed by any holes.
  List<Polygon> cellsToMultiPolygon(List<BigInt> h3Set);

  /// takes as input a GeoJSON-like data structure describing a polygon
  /// (i.e., an outer ring and optional holes) and a target cell resolution.
  /// It produces a collection of cells that are contained within the polygon.
  ///
  /// This function differs from polygonToCells in that it uses an experimental new algorithm
  /// which supports center-based, fully-contained, and overlapping containment modes. with [flags]
  List<BigInt> polygonToCellsExperimental({
    required List<LatLng> coordinates,
    required int resolution,
    List<List<LatLng>> holes = const [],
    required int flags,
  });

  /// Provides a Error Message from the H3Error Codes [0-15]
  String describeH3Error(int err);

  /// It gives the Child Cell from the Parent Cell using
  /// the Resolution [childRes] and [childPos] Index in that Child Resolution
  BigInt childPosToCell(int childPos, BigInt parent, int childRes);

  /// Provides the position of the [child] cell within an ordered list of
  /// all children of the cell's parent at the specified resolution [parentRes].
  /// The order of the ordered list is the same as that returned by cellToChildren.
  int cellToChildPos(BigInt child, int parentRes);

  /// Determines if the given H3 index represents a valid H3 vertex.
  bool isValidVertex(BigInt h3Index);

  /// Returns the latitude and longitude coordinates of the given vertex
  LatLng vertexToLatLng(BigInt vertex);

  /// Returns the index for the specified cell vertex.
  /// Valid vertex numbers are between 0 and 5 (inclusive) for hexagonal cells,
  /// and 0 and 4 (inclusive) for pentagonal cells.
  BigInt cellToVertex(BigInt origin, int vertexNum);

  /// Returns the indexes for all vertexes of the given cell.
  List<BigInt> cellToVertexes(BigInt origin);

  /// Converts the H3Index representation of the index to the string representation
  String h3ToString(BigInt h3);

  /// Converts the string representation to H3Index (uint64_t) representation.
  BigInt stringToH3(String h3Str);
}
