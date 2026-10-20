import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/document_studio/domain/auren_document.dart';

void main() {
  final date = DateTime.utc(2026, 1, 1);

  test('stores content and exposes immutable revision history', () {
    final revisions = <AurenDocumentRevision>[
      AurenDocumentRevision(number: 1, title: 'Brief', body: 'First', savedAt: date),
    ];
    final doc = AurenDocument(
      id: 'doc-1', ownerId: 'user-1', title: 'Brief', body: 'Latest',
      status: AurenDocumentStatus.draft, createdAt: date, updatedAt: date,
      revisions: revisions,
    );
    revisions.clear();
    expect(doc.revisions, hasLength(1));
    expect(() => doc.revisions.clear(), throwsUnsupportedError);
  });

  test('rejects blank title and non-chronological timestamps', () {
    expect(() => AurenDocument(
      id: 'doc-1', ownerId: 'user-1', title: ' ', body: '',
      status: AurenDocumentStatus.draft, createdAt: date, updatedAt: date,
    ), throwsArgumentError);
    expect(() => AurenDocument(
      id: 'doc-1', ownerId: 'user-1', title: 'Brief', body: '',
      status: AurenDocumentStatus.draft, createdAt: date,
      updatedAt: date.subtract(const Duration(seconds: 1)),
    ), throwsArgumentError);
  });

  test('copyWith updates content without changing ownership', () {
    final doc = AurenDocument(
      id: 'doc-1', ownerId: 'user-1', title: 'Brief', body: 'Draft',
      status: AurenDocumentStatus.draft, createdAt: date, updatedAt: date,
    ).copyWith(title: 'Approved brief', status: AurenDocumentStatus.finalized);
    expect(doc.ownerId, 'user-1');
    expect(doc.title, 'Approved brief');
    expect(doc.status, AurenDocumentStatus.finalized);
  });
}
