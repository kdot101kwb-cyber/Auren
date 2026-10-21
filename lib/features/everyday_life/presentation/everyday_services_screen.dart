import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/everyday/appointment_draft_service.dart';
import '../../../services/everyday/appointment_draft_store.dart';
import '../../../services/everyday/household_maintenance_service.dart';
import '../../../services/everyday/household_maintenance_store.dart';
import '../../../services/everyday/trip_itinerary_service.dart';
import '../../../services/everyday/journey_itinerary_store.dart';
import '../../../services/everyday/home_utility_ledger_service.dart';
import '../../../services/everyday/home_utility_reading_store.dart';

/// Local-only household planning. This screen never books or contacts providers.
class AurenEverydayServicesScreen extends StatefulWidget {
  const AurenEverydayServicesScreen({super.key, this.uidOverride, this.useUidOverride = false});
  final String? uidOverride;
  final bool useUidOverride;
  @override State<AurenEverydayServicesScreen> createState() => _AurenEverydayServicesScreenState();
}
class _AurenEverydayServicesScreenState extends State<AurenEverydayServicesScreen> {
  int tab = 0;
  @override Widget build(BuildContext context) {
    final uid = widget.useUidOverride ? widget.uidOverride : FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Everyday Life & Services')),
      body: uid == null
        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('سجّل الدخول لحفظ بياناتك اليومية بأمان وفصلها عن المستخدمين الآخرين.')))
        : IndexedStack(index: tab, children: [
            _Appointments(uid: uid), _Maintenance(uid: uid), _Trips(uid: uid), _Meters(uid: uid),
          ]),
      bottomNavigationBar: uid == null ? null : NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab=v), destinations: const [
        NavigationDestination(icon: Icon(Icons.event_note), label: 'المواعيد'),
        NavigationDestination(icon: Icon(Icons.home_repair_service), label: 'الصيانة'),
        NavigationDestination(icon: Icon(Icons.route), label: 'الرحلات'),
        NavigationDestination(icon: Icon(Icons.speed), label: 'العدادات'),
      ]),
    );
  }
}

