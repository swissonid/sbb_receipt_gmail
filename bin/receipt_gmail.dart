import 'dart:io';

import 'package:receipt_gmail/sbb_receipts_extractor.dart' as receipt_gmail;

void main(List<String> arguments) async {
  await receipt_gmail.run();
  exit(0);
}
