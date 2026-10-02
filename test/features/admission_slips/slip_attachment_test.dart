import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/admission_slips/slip_attachment.dart';

void main() {
  test('encodes a PDF as a base64 data URI', () {
    final a = SlipAttachment.fromBytes(name: 'cert.pdf', bytes: [1, 2, 3]);
    expect(a.dataUri, 'data:application/pdf;base64,${base64Encode([1, 2, 3])}');
    expect(a.name, 'cert.pdf');
  });

  test('maps jpg/jpeg/png', () {
    expect(SlipAttachment.fromBytes(name: 'a.JPG', bytes: [1]).dataUri, startsWith('data:image/jpeg;base64,'));
    expect(SlipAttachment.fromBytes(name: 'a.jpeg', bytes: [1]).dataUri, startsWith('data:image/jpeg;base64,'));
    expect(SlipAttachment.fromBytes(name: 'a.png', bytes: [1]).dataUri, startsWith('data:image/png;base64,'));
  });

  test('rejects other types and oversize files', () {
    expect(() => SlipAttachment.fromBytes(name: 'a.svg', bytes: [1]), throwsFormatException);
    expect(() => SlipAttachment.fromBytes(name: 'a.docx', bytes: [1]), throwsFormatException);
    expect(() => SlipAttachment.fromBytes(name: 'noext', bytes: [1]), throwsFormatException);
    expect(
      () => SlipAttachment.fromBytes(name: 'big.png', bytes: List.filled(SlipAttachment.maxBytes + 1, 0)),
      throwsFormatException,
    );
  });
}
