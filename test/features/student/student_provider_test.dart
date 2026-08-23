import 'package:flutter_test/flutter_test.dart';
import 'package:atlasgo/src/features/student/student_provider.dart';

void main() {
  group('StudentProfile.fromJson', () {
    test('parses has_photo', () {
      final profile = StudentProfile.fromJson({
        'student': {'id': 1, 'name': 'Juan Dela Cruz', 'has_photo': true},
      });
      expect(profile.hasPhoto, isTrue);
    });

    test('defaults has_photo to false when absent', () {
      final profile = StudentProfile.fromJson({
        'student': {'id': 1, 'name': 'Juan Dela Cruz'},
      });
      expect(profile.hasPhoto, isFalse);
    });
  });

  group('StudentIdCard.fromJson', () {
    test('parses every field from the id-card response shape', () {
      final card = StudentIdCard.fromJson({
        'student': {
          'name': 'DELA CRUZ, JUAN',
          'barcode': '2024-00123',
          'lrn': '123456789012',
          'has_photo': true,
          'grade_level': 8,
          'section': 'Curie',
          'school_year': '2026-2027',
        },
        'ocd': {
          'name': 'MELBA C. PATACSIL, PhD',
          'position': 'Campus Director',
          'signature_uri': 'data:image/png;base64,AAAA',
        },
        'emergency': {
          'guardian_name': 'Maria Dela Cruz',
          'contact_no': '09171234567',
          'address': 'Butuan City',
        },
      });

      expect(card.name, 'DELA CRUZ, JUAN');
      expect(card.barcode, '2024-00123');
      expect(card.lrn, '123456789012');
      expect(card.hasPhoto, isTrue);
      expect(card.gradeLevel, 8);
      expect(card.section, 'Curie');
      expect(card.schoolYear, '2026-2027');
      expect(card.ocdName, 'MELBA C. PATACSIL, PhD');
      expect(card.ocdPosition, 'Campus Director');
      expect(card.ocdSignatureUri, 'data:image/png;base64,AAAA');
      expect(card.guardianName, 'Maria Dela Cruz');
      expect(card.contactNo, '09171234567');
      expect(card.address, 'Butuan City');
    });

    test('nulls out missing optional fields instead of throwing', () {
      final card = StudentIdCard.fromJson({
        'student': {'name': 'DELA CRUZ, JUAN', 'has_photo': false},
        'ocd': {'name': 'MELBA C. PATACSIL, PhD', 'position': 'Campus Director'},
        'emergency': <String, dynamic>{},
      });

      expect(card.barcode, isNull);
      expect(card.lrn, isNull);
      expect(card.ocdSignatureUri, isNull);
      expect(card.guardianName, isNull);
    });
  });
}
