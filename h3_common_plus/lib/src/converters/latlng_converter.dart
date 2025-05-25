import 'package:h3_common_plus/h3_common_plus.dart';

/// Converter between [LatLng] and [LatLngRadians]
class LatLngConverter {
  const LatLngConverter(AngleConverter angleConverter)
      : _angleConverter = angleConverter;

  final AngleConverter _angleConverter;

  LatLng radianToDegree(LatLngRadians radian) {
    return LatLng(
      lng: _angleConverter.radianToDegree(radian.lng),
      lat: _angleConverter.radianToDegree(radian.lat),
    );
  }

  LatLngRadians degreeToRadian(LatLng degree) {
    return LatLngRadians(
      lng: _angleConverter.degreeToRadian(degree.lng),
      lat: _angleConverter.degreeToRadian(degree.lat),
    );
  }
}

/// Extension to convert [LatLng] to [LatLngRadians]
extension LatLngConverterToRadianExtension on LatLng {
  LatLngRadians toRadians(LatLngConverter converter) {
    return converter.degreeToRadian(this);
  }
}

/// Extension to convert [LatLngRadians] to [LatLng]
extension LatLngConverterToDegreeExtension on LatLngRadians {
  LatLng toDegrees(LatLngConverter converter) {
    return converter.radianToDegree(this);
  }
}
