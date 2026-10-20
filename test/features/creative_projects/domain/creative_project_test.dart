import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/creative_projects/domain/creative_project.dart';

void main() {
  final createdAt = DateTime.utc(2026, 1, 1);

  AurenCreativeProject project({
    List<CreativeAssetReference> assets = const [],
    List<CreativeProjectVersion> versions = const [],
    DateTime? updatedAt,
  }) => AurenCreativeProject(
        id: 'project-1',
        ownerId: 'owner-1',
        title: 'Short film',
        description: 'A small production project',
        status: CreativeProjectStatus.planning,
        createdAt: createdAt,
        updatedAt: updatedAt ?? createdAt,
        assets: assets,
        versions: versions,
      );

  test('creates a project with immutable asset and version collections', () {
    final assets = <CreativeAssetReference>[
      CreativeAssetReference(
        id: 'asset-1',
        name: 'Script',
        kind: CreativeAssetKind.document,
        uri: 'local://script.md',
        addedAt: createdAt,
      ),
    ];
    final value = project(assets: assets);
    assets.clear();

    expect(value.assets, hasLength(1));
    expect(
      () => value.assets.clear(),
      throwsUnsupportedError,
    );
  });

  test('rejects blank project identity and title', () {
    expect(
      () => AurenCreativeProject(
        id: '',
        ownerId: 'owner-1',
        title: 'Title',
        description: '',
        status: CreativeProjectStatus.planning,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      throwsArgumentError,
    );
    expect(
      () => AurenCreativeProject(
        id: 'project-1',
        ownerId: 'owner-1',
        title: ' ',
        description: '',
        status: CreativeProjectStatus.planning,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      throwsArgumentError,
    );
  });

  test('rejects duplicate asset IDs and duplicate version numbers', () {
    final asset = CreativeAssetReference(
      id: 'asset-1',
      name: 'Script',
      kind: CreativeAssetKind.document,
      uri: 'local://script.md',
      addedAt: createdAt,
    );
    expect(() => project(assets: [asset, asset]), throwsArgumentError);

    final version = CreativeProjectVersion(
      number: 1,
      summary: 'Initial draft',
      createdAt: createdAt,
    );
    expect(() => project(versions: [version, version]), throwsArgumentError);
  });

  test('rejects invalid chronology and negative asset size', () {
    expect(() => project(updatedAt: createdAt.subtract(const Duration(seconds: 1))),
        throwsArgumentError);
    expect(
      () => CreativeAssetReference(
        id: 'asset-1',
        name: 'Bad file',
        kind: CreativeAssetKind.other,
        uri: 'local://bad',
        addedAt: createdAt,
        sizeBytes: -1,
      ),
      throwsArgumentError,
    );
  });

  test('copyWith preserves identity and updates selected fields', () {
    final original = project();
    final updated = original.copyWith(
      title: 'Final cut',
      status: CreativeProjectStatus.active,
      updatedAt: createdAt.add(const Duration(hours: 1)),
    );

    expect(updated.id, original.id);
    expect(updated.ownerId, original.ownerId);
    expect(updated.title, 'Final cut');
    expect(updated.status, CreativeProjectStatus.active);
    expect(updated.updatedAt, createdAt.add(const Duration(hours: 1)));
  });
}
