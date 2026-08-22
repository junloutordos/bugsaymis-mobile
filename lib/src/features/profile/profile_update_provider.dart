import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

final profileUpdateProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response =
      await ref.read(apiClientProvider).get('/student/portal/profile-update');
  return response.data as Map<String, dynamic>;
});

/// Human-readable labels for the editable students-table columns, in
/// display order, grouped for the form UI.
const kFieldGroups = {
  'Contact Info': {
    'studentcontact': 'Student Contact Number',
    'contactno1': 'Primary Contact Number',
    'contactno2': 'Secondary Contact Number',
    'student_email': 'Email Address',
  },
  'Address': {
    'houseno': 'House No. / Street',
    'barangay': 'Barangay',
    'municipal': 'Municipality/City',
    'district': 'District',
    'province': 'Province',
    'zipcode': 'Zip Code',
    'homeaddresstype': 'Address Type',
  },
  'Parent / Guardian Info': {
    'contactperson': 'Contact Person',
    'relation1': 'Relationship',
    'contact_address1': 'Contact Person Address',
    'contact_ofc_address1': 'Office Address',
    'contact_ofc_telno1': 'Office Telephone',
    'contactperson2': 'Secondary Contact Person',
    'relation2': 'Secondary Relationship',
    'contact_address2': 'Secondary Contact Address',
    'contact_ofc_address2': 'Secondary Office Address',
    'contact_ofc_telno2': 'Secondary Office Telephone',
    'mcpno': "Mother's Contact Number",
    'fcpno': "Father's Contact Number",
    'memailaddress': "Mother's Email",
    'femailaddress': "Father's Email",
    'moccupation': "Mother's Occupation",
    'foccupation': "Father's Occupation",
  },
  'Personal Details': {
    'bloodtype': 'Blood Type',
    'religion': 'Religion',
    'ethnic': 'Ethnicity',
    'nationality': 'Nationality',
  },
};
