/// Extensible finance domain for NOVA. Add providers/categories here without
/// coupling wallet UI to provider-specific APIs.
class NovaFinanceProvider {
  final String id;
  final String name;
  final String defaultCurrency;
  final List<String> supportedCurrencies;
  final String integrationMode;
  final String? officialUrl;

  const NovaFinanceProvider({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    required this.supportedCurrencies,
    this.integrationMode = 'manual_only',
    this.officialUrl,
  });
}

class NovaFinanceRegistry {
  NovaFinanceRegistry._();

  static const providers = <NovaFinanceProvider>[
    NovaFinanceProvider(id: 'bravo', name: 'Bravo', defaultCurrency: 'SDG', supportedCurrencies: ['SDG', 'USD'], officialUrl: 'https://play.google.com/store/apps/details?id=istinara.bravocash'),
    NovaFinanceProvider(id: 'mycashi', name: 'MyCashi', defaultCurrency: 'SDG', supportedCurrencies: ['SDG', 'USD'], officialUrl: 'https://play.google.com/store/apps/details?id=com.alsoug.mycashi'),
    NovaFinanceProvider(id: 'trust_wallet', name: 'Trust Wallet', defaultCurrency: 'USDT', supportedCurrencies: ['USDT', 'USD', 'BTC', 'ETH', 'TRX'], officialUrl: 'https://trustwallet.com/'),
    NovaFinanceProvider(id: 'paypal', name: 'PayPal', defaultCurrency: 'USD', supportedCurrencies: ['USD', 'EUR', 'GBP', 'SAR'], officialUrl: 'https://www.paypal.com/'),
  ];

  static const categories = <NovaFinanceCategory>[
    NovaFinanceCategory(id: 'services', name: 'خدمات وعمل حر', appliesTo: 'income'),
    NovaFinanceCategory(id: 'salary', name: 'راتب أو أجر', appliesTo: 'income'),
    NovaFinanceCategory(id: 'sales', name: 'مبيعات', appliesTo: 'income'),
    NovaFinanceCategory(id: 'affiliate', name: 'عمولات وتسويق بالعمولة', appliesTo: 'income'),
    NovaFinanceCategory(id: 'investment', name: 'استثمار', appliesTo: 'both'),
    NovaFinanceCategory(id: 'food', name: 'طعام واحتياجات', appliesTo: 'expense'),
    NovaFinanceCategory(id: 'transport', name: 'مواصلات', appliesTo: 'expense'),
    NovaFinanceCategory(id: 'bills', name: 'فواتير واتصالات', appliesTo: 'expense'),
    NovaFinanceCategory(id: 'tools', name: 'أدوات واشتراكات', appliesTo: 'expense'),
    NovaFinanceCategory(id: 'transfer', name: 'تحويل بين محافظ', appliesTo: 'both'),
    NovaFinanceCategory(id: 'other', name: 'أخرى', appliesTo: 'both'),
  ];

  static NovaFinanceProvider? provider(String id) {
    for (final item in providers) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class NovaFinanceCategory {
  final String id;
  final String name;
  final String appliesTo;

  const NovaFinanceCategory({required this.id, required this.name, this.appliesTo = 'both'});
}

class NovaFinanceTransaction {
  static const currentSchemaVersion = 2;
  final String id;
  final String walletId;
  final String type;
  final double amount;
  final String currency;
  final String categoryId;
  final String note;
  final String reference;
  final String counterparty;
  final List<String> tags;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String status;
  final bool providerVerified;
  final Map<String, dynamic> metadata;

  const NovaFinanceTransaction({
    required this.id, required this.walletId, required this.type,
    required this.amount, required this.currency,
    this.categoryId = 'other', this.note = '', this.reference = '',
    this.counterparty = '', this.tags = const [],
    required this.occurredAt, required this.createdAt,
    this.status = 'recorded_by_user', this.providerVerified = false,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': currentSchemaVersion, 'id': id, 'walletId': walletId,
    'type': type, 'amount': amount, 'currency': currency,
    'categoryId': categoryId, 'note': note, 'reference': reference,
    'counterparty': counterparty, 'tags': tags,
    'occurredAt': occurredAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(), 'status': status,
    'providerVerified': providerVerified, 'metadata': metadata,
  };

  factory NovaFinanceTransaction.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final created = DateTime.tryParse('${json['createdAt'] ?? json['occurredAt'] ?? ''}') ?? now;
    return NovaFinanceTransaction(
      id: '${json['id'] ?? created.microsecondsSinceEpoch}',
      walletId: '${json['walletId'] ?? ''}',
      type: '${json['type'] ?? 'expense'}',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: '${json['currency'] ?? 'SDG'}'.toUpperCase(),
      categoryId: '${json['categoryId'] ?? 'other'}',
      note: '${json['note'] ?? ''}',
      reference: '${json['reference'] ?? ''}',
      counterparty: '${json['counterparty'] ?? ''}',
      tags: (json['tags'] as List<dynamic>? ?? const []).map((e) => '$e').toList(),
      occurredAt: DateTime.tryParse('${json['occurredAt'] ?? ''}') ?? created,
      createdAt: created,
      status: '${json['status'] ?? 'recorded_by_user'}',
      providerVerified: json['providerVerified'] == true,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }
}
