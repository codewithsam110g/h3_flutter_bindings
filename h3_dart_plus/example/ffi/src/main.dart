import 'package:h3_dart_plus/h3_dart_plus.dart';

void main() {
  final h3 = H3Factory().byPath('../../../h3_ffi_plus/c/h3lib/build/h3.so');

  final isValid = h3.isValidCell(BigInt.parse('0x85283473fffffff'));
  print('0x85283473fffffff is valid hex: $isValid');
}
