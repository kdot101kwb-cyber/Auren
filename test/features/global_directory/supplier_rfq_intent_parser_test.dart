import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/global_directory/domain/supplier_rfq_intent_parser.dart';
void main(){
 group('SupplierRfqIntentParser',(){
  test('extracts English request fields',(){
   final r=SupplierRfqIntentParser.parse('I need 500 cotton shirts delivered to Khartoum, Sudan with a budget of \$1200 within 14 days');
   expect(r.quantity,'500 pieces'); expect(r.unit,'pieces'); expect(r.destination,'Khartoum, Sudan'); expect(r.budget,'1200'); expect(r.currency,'USD'); expect(r.leadTime,'14 days'); expect(r.product,contains('cotton shirts')); expect(r.missingRequiredFields,isEmpty);
  });
  test('normalizes Arabic digits and extracts Arabic fields',(){
   final r=SupplierRfqIntentParser.parse('أحتاج ٥٠٠ قطعة قماش إلى الخرطوم بميزانية ١٢٠٠ دولار');
   expect(r.quantity,'500 pieces'); expect(r.destination,'الخرطوم'); expect(r.budget,'1200'); expect(r.currency,'USD'); expect(r.product,contains('قماش'));
  });
  test('reports missing required fields',(){
   final r=SupplierRfqIntentParser.parse('I need cotton shirts'); expect(r.product,'cotton shirts'); expect(r.missingRequiredFields,containsAll(['الكمية','وجهة التسليم']));
  });
  test('does not invent details for vague input',(){
   final r=SupplierRfqIntentParser.parse('hello'); expect(r.product,isNull); expect(r.quantity,isNull); expect(r.destination,isNull); expect(r.budget,isNull); expect(r.missingRequiredFields,hasLength(3));
  });
  test('supports currency codes without conversion',(){
   final r=SupplierRfqIntentParser.parse('need 20 boxes of tea to Nairobi budget KES 4500'); expect(r.currency,'KES'); expect(r.budget,'4500');
  });
 });
}