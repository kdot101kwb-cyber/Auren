/// Offline, deterministic first-pass extraction for supplier RFQ requests.
class SupplierRfqIntent {
  const SupplierRfqIntent({this.product,this.quantity,this.unit,this.destination,this.budget,this.currency,this.leadTime});
  final String? product, quantity, unit, destination, budget, currency, leadTime;
  bool get hasUsefulFields => [product,quantity,destination,budget,currency,leadTime].any((v)=>v!=null&&v!.isNotEmpty);
  List<String> get missingRequiredFields => [
    if(product==null) 'المنتج',
    if(quantity==null) 'الكمية',
    if(destination==null) 'وجهة التسليم',
  ];
}
class SupplierRfqIntentParser {
  const SupplierRfqIntentParser._();
  static SupplierRfqIntent parse(String input) {
    final text=_digits(input).replaceAll(RegExp(r'\s+'),' ').trim();
    if(text.isEmpty) return const SupplierRfqIntent();
    final qm=RegExp(r'(?:quantity\s*[:=]?\s*|qty\s*[:=]?\s*|الكمية\s*[:=]?\s*|عدد\s*)?(\d+(?:[,.]\d+)?)\s*(pieces?|pcs|units?|kg|g|tons?|liters?|litres?|meters?|metres?|yards?|boxes?|قطعة|قطع|حبة|حبات|كيلو(?:غرام)?|طن|لتر|متر|كرتون|صندوق)?',caseSensitive:false).firstMatch(text);
    final quantity=qm?.group(1)?.replaceAll(',','.');
    final unit=_unit(qm?.group(2));
    String? destination;
    final dm=RegExp(r'(?:delivered\s+to|ship(?:ped)?\s+to|destination\s*[:=]?|to|إلى|الى|للتسليم في|التسليم إلى|في)\s+(.+)',caseSensitive:false).firstMatch(text);
    if(dm!=null){
      destination=dm.group(1)!.trim().replaceFirst(RegExp(r'\s+(?:with a budget|budget|under|within|in\s+\d+\s+days|خلال|بميزانية|ميزانية|بحدود).*
      if(destination.isEmpty) destination=null;
    }
    String? budget,currency;
    final bm=RegExp(r'(?:budget|بميزانية|ميزانية|بحدود|حد أقصى)\s*[:=]?\s*(USD|EUR|SDG|KES|NGN|\$|€)?\s*(\d[\d,.]*)\s*(USD|EUR|SDG|KES|NGN|دولار|دولارات|يورو|جنيه)?',caseSensitive:false).firstMatch(text);
    final sm=RegExp(r'([$€])\s*(\d[\d,.]*)').firstMatch(text);
    if(bm!=null){budget=bm.group(2)?.replaceAll(',','');currency=_currency(bm.group(1))??_currency(bm.group(3));}
    else if(sm!=null){budget=sm.group(2)?.replaceAll(',','');currency=_currency(sm.group(1));}
    final ec=RegExp(r'\b(USD|EUR|SDG|KES|NGN)\b',caseSensitive:false).firstMatch(text);
    currency ??= _currency(ec?.group(1));
    if(currency==null&&RegExp(r'دولار|دولارات').hasMatch(text)) currency='USD';
    if(currency==null&&RegExp(r'يورو').hasMatch(text)) currency='EUR';
    String? leadTime;
    final lm=RegExp(r'(?:within|in|lead time\s*[:=]?|خلال|مدة التوريد\s*[:=]?)\s*(\d+)\s*(days?|weeks?|أيام|يوم|أسابيع|أسبوع)',caseSensitive:false).firstMatch(text);
    if(lm!=null) leadTime='${lm.group(1)} ${lm.group(2)}';
    String? product;
    if(qm!=null){
      var before=text.substring(0,qm.start).trim().replaceFirst(RegExp(r'^(?:i need|need|looking for|طلب|أحتاج|احتاج|عايز|عاوز|محتاج|اريد|أريد)\s+',caseSensitive:false),'');
      before=before.replaceFirst(RegExp(r'^(?:about|around|approximately)\s+',caseSensitive:false),'');
      if(before.isNotEmpty) product=before;
      if(product==null||product.isEmpty){
        var after=text.substring(qm.end).trim().replaceFirst(RegExp(r'^(?:of|من)\s+'),'');
        if(after.isNotEmpty) product=after.split(RegExp(r'\s+(?:delivered\s+to|shipped?\s+to|with\s+a\s+budget|budget|within|to|in|for|إلى|الى|في|بميزانية|خلال)\s+',caseSensitive:false)).first.trim();
      }
    } else {
      final pm=RegExp(r'(?:i need|need|looking for|product\s*[:=]?|المنتج\s*[:=]?|أحتاج|احتاج|عايز|عاوز|محتاج|اريد|أريد)\s+(.+)',caseSensitive:false).firstMatch(text);
      if(pm!=null) product=pm.group(1)!.split(RegExp(r'\s+(?:to|in|for|إلى|الى|في|بميزانية|ميزانية|خلال)\s+',caseSensitive:false)).first.trim();
    }
    if(product!=null){product=product.replaceFirst(RegExp(r'\s+(?:budget|بميزانية|ميزانية|\$|€).*$',caseSensitive:false),'').trim();if(product.isEmpty)product=null;}
    return SupplierRfqIntent(product:product,quantity:quantity==null?null:'$quantity${unit==null?'':' $unit'}',unit:unit,destination:destination,budget:budget,currency:currency,leadTime:leadTime);
  }
  static String _digits(String value){
    const a='٠١٢٣٤٥٦٧٨٩',p='۰۱۲۳۴۵۶۷۸۹'; final out=StringBuffer();
    for(final rune in value.runes){final c=String.fromCharCode(rune), ai=a.indexOf(c), pi=p.indexOf(c);out.write(ai>=0?ai:pi>=0?pi:c);} return out.toString();
  }
  static String? _unit(String? raw){
    if(raw==null||raw.isEmpty)return null; final v=raw.toLowerCase();
    if(['piece','pieces','pcs','unit','units','قطعة','قطع','حبة','حبات'].contains(v))return 'pieces';
    if(['kg','g','كيلو','كيلوغرام'].contains(v))return v=='g'?'g':'kg';
    if(['ton','tons','طن'].contains(v))return 'tons';
    if(['liter','liters','litre','litres','لتر'].contains(v))return 'liters';
    if(['meter','meters','metre','metres','متر'].contains(v))return 'meters';
    if(['yard','yards'].contains(v))return 'yards';
    if(['box','boxes','صندوق','كرتون'].contains(v))return 'boxes';
    return v;
  }
  static String? _currency(String? raw){
    if(raw==null)return null;
    switch(raw.toUpperCase()){
      case 'USD': case r'$': case 'دولار': case 'دولارات': return 'USD';
      case 'EUR': case '€': case 'يورو': return 'EUR';
      case 'SDG': return 'SDG'; case 'KES': return 'KES'; case 'NGN': return 'NGN';
      default:return null;
    }
  }
},caseSensitive:false),'').trim();
      if(destination.isEmpty) destination=null;
    }
    String? budget,currency;
    final bm=RegExp(r'(?:budget|بميزانية|ميزانية|بحدود|حد أقصى)\s*[:=]?\s*(USD|EUR|SDG|KES|NGN|\$|€)?\s*(\d[\d,.]*)\s*(USD|EUR|SDG|KES|NGN|دولار|دولارات|يورو|جنيه)?',caseSensitive:false).firstMatch(text);
    final sm=RegExp(r'([$€])\s*(\d[\d,.]*)').firstMatch(text);
    if(bm!=null){budget=bm.group(2)?.replaceAll(',','');currency=_currency(bm.group(1))??_currency(bm.group(3));}
    else if(sm!=null){budget=sm.group(2)?.replaceAll(',','');currency=_currency(sm.group(1));}
    final ec=RegExp(r'\b(USD|EUR|SDG|KES|NGN)\b',caseSensitive:false).firstMatch(text);
    currency ??= _currency(ec?.group(1));
    if(currency==null&&RegExp(r'دولار|دولارات').hasMatch(text)) currency='USD';
    if(currency==null&&RegExp(r'يورو').hasMatch(text)) currency='EUR';
    String? leadTime;
    final lm=RegExp(r'(?:within|in|lead time\s*[:=]?|خلال|مدة التوريد\s*[:=]?)\s*(\d+)\s*(days?|weeks?|أيام|يوم|أسابيع|أسبوع)',caseSensitive:false).firstMatch(text);
    if(lm!=null) leadTime='${lm.group(1)} ${lm.group(2)}';
    String? product;
    if(qm!=null){
      var before=text.substring(0,qm.start).trim().replaceFirst(RegExp(r'^(?:i need|need|looking for|طلب|أحتاج|احتاج|عايز|عاوز|محتاج|اريد|أريد)\s+',caseSensitive:false),'');
      before=before.replaceFirst(RegExp(r'^(?:about|around|approximately)\s+',caseSensitive:false),'');
      if(before.isNotEmpty) product=before;
      if(product==null||product.isEmpty){
        var after=text.substring(qm.end).trim().replaceFirst(RegExp(r'^(?:of|من)\s+'),'');
        if(after.isNotEmpty) product=after.split(RegExp(r'\s+(?:delivered\s+to|shipped?\s+to|with\s+a\s+budget|budget|within|to|in|for|إلى|الى|في|بميزانية|خلال)\s+',caseSensitive:false)).first.trim();
      }
    } else {
      final pm=RegExp(r'(?:i need|need|looking for|product\s*[:=]?|المنتج\s*[:=]?|أحتاج|احتاج|عايز|عاوز|محتاج|اريد|أريد)\s+(.+)',caseSensitive:false).firstMatch(text);
      if(pm!=null) product=pm.group(1)!.split(RegExp(r'\s+(?:to|in|for|إلى|الى|في|بميزانية|ميزانية|خلال)\s+',caseSensitive:false)).first.trim();
    }
    if(product!=null){product=product.replaceFirst(RegExp(r'\s+(?:budget|بميزانية|ميزانية|\$|€).*$',caseSensitive:false),'').trim();if(product.isEmpty)product=null;}
    return SupplierRfqIntent(product:product,quantity:quantity==null?null:'$quantity${unit==null?'':' $unit'}',unit:unit,destination:destination,budget:budget,currency:currency,leadTime:leadTime);
  }
  static String _digits(String value){
    const a='٠١٢٣٤٥٦٧٨٩',p='۰۱۲۳۴۵۶۷۸۹'; final out=StringBuffer();
    for(final rune in value.runes){final c=String.fromCharCode(rune), ai=a.indexOf(c), pi=p.indexOf(c);out.write(ai>=0?ai:pi>=0?pi:c);} return out.toString();
  }
  static String? _unit(String? raw){
    if(raw==null||raw.isEmpty)return null; final v=raw.toLowerCase();
    if(['piece','pieces','pcs','unit','units','قطعة','قطع','حبة','حبات'].contains(v))return 'pieces';
    if(['kg','g','كيلو','كيلوغرام'].contains(v))return v=='g'?'g':'kg';
    if(['ton','tons','طن'].contains(v))return 'tons';
    if(['liter','liters','litre','litres','لتر'].contains(v))return 'liters';
    if(['meter','meters','metre','metres','متر'].contains(v))return 'meters';
    if(['yard','yards'].contains(v))return 'yards';
    if(['box','boxes','صندوق','كرتون'].contains(v))return 'boxes';
    return v;
  }
  static String? _currency(String? raw){
    if(raw==null)return null;
    switch(raw.toUpperCase()){
      case 'USD': case r'$': case 'دولار': case 'دولارات': return 'USD';
      case 'EUR': case '€': case 'يورو': return 'EUR';
      case 'SDG': return 'SDG'; case 'KES': return 'KES'; case 'NGN': return 'NGN';
      default:return null;
    }
  }
}