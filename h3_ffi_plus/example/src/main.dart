import 'package:h3_ffi_plus/h3_ffi_plus.dart';

void main() {
  final h3 = H3FfiFactory().byPath('../../h3_ff_plusi/c/h3lib/build/h3.so');

  final isValid = h3.isValidCell(BigInt.parse('0x85283473fffffff'));
  print('0x85283473fffffff is valid hex: $isValid');
}
