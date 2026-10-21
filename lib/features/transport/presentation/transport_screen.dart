import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';
import '../data/mobility_local_store.dart';
import '../domain/mobility_models.dart';

class AurenTransportScreen extends StatefulWidget {
  const AurenTransportScreen({super.key});

  @override
  State<AurenTransportScreen> createState() => _AurenTransportScreenState();
}

class _AurenTransportScreenState extends State<AurenTransportScreen> {
  final MobilityLocalStore _localStore = MobilityLocalStore();
  bool _loadingRecords = true;
  final _routeOperator = TextEditingController();
  final _routeName = TextEditingController();
  final _routeStops = TextEditingController();
  final _routeSource = TextEditingController();
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleYear = TextEditingController();
  final _vehicleRegistration = TextEditingController();
  final _vehicleNotes = TextEditingController();
  final _insuranceExpiry = TextEditingController();
  final _maintenanceDue = TextEditingController();
  final _cargoRef = TextEditingController();
  final _cargoOrigin = TextEditingController();
  final _cargoDestination = TextEditingController();
  final _cargoCarrier = TextEditingController();
  final _cargoRequirements = TextEditingController();
  final _cargoNotes = TextEditingController();
  CargoStatus _cargoStatus = CargoStatus.draft;
  final _portName = TextEditingController();
  final _portCountry = TextEditingController();
  final _portSource = TextEditingController();
  final _distance = TextEditingController();
  final _trips = TextEditingController(text: '1');
  final _consumption = TextEditingController();
  final _fuelPrice = TextEditingController();
  final _tolls = TextEditingController(text: '0');
  final _parking = TextEditingController(text: '0');
  final _other = TextEditingController(text: '0');
  final _currency = TextEditingController();
  final List<PublicTransportRoute> _routes = [];
  final List<VehicleRecord> _vehicles = [];
  final List<CargoShipment> _shipments = [];
  final List<PortInformation> _ports = [];
  MobilityCostEstimate? _estimate;
  String? _costError;

  @override
  void initState() {
    super.initState();
    _loadLocalRecords();
  }

