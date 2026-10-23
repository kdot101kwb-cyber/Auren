import 'package:auren/services/emergency/emergency_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emergency contact is displayable only with complete location and phone', () {
    const valid = AurenEmergencyContact(
      id: 'clinic-1',
      name: 'Verified local clinic',
      type: 'clinic',
      phone: '+000000000',
      city: 'Sample City',
      country: 'Sample Country',
    );
    const missingPhone = AurenEmergencyContact(
      id: 'clinic-2',
      name: 'Clinic',
      type: 'clinic',
      phone: ' ',
      city: 'Sample City',
      country: 'Sample Country',
    );
    const missingLocation = AurenEmergencyContact(
      id: 'clinic-3',
      name: 'Clinic',
      type: 'clinic',
      phone: '+000000000',
      city: '',
      country: 'Sample Country',
    );

    expect(valid.isDisplayable, isTrue);
    expect(missingPhone.isDisplayable, isFalse);
    expect(missingLocation.isDisplayable, isFalse);
  });
}
