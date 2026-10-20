import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth/auth_service.dart';
import '../domain/visual_design.dart';

/// Lightweight offline visual composition using native Flutter drawing.
/// This is not an AI image generator or a full bitmap editor.
class AurenVisualCreatorScreen extends StatefulWidget {
  const AurenVisualCreatorScreen({super.key});

  @override
  State<AurenVisualCreatorScreen> createState() => _AurenVisualCreatorScreenState();
}

class _AurenVisualCreatorScreenState extends State<AurenVisualCreatorScreen> {
  final _auth = FirebaseAurenAuthService();
  final List<VisualLayer> _layers = [];
  bool _loading = true;
  String _name = 'تصميم جديد';
  String? _selectedId;
  String? get _uid => _auth.currentUserId;
  String _key(String uid) => 'auren.visual_creator.v1.$uid';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(uid));
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final design = AurenVisualDesign(
          id: data['id'] as String,
          ownerId: data['ownerId'] as String,
          name: data['name'] as String,
          width: (data['width'] as num).toDouble(),
          height: (data['height'] as num).toDouble(),
          updatedAt: DateTime.parse(data['updatedAt'] as String),
          layers: (data['layers'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map((layer) => VisualLayer(
                    id: layer['id'] as String,
                    kind: VisualLayerKind.values.firstWhere((v) => v.name == layer['kind']),
                    x: (layer['x'] as num).toDouble(),
                    y: (layer['y'] as num).toDouble(),
                    width: (layer['width'] as num).toDouble(),
                    height: (layer['height'] as num).toDouble(),
                    order: layer['order'] as int,
                    visible: layer['visible'] as bool? ?? true,
                    locked: layer['locked'] as bool? ?? false,
                    assetUri: layer['assetUri'] as String?,
                    text: layer['text'] as String?,
                  ))
              .toList(),
        );
        if (mounted) setState(() { _name = design.name; _layers..clear()..addAll(design.layers); });
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح التصميم المحلي: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final design = AurenVisualDesign(
        id: 'visual-$uid',
        ownerId: uid,
        name: _name.trim().isEmpty ? 'تصميم جديد' : _name.trim(),
        width: 1080,
        height: 1350,
        updatedAt: DateTime.now(),
        layers: _layers,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(uid), jsonEncode({
        'id': design.id,
        'ownerId': design.ownerId,
        'name': design.name,
        'width': design.width,
        'height': design.height,
        'updatedAt': design.updatedAt.toIso8601String(),
        'layers': design.layers.map((layer) => {
          'id': layer.id, 'kind': layer.kind.name, 'x': layer.x, 'y': layer.y,
          'width': layer.width, 'height': layer.height, 'order': layer.order,
          'visible': layer.visible, 'locked': layer.locked,
          'assetUri': layer.assetUri, 'text': layer.text,
        }).toList(),
      }));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التصميم على هذا الجهاز.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ التصميم: $error')),
      );
    }
  }

  Future<void> _addText() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة نص'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(hintText: 'اكتب النص على التصميم'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('إضافة')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    setState(() {
      final order = _layers.length;
      final layer = VisualLayer(
        id: 'layer-${DateTime.now().microsecondsSinceEpoch}',
        kind: VisualLayerKind.text,
        x: 90,
        y: 120 + order * 90,
        width: 900,
        height: 90,
        order: order,
        text: value,
      );
      _layers.add(layer);
      _selectedId = layer.id;
    });
  }

  void _addShape() {
    setState(() {
      final order = _layers.length;
      final layer = VisualLayer(
        id: 'layer-${DateTime.now().microsecondsSinceEpoch}',
        kind: VisualLayerKind.shape,
        x: 100 + (order % 4) * 55,
        y: 220 + (order % 4) * 55,
        width: 420,
        height: 190,
        order: order,
      );
      _layers.add(layer);
      _selectedId = layer.id;
    });
  }

  void _toggleVisibility(VisualLayer layer) {
    setState(() {
      final index = _layers.indexWhere((item) => item.id == layer.id);
      if (index < 0) return;
      _layers[index] = VisualLayer(
        id: layer.id, kind: layer.kind, x: layer.x, y: layer.y,
        width: layer.width, height: layer.height, order: layer.order,
        visible: !layer.visible, locked: layer.locked,
        assetUri: layer.assetUri, text: layer.text,
      );
    });
  }

  void _removeSelected() {
    setState(() {
      _layers.removeWhere((layer) => layer.id == _selectedId);
      _selectedId = null;
    });
  }

  Future<void> _rename() async {
    final controller = TextEditingController(text: _name);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اسم التصميم'),
        content: TextField(controller: controller, autofocus: true, maxLength: 80),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('حفظ')),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty && mounted) setState(() => _name = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) return const Scaffold(body: Center(child: Text('سجّل الدخول لاستخدام Visual Creator.')));
    return Scaffold(
      appBar: AppBar(
        title: Text(_name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(tooltip: 'إعادة تسمية', onPressed: _rename, icon: const Icon(Icons.edit_outlined)),
          IconButton(tooltip: 'حفظ', onPressed: _save, icon: const Icon(Icons.save_outlined)),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('صمّم منشوراً أو غلافاً بسيطاً بالنصوص والأشكال.'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _addText, icon: const Icon(Icons.title), label: const Text('إضافة نص'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: _addShape, icon: const Icon(Icons.rectangle_outlined), label: const Text('إضافة شكل'))),
          ]),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 4 / 5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GestureDetector(
                  onTapDown: (details) {
                    final size = context.size;
                    if (size == null) return;
                    final x = details.localPosition.dx / size.width * 1080;
                    final y = details.localPosition.dy / size.height * 1350;
                    final hit = _layers.where((l) => l.visible && x >= l.x && x <= l.x + l.width && y >= l.y && y <= l.y + l.height).toList()
                      ..sort((a, b) => b.order.compareTo(a.order));
                    setState(() => _selectedId = hit.isEmpty ? null : hit.first.id);
                  },
                  child: CustomPaint(
                    painter: _VisualCanvasPainter(_layers, _selectedId),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Text('الطبقات (${_layers.length})', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: _selectedId == null ? null : _removeSelected,
              icon: const Icon(Icons.delete_outline),
              label: const Text('حذف المحدد'),
            ),
          ]),
          if (_layers.isEmpty)
            const Padding(padding: EdgeInsets.all(18), child: Text('أضف نصاً أو شكلاً للبدء.'))
          else
            ..._layers.reversed.map((layer) => Card(
              child: ListTile(
                selected: layer.id == _selectedId,
                leading: Icon(layer.kind == VisualLayerKind.text ? Icons.title : Icons.rectangle_outlined),
                title: Text(layer.kind == VisualLayerKind.text ? layer.text ?? 'نص' : 'شكل'),
                subtitle: Text(layer.visible ? 'ظاهر' : 'مخفي'),
                onTap: () => setState(() => _selectedId = layer.id),
                trailing: IconButton(
                  tooltip: layer.visible ? 'إخفاء الطبقة' : 'إظهار الطبقة',
                  onPressed: () => _toggleVisibility(layer),
                  icon: Icon(layer.visible ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
            )),
          const SizedBox(height: 8),
          const Text('هذا محرر أولي محلي للنصوص والأشكال فقط؛ لا يتضمن توليد صور بالذكاء الاصطناعي أو استيراد الصور أو تصدير PNG بعد.',
              style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _VisualCanvasPainter extends CustomPainter {
  _VisualCanvasPainter(this.layers, this.selectedId);
  final List<VisualLayer> layers;
  final String? selectedId;
  static const _palette = [
    Color(0xFF5B4BDB),
    Color(0xFF00A6A6),
    Color(0xFFE85D75),
    Color(0xFFF2A93B),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 1080;
    final scaleY = size.height / 1350;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1080, 1350), Paint()..color = const Color(0xFFF7F5FF));
    for (final layer in layers.where((l) => l.visible).toList()..sort((a, b) => a.order.compareTo(b.order))) {
      final rect = Rect.fromLTWH(layer.x, layer.y, layer.width, layer.height);
      final paint = Paint()..color = _palette[layer.order % _palette.length];
      if (layer.kind == VisualLayerKind.shape) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(28)), paint);
      } else if (layer.kind == VisualLayerKind.text) {
        final text = TextPainter(
          text: TextSpan(text: layer.text, style: const TextStyle(color: Color(0xFF1D1B2E), fontSize: 52, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.rtl,
          maxLines: 3,
          ellipsis: '…',
        )..layout(maxWidth: layer.width);
        text.paint(canvas, Offset(layer.x, layer.y));
      }
      if (layer.id == selectedId) {
        canvas.drawRect(rect, Paint()..color = const Color(0xFF3B82F6)..style = PaintingStyle.stroke..strokeWidth = 5);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VisualCanvasPainter oldDelegate) =>
      oldDelegate.layers != layers || oldDelegate.selectedId != selectedId;
}