class _Appointments extends StatefulWidget { const _Appointments({required this.uid}); final String uid; @override State<_Appointments> createState()=>_AppointmentsState(); }
class _AppointmentsState extends State<_Appointments> {
  final store=AurenAppointmentDraftStore(); final title=TextEditingController(); final notes=TextEditingController();
  List<AurenAppointmentDraft> rows=[]; String? error; bool loading=true;
  @override void initState(){super.initState();load();}
  @override void dispose(){title.dispose();notes.dispose();super.dispose();}
  Future<void> load() async {try{final v=await store.loadDrafts(widget.uid);if(mounted)setState(()=>rows=v);}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> add() async {try{await store.saveDraft(widget.uid,AurenAppointmentDraft(id:DateTime.now().microsecondsSinceEpoch.toString(),title:title.text.trim(),startsAt:DateTime.now().add(const Duration(hours:1)),notes:notes.text.trim()));title.clear();notes.clear();error=null;await load();}catch(e){setState(()=>error=e.toString());}}
  Future<void> change(AurenAppointmentDraft r,AppointmentDraftStatus s) async {try{await store.transitionDraft(widget.uid,r.id,s);await load();}catch(e){setState(()=>error=e.toString());}}
  @override Widget build(BuildContext context)=>_Page(title:'مسودات المواعيد',description:'مسودة محلية فقط؛ لا يتم الاتصال بمقدم خدمة أو تأكيد حجز.',loading:loading,error:error,children:[
    TextField(controller:title,decoration:const InputDecoration(labelText:'عنوان الموعد')),
    TextField(controller:notes,decoration:const InputDecoration(labelText:'ملاحظات')),
    FilledButton(onPressed:add,child:const Text('حفظ المسودة')),
    for(final r in rows) ListTile(title:Text(r.title),subtitle:Text(r.status.name+' • '+r.startsAt.toLocal().toString()),trailing:r.status==AppointmentDraftStatus.planned?PopupMenuButton<AppointmentDraftStatus>(onSelected:(s)=>change(r,s),itemBuilder:(_)=>const [PopupMenuItem(value:AppointmentDraftStatus.completed,child:Text('إكمال')),PopupMenuItem(value:AppointmentDraftStatus.cancelled,child:Text('إلغاء'))]):null),
  ]);
}

class _Maintenance extends StatefulWidget { const _Maintenance({required this.uid}); final String uid; @override State<_Maintenance> createState()=>_MaintenanceState(); }
class _MaintenanceState extends State<_Maintenance> {
  final store=AurenHouseholdMaintenanceStore(); final title=TextEditingController(); final area=TextEditingController(); final cost=TextEditingController();
  List<AurenMaintenanceTask> rows=[]; String? error; bool loading=true;
  @override void initState(){super.initState();load();}
  @override void dispose(){title.dispose();area.dispose();cost.dispose();super.dispose();}
  Future<void> load() async {try{final v=await store.loadTasks(widget.uid);if(mounted)setState(()=>rows=v);}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> add() async {final raw=cost.text.trim();final n=raw.isEmpty?null:int.tryParse(raw);if(raw.isNotEmpty&&n==null){setState(()=>error='أدخل تكلفة صحيحة.');return;}try{await store.saveTask(widget.uid,AurenMaintenanceTask(id:DateTime.now().microsecondsSinceEpoch.toString(),title:title.text.trim(),area:area.text.trim(),estimatedCostMinor:n));title.clear();area.clear();cost.clear();error=null;await load();}catch(e){setState(()=>error=e.toString());}}
  Future<void> change(AurenMaintenanceTask r,AurenMaintenanceStatus s) async {try{await store.transitionTask(widget.uid,r.id,s);await load();}catch(e){setState(()=>error=e.toString());}}
  @override Widget build(BuildContext context)=>_Page(title:'صيانة المنزل',description:'مهام وتكاليف محلية؛ لا يتم طلب خدمة أو توظيف فني.',loading:loading,error:error,children:[
    TextField(controller:title,decoration:const InputDecoration(labelText:'المهمة')),
    TextField(controller:area,decoration:const InputDecoration(labelText:'المكان')),
    TextField(controller:cost,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'التكلفة التقديرية (اختياري)')),
    FilledButton(onPressed:add,child:const Text('إضافة مهمة')),
    for(final r in rows) ListTile(title:Text(r.title),subtitle:Text(r.area+' • '+r.status.name),trailing:r.status==AurenMaintenanceStatus.completed||r.status==AurenMaintenanceStatus.cancelled?null:PopupMenuButton<AurenMaintenanceStatus>(onSelected:(s)=>change(r,s),itemBuilder:(_)=>[if(r.status==AurenMaintenanceStatus.planned)const PopupMenuItem(value:AurenMaintenanceStatus.inProgress,child:Text('بدء')),const PopupMenuItem(value:AurenMaintenanceStatus.completed,child:Text('إكمال')),const PopupMenuItem(value:AurenMaintenanceStatus.cancelled,child:Text('إلغاء'))])),
  ]);
}

class _Trips extends StatefulWidget { const _Trips({required this.uid}); final String uid; @override State<_Trips> createState()=>_TripsState(); }
class _TripsState extends State<_Trips> {
  final store=AurenTripItineraryStore(); final title=TextEditingController(); final location=TextEditingController(); List<AurenTripStop> rows=[]; String? error; bool loading=true;
  @override void initState(){super.initState();load();}
  @override void dispose(){title.dispose();location.dispose();super.dispose();}
  Future<void> load() async {try{final v=await store.loadStops(widget.uid);if(mounted)setState(()=>rows=v);}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> add() async {try{await store.saveStop(widget.uid,AurenTripStop(id:DateTime.now().microsecondsSinceEpoch.toString(),title:title.text.trim(),location:location.text.trim()));title.clear();location.clear();error=null;await load();}catch(e){setState(()=>error=e.toString());}}
  Future<void> toggle(AurenTripStop r,bool v) async {try{await store.setStopCompleted(widget.uid,r.id,v);await load();}catch(e){setState(()=>error=e.toString());}}
  @override Widget build(BuildContext context)=>_Page(title:'مخطط الرحلات',description:'محطات وقائمة إنجاز فقط؛ لا يتم حجز نقل أو فنادق أو تذاكر.',loading:loading,error:error,children:[
    TextField(controller:title,decoration:const InputDecoration(labelText:'اسم المحطة')),
    TextField(controller:location,decoration:const InputDecoration(labelText:'الموقع (اختياري)')),
    FilledButton(onPressed:add,child:const Text('إضافة محطة')),
    if(rows.isNotEmpty) LinearProgressIndicator(value:rows.where((r)=>r.completed).length/rows.length),
    for(final r in rows) CheckboxListTile(value:r.completed,onChanged:(v)=>toggle(r,v??false),title:Text(r.title),subtitle:r.location.isEmpty?null:Text(r.location)),
  ]);
}

class _Meters extends StatefulWidget { const _Meters({required this.uid}); final String uid; @override State<_Meters> createState()=>_MetersState(); }
class _MetersState extends State<_Meters> {
  final store=AurenHomeUtilityReadingStore(); final meter=TextEditingController(); final label=TextEditingController(); final value=TextEditingController(); final unit=TextEditingController(text:'kWh');
  AurenUtilityKind kind=AurenUtilityKind.electricity; List<AurenUtilityReading> rows=[]; String? error; bool loading=true;
  @override void initState(){super.initState();load();}
  @override void dispose(){meter.dispose();label.dispose();value.dispose();unit.dispose();super.dispose();}
  Future<void> load() async {try{final v=await store.loadReadings(widget.uid);if(mounted)setState(()=>rows=v);}catch(e){if(mounted)setState(()=>error=e.toString());}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> add() async {final n=double.tryParse(value.text.trim());if(n==null||!n.isFinite||n<0){setState(()=>error='أدخل قراءة رقمية صحيحة غير سالبة.');return;}try{await store.saveReading(widget.uid,AurenUtilityReading(id:DateTime.now().microsecondsSinceEpoch.toString(),meterId:meter.text.trim(),label:label.text.trim(),kind:kind,value:n,unit:unit.text.trim(),recordedAt:DateTime.now()));value.clear();error=null;await load();}catch(e){setState(()=>error=e.toString());}}
  String _usageFor(AurenUtilityReading row) {
    final series = AurenHomeUtilityLedger.ordered(rows.where((v) => v.meterId == row.meterId));
    final index = series.indexWhere((v) => v.id == row.id);
    if (index < 1) return '—';
    final previous = series[index - 1];
    if (row.value < previous.value || row.unit != previous.unit || row.kind != previous.kind) return 'غير متاح';
    return '+${(row.value - previous.value).toStringAsFixed(2)} ${row.unit}';
  }
  @override Widget build(BuildContext context)=>_Page(title:'عدادات المنزل',description:'سجل القراءات التراكمية واحسب فرق الاستهلاك عند توفر قراءتين متوافقتين.',loading:loading,error:error,children:[
    TextField(controller:meter,decoration:const InputDecoration(labelText:'معرّف العداد الثابت')),
    TextField(controller:label,decoration:const InputDecoration(labelText:'اسم العداد')),
    DropdownButtonFormField<AurenUtilityKind>(value:kind,decoration:const InputDecoration(labelText:'النوع'),items:const [DropdownMenuItem(value:AurenUtilityKind.electricity,child:Text('كهرباء')),DropdownMenuItem(value:AurenUtilityKind.water,child:Text('مياه')),DropdownMenuItem(value:AurenUtilityKind.gas,child:Text('غاز')),DropdownMenuItem(value:AurenUtilityKind.other,child:Text('أخرى'))],onChanged:(v)=>setState(()=>kind=v??AurenUtilityKind.electricity)),
    TextField(controller:value,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'القراءة الحالية')),
    TextField(controller:unit,decoration:const InputDecoration(labelText:'الوحدة (kWh أو m³)')),
    FilledButton(onPressed:add,child:const Text('حفظ القراءة')),
    for(final r in rows) ListTile(title:Text(r.label+': '+r.value.toString()+' '+r.unit),subtitle:Text(r.recordedAt.toLocal().toString()),trailing:Text(_usageFor(r))),
  ]);
}

class _Page extends StatelessWidget {
  const _Page({required this.title,required this.description,required this.loading,required this.error,required this.children});
  final String title,description; final bool loading; final String? error; final List<Widget> children;
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    Text(title,style:Theme.of(context).textTheme.headlineSmall),Text(description),
    if(error!=null) Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
    if(loading) const Center(child:CircularProgressIndicator()),
    const SizedBox(height:12),...children,
  ]);
}
