import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auren/features/global_directory/presentation/auren_supplier_requests_screen.dart';
import 'package:auren/services/suppliers/auren_supplier_requests_repository.dart';

class _FakeRequestsSource implements AurenSupplierRequestsDataSource {
  _FakeRequestsSource(this.requests);

  List<AurenSupplierRequest> requests;
  Object? listError;
  String? lastStatus;
  int listCalls = 0;
  int cancelCalls = 0;
  int retryCalls = 0;
  final List<String> statusUpdates = [];

  @override
  Future<List<AurenSupplierRequest>> list({String? status, int limit = 30}) async {
    listCalls++;
    lastStatus = status;
    if (listError != null) throw listError!;
    return requests.where((r) => status == null || r.status == status).toList();
  }

  @override
  Future<AurenSupplierRequest> get({required String id, required String type}) async =>
      requests.firstWhere((r) => r.id == id && r.type == type);

  @override
  Future<void> cancel(AurenSupplierRequest request) async {
    cancelCalls++;
    _replace(request, status: 'cancelled');
  }

  @override
  Future<void> retry(AurenSupplierRequest request) async {
    retryCalls++;
    _replace(request, status: 'draft', externalDispatch: false,
        retryCount: request.retryCount + 1, lastError: '');
  }

  @override
  Future<void> updateStatus(AurenSupplierRequest request, String status) async {
    statusUpdates.add(status);
    _replace(request, status: status);
  }

  void _replace(
    AurenSupplierRequest request, {
    required String status,
    bool? externalDispatch,
    int? retryCount,
    String? lastError,
  }) {
    requests = requests.map((old) {
      if (old.id != request.id || old.type != request.type) return old;
      return AurenSupplierRequest(
        id: old.id,
        type: old.type,
        status: status,
        supplierName: old.supplierName,
        supplierId: old.supplierId,
        product: old.product,
        quantity: old.quantity,
        message: old.message,
        currency: old.currency,
        matchFlowId: old.matchFlowId,
        lastError: lastError ?? old.lastError,
        externalDispatch: externalDispatch ?? old.externalDispatch,
        retryCount: retryCount ?? old.retryCount,
      );
    }).toList();
  }
}

AurenSupplierRequest _request({
  String id = 'req-1',
  String status = 'draft',
  bool externalDispatch = false,
  int retryCount = 0,
}) =>
    AurenSupplierRequest(
      id: id,
      type: 'rfq',
      status: status,
      supplierName: 'Nile Textiles',
      supplierId: 'supplier-1',
      product: 'Cotton fabric',
      quantity: '100 metres',
      message: 'Quote requested for testing',
      currency: 'USD',
      matchFlowId: 'flow-1',
      lastError: '',
      externalDispatch: externalDispatch,
      retryCount: retryCount,
    );

void main() {
  testWidgets('shows draft status and makes clear no supplier was contacted', (tester) async {
    final source = _FakeRequestsSource([_request()]);

    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierRequestsScreen(dataSource: source),
    ));
    await tester.pumpAndSettle();

    expect(find.text('طلبات الموردين'), findsOneWidget);
    expect(find.text('Cotton fabric'), findsOneWidget);
    expect(find.textContaining('Nile Textiles'), findsOneWidget);
    expect(find.text('مسودة'), findsOneWidget);
    expect(find.text('لم يُسجّل إرسال خارجي لهذا الطلب.'), findsOneWidget);
    expect(find.textContaining('لا يوجد إرسال خارجي تلقائي.'), findsOneWidget);
    expect(find.text('تسجيل انتظار الرد'), findsNothing);
  });

  testWidgets('filters requests by selected lifecycle status', (tester) async {
    final source = _FakeRequestsSource([
      _request(id: 'draft-1'),
      _request(id: 'waiting-1', status: 'waiting_response', externalDispatch: true),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierRequestsScreen(dataSource: source),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Cotton fabric'), findsNWidgets(2));

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بانتظار الرد').last);
    await tester.pumpAndSettle();

    expect(source.lastStatus, 'waiting_response');
    expect(find.text('Cotton fabric'), findsOneWidget);
    expect(find.text('تسجيل وصول رد'), findsOneWidget);
  });

  testWidgets('shows recoverable error state and retries loading', (tester) async {
    final source = _FakeRequestsSource([]);
    source.listError = StateError('offline');

    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierRequestsScreen(dataSource: source),
    ));
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل طلبات الموردين.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    source.listError = null;
    source.requests = [_request()];
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(source.listCalls, 2);
    expect(find.text('Cotton fabric'), findsOneWidget);
  });

  testWidgets('requires confirmation before cancelling a request', (tester) async {
    final source = _FakeRequestsSource([_request()]);
    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierRequestsScreen(dataSource: source),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إلغاء الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('إلغاء الطلب؟'), findsOneWidget);
    expect(source.cancelCalls, 0);

    await tester.tap(find.text('رجوع'));
    await tester.pumpAndSettle();
    expect(source.cancelCalls, 0);

    await tester.tap(find.text('إلغاء الطلب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(source.cancelCalls, 1);
    expect(find.text('ملغي'), findsOneWidget);
    expect(source.requests.single.externalDispatch, isFalse);
  });

  testWidgets('retry is confirmed and returns request to a non-dispatched draft', (tester) async {
    final source = _FakeRequestsSource([
      _request(status: 'failed', retryCount: 2, externalDispatch: true),
    ]);
    await tester.pumpWidget(MaterialApp(
      home: AurenSupplierRequestsScreen(dataSource: source),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إعادة كمسودة'));
    await tester.pumpAndSettle();
    expect(source.retryCalls, 0);
    expect(find.text('إعادة الطلب كمسودة؟'), findsOneWidget);

    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(source.retryCalls, 1);
    expect(source.requests.single.status, 'draft');
    expect(source.requests.single.externalDispatch, isFalse);
    expect(source.requests.single.retryCount, 3);
    expect(find.text('مسودة'), findsOneWidget);
  });
}
