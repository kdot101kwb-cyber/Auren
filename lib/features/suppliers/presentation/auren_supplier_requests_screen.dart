import 'package:flutter/material.dart';
import '../../../services/suppliers/auren_supplier_requests_repository.dart';

class AurenSupplierRequestsScreen extends StatefulWidget {
  const AurenSupplierRequestsScreen({super.key});
  @override State<AurenSupplierRequestsScreen> createState()=>_AurenSupplierRequestsScreenState();
}
class _AurenSupplierRequestsScreenState extends State<AurenSupplierRequestsScreen> {
  final _repo=AurenSupplierRequestsRepository(); Future<List<AurenSupplierRequest>>? _future; String _filter='all';
  @override void initState(){super.initState();_load();}
  void _load(){_future=_repo.list(status:_filter=='all'?null:_filter);}
  Future<void> _refresh() async{setState(_load);try{await _future;}catch(_){ }if(mounted)setState((){});}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('طلبات الموردين'),actions:[IconButton(onPressed:_refresh,icon:const Icon(Icons.refresh))]),
    body:Column(children:[
      SingleChildScrollView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.all(12),child:Row(children:[
        for(final e in const {'all':'الكل','draft':'مسودة','waiting_response':'بانتظار الرد','replied':'تم الرد','completed':'مكتمل','failed':'فشل','cancelled':'ملغى'}.entries)
          Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(e.value),selected:_filter==e.key,onSelected:(_){setState((){_filter=e.key;_load();});})),
      ])),
      Expanded(child:FutureBuilder<List<AurenSupplierRequest>>(future:_future,builder:(c,s){
        if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
        if(s.hasError)return _message('تعذر تحميل طلبات الموردين.',_refresh);
        final rows=s.data??const <AurenSupplierRequest>[];
        if(rows.isEmpty)return _message('لا توجد طلبات في هذه الحالة.');
        return RefreshIndicator(onRefresh:_refresh,child:ListView.separated(padding:const EdgeInsets.all(12),itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(_,i)=>_card(rows[i])));
      })),
    ]));
  Widget _card(AurenSupplierRequest r)=>Card(child:ListTile(
    leading:CircleAvatar(child:Icon(r.type=='rfq'?Icons.request_quote_outlined:Icons.storefront_outlined)),
    title:Text(r.title,maxLines:1,overflow:TextOverflow.ellipsis),
    subtitle:Text([r.supplierName,_status(r.status),if(r.status=='waiting_response'&&!r.externalDispatch)'لم يُرسل خارجياً'].where((x)=>x.isNotEmpty).join(' • '),maxLines:3),
    trailing:PopupMenuButton<String>(onSelected:(a)=>_action(a,r),itemBuilder:(_)=>[
      const PopupMenuItem(value:'details',child:Text('التفاصيل')),
      if(r.status!='completed'&&r.status!='cancelled')const PopupMenuItem(value:'cancel',child:Text('إلغاء')),
      if((r.status=='failed'||r.status=='cancelled')&&r.retryCount<5)const PopupMenuItem(value:'retry',child:Text('إعادة المحاولة')),
      if(r.status=='draft'||r.status=='waiting_response')const PopupMenuItem(value:'failed',child:Text('تسجيل فشل')),
      if(r.externalDispatch&&r.status=='waiting_response')const PopupMenuItem(value:'replied',child:Text('تسجيل الرد')),
      if(r.status=='replied')const PopupMenuItem(value:'completed',child:Text('إكمال الطلب')),
    ]),onTap:()=>_details(r)));
  Future<void> _action(String a,AurenSupplierRequest r) async{
    if(a=='details'){await _details(r);return;}
    if(a=='cancel'){
      final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
        title:const Text('إلغاء طلب المورد؟'),
        content:const Text('سيتم إلغاء الطلب داخل AUREN ولن يتم إرسال أي رسالة خارجية.'),
        actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('إلغاء الطلب'))],
      ));
      if(ok!=true)return;
    }
    if(a=='replied'||a=='completed'||a=='failed'){
      final label=a=='replied'?'تسجيل أن المورد رد؟':a=='failed'?'تسجيل فشل الطلب؟':'إكمال الطلب؟';
      final content=a=='failed'?'سيُسجل الطلب كفاشل داخل AUREN فقط، دون إرسال أي رسالة خارجية.':'سيتم تحديث الحالة داخل AUREN فقط.';
      final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(label),content:Text(content),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('تأكيد'))]));
      if(ok==true){try{await _repo.updateStatus(r,a);if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(a=='failed'?'تم تسجيل فشل الطلب.':'تم تحديث الحالة.')));setState(_load);}}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر تحديث الحالة.')));}} 
      return;
    }
    if(a=='retry'){
      final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
        title:const Text('إعادة المحاولة؟'),
        content:const Text('سيعود الطلب إلى مسودة. لن يتم الإرسال الخارجي تلقائياً.'),
        actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('رجوع')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('إعادة المحاولة'))],
      ));
      if(ok!=true)return;
    }
    try{
      if(a=='cancel')await _repo.cancel(r);if(a=='retry')await _repo.retry(r);
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(a=='cancel'?'تم إلغاء الطلب.':'تمت إعادة الطلب إلى المسودة.')));setState(_load);}
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر تنفيذ العملية. حاول مرة أخرى.')));}
  }
  Future<void> _details(AurenSupplierRequest r)=>showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(_)=>SafeArea(child:Padding(
    padding:const EdgeInsets.all(20),child:ListView(shrinkWrap:true,children:[
      Text(r.supplierName.isEmpty?'المورد':r.supplierName,style:Theme.of(context).textTheme.titleLarge),
      const SizedBox(height:12),_row('النوع',r.type=='rfq'?'طلب عرض سعر':'تواصل'),_row('الحالة',_status(r.status)),
      if(r.product.isNotEmpty)_row('المنتج',r.product),if(r.quantity.isNotEmpty)_row('الكمية',r.quantity),if(r.currency.isNotEmpty)_row('العملة',r.currency),if(r.message.isNotEmpty)_row('الرسالة',r.message),
      _row('الإرسال الخارجي',r.externalDispatch?'تم الإرسال':'غير مُرسل'),if(r.retryCount>0)_row('المحاولات',r.retryCount.toString()),if(r.matchFlowId.isNotEmpty)_row('Match Flow',r.matchFlowId),
      if(r.status=='failed')Card(child:Padding(padding:const EdgeInsets.all(12),child:Text(r.lastError.isNotEmpty?'سبب الفشل: ${r.lastError}${r.retryCount>=5?'\nتم بلوغ الحد الأقصى لإعادة المحاولة (5).':'\nيمكنك استخدام «إعادة المحاولة».'}':'حدث فشل في الطلب.${r.retryCount>=5?' تم بلوغ الحد الأقصى لإعادة المحاولة (5).':' يمكنك استخدام «إعادة المحاولة».'}'))),
      if(r.retryCount>=5)_row('حد المحاولات','اكتملت 5 محاولات؛ لا يمكن إعادة المحاولة مرة أخرى.'),
      if(r.status=='waiting_response'&&!r.externalDispatch)const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('الحالة «بانتظار الرد» تعني أن Match Flow ينتظر الخطوة التالية؛ الطلب محفوظ داخل AUREN ولم يتم إرسال رسالة خارجية بعد.'))),
    ]))));
  Widget _row(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:110,child:Text(a,style:const TextStyle(fontWeight:FontWeight.bold))),Expanded(child:Text(b))]));
  Widget _message(String t,[Future<void> Function()? action])=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(t),if(action!=null)FilledButton.icon(onPressed:action,icon:const Icon(Icons.refresh),label:const Text('إعادة المحاولة'))]));
  String _status(String v)=>const {'draft':'مسودة','waiting_response':'بانتظار الرد','replied':'تم الرد','completed':'مكتمل','failed':'فشل','cancelled':'ملغى'}[v]??v;
}
