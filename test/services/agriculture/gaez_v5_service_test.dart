import 'package:flutter_test/flutter_test.dart';
import 'package:auren/services/agriculture/gaez_v5_service.dart';

void main() {
  test('builds the official RES05 raster URL', () {
    final service = AurenGaezV5Service();
    final url = service.buildRasterUrl(
      mapset: 'RES05-ETL',
      period: 'HP0120',
      climate: 'AGERA5',
      scenario: 'HIST',
      crop: 'ALF',
      input: 'HILM',
    );

    expect(url,
        'https://storage.googleapis.com/fao-gismgr-gaez-v5-data/DATA/GAEZ-V5/MAPSET/RES05-ETL/GAEZ-V5.RES05-ETL.HP0120.AGERA5.HIST.ALF.HILM.tif');
  });

  test('describes a historical crop dataset', () {
    final result = AurenGaezV5Service().historicalCropDataset(crop: 'ALF');
    expect(result['source'], 'FAO/IIASA GAEZ v5');
    expect(result['resource'], 'RES05');
    expect(result['period'], 'HP0120');
    expect(result['climate'], 'AGERA5');
    expect(result['scenario'], 'HIST');
    expect(result['crop'], 'ALF');
    expect(result['input'], 'HRLM');
  });
}