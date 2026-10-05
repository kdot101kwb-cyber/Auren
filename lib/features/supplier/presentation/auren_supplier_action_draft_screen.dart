import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../personal_ai/presentation/action_center_screen.dart';

class AurenSupplierActionDraftScreen extends StatefulWidget {
  final String supplierId;
  final String operation;
  final String intent;
  final String? matchFlowId;
  final Map<String, dynamic> initialPayload;

  const AurenSupplierActionDraftScreen({
    super.key, required this.supplierId, required this.operation,
    required this.intent, this.matchFlowId, this.initialPayload = const {},
  });

  @override State<AurenSupplierActionDraftScreen> createState() => _AurenSupplierActionDraftScreenState();
}

class _AurenSupplierActionDraftScreenState extends State<AurenSupplierActionDraftScreen> {
  late final TextEditingController _message, _product, _quantity, _unit, _currency, _notes;
  String _channel = 'draft';
  String? _actionId;
  bool _busy = false;
  bool get _isRfq => widget.operation == 'rfq';

  @override void initState() {
    super.initState();
    final p = widget.initialPayload;
    _message = TextEditingController(text: '${p['message'] ?? ''}');
    _product = TextEditingController(text: '${p['product'] ?? ''}');
    _quantity = TextEditingController(text: '${p['quantity'] ?? ''}');
    _unit = TextEditingController(text: '${p['unit'] ?? ''}');
    _currency = TextEditingController(text: '${p['currency'] ?? ''}');
    _notes = TextEditingController(text: '${p['notes'] ?? widget.intent}');
  }
  @override void dispose() { for (final c in [_message,_product,_quantity,_unit,_currency,_notes]) c.dispose(); super.dispose(); }

  Future<String> _createAction() async {
    final call = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('createAurenMatchAction');
    final payload = <String,dynamic>{'operation':widget.operation,'supplierId':widget.supplierId,'channel':_channel};
    
    if (_isRfq) { payload.addAll({'product':_product.text.trim(),'quantity':_quantity.text.trim(),'unit':_unit.text.trim(),'currency':_currency.text.trim().toUpperCase(),'notes':_notes.text.trim()}); }
    else { payload['message'] = _message.text.trim(); }
    final result = await call.call({'operation': widget.operation, 'payload': payload});
    final data = Map<String,dynamic>.from(result.data as Map);
    final id = '${data['actionId'] ?? ''}'.trim();
    if (id.isEmpty) throw StateError('لم يتم إنشاء الإجراء.');
    return id;
  }

  Future<void> _saveDraft() async {
    if (_busy) return;
    if (_isRfq && (_product.text.trim().isEmpty || _quantity.text.trim().isEmpty)) { _show('أدخل المنتج والكمية أولاً.'); return; }
    if (!_isRfq && _message.text.trim().isEmpty) { _show('اكتب رسالة التواصل أولاً.'); return; }
    setState(() => _busy=true);
    try { final id=await _createAction(); if(!mounted)return; setState(() => _actionId=id); _show('تم حفظ المسودة. لم يتم إرسالها.'); }
    catch(e){_show('تعذر حفظ المسودة: $e');} finally{if(mounted)setState(()=>_busy=false);}
  }

  void _show(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
  Widget _field(String label,TextEditingController c,{int min=1,int max=3,TextInputType? keyboard})=>Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:c,minLines:min,maxLines:max,keyboardType:keyboard,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));

  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:Text(_isRfq?'مسودة طلب عرض سعر':'مسودة تواصل')),body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.auto_awesome)),title:Text(_isRfq?'راجع RFQ قبل الموافقة':'راجع رسالة التواصل قبل الموافقة',style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:const Text('AUREN لا تنفذ الإجراء الحساس إلا بعد موافقة صريحة منك.'))),
      const SizedBox(height:12),
      if(_isRfq)...[_field('المنتج',_product),_field('الكمية',_quantity,keyboard:const TextInputType.numberWithOptions(decimal:true)),_field('الوحدة',_unit),_field('العملة',_currency),_field('ملاحظات',_notes,min:3,max:6)] else ...[_field('رسالة التواصل',_message,min:5,max:9)],
      DropdownButtonFormField<String>(value:_channel,decoration:const InputDecoration(labelText:'القناة',border:OutlineInputBorder()),items:const[DropdownMenuItem(value:'draft',child:Text('مسودة داخل AUREN'))],onChanged:_busy?null:(v){if(v!=null)setState(()=>_channel=v);}),
      const SizedBox(height:16),
      if(_actionId==null) FilledButton.icon(onPressed:_busy?null:_saveDraft,icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save_outlined),label:const Text('حفظ المسودة'))
      else ...[
        FilledButton.icon(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AurenActionCenterScreen())), icon: const Icon(Icons.shield_outlined), label: const Text('فتح Action Center للموافقة')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _busy ? null : () => setState(() => _actionId = null), icon: const Icon(Icons.edit_outlined), label: const Text('تعديل المسودة')),
      ],
      if(_actionId!=null)...[const SizedBox(height:10),const Text('المسودة محفوظة كإجراء معلّق. الموافقة والتنفيذ يتمان من Action Center باستخدام نظام AUREN الموحد.',textAlign:TextAlign.center)],
    ]));
  }
}