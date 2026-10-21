import 'package:flutter/material.dart';

import '../../messenger/presentation/messenger_screen.dart';
import '../domain/mobility_models.dart';

class AurenTransportScreen extends StatefulWidget {
  const AurenTransportScreen({super.key});

  @override
  State<AurenTransportScreen> createState() => _AurenTransportScreenState();
}

class _AurenTransportScreenState extends State<AurenTransportScreen> {
  final _routeOperator = TextEditingController();
  final _routeName = TextEditingController();
  final _routeStops = TextEditingController();
  final _routeSource = TextEditingController();
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleYear = TextEditingController();
  final _cargoRef = TextEditingController();
  final _cargoOrigin = TextEditingController();
  final _cargoDestination = TextEditingController();
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
  void dispose() {
    for (final controller in [
      _routeOperator, _routeName, _routeStops, _routeSource,
      _vehicleMake, _vehicleModel, _vehicleYear,
      _cargoRef, _cargoOrigin, _cargoDestination,
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

  void _saveRoute() {
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
    _routeOperator.clear(); _routeName.clear(); _routeStops.clear(); _routeSource.clear();
  }

  void _saveVehicle() {
    final year = int.tryParse(_vehicleYear.text.trim());
    if (year == null) {
      _message('أدخل سنة مركبة صحيحة.');
      return;
    }
    final vehicle = VehicleRecord(make: _vehicleMake.text, model: _vehicleModel.text, year: year);
    if (!vehicle.isValid) {
      _message('أدخل الشركة والطراز وسنة صالحة.');
      return;
    }
    setState(() => _vehicles.add(vehicle));
    _vehicleMake.clear(); _vehicleModel.clear(); _vehicleYear.clear();
  }

  void _saveShipment() {
    final shipment = CargoShipment(
      reference: _cargoRef.text,
      origin: _cargoOrigin.text,
      destination: _cargoDestination.text,
      status: CargoStatus.draft,
    );
    if (!shipment.isValid) {
      _message('مرجع الشحنة ونقطة الإرسال والتسليم مطلوبة.');
      return;
    }
    setState(() => _shipments.add(shipment));
    _cargoRef.clear(); _cargoOrigin.clear(); _cargoDestination.clear();
  }

  void _savePort() {
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تنقّل أوضح، دون معلومات مختلقة', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('أدخل بياناتك بنفسك. المسارات والموانئ لا تُعرض كبيانات موثوقة إلا عند تسمية المصدر. لا توجد حجوزات أو مدفوعات تلقائية.'),
                const SizedBox(height: 8),
                const Text('ملاحظة: السجلات في هذه النسخة مؤقتة داخل الشاشة ولا تُحفظ بعد إغلاقها.'),
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
                onPressed: _saveRoute, child: const Text('حفظ محليًا'))),
              _savedItems(_routes, 'لا توجد مسارات محفوظة. لن نخترع مسارات أو مواعيد.', (r) => '${r.routeName} • ${r.operator} • ${r.stops.length} توقفات • المصدر: ${r.evidence!.sourceName}'),
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
              Align(alignment: Alignment.centerRight, child: FilledButton(
                onPressed: _saveVehicle, child: const Text('إضافة مركبة'))),
              _savedItems(_vehicles, 'لا توجد مركبات مسجلة.', (v) => '${v.year} ${v.make} ${v.model} • أضف الوثائق والصيانة في مرحلة لاحقة'),
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
              Align(alignment: Alignment.centerRight, child: FilledButton(
                onPressed: _saveShipment, child: const Text('حفظ مسودة الشحنة'))),
              _savedItems(_shipments, 'لا توجد شحنات. الحفظ هنا لا يرسل طلبًا إلى ناقل.', (s) => '${s.reference}: ${s.origin} → ${s.destination} • مسودة'),
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
                onPressed: _savePort, child: const Text('حفظ معلومات الميناء'))),
              _savedItems(_ports, 'لا توجد معلومات موانئ موثقة. لا نعرض حالة تشغيل أو مواعيد مباشرة دون مصدر.', (p) => '${p.portName} • ${p.country} • المصدر: ${p.evidence!.sourceName}'),
            ],
          ),
        ],
      ),
    );
  }
}
