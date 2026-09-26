import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/creator/creator_studio_repository.dart';

void main() {
  test('creator stats model exposes total content', () {
    const stats = AurenCreatorStats(posts: 4, likes: 12, mediaPosts: 3);
    expect(stats.totalContent, 4);
  });
}
