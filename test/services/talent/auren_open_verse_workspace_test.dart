import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auren/services/talent/auren_open_verse_workspace.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves and restores a collaboration draft locally', () async {
    final workspace = AurenOpenVerseWorkspace();
    final saved = await workspace.saveProject(
      title: 'Sudan Open Verse',
      brief: 'A multilingual chorus with open verses.',
      genre: 'Afro-fusion',
      roles: 'Singer; producer; songwriter',
      bpm: 96,
    );

    final restored = await workspace.listProjects();
    expect(restored, hasLength(1));
    expect(restored.single.id, saved.id);
    expect(restored.single.title, 'Sudan Open Verse');
    expect(restored.single.bpm, 96);
    expect(restored.single.roles, contains('producer'));
  });

  test('updates existing draft rather than duplicating it', () async {
    final workspace = AurenOpenVerseWorkspace();
    final first = await workspace.saveProject(title: 'Draft', brief: 'First');
    await workspace.saveProject(id: first.id, title: 'Draft v2', brief: 'Updated');

    final projects = await workspace.listProjects();
    expect(projects, hasLength(1));
    expect(projects.single.title, 'Draft v2');
    expect(projects.single.brief, 'Updated');
  });

  test('rejects blank titles, oversized fields and invalid BPM', () async {
    final workspace = AurenOpenVerseWorkspace();
    await expectLater(workspace.saveProject(title: '  ', brief: ''), throwsArgumentError);
    await expectLater(workspace.saveProject(title: 'x', brief: 'b', bpm: 20), throwsArgumentError);
    await expectLater(workspace.saveProject(title: 'x', brief: 'b', roles: 'r' * 1001), throwsArgumentError);
  });

  test('removes a draft and reports unknown ids without changing data', () async {
    final workspace = AurenOpenVerseWorkspace();
    final saved = await workspace.saveProject(title: 'Draft', brief: '');
    expect(await workspace.removeProject('unknown'), isFalse);
    expect(await workspace.removeProject(saved.id), isTrue);
    expect(await workspace.listProjects(), isEmpty);
  });

  test('skips malformed local entries without hiding valid drafts', () async {
    SharedPreferences.setMockInitialValues({
      AurenOpenVerseWorkspace.storageKey: [
        '{bad json',
        '{"id":"ok","title":"Valid draft","brief":""}',
      ],
    });
    final projects = await AurenOpenVerseWorkspace().listProjects();
    expect(projects, hasLength(1));
    expect(projects.single.title, 'Valid draft');
  });
}
