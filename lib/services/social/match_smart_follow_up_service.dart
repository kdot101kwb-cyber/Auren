import '../../core/models/message.dart';

class AurenSmartFollowUp {
  final String summary;
  final String? price;
  final String? currency;
  final String? minimumOrder;
  final String? leadTime;
  final String? shipping;
  final String? quantity;
  final List<String> missing;
  final List<String> questions;

  const AurenSmartFollowUp({
    required this.summary,
    this.price,
    this.currency,
    this.minimumOrder,
    this.leadTime,
    this.shipping,
    this.quantity,
    this.missing = const [],
    this.questions = const [],
  });

  bool get hasDetails =>
      price != null ||
      minimumOrder != null ||
      leadTime != null ||
      shipping != null ||
      quantity != null;

  String get questionsText => questions.join('\n');
}

class AurenSmartFollowUpService {
  AurenSmartFollowUp analyze({
    required AurenMessage reply,
    required String action,
    required String intent,
  }) {
    final text = reply.text.trim();
    final lower = text.toLowerCase();

    final price = _extractPrice(text);
    final currency = _extractCurrency(text);
    final moq = _extract(text, [
      RegExp(
        r'(?:moq|minimum\s+order|minimum\s+quantity|حد\s*أدنى|اقل\s+كمية|أقل\s+كمية)\s*[:：-]?\s*([\d٠-٩.,]+(?:\s*[a-zA-Z%]+)?(?:\s*(?:pcs|pieces|قطعة|قطع|وحدة|كرتون|كرتونة))?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:moq|minimum\s+order|minimum\s+quantity)\s*(?:is|=|:)?\s*([\d٠-٩.,]+)',
        caseSensitive: false,
      ),
    ]);
    final lead = _extract(text, [
      RegExp(
        r'(?:lead\s*time|production\s*time|preparation|مدة\s*(?:التجهيز|التصنيع)|زمن\s*(?:التجهيز|التصنيع))\s*[:：-]?\s*([^،,.;\n]{1,40})',
        caseSensitive: false,
      ),
      RegExp(
        r'([\d٠-٩]+)\s*(?:days?|أيام?|يوم)',
        caseSensitive: false,
      ),
    ]);
    final shipping = _extract(text, [
      RegExp(
        r'(?:shipping|delivery|الشحن|التوصيل|التسليم)\s*[:：-]?\s*([^،,.;\n]{1,70})',
        caseSensitive: false,
      ),
    ]);
    final quantity = _extract(text, [
      RegExp(
        r'(?:quantity|qty|الكمية)\s*[:：-]?\s*([\d٠-٩.,]+)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:عايز|أريد|اريد|نحتاج|نريد|need|want|looking\s+for)\s*([\d٠-٩.,]+)\s*(?:قطعة|قطع|وحدة|pcs|pieces)',
        caseSensitive: false,
      ),
    ]);

    final missing = <String>[];
    final questions = <String>[];

    if (action == 'requestQuote') {
      if (price == null) {
        missing.add('السعر');
        questions.add('ما السعر النهائي للكمية المطلوبة، وبأي عملة؟');
      }
      if (moq == null) {
        missing.add('الحد الأدنى للطلب');
        questions.add('ما الحد الأدنى للطلب (MOQ)؟');
      }
      if (lead == null) {
        missing.add('مدة التجهيز');
        questions.add('كم مدة التجهيز أو التصنيع؟');
      }
      if (shipping == null) {
        missing.add('خيارات الشحن');
        questions.add('ما خيارات الشحن والتكلفة ومدة التوصيل إلى الوجهة؟');
      }
      if (quantity == null &&
          _containsAny(lower, ['quote', 'عرض سعر', 'السعر', 'price'])) {
        missing.add('الكمية');
        questions.add('ما الكمية التي يمكن تسعيرها في العرض؟');
      }
    } else if (action == 'apply') {
      if (!_containsAny(lower, [
        'next',
        'step',
        'خطوة',
        'مستند',
        'document',
        'cv',
        'سيرة',
        'apply',
        'تقديم',
      ])) {
        missing.add('الخطوة التالية');
        questions.add(
          'ما الخطوة التالية، وهل توجد مستندات أو معلومات إضافية مطلوبة؟',
        );
      }
    } else if (action == 'contact') {
      if (text.length < 20) {
        missing.add('تفاصيل كافية للرد');
        questions.add('هل يمكنك توضيح التفاصيل المطلوبة أو الخطوة التالية؟');
      }
    }

    final detailParts = <String>[
      if (price != null)
        'السعر: ' + price + (currency == null ? '' : ' ' + currency),
      if (moq != null) 'MOQ: ' + moq,
      if (lead != null) 'التجهيز: ' + lead,
      if (shipping != null) 'الشحن: ' + shipping,
      if (quantity != null) 'الكمية: ' + quantity,
    ];

    final summary = detailParts.isEmpty
        ? 'تم استلام الرد. لم يتم استخراج تفاصيل منظمة كافية بعد.'
        : detailParts.join(' • ');

    return AurenSmartFollowUp(
      summary: summary,
      price: price,
      currency: currency,
      minimumOrder: moq,
      leadTime: lead,
      shipping: shipping,
      quantity: quantity,
      missing: missing,
      questions: questions,
    );
  }

  String? _extractPrice(String text) {
    final patterns = [
      RegExp(
        r'(?:[$€£]|USD|EUR|GBP|دولار|يورو|جنيه)\s*([\d٠-٩][\d٠-٩.,]*)',
        caseSensitive: false,
      ),
      RegExp(
        r'([\d٠-٩][\d٠-٩.,]*)\s*(?:USD|EUR|GBP|دولار|يورو|جنيه)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:price|السعر)\s*[:：-]?\s*([\d٠-٩][\d٠-٩.,]*)',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  String? _extractCurrency(String text) {
    final currencies = [
      RegExp(r'\b(USD|EUR|GBP)\b', caseSensitive: false),
      RegExp(r'([$€£])'),
      RegExp(r'(دولار|يورو|جنيه)', caseSensitive: false),
    ];
    for (final pattern in currencies) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  String? _extract(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = match.groupCount >= 1 ? match.group(1) : match.group(0);
        if (value != null && value.trim().isNotEmpty) return value.trim();
      }
    }
    return null;
  }

  bool _containsAny(String text, List<String> values) =>
      values.any(text.contains);
}