  Future<void> _loadLocalRecords() async {
    try {
      final results = await Future.wait<Object>([
        _localStore.loadRoutes(),
        _localStore.loadVehicles(),
        _localStore.loadShipments(),
        _localStore.loadPorts(),
      ]);
      if (!mounted) return;
      setState(() {
        _routes.addAll(results[0] as List<PublicTransportRoute>);
        _vehicles.addAll(results[1] as List<VehicleRecord>);
        _shipments.addAll(results[2] as List<CargoShipment>);
        _ports.addAll(results[3] as List<PortInformation>);
        _loadingRecords = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRecords = false);
      if (mounted) _message('تعذر تحميل بعض السجلات المحلية. يمكنك المتابعة وإعادة المحاولة لاحقًا.');
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _routeOperator, _routeName, _routeStops, _routeSource,
      _vehicleMake, _vehicleModel, _vehicleYear, _vehicleRegistration, _vehicleNotes,
      _insuranceExpiry, _maintenanceDue,
      _cargoRef, _cargoOrigin, _cargoDestination, _cargoCarrier, _cargoRequirements, _cargoNotes,
      _portName, _portCountry, _portSource,
      _distance, _trips, _consumption, _fuelPrice, _tolls,
      _parking, _other, _currency,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim());

  Future<void> _saveRoute() async {
    final source = _routeSource.text.trim();
    final route = PublicTransportRoute(
      operator: _routeOperator.text,
      routeName: _routeName.text,
      stops: _routeStops.text.split(','),
      evidence: source.isEmpty
          ? null
          : MobilityEvidence(sourceName: source, observedAt: DateTime.now()),
    );
    if (!route.isPublishable) {
      _message('أدخل المشغّل والمسار والتوقفات ومصدرًا واضحًا للمعلومات.');
      return;
    }
    setState(() => _routes.add(route));
    try {
      await _localStore.saveRoutes(_routes);
    } catch (_) {
      _message('أُضيف المسار للشاشة، لكن تعذر حفظه على الجهاز.');
    }
    _routeOperator.clear(); _routeName.clear(); _routeStops.clear(); _routeSource.clear();
  }

  Future<void> _saveVehicle() async {
    final year = int.tryParse(_vehicleYear.text.trim());
    if (year == null) {
      _message('أدخل سنة مركبة صحيحة.');
      return;
    }
    final insuranceText = _insuranceExpiry.text.trim();
    final maintenanceText = _maintenanceDue.text.trim();
    final insuranceDate = insuranceText.isEmpty ? null : DateTime.tryParse(insuranceText);
    final maintenanceDate = maintenanceText.isEmpty ? null : DateTime.tryParse(maintenanceText);
    if ((insuranceText.isNotEmpty && insuranceDate == null) ||
        (maintenanceText.isNotEmpty && maintenanceDate == null)) {
      _message('استخدم صيغة التاريخ YYYY-MM-DD.');
      return;
    }
    final vehicle = VehicleRecord(
      make: _vehicleMake.text,
      model: _vehicleModel.text,
      year: year,
      registrationId: _vehicleRegistration.text.trim().isEmpty ? null : _vehicleRegistration.text.trim(),
      notes: _vehicleNotes.text.trim(),
      insuranceExpiresAt: insuranceDate,
      maintenanceDueAt: maintenanceDate,
    );
    if (!vehicle.isValid) {
      _message('أدخل الشركة والطراز وسنة صالحة.');
      return;
    }
    setState(() => _vehicles.add(vehicle));
    try {
      await _localStore.saveVehicles(_vehicles);
    } catch (_) {
      _message('أُضيفت المركبة للشاشة، لكن تعذر حفظها على الجهاز.');
    }
    _vehicleMake.clear(); _vehicleModel.clear(); _vehicleYear.clear();
    _vehicleRegistration.clear(); _vehicleNotes.clear(); _insuranceExpiry.clear(); _maintenanceDue.clear();
  }

  Future<void> _saveShipment() async {
    final shipment = CargoShipment(
      reference: _cargoRef.text,
      origin: _cargoOrigin.text,
      destination: _cargoDestination.text,
      carrier: _cargoCarrier.text.trim().isEmpty ? null : _cargoCarrier.text.trim(),
      status: _cargoStatus,
      deliveryRequirements: _cargoRequirements.text
          .split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList(),
      notes: _cargoNotes.text.trim(),
    );
    if (!shipment.isValid) {
      _message('مرجع الشحنة ونقطة الإرسال والتسليم مطلوبة.');
      return;
    }
    setState(() => _shipments.add(shipment));
    try {
      await _localStore.saveShipments(_shipments);
    } catch (_) {
      _message('أُضيفت الشحنة للشاشة، لكن تعذر حفظها على الجهاز.');
    }
    _cargoRef.clear(); _cargoOrigin.clear(); _cargoDestination.clear(); _cargoCarrier.clear();
    _cargoRequirements.clear(); _cargoNotes.clear();
    setState(() => _cargoStatus = CargoStatus.draft);
  }

  Future<void> _savePort() async {
    final source = _portSource.text.trim();
    final port = PortInformation(
      portName: _portName.text,
      country: _portCountry.text,
      evidence: source.isEmpty
          ? null
          : MobilityEvidence(sourceName: source, observedAt: DateTime.now()),
    );
    if (!port.isPublishable) {
      _message('أدخل اسم الميناء والدولة ومصدرًا واضحًا للمعلومات.');
      return;
    }
    setState(() => _ports.add(port));
    try {
      await _localStore.savePorts(_ports);
    } catch (_) {
      _message('أُضيفت معلومات الميناء للشاشة، لكن تعذر حفظها على الجهاز.');
    }
    _portName.clear(); _portCountry.clear(); _portSource.clear();
  }

  void _calculateCost() {
    final estimate = MobilityCostEstimate(
      distanceKm: _number(_distance) ?? double.nan,
      trips: int.tryParse(_trips.text.trim()) ?? 0,
      fuelLitresPer100Km: _number(_consumption) ?? double.nan,
      fuelPricePerLitre: _number(_fuelPrice) ?? double.nan,
      tolls: _number(_tolls) ?? double.nan,
      parking: _number(_parking) ?? double.nan,
      otherCosts: _number(_other) ?? double.nan,
      currency: _currency.text,
    );
    setState(() {
      if (!estimate.isValid) {
        _estimate = null;
        _costError = 'راجع المدخلات؛ استخدم أرقامًا غير سالبة وحدد العملة.';
      } else {
        _estimate = estimate;
        _costError = null;
      }
    });
  }

  String _cargoStatusLabel(CargoStatus status) => switch (status) {
    CargoStatus.draft => 'مسودة',
    CargoStatus.prepared => 'جاهزة',
    CargoStatus.inTransit => 'قيد النقل',
    CargoStatus.delayed => 'متأخرة',
    CargoStatus.delivered => 'تم التسليم',
    CargoStatus.cancelled => 'ملغاة',
  };

  String _vehicleSummary(VehicleRecord vehicle) {
    final now = DateTime.now();
    final alerts = <String>[];
    if (vehicle.insuranceNeedsAttention(now)) alerts.add('تنبيه: التأمين يحتاج مراجعة');
    if (vehicle.maintenanceNeedsAttention(now)) alerts.add('تنبيه: موعد الصيانة حان أو فات');
    final details = '${vehicle.year} ${vehicle.make} ${vehicle.model} • التسجيل: ${vehicle.registrationId ?? 'غير مدخل'} • ملاحظات: ${vehicle.notes.isEmpty ? 'لا توجد' : vehicle.notes} • التأمين: ${vehicle.insuranceExpiresAt?.toIso8601String().split('T').first ?? 'غير مدخل'} • الصيانة: ${vehicle.maintenanceDueAt?.toIso8601String().split('T').first ?? 'غير مدخل'}';
    return alerts.isEmpty ? details : '$details • ${alerts.join(' • ')}';
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Widget _field(String label, TextEditingController controller,
      {String? hint, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _savedItems<T>(List<T> items, String empty, String Function(T) label) {
    if (items.isEmpty) return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(empty, style: Theme.of(context).textTheme.bodySmall),
    );
    return Column(
      children: items.map((item) => ListTile(
        dense: true,
        leading: const Icon(Icons.check_circle_outline),
        title: Text(label(item)),
      )).toList(),
    );
  }

  Widget _section({required IconData icon, required String title,
      required String description, required List<Widget> children}) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(description),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUREN Mobility & Transport'),
        actions: [
          IconButton(
            tooltip: 'اسأل AUREN',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const MessengerScreen(
                initialPrompt: 'ساعدني في تنظيم معلومات النقل والمركبات والتكاليف والشحن داخل AUREN. لا تفترض أسعارًا أو مواعيد غير موثقة.',
              ),
            )),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loadingRecords) const LinearProgressIndicator(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تنقّل أوضح، دون معلومات مختلقة', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('أدخل بياناتك بنفسك. المسارات والموانئ لا تُعرض كبيانات موثوقة إلا عند تسمية المصدر. لا توجد حجوزات أو مدفوعات تلقائية.'),
                const SizedBox(height: 8),
                const Text('تُحفظ المسارات والمركبات والشحنات ومعلومات الموانئ محليًا على الجهاز، دون مزامنة سحابية.'),
              ]),
            ),
          ),
          _section(
            icon: Icons.directions_bus_outlined,
            title: 'Public Transport Intelligence',
            description: 'المسارات والتوقفات من مصدر يحدده المستخدم',
            children: [
              _field('اسم المشغّل', _routeOperator),
              _field('اسم / رقم المسار', _routeName),
              _field('التوقفات بالترتيب، مفصولة بفواصل', _routeStops),
              _field('مصدر المعلومات', _routeSource, hint: 'مثال: موقع المشغّل أو جدول رسمي'),
              Align(alignment: Alignment.centerRight, child: FilledButton(
                onPressed: _loadingRecords ? null : _saveRoute, child: const Text('حفظ محليًا'))),
              _savedItems(_routes, 'لا توجد مسارات محفوظة. لن نخترع مسارات أو مواعيد.', (r) => '${r.routeName} • ${r.operator} • ${r.stops.length} توقفات • المصدر: ${r.evidence?.sourceName ?? 'غير موثق'}'),
            ],
          ),
          _section(
            icon: Icons.directions_car_outlined,
            title: 'Vehicle Ownership',
            description: 'سجل المركبات ومتابعة الوثائق والصيانة',
            children: [
              _field('الشركة / الصانع', _vehicleMake),
              _field('الطراز', _vehicleModel),
              _field('سنة الصنع', _vehicleYear, keyboard: TextInputType.number),
              _field('رقم التسجيل (اختياري)', _vehicleRegistration),
              _field('ملاحظات المركبة (اختياري)', _vehicleNotes),
              _field('انتهاء التأمين YYYY-MM-DD (اختياري)', _insuranceExpiry),
              _field('موعد الصيانة YYYY-MM-DD (اختياري)', _maintenanceDue),
              Align(alignment: Alignment.centerRight, child: FilledButton(
                onPressed: _loadingRecords ? null : _saveVehicle, child: const Text('إضافة مركبة'))),
              _savedItems(_vehicles, 'لا توجد مركبات مسجلة.', _vehicleSummary),
            ],
          ),
          _section(
            icon: Icons.calculate_outlined,
            title: 'Mobility Cost Planner',
            description: 'تقدير واضح مبني على مدخلاتك فقط',
            children: [
              _field('المسافة لكل رحلة (كم)', _distance, keyboard: TextInputType.number),
              _field('عدد الرحلات', _trips, keyboard: TextInputType.number),
              _field('استهلاك الوقود (لتر / 100 كم)', _consumption, keyboard: TextInputType.number),
              _field('سعر لتر الوقود', _fuelPrice, keyboard: TextInputType.number),
              _field('رسوم الطريق لكل رحلة', _tolls, keyboard: TextInputType.number),
              _field('مواقف لكل رحلة', _parking, keyboard: TextInputType.number),
              _field('تكاليف أخرى لكل رحلة', _other, keyboard: TextInputType.number),
              _field('العملة', _currency, hint: 'اكتب العملة بنفسك، مثل SDG'),
              Align(alignment: Alignment.centerRight, child: FilledButton(
                onPressed: _calculateCost, child: const Text('احسب التقدير'))),
              if (_costError != null) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_costError!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
              if (_estimate != null) Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('الإجمالي التقديري: ${_estimate!.total.toStringAsFixed(2)} ${_estimate!.currency}',
                    style: Theme.of(context).textTheme.titleMedium),
                  Text('الوقود: ${_estimate!.fuelCost.toStringAsFixed(2)} ${_estimate!.currency}'),
                  const Text('الافتراضات: المسافة والاستهلاك والأسعار والرسوم من إدخالك؛ لا يشمل التقدير أي بند لم تدخله.'),
                ]),
              ),
            ],
          ),
          _section(
            icon: Icons.local_shipping_outlined,
            title: 'Freight & Cargo Coordination',
            description: 'تنظيم مرجع الشحنة وحالتها ومتطلبات التسليم',
            children: [
              _field('مرجع الشحنة', _cargoRef),
              _field('من', _cargoOrigin),
              _field('إلى', _cargoDestination),
              _field('الناقل (اختياري)', _cargoCarrier),
              _field('متطلبات التسليم، مفصولة بفواصل (اختياري)', _cargoRequirements),
              _field('ملاحظات (اختياري)', _cargoNotes),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DropdownButtonFormField<CargoStatus>(
                  value: _cargoStatus,
                  decoration: const InputDecoration(
                    labelText: 'حالة الشحنة',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: CargoStatus.values.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(_cargoStatusLabel(status)),
                  )).toList(),
                  onChanged: (status) {
                    if (status != null) setState(() => _cargoStatus = status);
                  },
                ),
              ),
              Align(alignment: Alignment.centerRight, child: FilledButton(
                onPressed: _loadingRecords ? null : _saveShipment, child: const Text('حفظ مسودة الشحنة'))),
              _savedItems(_shipments, 'لا توجد شحنات. الحفظ هنا لا يرسل طلبًا إلى ناقل.', (s) => '${s.reference}: ${s.origin} → ${s.destination} • ${_cargoStatusLabel(s.status)}${s.deliveryRequirements.isEmpty ? '' : ' • المتطلبات: ${s.deliveryRequirements.join(', ')}'}'),
            ],
          ),
          _section(
            icon: Icons.anchor_outlined,
            title: 'Maritime & Port Intelligence',
            description: 'ملاحظات الموانئ مع توثيق المصدر',
            children: [
              _field('اسم الميناء', _portName),
              _field('الدولة', _portCountry),
              _field('مصدر المعلومات', _portSource, hint: 'مصدر رسمي أو مشغّل الميناء'),
              Align(alignment: Alignment.centerRight, child: FilledButton(
                onPressed: _loadingRecords ? null : _savePort, child: const Text('حفظ معلومات الميناء'))),
              _savedItems(_ports, 'لا توجد معلومات موانئ موثقة. لا نعرض حالة تشغيل أو مواعيد مباشرة دون مصدر.', (p) => '${p.portName} • ${p.country} • المصدر: ${p.evidence?.sourceName ?? 'غير موثق'}'),
            ],
          ),
        ],
      ),
    );
  }
}
