import 'lat_lng.dart';

/// A polygon representation following the H3 specification.
///
/// A polygon consists of an outer loop defined by a list of [LatLng] coordinates,
/// and zero or more inner loops (holes), each also defined by a list of [LatLng] coordinates.
///
/// The outer loop defines the boundary of the polygon, while the inner loops
/// represent areas excluded from the polygon (holes).

class Polygon {
  final List<LatLng> outer;
  final List<List<LatLng>> holes;

  Polygon({
    required this.outer,
    this.holes = const [],
  });
}

