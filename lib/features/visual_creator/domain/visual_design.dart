enum VisualLayerKind { text, image, shape }

class VisualLayer {
  final String id;
  final VisualLayerKind kind;
  final double x;
  final double y;
  final double width;
  final double height;
  final int order;
  final bool visible;
  final bool locked;
  final String? assetUri;
  final String? text;

  VisualLayer({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.order,
    this.visible = true,
    this.locked = false,
    this.assetUri,
    this.text,
  }) {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'id');
    if (![x, y, width, height].every((v) => v.isFinite)) {
      throw ArgumentError('Layer geometry must be finite.');
    }
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Layer width and height must be positive.');
    }
    if (kind == VisualLayerKind.image && (assetUri == null || assetUri!.trim().isEmpty)) {
      throw ArgumentError('Image layers require an asset URI.');
    }
    if (kind == VisualLayerKind.text && (text == null || text!.trim().isEmpty)) {
      throw ArgumentError('Text layers require text.');
    }
  }
}

class AurenVisualDesign {
  final String id;
  final String ownerId;
  final String name;
  final double width;
  final double height;
  final List<VisualLayer> layers;
  final DateTime updatedAt;

  AurenVisualDesign({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.width,
    required this.height,
    required this.updatedAt,
    List<VisualLayer> layers = const [],
  }) : layers = List.unmodifiable(layers) {
    if (id.trim().isEmpty || ownerId.trim().isEmpty || name.trim().isEmpty) {
      throw ArgumentError('Design id, owner, and name are required.');
    }
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      throw ArgumentError('Canvas dimensions must be finite and positive.');
    }
    final ids = this.layers.map((layer) => layer.id).toSet();
    if (ids.length != this.layers.length) throw ArgumentError('Layer IDs must be unique.');
  }

  List<VisualLayer> get orderedVisibleLayers => layers
      .where((layer) => layer.visible)
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
}

/// Returns a copy with the requested layer moved one position in z-order.
/// Direction +1 brings the layer forward; -1 sends it backward.
List<VisualLayer> reorderVisualLayers(
  List<VisualLayer> layers,
  String layerId,
  int direction,
) {
  if (direction != -1 && direction != 1) {
    throw ArgumentError.value(direction, 'direction', 'Must be -1 or 1.');
  }
  final ordered = layers.toList()..sort((a, b) => a.order.compareTo(b.order));
  final index = ordered.indexWhere((layer) => layer.id == layerId);
  final target = index + direction;
  if (index < 0 || target < 0 || target >= ordered.length) {
    return List.unmodifiable(ordered);
  }
  final moving = ordered[index];
  ordered[index] = ordered[target];
  ordered[target] = moving;
  return List.unmodifiable([
    for (var i = 0; i < ordered.length; i++)
      VisualLayer(
        id: ordered[i].id,
        kind: ordered[i].kind,
        x: ordered[i].x,
        y: ordered[i].y,
        width: ordered[i].width,
        height: ordered[i].height,
        order: i,
        visible: ordered[i].visible,
        locked: ordered[i].locked,
        assetUri: ordered[i].assetUri,
        text: ordered[i].text,
      ),
  ]);
}
