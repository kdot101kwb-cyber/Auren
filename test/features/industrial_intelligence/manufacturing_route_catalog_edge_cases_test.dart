import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/industrial_intelligence/domain/manufacturing_route_catalog.dart';

void main() {
  group('ManufacturingRouteCatalog integrity edge cases', () {
    test('every route and stage has complete planning metadata', () {
      for (final route in ManufacturingRouteCatalog.routes) {
        expect(route.id.trim(), isNotEmpty, reason: 'Route ID must be present');
        expect(route.overview.trim(), isNotEmpty, reason: route.id);
        expect(route.rawMaterial.trim(), isNotEmpty, reason: route.id);
        expect(route.finalProduct.trim(), isNotEmpty, reason: route.id);
        expect(route.prerequisites, isNotEmpty, reason: route.id);
        expect(
          route.prerequisites.every((item) => item.trim().isNotEmpty),
          isTrue,
          reason: 'Prerequisites must not contain blank entries: ${route.id}',
        );

        for (var index = 0; index < route.stages.length; index++) {
          final stage = route.stages[index];
          final context = '${route.id} stage $index';
          expect(stage.name.trim(), isNotEmpty, reason: context);
          expect(stage.purpose.trim(), isNotEmpty, reason: context);
          expect(stage.typicalInputs, isNotEmpty, reason: context);
          expect(stage.typicalOutputs, isNotEmpty, reason: context);
          expect(stage.considerations, isNotEmpty, reason: context);
          expect(
            [...stage.typicalInputs, ...stage.typicalOutputs, ...stage.considerations]
                .every((item) => item.trim().isNotEmpty),
            isTrue,
            reason: 'Stage metadata must not contain blank entries: $context',
          );
        }
      }
    });

    test('route identifiers resolve to the exact catalog route instances', () {
      for (final route in ManufacturingRouteCatalog.routes) {
        expect(ManufacturingRouteCatalog.findById(route.id), same(route));
      }
    });

    test('route IDs are unique regardless of letter case', () {
      final normalizedIds = ManufacturingRouteCatalog.routes
          .map((route) => route.id.trim().toLowerCase())
          .toList();
      expect(normalizedIds.toSet().length, normalizedIds.length);
    });

    test('every route can be found by its raw material and final product', () {
      for (final route in ManufacturingRouteCatalog.routes) {
        expect(
          ManufacturingRouteCatalog.findByRawMaterial(route.rawMaterial),
          same(route),
          reason: 'Raw material lookup for ${route.id}',
        );
        expect(
          ManufacturingRouteCatalog.findByRawMaterial(route.finalProduct),
          same(route),
          reason: 'Final product lookup for ${route.id}',
        );
      }
    });

    test('route ID lookup trims whitespace and ignores case', () {
      expect(ManufacturingRouteCatalog.findById(' SESAME-TO-TAHINI ')?.id,
          'sesame-to-tahini');
      expect(ManufacturingRouteCatalog.findById('COTTON-TO-GARMENT')?.id,
          'cotton-to-garment');
    });

    test('route ID lookup rejects blank and unknown identifiers safely', () {
      expect(ManufacturingRouteCatalog.findById(''), isNull);
      expect(ManufacturingRouteCatalog.findById('  \t '), isNull);
      expect(ManufacturingRouteCatalog.findById('not-a-route'), isNull);
    });

    test('raw material lookup accepts route IDs without case sensitivity', () {
      expect(
        ManufacturingRouteCatalog.findByRawMaterial('SESAME-TO-TAHINI')?.id,
        'sesame-to-tahini',
      );
      expect(
        ManufacturingRouteCatalog.findByRawMaterial('  cotton-to-garment  ')?.id,
        'cotton-to-garment',
      );
    });

    test('raw material lookup rejects empty and unknown input safely', () {
      expect(ManufacturingRouteCatalog.findByRawMaterial(''), isNull);
      expect(ManufacturingRouteCatalog.findByRawMaterial('   '), isNull);
      expect(ManufacturingRouteCatalog.findByRawMaterial('\t\n'), isNull);
      expect(ManufacturingRouteCatalog.findByRawMaterial('unknown material'), isNull);
    });
  });
}
