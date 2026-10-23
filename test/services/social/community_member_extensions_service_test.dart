import 'package:auren/services/social/community_member_extensions_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('translation drafts are bounded, local, and removable', () async {
    final service = AurenCommunityMemberExtensionsService();
    await service.addTranslation(communityId: 'garden', sourceText: 'Hello',
      translatedText: 'مرحبا', language: 'Arabic');
    final saved = await service.translations('garden');
    expect(saved, hasLength(1));
    expect(saved.single['status'], 'draft');
    expect((await service.translations('book-club')), isEmpty);
    await service.removeTranslation('garden', saved.single['id'] as String);
    expect(await service.translations('garden'), isEmpty);
    await expectLater(service.addTranslation(communityId: 'garden', sourceText: '',
      translatedText: 'مرحبا', language: 'Arabic'), throwsArgumentError);
  });

  test('volunteer hour entries reject invalid values and can be removed', () async {
    final service = AurenCommunityMemberExtensionsService();
    await expectLater(service.addVolunteerHours(communityId: 'garden',
      activity: 'Cleanup', hours: 25, date: DateTime(2026, 10, 1)),
      throwsArgumentError);
    await service.addVolunteerHours(communityId: 'garden', activity: 'Cleanup',
      hours: 2.5, date: DateTime(2026, 10, 1));
    final saved = await service.volunteerHours('garden');
    expect(saved.single['hours'], 2.5);
    expect(saved.single['date'], contains('2026-10-01'));
    await service.removeVolunteerHours('garden', saved.single['id'] as String);
    expect(await service.volunteerHours('garden'), isEmpty);
  });

  test('availability profile remains opt-in and local', () async {
    final service = AurenCommunityMemberExtensionsService();
    expect(await service.availability('garden'), {'visible': false, 'text': ''});
    await service.saveAvailability(communityId: 'garden',
      text: 'Evenings', visible: true);
    expect(await service.availability('garden'), {'visible': true, 'text': 'Evenings'});
    expect(await service.availability('book-club'), {'visible': false, 'text': ''});
    await expectLater(service.saveAvailability(communityId: 'garden',
      text: List.filled(501, 'x').join(), visible: false), throwsArgumentError);
  });

  test('community glossary validates and stores terms by community', () async {
    final service = AurenCommunityMemberExtensionsService();
    await service.addGlossaryTerm(communityId: 'garden', term: 'Mulch',
      meaning: 'Covering soil with material', language: 'English');
    final saved = await service.glossary('garden');
    expect(saved.single['term'], 'Mulch');
    expect((await service.glossary('book-club')), isEmpty);
    await expectLater(service.addGlossaryTerm(communityId: 'garden', term: ' ',
      meaning: 'Meaning', language: 'English'), throwsArgumentError);
  });

  test('invalid community IDs are rejected by every extension', () async {
    final service = AurenCommunityMemberExtensionsService();
    await expectLater(service.translations(' '), throwsArgumentError);
    await expectLater(service.glossary(' '), throwsArgumentError);
    await expectLater(service.volunteerHours(' '), throwsArgumentError);
    await expectLater(service.availability(' '), throwsArgumentError);
  });
}
