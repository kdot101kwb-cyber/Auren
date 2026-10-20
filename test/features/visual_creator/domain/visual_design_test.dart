import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/visual_creator/domain/visual_design.dart';

void main() {
  final date = DateTime.utc(2026, 1, 1);
  VisualLayer layer(String id, int order, {bool visible = true}) => VisualLayer(
    id: id, kind: VisualLayerKind.shape, x: 0, y: 0, width: 20, height: 20,
    order: order, visible: visible,
  );

  test('orders visible layers and omits hidden layers', () {
    final design = AurenVisualDesign(
      id: 'design-1', ownerId: 'user-1', name: 'Cover', width: 1080,
      height: 1350, updatedAt: date,
      layers: [layer('top', 2), layer('hidden', 0, visible: false), layer('bottom', 1)],
    );
    expect(design.orderedVisibleLayers.map((e) => e.id), ['bottom', 'top']);
  });

  test('rejects duplicate layer IDs and invalid geometry', () {
    expect(() => AurenVisualDesign(
      id: 'design-1', ownerId: 'user-1', name: 'Cover', width: 1080,
      height: 1350, updatedAt: date, layers: [layer('same', 1), layer('same', 2)],
    ), throwsArgumentError);
    expect(() => VisualLayer(
      id: 'bad', kind: VisualLayerKind.shape, x: 0, y: 0, width: 0, height: 10, order: 0,
    ), throwsArgumentError);
  });

  test('image and text layers require their content reference', () {
    expect(() => VisualLayer(
      id: 'image', kind: VisualLayerKind.image, x: 0, y: 0, width: 10, height: 10, order: 0,
    ), throwsArgumentError);
    expect(() => VisualLayer(
      id: 'text', kind: VisualLayerKind.text, x: 0, y: 0, width: 10, height: 10, order: 0,
    ), throwsArgumentError);
  });
}
