import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/models/user_profile.dart';

class AurenPhoneDiscoveryScreen extends StatefulWidget {
  const AurenPhoneDiscoveryScreen({super.key});

  @override
  State<AurenPhoneDiscoveryScreen> createState() => _AurenPhoneDiscoveryScreenState();
}

class _AurenPhoneDiscoveryScreenState extends State<AurenPhoneDiscoveryScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _countryCode = TextEditingController(text: '+249');
  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  String? _verificationId;
  String? _status;
  bool _busy = false;
  List<AurenUserProfile> _matches = const [];

  bool get _verified => _auth.currentUser?.phoneNumber != null;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _countryCode.dispose();
    super.dispose();
  }

  String? _toE164(String input) {
    final raw = input.trim().replaceAll(RegExp(r'[()\s.-]'), '');
    if (raw.startsWith('+')) {
      return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(raw) ? raw : null;
    }
    final country = _countryCode.text.trim().replaceAll(RegExp(r'[^+\d]'), '');
    if (!RegExp(r'^\+[1-9]\d{0,3}$').hasMatch(country)) return null;
    final national = raw.replaceAll(RegExp(r'^0+'), '');
    final result = '$country$national';
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(result) ? result : null;
  }

  Future<void> _verifyPhone() async {
    final phone = _toE164(_phone.text);
    if (phone == null) {
      setState(() => _status = 'أدخل رقم هاتف صحيحاً مع مفتاح الدولة.');
      return;
    }
    setState(() { _busy = true; _status = 'جارٍ إرسال رمز التحقق…'; });
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await _linkCredential(credential);
          } catch (e) {
            if (mounted) setState(() => _status = 'تعذر ربط الرقم بالحساب الحالي: $e');
          }
        },
        verificationFailed: (error) {
          if (mounted) setState(() { _busy = false; _status = 'فشل التحقق: ${error.message ?? error.code}'; });
        },
        codeSent: (verificationId, _) {
          if (mounted) setState(() {
            _verificationId = verificationId;
            _busy = false;
            _status = 'أُرسل الرمز. أدخله لإكمال ربط الرقم بحسابك الحالي.';
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (mounted) setState(() => _verificationId = verificationId);
        },
      );
    } catch (e) {
      if (mounted) setState(() { _busy = false; _status = 'تعذر بدء التحقق: $e'; });
    }
  }

  Future<void> _confirmCode() async {
    final id = _verificationId;
    if (id == null || _code.text.trim().length < 4) {
      setState(() => _status = 'أدخل رمز التحقق الذي وصلك.');
      return;
    }
    setState(() { _busy = true; _status = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: _code.text.trim(),
      );
      await _linkCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _status = e.code == 'credential-already-in-use'
          ? 'هذا الرقم مرتبط بحساب آخر. لم ندمج الحسابات تلقائياً حفاظاً على أمانها.'
          : 'تعذر التحقق من الرمز: ${e.message ?? e.code}');
    } catch (e) {
      if (mounted) setState(() => _status = 'تعذر ربط الرقم: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _linkCredential(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('سجّل الدخول أولاً.');
    if (user.phoneNumber == null) {
      await user.linkWithCredential(credential);
    }
    await _auth.currentUser?.getIdToken(true);
    _phone.clear();
    _code.clear();
    if (mounted) setState(() { _busy = false; _status = 'تم التحقق من رقمك. يمكنك الآن البحث ومزامنة جهات الاتصال.'; });
  }

  Future<List<AurenUserProfile>> _lookup(List<String> numbers) async {
    final callable = _functions.httpsCallable('lookupAurenPhoneContacts');
    final result = await callable.call(<String, dynamic>{'phoneNumbers': numbers.take(50).toSet().toList()});
    final data = Map<String, dynamic>.from(result.data as Map);
    final users = (data['users'] as List? ?? const []).whereType<Map>();
    return users.map((entry) {
      final user = Map<String, dynamic>.from(entry);
      return AurenUserProfile(
        uid: user['uid'] as String,
        displayName: user['displayName'] as String? ?? 'AUREN User',
        photoUrl: user['photoUrl'] as String?,
        createdAt: DateTime.now(),
      );
    }).where((user) => user.uid != _auth.currentUser?.uid).toList();
  }

  Future<void> _searchNumber() async {
    if (!_verified) {
      setState(() => _status = 'تحقق من رقم هاتفك أولاً.');
      return;
    }
    final number = _toE164(_phone.text);
    if (number == null) {
      setState(() => _status = 'أدخل رقم هاتف صحيحاً مع مفتاح الدولة.');
      return;
    }
    await _runLookup([number]);
  }

  Future<void> _syncContacts() async {
    if (!_verified) {
      setState(() => _status = 'تحقق من رقم هاتفك أولاً.');
      return;
    }
    setState(() { _busy = true; _status = 'نطلب إذن جهات الاتصال…'; });
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        setState(() => _status = 'لم يُمنح إذن جهات الاتصال. يمكنك البحث برقم يدوي بدلاً من ذلك.');
        return;
      }
      final contacts = await FlutterContacts.getContacts(withProperties: true, withPhoto: false);
      final numbers = <String>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = _toE164(phone.number);
          if (normalized != null) numbers.add(normalized);
          if (numbers.length >= 50) break;
        }
        if (numbers.length >= 50) break;
      }
      if (numbers.isEmpty) {
        setState(() => _status = 'لم نعثر على أرقام صالحة. تأكد من مفتاح الدولة الافتراضي.');
        return;
      }
      await _runLookup(numbers.toList(), alreadyBusy: true);
    } catch (e) {
      if (mounted) setState(() => _status = 'تعذرت مزامنة جهات الاتصال: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runLookup(List<String> numbers, {bool alreadyBusy = false}) async {
    if (!alreadyBusy) setState(() { _busy = true; _status = 'جارٍ البحث…'; });
    try {
      final users = await _lookup(numbers);
      if (!mounted) return;
      setState(() {
        _matches = users;
        _status = users.isEmpty ? 'لم نعثر على حسابات مطابقة.' : 'عثرنا على ${users.length} حساباً على AUREN.';
      });
    } on FirebaseFunctionsException catch (e) {
      if (mounted) setState(() => _status = e.code == 'failed-precondition'
          ? 'تحقق من رقم هاتفك أولاً.'
          : 'تعذر البحث: ${e.message ?? e.code}');
    } catch (e) {
      if (mounted) setState(() => _status = 'تعذر البحث: $e');
    } finally {
      if (mounted && !alreadyBusy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العثور على الأصدقاء')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('اربط رقمك أولاً، ثم ابحث عن مستخدمي AUREN أو اعثر على جهات اتصالك الموجودة على التطبيق.'),
          const SizedBox(height: 12),
          if (!_verified) ...[
            TextField(
              controller: _countryCode,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'مفتاح الدولة الافتراضي', hintText: '+249'),
            ),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم هاتفك للتحقق', hintText: '9xxxxxxxx'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _verifyPhone,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('تحقق من رقمي'),
            ),
            if (_verificationId != null) ...[
              TextField(controller: _code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رمز SMS')),
              FilledButton(onPressed: _busy ? null : _confirmCode, child: const Text('تأكيد الرمز')),
            ],
          ] else ...[
            Text('رقمك الموثق: ${_auth.currentUser?.phoneNumber}', style: Theme.of(context).textTheme.bodyMedium),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'ابحث برقم هاتف', hintText: '+249… أو رقم محلي'),
            ),
            FilledButton.icon(
              onPressed: _busy ? null : _searchNumber,
              icon: const Icon(Icons.search),
              label: const Text('البحث برقم الهاتف'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _syncContacts,
              icon: const Icon(Icons.contacts_outlined),
              label: const Text('مزامنة جهات الاتصال'),
            ),
          ],
          if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          if (_status != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_status!)),
          const Divider(),
          for (final user in _matches)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
                child: user.photoUrl == null ? const Icon(Icons.person_outline) : null,
              ),
              title: Text(user.displayName),
              subtitle: const Text('مستخدم على AUREN'),
              trailing: IconButton(
                tooltip: 'فتح المحادثة',
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () => Navigator.pop(context, user),
              ),
            ),
          const SizedBox(height: 12),
          const Text('الخصوصية: لا تُرفع الأسماء أو قائمة جهات الاتصال إلى الخادم. تُرسل الأرقام المراد مطابقتها فقط بعد موافقتك، ولا تُحفظ أرقام البحث في قاعدة البيانات.'),
        ],
      ),
    );
  }
}
