import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/payments/tron_usdt_monitor.dart';

/// Read-only view for monitoring a public Trust Wallet address on TRON.
class TrustWalletMonitorScreen extends StatefulWidget {
  const TrustWalletMonitorScreen({super.key});

  @override
  State<TrustWalletMonitorScreen> createState() => _TrustWalletMonitorScreenState();
}

class _TrustWalletMonitorScreenState extends State<TrustWalletMonitorScreen> {
  static const _addressKey = 'trust_wallet_tron_public_address';
  final _addressController = TextEditingController();
  final _monitor = TronUsdtMonitor();

  double? _balance;
  List<TronUsdtTransfer> _transfers = const [];
  bool _loading = false;
  String? _error;
  String? _loadedAddress;

  @override
  void initState() {
    super.initState();
    _restoreAddress();
  }

  Future<void> _restoreAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_addressKey) ?? '';
    if (!mounted) return;
    _addressController.text = saved;
    if (saved.isNotEmpty) await _refresh();
  }

  Future<void> _saveAndRefresh() async {
    final address = _addressController.text.trim();
    if (!_monitor.looksLikeTronAddress(address)) {
      setState(() => _error = 'راجع العنوان. المطلوب عنوان TRON عام يبدأ بحرف T.');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, address);
    await _refresh();
  }

  Future<void> _refresh() async {
    final address = _addressController.text.trim();
    if (!_monitor.looksLikeTronAddress(address)) {
      setState(() => _error = 'أدخل عنوان TRON العام أولاً.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _monitor.fetchUsdtBalance(address),
        _monitor.fetchTransfers(address),
      ]);
      if (!mounted) return;
      setState(() {
        _balance = results[0] as double;
        _transfers = results[1] as List<TronUsdtTransfer>;
        _loadedAddress = address;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحديث بيانات الشبكة: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _monitor.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust Wallet • USDT TRC20'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مراقبة للقراءة فقط',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  const Text('أدخل عنوان الاستلام العام. لا تدخل عبارة الاسترداد أو المفتاح الخاص.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'عنوان TRON العام',
                      hintText: 'T...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _saveAndRefresh,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('حفظ العنوان وقراءة الرصيد'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('PayPal'),
              subtitle: const Text('مكان مخصص للربط مستقبلاً • غير متصل حالياً'),
              trailing: const Chip(label: Text('قريباً')),
              isThreeLine: false,
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ربط PayPal مستقبلاً'),
                  content: const Text(
                    'تم تخصيص مكان لـ PayPal في صفحة المحفظة. الربط غير مفعّل حالياً، ولن نطلب كلمة مرور PayPal أو رموز التحقق داخل التطبيق. قبل التنفيذ يجب التأكد من أن PayPal يدعم الاستلام والسحب في بلد حسابك، ثم استخدام مسار رسمي وآمن عند توفره.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('حسناً'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            ),
          if (_loadedAddress != null && _loadedAddress == _addressController.text.trim()) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('رصيد USDT'),
                subtitle: const Text('شبكة TRON • TRC20'),
                trailing: Text(
                  _balance == null ? '—' : _balance!.toStringAsFixed(6),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('آخر التحويلات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            if (_transfers.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('لم تظهر تحويلات USDT في النتيجة الحالية.')))
            else
              ..._transfers.map((tx) {
                final incoming = tx.to == _loadedAddress;
                final date = tx.timestamp?.toLocal().toString().split('.').first ?? 'وقت غير متاح';
                return Card(
                  child: ListTile(
                    leading: Icon(incoming ? Icons.south_west : Icons.north_east),
                    title: Text('${incoming ? '+' : '-'}${tx.amount.toStringAsFixed(6)} USDT'),
                    subtitle: Text('${incoming ? 'من' : 'إلى'}: ${incoming ? tx.from : tx.to}\n$date'),
                    isThreeLine: true,
                    trailing: Icon(tx.confirmed ? Icons.verified_outlined : Icons.hourglass_empty),
                    onTap: tx.transactionId.isEmpty
                        ? null
                        : () {},
                  ),
                );
              }),
            const SizedBox(height: 8),
            Text(
              'مصدر البيانات: TRON network index API. الرصيد وسجل المعاملات للعرض فقط؛ لا توجد وظائف إرسال أو توقيع.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
