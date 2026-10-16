import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/events/auren_events_repository.dart';
import '../domain/auren_event.dart';

class AurenEventsScreen extends StatefulWidget {
  const AurenEventsScreen({super.key});
  @override
  State<AurenEventsScreen> createState() => _AurenEventsScreenState();
}

class _AurenEventsScreenState extends State<AurenEventsScreen> {
  final _repository = AurenEventsRepository();
  bool _creating = false;

  Future<void> _createEvent() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { _message('سجّل الدخول لإنشاء فعالية.'); return; }
    final title = TextEditingController();
    final description = TextEditingController();
    final location = TextEditingController();
    final capacity = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime start = DateTime.now().add(const Duration(days: 1));
    DateTime end = start.add(const Duration(hours: 2));
    final input = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('إنشاء فعالية'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: title, maxLength: 120, decoration: const InputDecoration(labelText: 'اسم الفعالية'),
              validator: (v) => v == null || v.trim().isEmpty ? 'اكتب اسم الفعالية' : null),
            TextFormField(controller: description, maxLength: 1000, minLines: 2, maxLines: 4,
              decoration: const InputDecoration(labelText: 'الوصف')),
            TextFormField(controller: location, maxLength: 180, decoration: const InputDecoration(labelText: 'المكان (اختياري)')),
            TextFormField(controller: capacity, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'عدد المشاركين (اختياري)', helperText: 'اتركه فارغاً دون حد للسعة'),
              validator: (v) { if (v == null || v.trim().isEmpty) return null; final n = int.tryParse(v.trim()); return n == null || n <= 0 ? 'أدخل عدداً أكبر من صفر' : null; }),
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('بداية الفعالية'), subtitle: Text(_dateLabel(start)),
              trailing: const Icon(Icons.calendar_month_outlined), onTap: () async {
                final date = await showDatePicker(context: context, initialDate: start, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
                if (time == null) return;
                setDialogState(() { start = DateTime(date.year, date.month, date.day, time.hour, time.minute); if (!end.isAfter(start)) end = start.add(const Duration(hours: 2)); });
              }),
            ListTile(contentPadding: EdgeInsets.zero, title: const Text('نهاية الفعالية'), subtitle: Text(_dateLabel(end)),
              trailing: const Icon(Icons.event_available_outlined), onTap: () async {
                final date = await showDatePicker(context: context, initialDate: end.isAfter(start) ? end : start, firstDate: start, lastDate: start.add(const Duration(days: 30)));
                if (date == null || !context.mounted) return;
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(end));
                if (time == null) return;
                setDialogState(() => end = DateTime(date.year, date.month, date.day, time.hour, time.minute));
              }),
          ]),
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            if (!formKey.currentState!.validate()) return;
            if (!start.isAfter(DateTime.now()) || !end.isAfter(start)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تأكد أن البداية في المستقبل والنهاية بعدها.'))); return;
            }
            Navigator.pop(dialogContext, {'title': title.text.trim(), 'description': description.text.trim(),
              'location': location.text.trim(), 'capacity': capacity.text.trim().isEmpty ? null : int.parse(capacity.text.trim()),
              'start': start, 'end': end});
          }, child: const Text('إنشاء')),
        ],
      )),
    );
    title.dispose(); description.dispose(); location.dispose(); capacity.dispose();
    if (input == null || !mounted) return;
    setState(() => _creating = true);
    try {
      await _repository.create(ownerId: uid, title: input['title'] as String,
        description: input['description'] as String, locationLabel: input['location'] as String,
        capacity: input['capacity'] as int?, startsAt: input['start'] as DateTime, endsAt: input['end'] as DateTime);
      _message('تم إنشاء الفعالية.');
    } catch (error) { _message('تعذر إنشاء الفعالية: $error'); }
    finally { if (mounted) setState(() => _creating = false); }
  }

  Future<void> _register(AurenEvent event) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { _message('سجّل الدخول للتسجيل في الفعالية.'); return; }
    try {
      final status = await _repository.register(eventId: event.id, userId: uid);
      if (!mounted) return;
      setState(() {});
      _message(status == AurenEventRsvpStatus.going ? 'تم تسجيلك كمشارك.'
        : status == AurenEventRsvpStatus.waitlisted ? 'اكتملت السعة؛ أُضيف اسمك إلى قائمة الانتظار.'
        : 'تسجيلك محفوظ.');
    } catch (error) { _message('تعذر التسجيل: $error'); }
  }

  Future<void> _cancelRegistration(AurenEvent event) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _message('سجّل الدخول لإدارة تسجيلك.');
      return;
    }
    try {
      await _repository.cancelRegistration(eventId: event.id, userId: uid);
      _message('تم إلغاء تسجيلك.');
      if (mounted) setState(() {});
    } catch (error) {
      _message('تعذر إلغاء التسجيل: $error');
    }
  }

  void _message(String value) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value))); }
  String _dateLabel(DateTime date) { final d = date.toLocal(); return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}'; }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('الفعاليات والتجارب')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _creating ? null : _createEvent,
        icon: _creating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
        label: const Text('إنشاء فعالية')),
      body: StreamBuilder<List<AurenEvent>>(stream: _repository.watchPublicEvents(), builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الفعاليات. تحقق من الاتصال والصلاحيات.'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final events = snapshot.data!;
        if (events.isEmpty) return ListView(padding: const EdgeInsets.all(24), children: const [
          SizedBox(height: 70), Icon(Icons.event_available_outlined, size: 56), SizedBox(height: 16),
          Center(child: Text('ما في فعاليات منشورة حالياً.')), SizedBox(height: 8),
          Center(child: Text('أنشئ أول فعالية وادعُ مجتمعك للمشاركة.')),
        ]);
        return ListView.separated(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, index) {
            final event = events[index];
            return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const CircleAvatar(child: Icon(Icons.event_outlined)), const SizedBox(width: 10),
                Expanded(child: Text(event.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                if (event.hostId == uid) const Chip(label: Text('من تنظيمك'))]),
              if (event.description.isNotEmpty) ...[const SizedBox(height: 8), Text(event.description)],
              const SizedBox(height: 8), Text('البداية: ${_dateLabel(event.startsAt)}'), Text('النهاية: ${_dateLabel(event.endsAt)}'),
              if (event.locationLabel != null) Text('المكان: ${event.locationLabel}'),
              if (event.capacity != null) Text('السعة: ${event.capacity} مشارك'),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: uid == null
                    ? FilledButton.tonalIcon(
                        onPressed: event.hostId == uid || !event.isUpcoming
                            ? null
                            : () => _register(event),
                        icon: const Icon(Icons.how_to_reg_outlined),
                        label: const Text('سجّل للمشاركة'),
                      )
                    : event.hostId == uid
                        ? const Chip(label: Text('أنت منظّم الفعالية'))
                        : FutureBuilder<AurenEventRsvpStatus?>(
                            future: _repository.getRegistrationStatus(
                              eventId: event.id,
                              userId: uid,
                            ),
                            builder: (context, registrationSnapshot) {
                              if (registrationSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const OutlinedButton(
                                  onPressed: null,
                                  child: Text('جارٍ التحقق من التسجيل...'),
                                );
                              }
                              final status = registrationSnapshot.data;
                              if (status == AurenEventRsvpStatus.going ||
                                  status == AurenEventRsvpStatus.waitlisted) {
                                return FilledButton.tonalIcon(
                                  onPressed: event.isUpcoming
                                      ? () => _cancelRegistration(event)
                                      : null,
                                  icon: const Icon(Icons.event_busy_outlined),
                                  label: Text(
                                    status == AurenEventRsvpStatus.going
                                        ? 'إلغاء التسجيل'
                                        : 'الانسحاب من قائمة الانتظار',
                                  ),
                                );
                              }
                              if (status == AurenEventRsvpStatus.cancelled) {
                                return FilledButton.tonalIcon(
                                  onPressed: event.isUpcoming
                                      ? () => _register(event)
                                      : null,
                                  icon: const Icon(Icons.how_to_reg_outlined),
                                  label: const Text('إعادة التسجيل'),
                                );
                              }
                              return FilledButton.tonalIcon(
                                onPressed: event.isUpcoming
                                    ? () => _register(event)
                                    : null,
                                icon: const Icon(Icons.how_to_reg_outlined),
                                label: const Text('سجّل للمشاركة'),
                              );
                            },
                          ),
              ),
            ])));
          });
      }),
    );
  }
}
