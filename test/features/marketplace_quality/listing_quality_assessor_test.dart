import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/marketplace_quality/domain/listing_quality_assessor.dart';
void main(){const a=ListingQualityAssessor();test('complete listing receives full score',(){final r=a.assess(const ListingDraft(title:'Phone',description:'Good used phone',price:20,currency:'USD',stock:1));expect(r.score,100);expect(r.isReady,isTrue);});test('invalid fields are all flagged',(){final r=a.assess(const ListingDraft(title:'x',description:'',price:0,currency:'US',stock:-1));expect(r.score,0);expect(r.issues,hasLength(5));});}
