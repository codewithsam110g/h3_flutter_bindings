/// A pair of latitude and longitude coordinates in degrees
///
/// World-wrapping supported - if you pass coordinates outside of the bounds
/// ([-180, 180] for longitude and [-90, 90] for latitude) they will be converted.
class LatLng {
  const LatLng({
    required double lng,
    required double lat,
  })  : lng = (lng + 180) % 360 - 180,
        lat = (lat + 90) % 180 - 90;

  final double lng;
  final double lat;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LatLng && other.lat == lat && other.lng == lng;
  }

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoCoord(lng: $lng, lat: $lat)';
}
