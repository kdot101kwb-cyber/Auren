import 'package:auren/services/women/women_support_resource_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('support resources persist locally and can be removed', () async {
    final service = AurenWomenSupportResourceService();
    final id = await service.add(
      title: 'Mentor contact',
      notes: 'Ask before sharing any personal details',
    );

    final saved = await service.list();
    expect(saved, hasLength(1));
    expect(saved.single.id, id);
    expect(saved.single.title, 'Mentor contact');
    expect(saved.single.notes, contains('personal details'));

    await service.remove(id);
    expect(await service.list(), isEmpty);
  });

  test('blank or oversized resource input is rejected', () async {
    final service = AurenWomenSupportResourceService();
    await expectLater(service.add(title: '  '), throwsArgumentError);
    await expectLater(
      service.add(title: 'x' * 121),
      throwsArgumentError,
    );
    expect(await service.list(), isEmpty);
  });

  test('malformed local cache fails closed', () async {
    SharedPreferences.setMockInitialValues({
      'auren.women.support_resources.v1': '{not-json',
    });
    expect(await AurenWomenSupportResourceService().list(), isEmpty);
  });
}
