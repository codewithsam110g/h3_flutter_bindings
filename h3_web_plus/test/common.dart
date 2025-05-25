import 'package:h3_web/h3_web.dart';

const geoPrecision = 7;

class ComparableLatLng {
  final String lat;
  final String lng;

  ComparableLatLng.fromLatLon({
    required double lat,
    required double lng,
  })  : lat = lat.toStringAsPrecision(geoPrecision),
        lng = lng.toStringAsPrecision(geoPrecision);

  ComparableLatLng.fromGeoCoord(LatLng latLng)
      : this.fromLatLon(lat: latLng.lat, lng: latLng.lng);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ComparableLatLng && other.lat == lat && other.lng == lng;
  }

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;

  @override
  String toString() => 'ComparableLatLng(lat: $lat, lon: $lng)';
}

bool almostEqual(num a, num b, [double factor = 1e-6]) =>
    (a - b).abs() < a * factor;
