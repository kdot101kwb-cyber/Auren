import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../services/suppliers/auren_supplier_requests_repository.dart';

/// Account-scoped supplier request list. It records local workflow state only;
/// it does not send messages to suppliers.
class AurenSupplierRequestsScreen extends StatefulWidget {
  const AurenSupplierRequestsScreen({super.key, this.dataSource});

  /// Optional data source keeps the UI testable without Firebase or network access.
  final AurenSupplierRequestsDataSource? dataSource;

  @override
  State<AurenSupplierRequestsScreen> createState() =>
      _AurenSupplierRequestsScreenState();
}

class _AurenSupplierRequestsScreenState
    extends State<AurenSupplierRequestsScreen> {
  late final AurenSupplierRequestsDataSource _repository;
  String _statusFilter = 'all';
  bool _loading = true;
  Object? _error;
  List<AurenSupplierRequest> _requests = const [];
  final Set<String> _busy = <String>{};

  static const _statuses = <String, String>{
    'all': 'كل الطلبات',
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
    _repository = widget.dataSource ?? AurenSupplierRequestsRepository();
    _load();
  }

  String _key(AurenSupplierRequest request) => '${request.type}:${request.id}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repository.list(
        status: _statusFilter == 'all' ? null : _statusFilter,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _requests = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _perform(
    AurenSupplierRequest request,
    String action,
  ) async {
    final key = _key(request);
    if (_busy.contains(key)) return;
    if (action == 'cancel' &&
        !await _confirm(
          'إلغاء الطلب؟',
          'سيُسجل الطلب كملغي. لن تُرسل رسالة إلغاء للمورد.',
        )) {
      return;
    }
    if (action == 'retry' &&
        !await _confirm(
          'إعادة الطلب كمسودة؟',
          'ستُعاد المحاولة إلى مسودة قابلة للمراجعة فقط؛ لن يُرسل الطلب تلقائياً.',
        )) {
      return;
    }
    setState(() => _busy.add(key));
    try {
      switch (action) {
        case 'cancel':
          await _repository.cancel(request);
          break;
        case 'retry':
          await _repository.retry(request);
          break;
        default:
          // Backend validates allowed transitions and external-dispatch evidence.
          await _repository.updateStatus(request, action);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_successMessage(action))),
      );
      await _load();
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث الطلب. تحقق من الاتصال ثم أعد المحاولة.')),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  String _successMessage(String action) => switch (action) {
        'cancel' => 'تم تسجيل الطلب كملغي.',
        'retry' => 'أُعيد الطلب إلى مسودة للمراجعة.',
        'waiting_response' => 'تم تحديث الحالة إلى بانتظار الرد.',
        'replied' => 'تم تسجيل وصول رد من المورد.',
        'completed' => 'تم إغلاق الطلب كمكتمل.',
        'failed' => 'تم تسجيل تعذر إكمال الطلب.',
        _ => 'تم تحديث الطلب.',
      };

  String _friendlyError(FirebaseFunctionsException error) {
    if (error.code == 'failed-precondition') {
      return 'لا يمكن تنفيذ التغيير الحالي. تأكد من حالة الطلب، وأن الإرسال الخارجي موثّق قبل تسجيل انتظار الرد.';
    }
    if (error.code == 'permission-denied') {
      return 'رفض الخادم التغيير بسبب صلاحيات أو ملكية الطلب.';
    }
    if (error.code == 'resource-exhausted') {
      return 'وصل الطلب إلى الحد الأقصى للمحاولات.';
    }
    if (error.code == 'not-found') return 'الطلب غير موجود أو لم يعد متاحاً.';
    return 'تعذر تحديث الطلب (${error.code}).';
  }

  String _statusLabel(String status) => _statuses[status] ?? status;

  Color _statusColor(BuildContext context, String status) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      'completed' => scheme.primary,
      'failed' => scheme.error,
      'cancelled' => scheme.outline,
      'waiting_response' => scheme.tertiary,
      'replied' => scheme.secondary,
      _ => scheme.onSurfaceVariant,
    };
  }

  List<Widget> _actions(AurenSupplierRequest request) {
    final status = request.status.toLowerCase();
    final actions = <Widget>[];
    if (status == 'draft' && request.externalDispatch) {
      actions.add(OutlinedButton(
        onPressed: () => _perform(request, 'waiting_response'),
        child: const Text('تسجيل انتظار الرد'),
      ));
    }
    if (status == 'waiting_response' && request.externalDispatch) {
      actions.add(OutlinedButton(
        onPressed: () => _perform(request, 'replied'),
        child: const Text('تسجيل وصول رد'),
      ));
    }
    if (status == 'waiting_response' || status == 'replied') {
      actions.add(OutlinedButton(
        onPressed: () => _perform(request, 'completed'),
        child: const Text('إكمال'),
      ));
    }
    if (status == 'draft' || status == 'waiting_response' || status == 'replied' || status == 'failed') {
      actions.add(TextButton(
        onPressed: () => _perform(request, 'cancel'),
        child: const Text('إلغاء الطلب'),
      ));
    }
    if ((status == 'failed' || status == 'cancelled') && request.retryCount < 5) {
      actions.add(OutlinedButton(
        onPressed: () => _perform(request, 'retry'),
        child: const Text('إعادة كمسودة'),
      ));
    }
    if (status == 'draft' || status == 'waiting_response') {
      actions.add(TextButton(
        onPressed: () => _perform(request, 'failed'),
        child: const Text('تسجيل فشل'),
      ));
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات الموردين'),
        actions: [
          IconButton(
            tooltip: 'تحديث القائمة',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              decoration: const InputDecoration(
                labelText: 'تصفية حسب الحالة',
                border: OutlineInputBorder(),
              ),
              items: _statuses.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _statusFilter = value);
                      _load();
                    },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'المسودة لا تعني أن المورد استلم الطلب. لا يوجد إرسال خارجي تلقائي.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorState(onRetry: _load)
                    : _requests.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: const [
                                SizedBox(height: 100),
                                Icon(Icons.inbox_outlined, size: 48),
                                SizedBox(height: 12),
                                Center(child: Text('لا توجد طلبات بهذه الحالة.')),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _requests.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final request = _requests[index];
                                final busy = _busy.contains(_key(request));
                                final actions = _actions(request);
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(request.type == 'rfq'
                                                ? Icons.request_quote_outlined
                                                : Icons.contact_mail_outlined),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(request.title,
                                                      style: Theme.of(context).textTheme.titleMedium),
                                                  if (request.supplierName.isNotEmpty)
                                                    Text('المورد: ${request.supplierName}'),
                                                  Text(request.type == 'rfq' ? 'طلب عرض سعر' : 'طلب تواصل'),
                                                ],
                                              ),
                                            ),
                                            Chip(
                                              label: Text(_statusLabel(request.status)),
                                              labelStyle: TextStyle(
                                                color: _statusColor(context, request.status),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (request.quantity.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text('الكمية: ${request.quantity}'),
                                        ],
                                        if (request.message.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(request.message, maxLines: 4, overflow: TextOverflow.ellipsis),
                                        ],
                                        if (request.externalDispatch) ...[
                                          const SizedBox(height: 6),
                                          const Text('سجل الطلب يشير إلى إرسال خارجي.'),
                                        ] else ...[
                                          const SizedBox(height: 6),
                                          const Text('لم يُسجّل إرسال خارجي لهذا الطلب.'),
                                        ],
                                        if (request.retryCount > 0) ...[
                                          const SizedBox(height: 4),
                                          Text('عدد المحاولات: ${request.retryCount}/5'),
                                        ],
                                        if (request.lastError.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text('آخر خطأ: ${request.lastError}',
                                              style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                        ],
                                        if (actions.isNotEmpty) ...[
                                          const Divider(height: 22),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: actions,
                                          ),
                                        ],
                                        if (busy) const LinearProgressIndicator(),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42),
              const SizedBox(height: 12),
              const Text('تعذر تحميل طلبات الموردين.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}
