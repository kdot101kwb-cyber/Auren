import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// User-scoped supplier contact/RFQ requests. Messages are never sent by this screen.
class SupplierRequestsScreen extends StatefulWidget {
  const SupplierRequestsScreen({super.key});

  @override
  State<SupplierRequestsScreen> createState() => _SupplierRequestsScreenState();
}

class _SupplierRequestsScreenState extends State<SupplierRequestsScreen> {
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  String _filter = 'all';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  static const _statuses = <String, String>{
    'draft': 'مسودة',
    'waiting_response': 'بانتظار الرد',
    'replied': 'تم الرد',
    'completed': 'مكتمل',
    'failed': 'فشل',
    'cancelled': 'ملغي',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        _requests = [];
        _error = 'سجّل الدخول لعرض طلباتك.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _functions.httpsCallable('listAurenSupplierRequests').call({
        'limit': 100,
        if (_filter != 'all') 'status': _filter,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      final raw = data['requests'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _requests = raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? 'تعذر تحميل طلبات الموردين.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تحميل الطلبات. تحقق من الاتصال ثم أعد المحاولة.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAction(
    Map<String, dynamic> request,
    String action, {
    String? status,
  }) async {
    final type = request['type'] == 'rfq' ? 'rfq' : 'contact';
    final id = (request['id'] ?? '').toString();
    if (id.isEmpty) return;
    final labels = <String, String>{
      'cancelAurenSupplierRequest': 'إلغاء الطلب',
      'retryAurenSupplierRequest': 'إعادة الطلب إلى المسودات',
      'updateAurenSupplierRequestStatus': 'تحديث الحالة',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels[action] ?? 'تأكيد الإجراء'),
        content: Text(action == 'cancelAurenSupplierRequest'
            ? 'هل تريد إلغاء هذا الطلب؟'
            : action == 'retryAurenSupplierRequest'
                ? 'سيُعاد الطلب إلى مسودة للمراجعة. لن تُرسل أي رسالة تلقائيًا.'
                : 'هل تريد تحديث حالة الطلب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('رجوع')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _functions.httpsCallable(action).call({
        'requestId': id,
        'type': type,
        if (status != null) 'status': status,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الطلب.')),
      );
      await _load();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'تعذر تنفيذ الإجراء.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تنفيذ الإجراء. حاول مرة أخرى.')),
      );
    }
  }

  void _showDetails(Map<String, dynamic> item) {
    final type = item['type'] == 'rfq' ? 'طلب عرض سعر' : 'طلب تواصل';
    final status = (item['status'] ?? 'draft').toString();
    final title = item['product'] ?? item['supplierName'] ?? 'طلب مورد';
    final details = <String>[
      'النوع: $type',
      'المورد: ${item['supplierName'] ?? 'غير محدد'}',
      if (item['product'] != null) 'المنتج: ${item['product']}',
      if (item['quantity'] != null) 'الكمية: ${item['quantity']}',
      if (item['message'] != null) 'الرسالة: ${item['message']}',
      if (item['notes'] != null && item['notes'].toString().isNotEmpty) 'ملاحظات: ${item['notes']}',
      'الحالة: ${_statuses[status] ?? status}',
      'الإرسال الخارجي: ${item['externalDispatch'] == true ? 'تم' : 'لم يتم'}',
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toString(), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...details.map((line) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: SelectableText(line),
              )),
              const SizedBox(height: 12),
              const Text('هذه مسودة/متابعة فقط؛ لا تُرسل AUREN رسالة إلى المورد تلقائيًا.'),
            ],
          ),
        ),
      ),
    );
  }

  String _title(Map<String, dynamic> item) {
    if (item['product'] != null) return item['product'].toString();
    return (item['supplierName'] ?? 'طلب مورد').toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الموردين'),
        actions: [IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'تحديث')],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                ('all', 'الكل'),
                ..._statuses.entries.map((entry) => (entry.key, entry.value)),
              ].map((entry) => Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(entry.$2),
                  selected: _filter == entry.$1,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() => _filter = entry.$1);
                    _load();
                  },
                ),
              )).toList(),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
                    ],
                  ),
                ),
              ),
            )
          else if (!_loading && _requests.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48),
                      SizedBox(height: 12),
                      Text('لا توجد طلبات في هذا التصنيف.', textAlign: TextAlign.center),
                      SizedBox(height: 6),
                      Text('ستظهر هنا مسودات التواصل وطلبات عروض الأسعار التي تنشئها.', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _requests[index];
                    final status = (item['status'] ?? 'draft').toString();
                    final isRfq = item['type'] == 'rfq';
                    final canCancel = !const {'completed', 'cancelled'}.contains(status);
                    final canRetry = const {'failed', 'cancelled'}.contains(status) &&
                        (int.tryParse('${item['retryCount'] ?? 0}') ?? 0) < 5;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(child: Icon(isRfq ? Icons.request_quote_outlined : Icons.mail_outline)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_title(item), style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      Text('${item['supplierName'] ?? 'مورد غير محدد'} · ${isRfq ? 'عرض سعر' : 'تواصل'}'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Chip(label: Text(_statuses[status] ?? status)),
                              ],
                            ),
                            if (item['quantity'] != null) Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('الكمية: ${item['quantity']}'),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showDetails(item),
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text('التفاصيل'),
                                ),
                                if (canCancel) TextButton.icon(
                                  onPressed: () => _runAction(item, 'cancelAurenSupplierRequest'),
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('إلغاء'),
                                ),
                                if (canRetry) FilledButton.tonalIcon(
                                  onPressed: () => _runAction(item, 'retryAurenSupplierRequest'),
                                  icon: const Icon(Icons.replay),
                                  label: const Text('إعادة المحاولة'),
                                ),
                                if (status == 'draft') TextButton.icon(
                                  onPressed: () => _runAction(item, 'updateAurenSupplierRequestStatus', status: 'failed'),
                                  icon: const Icon(Icons.error_outline),
                                  label: const Text('تسجيل فشل'),
                                ),
                                if (status == 'replied') FilledButton.tonalIcon(
                                  onPressed: () => _runAction(item, 'updateAurenSupplierRequestStatus', status: 'completed'),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('إكمال'),
                                ),
                              ],
                            ),
                            if (item['externalDispatch'] != true)
                              const Text('لم يتم إرسال رسالة خارجية.', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
