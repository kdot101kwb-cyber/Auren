import 'package:cloud_firestore/cloud_firestore.dart';

class AurenBusinessAnalytics {
  final int views, saves, reviews, contacts, totalEvents;
  final DateTime? latestActivity;
  const AurenBusinessAnalytics({required this.views,required this.saves,required this.reviews,required this.contacts,required this.totalEvents,this.latestActivity});
  int get engagement => saves + reviews + contacts;
  double get engagementRate => views == 0 ? 0 : engagement / views * 100;
}

class BusinessAnalyticsService {
  final FirebaseFirestore _db;
  BusinessAnalyticsService({FirebaseFirestore? firestore}):_db=firestore??FirebaseFirestore.instance;

  Stream<AurenBusinessAnalytics> watchBusiness(String businessId) => _db
      .collection('businesses').doc(businessId).collection('events')
      .orderBy('createdAt', descending:true).limit(500).snapshots().map((events) {
    var views=0, saves=0, reviews=0, contacts=0; DateTime? latest;
    for(final event in events.docs){
      final data=event.data();
      switch(data['type']){
        case 'save': saves++; break;
        case 'review': reviews++; break;
        case 'contact': contacts++; break;
        default: views++;
      }
      final ts=data['createdAt'];
      if(ts is Timestamp){final d=ts.toDate(); if(latest==null||d.isAfter(latest!)) latest=d;}
    }
    return AurenBusinessAnalytics(views:views,saves:saves,reviews:reviews,contacts:contacts,totalEvents:events.docs.length,latestActivity:latest);
  });
}
