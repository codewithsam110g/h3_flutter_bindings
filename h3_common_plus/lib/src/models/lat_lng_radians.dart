import 'dart:math';

/// A pair of latitude and longitude coordinates in radians
///
/// World-wrapping supported - if you pass coordinates outside of the bounds
/// ([-pi, pi] for longitude and [-pi/2, pi/2] for latitude) they will be converted.
class LatLngRadians {
  const LatLngRadians({
    required double lng,
    required double lat,
  })  : lng = (lng + pi) % (pi * 2) - pi,
        lat = (lat + (pi / 2)) % pi - (pi / 2);

  final double lng;
  final double lat;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LatLngRadians && other.lat == lat && other.lng == lng;
  }

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'LatLngRadians(lng: $lng, lat: $lat)';
}
