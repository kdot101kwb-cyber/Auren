import 'package:flutter/material.dart';
import '../../../services/agriculture/agriculture_market_prices_service.dart';

class AgricultureMarketPricesScreen extends StatefulWidget {
  const AgricultureMarketPricesScreen({super.key});
  @override State<AgricultureMarketPricesScreen> createState() => _AgricultureMarketPricesScreenState();
}

class _AgricultureMarketPricesScreenState extends State<AgricultureMarketPricesScreen> {
  final _country = TextEditingController(text:'ALL');
  final _state = TextEditingController();
  final _city = TextEditingController();
  final _commodity = TextEditingController();
  final _service = AgricultureMarketPricesService();
  List<AgricultureMarketPrice> _global = const [];
  List<AgricultureMarketPrice> _local = const [];
  String? _note;
  bool _loading = false;

  @override
  void dispose() { _country.dispose(); _state.dispose(); _city.dispose(); _commodity.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final country = _country.text.trim().toUpperCase();
      final data = await _service.getPrices(country:country.isEmpty ? 'ALL' : country, state:_state.text, city:_city.text, commodity:_commodity.text);
      if (!mounted) return;
      setState(() {
        _global = List<AgricultureMarketPrice>.from(data['global'] as List);
        _local = List<AgricultureMarketPrice>.from(data['local'] as List);
        _note = data['localDataNote']?.toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _note = 'تعذر تحميل الأسعار حالياً: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AUREN Market Prices')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('أسعار الزراعة والثروة الحيوانية', style: TextStyle(fontSize:21,fontWeight:FontWeight.w900)),
              const SizedBox(height:6),
              const Text('البورصات العالمية + الأسعار المحلية الموثقة لكل الدول، حسب ISO3 ثم الولاية والمدينة والسوق.'),
              const SizedBox(height:12),
              Row(children:[
                Expanded(child:_field(_country,'الدولة ISO3 أو ALL')),
                const SizedBox(width:8),
                Expanded(child:_field(_state,'الولاية')),
              ]),
              _field(_city,'المدينة'),
              _field(_commodity,'المحصول / السلعة (اختياري)'),
              SizedBox(width:double.infinity,child:FilledButton.icon(
                onPressed:_loading ? null : _load,
                icon:_loading ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.refresh),
                label:Text(_loading ? 'جاري التحديث...' : 'تحديث الأسعار'),
              )),
            ]),
          )),
          const SizedBox(height:16),
          _section('البورصة العالمية', _global, Icons.public),
          const SizedBox(height:12),
          _section('السوق المحلي', _local, Icons.storefront_outlined),
          if (_note != null) Padding(
            padding: const EdgeInsets.only(top:12),
            child: Card(child: Padding(padding:const EdgeInsets.all(14),child:Text(_note!))),
          ),
        ],
      ),
    ),
  );

  Widget _field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom:8),
    child: TextField(controller:c,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())),
  );

  Widget _section(String title, List<AgricultureMarketPrice> rows, IconData icon) {
    if (rows.isEmpty) return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
      const SizedBox(height:6),
      const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('لا توجد بيانات متاحة حالياً.'))),
    ]);
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
      const SizedBox(height:6),
      ...rows.map((p)=>Card(child:ListTile(
        leading:CircleAvatar(child:Icon(icon)),
        title:Text('\${p.commodity}',style:const TextStyle(fontWeight:FontWeight.w800)),
        subtitle:Text([
          if(p.marketName.isNotEmpty)p.marketName,
          if(p.state.isNotEmpty)p.state,
          if(p.city.isNotEmpty)p.city,
          if(p.exchange != null && p.exchange!.isNotEmpty)p.exchange!,
          p.source,
        ].join(' • '),maxLines:3,overflow:TextOverflow.ellipsis),
        trailing:SizedBox(width:110,child:Text(
          '\${p.price.toStringAsFixed(2)} \${p.currency}',
          textAlign:TextAlign.end,
          style:const TextStyle(fontWeight:FontWeight.w900),
        )),
      ))),
    ]);
  }
}
