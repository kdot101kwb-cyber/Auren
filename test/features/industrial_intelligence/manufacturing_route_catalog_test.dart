import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/domain/manufacturing_route_catalog.dart';

void main() {
  group('ManufacturingRouteCatalog', () {
    test('contains unique non-empty route identifiers', () {
      final ids = ManufacturingRouteCatalog.routes.map((route) => route.id).toList();
      expect(ids, isNotEmpty);
      expect(ids.toSet().length, ids.length);
      for (final route in ManufacturingRouteCatalog.routes) {
        expect(route.rawMaterial.trim(), isNotEmpty);
        expect(route.finalProduct.trim(), isNotEmpty);
        expect(route.stages, isNotEmpty);
        expect(route.prerequisites, isNotEmpty);
        for (final stage in route.stages) {
          expect(stage.name.trim(), isNotEmpty);
          expect(stage.purpose.trim(), isNotEmpty);
          expect(stage.typicalInputs, isNotEmpty);
          expect(stage.typicalOutputs, isNotEmpty);
        }
      }
    });

    test('finds a route by identifier', () {
      expect(
        ManufacturingRouteCatalog.findById('sesame-to-tahini')?.finalProduct,
        'الطحينة',
      );
      expect(ManufacturingRouteCatalog.findById('missing-route'), isNull);
    });

    test('finds a route by raw material without surrounding whitespace', () {
      expect(
        ManufacturingRouteCatalog.findByRawMaterial('  القطن  ')?.id,
        'cotton-to-garment',
      );
      expect(
        ManufacturingRouteCatalog.findByRawMaterial('منتجات جلدية')?.id,
        'hides-to-leather-goods',
      );
      expect(ManufacturingRouteCatalog.findByRawMaterial('   '), isNull);
      expect(ManufacturingRouteCatalog.findByRawMaterial('مادة غير معروفة'), isNull);
    });
  });
}
