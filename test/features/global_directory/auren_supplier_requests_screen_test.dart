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
  Future<void> cancel(AurenSupplierRequest request) async {}

  @override
  Future<void> retry(AurenSupplierRequest request) async {}

  @override
  Future<void> updateStatus(AurenSupplierRequest request, String status) async {}
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
    expect(find.text('Nile Textiles').evaluate().isNotEmpty, isTrue);
    expect(find.text('مسودة'), findsOneWidget);
    expect(find.text('لم يُسجّل إرسال خارجي لهذا الطلب.'), findsOneWidget);
    expect(find.text('لا يوجد إرسال خارجي تلقائي.'), findsOneWidget);
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
}
