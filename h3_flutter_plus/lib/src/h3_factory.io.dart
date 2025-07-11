import 'package:h3_ffi_plus/h3_ffi_plus.dart';

import 'dynamic_library_resolver.dart';
import 'h3_factory.base.dart';

class H3Factory implements BaseH3Factory {
  const H3Factory();

  final _internal = const H3FfiFactory();

  @override
  H3 load() {
    return _internal.byDynamicLibary(resolveDynamicLibrary());
  }
}
