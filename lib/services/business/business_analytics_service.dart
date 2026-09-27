import 'package:cloud_firestore/cloud_firestore.dart';

class AurenBusinessAnalytics {
  final int views, saves, reviews, contacts, leads, messages, totalEvents, products;
  final DateTime? latestActivity;
  const AurenBusinessAnalytics({required this.views,required this.saves,required this.reviews,required this.contacts,required this.leads,required this.messages,required this.totalEvents,required this.products,this.latestActivity});
  int get engagement => saves + reviews + contacts + leads + messages;
  double get engagementRate => views == 0 ? 0 : engagement / views * 100;
}

class BusinessAnalyticsService {
  final FirebaseFirestore _db;
  BusinessAnalyticsService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;

  Stream<AurenBusinessAnalytics> watchBusiness(String businessId) => _db
      .collection('businesses').doc(businessId).collection('events')
      .orderBy('createdAt', descending:true).limit(500).snapshots().map((events) {
    var views=0, saves=0, reviews=0, contacts=0, leads=0, messages=0; DateTime? latest;
    for(final event in events.docs){
      final data=event.data();
      switch(data['type']){
        case 'save': saves++; break;
        case 'review': reviews++; break;
        case 'contact': contacts++; break;
        case 'lead': leads++; break;
        case 'message': messages++; break;
        case 'view': views++; break;
      }
      final ts=data['createdAt'];
      if(ts is Timestamp){final d=ts.toDate(); if(latest==null||d.isAfter(latest!)) latest=d;}
    }
    return AurenBusinessAnalytics(views:views,saves:saves,reviews:reviews,contacts:contacts,leads:leads,messages:messages,totalEvents:events.docs.length,products:0,latestActivity:latest);
  });

  Future<int> productCount(String businessId) async => (await _db.collection('products').where('businessId',isEqualTo:businessId).limit(100).get()).docs.length;
}
