import 'package:flutter/material.dart';

import '../../../services/low_data_policy.dart';
import '../data/everyday_life_local_store.dart';
import '../domain/everyday_life_item.dart';

class AurenEverydayLifeScreen extends StatefulWidget {
  const AurenEverydayLifeScreen({super.key});

  @override
  State<AurenEverydayLifeScreen> createState() => _AurenEverydayLifeScreenState();
}

class _AurenEverydayLifeScreenState extends State<AurenEverydayLifeScreen>
    with SingleTickerProviderStateMixin {
  final _store = EverydayLifeLocalStore();
  late final TabController _tabs;
  List<EverydayLifeItem> _items = const [];
  bool _loading = true;
  String? _error;

  static const _sections = <EverydayLifeKind>[
    EverydayLifeKind.task,
    EverydayLifeKind.household,
    EverydayLifeKind.appointmentDraft,
    EverydayLifeKind.localService,
  ];
  static const _titles = <String>[
    'Organizer',
    'Home',
    'Appointments',
    'Local services',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _sections.length, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final items = await _store.readAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر قراءة البيانات المحلية. حاول مرة أخرى.';
      });
    }
  }

  Future<void> _add(EverydayLifeKind kind) async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    final providerController = TextEditingController();
    final contactController = TextEditingController();
    final locationController = TextEditingController();
    final isDirectory = kind == EverydayLifeKind.localService;
    final isAppointment = kind == EverydayLifeKind.appointmentDraft;
    final isHousehold = kind == EverydayLifeKind.household;
    final title = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDirectory ? 'إضافة خدمة محلية' :
                isAppointment ? 'مسودة طلب خدمة / موعد' :
                isHousehold ? 'إضافة مهمة منزلية' : 'إضافة مهمة أو ملاحظة',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'العنوان *'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'تفاصيل / ملاحظات'),
                maxLines: 3,
              ),
              if (isDirectory || isAppointment) ...[
                TextField(controller: providerController, decoration: const InputDecoration(labelText: 'اسم مقدم الخدمة (اختياري)')),
                TextField(controller: contactController, decoration: const InputDecoration(labelText: 'وسيلة التواصل (اختياري)')),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'الموقع (اختياري)')),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('إلغاء'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        Navigator.pop(sheetContext, titleController.text.trim());
                      }
                    },
                    child: const Text('حفظ محلياً'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (title == null || title.trim().isEmpty || !mounted) {
      titleController.dispose();
      detailsController.dispose();
      providerController.dispose();
      contactController.dispose();
      locationController.dispose();
      return;
    }
    final item = EverydayLifeItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      kind: kind,
      title: title,
      details: detailsController.text.trim(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
      providerName: providerController.text.trim(),
      contact: contactController.text.trim(),
      location: locationController.text.trim(),
      informationConfirmed: false,
    );
    titleController.dispose();
    detailsController.dispose();
    providerController.dispose();
    contactController.dispose();
    locationController.dispose();
    try {
      await _store.save(item);
      await _refresh();
      if (mounted && isAppointment) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حُفظ الطلب كمسودة فقط؛ لم يُرسل ولم يُؤكَّد أي موعد.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الحفظ على هذا الجهاز.')),
        );
      }
    }
  }

  Future<void> _toggle(EverydayLifeItem item) async {
    await _store.save(item.copyWith(
      completed: !item.completed,
      favorite: item.favorite,
    ));
    await _refresh();
  }

  Future<void> _favorite(EverydayLifeItem item) async {
    await _store.save(item.copyWith(favorite: !item.favorite));
    await _refresh();
  }

  Future<void> _delete(EverydayLifeItem item) async {
    await _store.delete(item.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Everyday Life & Services'),
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabs: _titles.map((title) => Tab(text: title)).toList(),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
                ],
              ))
            : TabBarView(
                controller: _tabs,
                children: List.generate(_sections.length, (index) {
                  final kind = _sections[index];
                  final entries = _items.where((item) =>
                    item.kind == kind ||
                    (kind == EverydayLifeKind.task && item.kind == EverydayLifeKind.note),
                  ).toList().reversed.toList();
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (kind == EverydayLifeKind.appointmentDraft)
                          const Card(child: ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('طلبات غير مرسلة'),
                            subtitle: Text('كل طلب محفوظ كمسودة للمراجعة. لا يوجد حجز أو اتصال خارجي تلقائي.'),
                          )),
                        if (kind == EverydayLifeKind.localService)
                          const Card(child: ListTile(
                            leading: Icon(Icons.fact_check_outlined),
                            title: Text('بيانات الدليل'),
                            subtitle: Text('المعلومات التي تضيفها غير مؤكدة افتراضياً. تحقق منها بنفسك قبل الاعتماد عليها. لا توجد أسعار أو مواعيد افتراضية.'),
                          )),
                        FilledButton.icon(
                          onPressed: () => _add(kind),
                          icon: const Icon(Icons.add),
                          label: Text(kind == EverydayLifeKind.localService
                              ? 'أضف خدمة بنفسك'
                              : kind == EverydayLifeKind.appointmentDraft
                                  ? 'إنشاء مسودة طلب'
                                  : kind == EverydayLifeKind.household
                                      ? 'أضف مهمة منزلية'
                                      : 'أضف مهمة / ملاحظة'),
                        ),
                        const SizedBox(height: 8),
                        if (entries.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('لا توجد عناصر بعد. أضف أول عنصر واحفظه محلياً.'),
                          ),
                        ...entries.map((item) => Card(
                          child: ListTile(
                            leading: kind == EverydayLifeKind.localService
                                ? Icon(item.informationConfirmed ? Icons.verified_outlined : Icons.help_outline)
                                : Checkbox(
                                    value: item.completed,
                                    onChanged: (_) => _toggle(item),
                                  ),
                            title: Text(item.title),
                            subtitle: Text(_subtitle(item)),
                            isThreeLine: item.details.isNotEmpty,
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'favorite') _favorite(item);
                                if (action == 'done') _toggle(item);
                                if (action == 'delete') _delete(item);
                                if (action == 'confirmed' && kind == EverydayLifeKind.localService) {
                                  _store.save(item.copyWith(informationConfirmed: true)).then((_) => _refresh());
                                }
                              },
                              itemBuilder: (_) => [
                                if (kind == EverydayLifeKind.localService)
                                  PopupMenuItem(
                                    value: 'confirmed',
                                    child: Text(item.informationConfirmed ? 'تم وضع علامة تحقق' : 'وضع علامة: تحققت منه'),
                                  ),
                                PopupMenuItem(
                                  value: 'favorite',
                                  child: Text(item.favorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة'),
                                ),
                                if (kind != EverydayLifeKind.localService)
                                  const PopupMenuItem(value: 'done', child: Text('تغيير حالة الإنجاز')),
                                const PopupMenuItem(value: 'delete', child: Text('حذف')),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  );
                }),
              ),
  );

  String _subtitle(EverydayLifeItem item) {
    final parts = <String>[];
    if (item.details.isNotEmpty) parts.add(item.details);
    if (item.kind == EverydayLifeKind.appointmentDraft) parts.add('مسودة غير مرسلة');
    if (item.kind == EverydayLifeKind.localService) {
      if (item.providerName.isNotEmpty) parts.add(item.providerName);
      if (item.contact.isNotEmpty) parts.add(item.contact);
      if (item.location.isNotEmpty) parts.add(item.location);
      parts.add(item.informationConfirmed ? 'وضع المستخدم علامة التحقق' : 'معلومات غير مؤكدة');
    }
    if (item.favorite) parts.add('★ مفضلة');
    if (item.completed) parts.add('مكتملة');
    return parts.isEmpty ? 'محفوظ على هذا الجهاز' : parts.join(' • ');
  }
}
