import 'package:cloud_functions/cloud_functions.dart';

class AurenSupplierRequest {
  final String id,type,status,supplierName,supplierId,product,quantity,message,currency,matchFlowId,lastError;
  final bool externalDispatch; final int retryCount;
  const AurenSupplierRequest({required this.id,required this.type,required this.status,required this.supplierName,required this.supplierId,required this.product,required this.quantity,required this.message,required this.currency,required this.matchFlowId,required this.lastError,required this.externalDispatch,required this.retryCount});
  factory AurenSupplierRequest.fromMap(Map<String,dynamic> d)=>AurenSupplierRequest(
    id:d['id']?.toString()??'',type:d['type']?.toString()??'contact',status:d['status']?.toString()??'draft',
    supplierName:(d['supplierName']??d['supplierId']??'').toString(),supplierId:d['supplierId']?.toString()??'',
    product:d['product']?.toString()??'',quantity:d['quantity']?.toString()??'',message:d['message']?.toString()??'',
    currency:d['currency']?.toString()??'',matchFlowId:d['matchFlowId']?.toString()??'',lastError:d['lastError']?.toString()??'',
    externalDispatch:d['externalDispatch']==true,retryCount:int.tryParse(d['retryCount']?.toString()??'0')??0);
  String get title=>type=='rfq'?(product.isEmpty?'طلب عرض سعر':product):'طلب تواصل';
}
class AurenSupplierRequestsRepository {
  final FirebaseFunctions _functions;
  AurenSupplierRequestsRepository({FirebaseFunctions? functions}):_functions=functions??FirebaseFunctions.instanceFor(region:'us-central1');
  Future<List<AurenSupplierRequest>> list({String? status,int limit=30}) async {
    final r=await _functions.httpsCallable('listAurenSupplierRequests').call({if(status!=null&&status.isNotEmpty)'status':status,'limit':limit});
    final rows=(Map<String,dynamic>.from(r.data as Map)['requests'] as List?)??const [];
    return rows.map((e)=>AurenSupplierRequest.fromMap(Map<String,dynamic>.from(e as Map))).toList();
  }
  Future<AurenSupplierRequest> get({required String id,required String type}) async {
    final r=await _functions.httpsCallable('getAurenSupplierRequest').call({'requestId':id,'type':type});
    return AurenSupplierRequest.fromMap(Map<String,dynamic>.from(r.data as Map));
  }
  Future<void> cancel(AurenSupplierRequest r) async{await _functions.httpsCallable('cancelAurenSupplierRequest').call({'requestId':r.id,'type':r.type});}
  Future<void> retry(AurenSupplierRequest r) async{await _functions.httpsCallable('retryAurenSupplierRequest').call({'requestId':r.id,'type':r.type});}
  Future<void> updateStatus(AurenSupplierRequest r,String status) async{await _functions.httpsCallable('updateAurenSupplierRequestStatus').call({'requestId':r.id,'type':r.type,'status':status});}
}
