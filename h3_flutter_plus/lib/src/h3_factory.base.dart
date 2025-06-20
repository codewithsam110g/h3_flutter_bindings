import 'package:h3_common_plus/h3_common_plus.dart';

/// H3Factory is used to build H3 instance
abstract class BaseH3Factory {
  /// Resolves H3 for current platform
  H3 load();
}
