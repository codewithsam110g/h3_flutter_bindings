import 'package:h3_common_plus/h3_common_plus.dart';

import 'h3_factory.base.dart';

class H3Factory implements BaseH3Factory {
  const H3Factory();

  @override
  H3 process() {
    throw UnimplementedError();
  }

  @override
  H3 byPath(String libraryPath) {
    throw UnimplementedError();
  }

  @override
  H3 web() {
    throw UnimplementedError();
  }
}
