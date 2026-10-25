import 'package:flutter/material.dart';

import '../data/everyday_life_local_store.dart';
import '../domain/everyday_life_item.dart';

class AurenEverydayLifeScreen extends StatefulWidget {
  const AurenEverydayLifeScreen({super.key, this.store});

  /// Injectable local store keeps persistence failures testable without
  /// changing the production device-local default.
  final EverydayLifeLocalStore? store;

  @override
  State<AurenEverydayLifeScreen> createState() => _AurenEverydayLifeScreenState();
}

class _AurenEverydayLifeScreenState extends State<AurenEverydayLifeScreen>
    with SingleTickerProviderStateMixin {
  final _defaultStore = EverydayLifeLocalStore();
  EverydayLifeLocalStore get _store => widget.store ?? _defaultStore;
  late final TabController _tabs;
  List<EverydayLifeItem> _items = const [];
  bool _loading = true;
  String? _error;

  static const _sections = <EverydayLifeKind>[
    EverydayLifeKind.task,
    EverydayLifeKind.household,
    EverydayLifeKind.householdSupply,
    EverydayLifeKind.householdMaintenance,
    EverydayLifeKind.appointmentDraft,
    EverydayLifeKind.localService,
  ];
  static const _titles = <String>[
    'Organizer',
    'Home',
    'Supplies',
    'Maintenance',
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
    final categoryController = TextEditingController();
    final quantityController = TextEditingController();
    final requestedWindowController = TextEditingController();
    final isDirectory = kind == EverydayLifeKind.localService;
    final isList = kind == EverydayLifeKind.taskList;
    final isNote = kind == EverydayLifeKind.note;
    final isAppointment = kind == EverydayLifeKind.appointmentDraft;
    final isHousehold = kind == EverydayLifeKind.household ||
        kind == EverydayLifeKind.householdSupply ||
        kind == EverydayLifeKind.householdMaintenance;
    final isSupply = kind == EverydayLifeKind.householdSupply;
    final isMaintenance = kind == EverydayLifeKind.householdMaintenance;
    // Snapshot every field before popping the sheet. The route future resolves
    // as the reverse animation starts, so persistence must not depend on live
    // TextField widgets continuing to exist during that transition.
    var formValues = <String, String>{};
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
                isList ? 'إنشاء قائمة يومية' :
                isNote ? 'إضافة ملاحظة يومية' :
                isSupply ? 'إضافة مستلزم منزلي' :
                isMaintenance ? 'إضافة صيانة منزلية' :
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
                decoration: InputDecoration(
                  labelText: isList ? 'عناصر القائمة (كل عنصر في سطر)' : 'تفاصيل / ملاحظات',
                  hintText: isList ? 'مثال: خبز\\nحليب\\nمنظف' : null,
                ),
                maxLines: isList ? 6 : 3,
              ),
              if (isSupply)
                TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'الكمية (اختياري)')),
              if (isDirectory || isHousehold)
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(
                    labelText: isHousehold
                        ? 'تصنيف المنزل (اختياري)'
                        : 'التصنيف (اختياري)',
                  ),
                ),
              if (isAppointment || isMaintenance)
                TextField(controller: requestedWindowController, decoration: const InputDecoration(labelText: 'الوقت المطلوب (اختياري؛ غير مؤكد)')),
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
                      final enteredTitle = titleController.text.trim();
                      if (enteredTitle.isNotEmpty) {
                        formValues = {
                          'title': enteredTitle,
                          'details': detailsController.text.trim(),
                          'category': categoryController.text.trim(),
                          'quantity': quantityController.text.trim(),
                          'requestedWindow': requestedWindowController.text.trim(),
                          'providerName': providerController.text.trim(),
                          'contact': contactController.text.trim(),
                          'location': locationController.text.trim(),
                        };
                        Navigator.pop(sheetContext, enteredTitle);
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
    // The modal result completes as the reverse transition starts; its
    // TextFields may still rebuild during that animation. Defer controller
    // disposal until the closing transition has finished.
    void disposeControllers() {
      titleController.dispose();
      detailsController.dispose();
      providerController.dispose();
      contactController.dispose();
      locationController.dispose();
      categoryController.dispose();
      quantityController.dispose();
      requestedWindowController.dispose();
    }

    void disposeControllersAfterSheetCloses() {
      Future<void>.delayed(const Duration(milliseconds: 400), disposeControllers);
    }

    if (title == null || title.trim().isEmpty || !mounted) {
      disposeControllersAfterSheetCloses();
      return;
    }
    final item = EverydayLifeItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      kind: kind,
      title: title,
      details: formValues['details'] ?? '',
      category: formValues['category'] ?? '',
      quantity: formValues['quantity'] ?? '',
      requestedWindow: formValues['requestedWindow'] ?? '',
      createdAt: DateTime.now().toUtc().toIso8601String(),
      providerName: formValues['providerName'] ?? '',
      contact: formValues['contact'] ?? '',
      location: formValues['location'] ?? '',
      informationConfirmed: false,
    );
    disposeControllersAfterSheetCloses();
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

  Future<void> _runMutation(Future<void> Function() mutation) async {
    try {
      await mutation();
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('تعذر حفظ التغيير محلياً؛ احتفظنا بالبيانات السابقة. حاول مرة أخرى.'),
          ),
        );
    }
  }

  Future<void> _toggle(EverydayLifeItem item) => _runMutation(() async {
    await _store.save(item.copyWith(
      completed: !item.completed,
      favorite: item.favorite,
    ));
  });

  Future<void> _favorite(EverydayLifeItem item) => _runMutation(() async {
    await _store.save(item.copyWith(favorite: !item.favorite));
  });

  Future<void> _delete(EverydayLifeItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف هذا العنصر؟'),
        content: Text('سيتم حذف «${item.title}» من هذا الجهاز نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف العنصر'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runMutation(() async {
      await _store.delete(item.id);
    });
  }

  Future<void> _toggleVerification(EverydayLifeItem item) =>
      _runMutation(() async {
        await _store.save(item.copyWith(
          informationConfirmed: !item.informationConfirmed,
        ));
      });

  Future<void> _clearLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مسح بيانات الحياة اليومية؟'),
        content: const Text(
          'سيتم حذف المهام والملاحظات والقوائم المنزلية ومسودات الطلبات '
          'ودليل الخدمات المحفوظة على هذا الجهاز. لا يمكن التراجع عن ذلك. '
          'لن تُمس إعدادات AUREN الأخرى.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('مسح البيانات المحلية'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _store.clearAll();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مسح بيانات الحياة اليومية من هذا الجهاز.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر مسح البيانات؛ لم نعرض العملية كأنها نجحت.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Everyday Life & Services'),
      actions: [
        IconButton(
          tooltip: 'إدارة البيانات المحلية',
          onPressed: _clearLocalData,
          icon: const Icon(Icons.delete_sweep_outlined),
        ),
      ],
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
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'إذا استمر الخطأ بسبب تلف البيانات، يمكنك استخدام رمز إدارة البيانات أعلى الشاشة لمسح بيانات هذه الميزة فقط بعد التأكيد. لن تُمس إعدادات AUREN الأخرى.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  TextButton(onPressed: _refresh, child: const Text('إعادة المحاولة')),
                ],
              ))
            : TabBarView(
                controller: _tabs,
                children: List.generate(_sections.length, (index) {
                  final kind = _sections[index];
                  final entries = _items.where((item) =>
                    item.kind == kind ||
                    (kind == EverydayLifeKind.task &&
                      (item.kind == EverydayLifeKind.note || item.kind == EverydayLifeKind.taskList)),
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
                        if (kind == EverydayLifeKind.task) ...[
                          FilledButton.icon(
                            onPressed: () => _add(EverydayLifeKind.task),
                            icon: const Icon(Icons.add_task),
                            label: const Text('أضف مهمة'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _add(EverydayLifeKind.note),
                            icon: const Icon(Icons.note_add_outlined),
                            label: const Text('أضف ملاحظة'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _add(EverydayLifeKind.taskList),
                            icon: const Icon(Icons.checklist_outlined),
                            label: const Text('أضف قائمة'),
                          ),
                        ] else FilledButton.icon(
                          onPressed: () => _add(kind),
                          icon: const Icon(Icons.add),
                          label: Text(kind == EverydayLifeKind.localService
                              ? 'أضف خدمة بنفسك'
                              : kind == EverydayLifeKind.appointmentDraft
                                  ? 'إنشاء مسودة طلب'
                                  : kind == EverydayLifeKind.householdSupply
                                      ? 'أضف مستلزم منزلي'
                                      : kind == EverydayLifeKind.householdMaintenance
                                          ? 'أضف مهمة صيانة'
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
                                  _toggleVerification(item);
                                }
                              },
                              itemBuilder: (_) => [
                                if (kind == EverydayLifeKind.localService)
                                  PopupMenuItem(
                                    value: 'confirmed',
                                    child: Text(item.informationConfirmed ? 'إزالة علامة التحقق' : 'وضع علامة: تحققت منه'),
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
    if (item.details.isNotEmpty) {
      parts.add(item.kind == EverydayLifeKind.taskList
          ? 'عناصر القائمة:\\n${item.details}'
          : item.details);
    }
    if (item.category.isNotEmpty) parts.add('التصنيف: ${item.category}');
    if (item.quantity.isNotEmpty) parts.add('الكمية: ${item.quantity}');
    if (item.requestedWindow.isNotEmpty) parts.add('الوقت المطلوب (غير مؤكد): ${item.requestedWindow}');
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
