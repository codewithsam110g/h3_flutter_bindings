import 'dart:html';

import 'package:h3_dart_plus/h3_dart_plus.dart';

void main() {
  const h3Factory = H3Factory();
  final h3 = h3Factory.web();
  final isValid = h3.isValidCell(BigInt.parse('0x85283473fffffff'));
  querySelector('#output')?.text = '0x85283473fffffff is valid hex: $isValid';
}
