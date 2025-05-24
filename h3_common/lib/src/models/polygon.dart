import 'lat_lng.dart';

class Polygon {
  final List<LatLng> outer;
  final List<List<LatLng>> holes;

  Polygon({
    required this.outer,
    this.holes = const [],
  });
}

