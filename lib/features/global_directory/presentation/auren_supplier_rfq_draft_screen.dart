import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Prepares an editable RFQ draft. It never sends a message to a supplier.
class AurenSupplierRfqDraftScreen extends StatefulWidget {
  const AurenSupplierRfqDraftScreen({super.key});

  @override
  State<AurenSupplierRfqDraftScreen> createState() =>
      _AurenSupplierRfqDraftScreenState();
}

class _AurenSupplierRfqDraftScreenState
    extends State<AurenSupplierRfqDraftScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _destinationController = TextEditingController();
  final _specificationsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _contactController = TextEditingController();
  String _currency = 'USD';
  String _delivery = 'شحن إلى العنوان';
  String? _draft;

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _destinationController.dispose();
    _specificationsController.dispose();
    _budgetController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  String _language = 'ar';

  static const _languages = <String, String>{
    'ar': 'العربية',
    'en': 'English',
    'zh': '中文',
    'fr': 'Français',
    'es': 'Español',
    'tr': 'Türkçe',
    'pt': 'Português',
    'sw': 'Kiswahili',
  };

  String get _localizedDelivery {
    const labels = <String, Map<String, String>>{
      'en': {
        'شحن إلى العنوان': 'Ship to destination',
        'استلام من المورد': 'Pickup from supplier',
        'يُحدّد لاحقاً': 'To be agreed',
      },
      'zh': {
        'شحن إلى العنوان': '送货至指定地点',
        'استلام من المورد': '供应商处自提',
        'يُحدّد لاحقاً': '另行协商',
      },
      'fr': {
        'شحن إلى العنوان': 'Livraison à destination',
        'استلام من المورد': 'Retrait chez le fournisseur',
        'يُحدّد لاحقاً': 'À convenir',
      },
      'es': {
        'شحن إلى العنوان': 'Envío al destino',
        'استلام من المورد': 'Recogida en el proveedor',
        'يُحدّد لاحقاً': 'Por acordar',
      },
      'tr': {
        'شحن إلى العنوان': 'Adrese teslimat',
        'استلام من المورد': 'Tedarikçiden teslim alma',
        'يُحدّد لاحقاً': 'Daha sonra kararlaştırılacak',
      },
      'pt': {
        'شحن إلى العنوان': 'Entrega no destino',
        'استلام من المورد': 'Retirada no fornecedor',
        'يُحدّد لاحقاً': 'A combinar',
      },
      'sw': {
        'شحن إلى العنوان': 'Kusafirisha hadi unakopelekewa',
        'استلام من المورد': 'Kuchukua kwa msambazaji',
        'يُحدّد لاحقاً': 'Kukubaliana baadaye',
      },
    };
    return labels[_language]?[_delivery] ?? _delivery;
  }

  String _buildDraft() {
    final product = _productController.text.trim();
    final quantity = _quantityController.text.trim();
    final destination = _destinationController.text.trim();
    final budget = _budgetController.text.trim();
    final specs = _specificationsController.text.trim();
    final contact = _contactController.text.trim();
    final shownSpecs = specs.isEmpty ? null : specs;
    final shownBudget = budget.isEmpty ? null : '$budget $_currency';
    final shownContact = contact.isEmpty ? null : contact;

    switch (_language) {
      case 'en':
        return '''REQUEST FOR QUOTATION (RFQ)

Hello,
Please provide a quotation for:
- Product/service: $product
- Quantity: $quantity
- Specifications: ${shownSpecs ?? 'Please suggest available options'}
- Delivery destination: $destination
- Delivery method: ${_localizedDelivery}
- Target budget: ${shownBudget ?? 'Please provide available pricing'}
${shownContact == null ? '' : '- Preferred contact method: $shownContact'}

Please include unit and total prices, minimum order quantity, production and delivery lead times, payment and warranty terms, quote validity, and all additional fees.

Thank you.'''.trim();
      case 'zh':
        return '''询价单（RFQ）

您好！
请为以下产品/服务提供报价：
- 产品/服务：$product
- 数量：$quantity
- 规格：${shownSpecs ?? '请推荐可供选择的规格'}
- 交货目的地：$destination
- 交付方式：${_localizedDelivery}
- 目标预算：${shownBudget ?? '请提供可选价格'}
${shownContact == null ? '' : '- 首选联系方式：$shownContact'}

请注明单价和总价、最低订购量、生产及交货时间、付款和保修条款、报价有效期及所有额外费用。

谢谢！'''.trim();
      case 'fr':
        return '''DEMANDE DE DEVIS (RFQ)

Bonjour,
Veuillez nous transmettre un devis pour :
- Produit/service : $product
- Quantité : $quantity
- Spécifications : ${shownSpecs ?? 'Veuillez proposer les options disponibles'}
- Destination de livraison : $destination
- Mode de livraison : ${_localizedDelivery}
- Budget cible : ${shownBudget ?? 'Veuillez indiquer les tarifs disponibles'}
${shownContact == null ? '' : '- Moyen de contact préféré : $shownContact'}

Merci d’indiquer les prix unitaires et totaux, la quantité minimale de commande, les délais de production et de livraison, les conditions de paiement et de garantie, la validité du devis et tous les frais supplémentaires.

Merci.'''.trim();
      case 'es':
        return '''SOLICITUD DE COTIZACIÓN (RFQ)

Hola:
Solicitamos una cotización para:
- Producto/servicio: $product
- Cantidad: $quantity
- Especificaciones: ${shownSpecs ?? 'Por favor, sugiera las opciones disponibles'}
- Destino de entrega: $destination
- Método de entrega: ${_localizedDelivery}
- Presupuesto objetivo: ${shownBudget ?? 'Indique los precios disponibles'}
${shownContact == null ? '' : '- Medio de contacto preferido: $shownContact'}

Incluya precios unitarios y totales, pedido mínimo, plazos de producción y entrega, condiciones de pago y garantía, vigencia de la oferta y todos los cargos adicionales.

Gracias.'''.trim();
      case 'tr':
        return '''FİYAT TEKLİFİ TALEBİ (RFQ)

Merhaba,
Aşağıdaki ürün/hizmet için fiyat teklifi rica ederiz:
- Ürün/hizmet: $product
- Miktar: $quantity
- Özellikler: ${shownSpecs ?? 'Lütfen mevcut seçenekleri önerin'}
- Teslimat adresi: $destination
- Teslimat yöntemi: ${_localizedDelivery}
- Hedef bütçe: ${shownBudget ?? 'Lütfen mevcut fiyatları belirtin'}
${shownContact == null ? '' : '- Tercih edilen iletişim yöntemi: $shownContact'}

Birim ve toplam fiyatları, minimum sipariş miktarını, üretim ve teslimat sürelerini, ödeme ve garanti koşullarını, teklif geçerlilik süresini ve tüm ek ücretleri belirtin.

Teşekkürler.'''.trim();
      case 'pt':
        return '''SOLICITAÇÃO DE COTAÇÃO (RFQ)

Olá,
Solicitamos uma cotação para:
- Produto/serviço: $product
- Quantidade: $quantity
- Especificações: ${shownSpecs ?? 'Por favor, sugira as opções disponíveis'}
- Destino da entrega: $destination
- Método de entrega: ${_localizedDelivery}
- Orçamento previsto: ${shownBudget ?? 'Informe os preços disponíveis'}
${shownContact == null ? '' : '- Meio de contato preferido: $shownContact'}

Inclua preços unitários e totais, quantidade mínima do pedido, prazos de produção e entrega, condições de pagamento e garantia, validade da proposta e todas as taxas adicionais.

Obrigado(a).'''.trim();
      case 'sw':
        return '''OMBI LA BEI (RFQ)

Habari,
Tunaomba bei ya bidhaa/huduma ifuatayo:
- Bidhaa/huduma: $product
- Kiasi: $quantity
- Sifa: ${shownSpecs ?? 'Tafadhali pendekeza chaguo zinazopatikana'}
- Mahali pa kupeleka: $destination
- Njia ya usafirishaji: ${_localizedDelivery}
- Bajeti inayolengwa: ${shownBudget ?? 'Tafadhali toa bei zinazopatikana'}
${shownContact == null ? '' : '- Njia tunayopendelea ya mawasiliano: $shownContact'}

Tafadhali jumuisha bei ya kila kipimo na jumla, kiwango cha chini cha oda, muda wa uzalishaji na usafirishaji, masharti ya malipo na dhamana, muda wa uhalali wa bei, na gharama zote za ziada.

Asante.'''.trim();
      default:
        return '''
طلب عرض سعر (RFQ)

مرحباً،
نرغب في الحصول على عرض سعر للمنتج/الخدمة التالية:
- المنتج أو الخدمة: $product
- الكمية المطلوبة: $quantity
- المواصفات: ${shownSpecs ?? 'يرجى اقتراح الخيارات المتاحة'}
- الوجهة: $destination
- طريقة التسليم: ${_localizedDelivery}
- الميزانية المستهدفة: ${shownBudget ?? 'يرجى توضيح الأسعار المتاحة'}
${shownContact == null ? '' : '- وسيلة التواصل التي سنستخدمها: $shownContact'}

يرجى إرسال السعر التفصيلي، والحد الأدنى للطلب، ومدة التجهيز والتسليم، وشروط الدفع والضمان، ومدة صلاحية العرض. يرجى توضيح أي رسوم إضافية.

شكراً لكم.
'''.trim();
    }
  }

  Future<void> _copyDraft() async {
    final draft = _draft;
    if (draft == null) return;
    await Clipboard.setData(ClipboardData(text: draft));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ مسودة طلب عرض السعر. لم يتم إرسالها لأي جهة.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('طلب عرض سعر من مورد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: const Text(
              'أدخل تفاصيل طلبك لتجهيز مسودة واضحة يمكنك مراجعتها وتعديلها ثم نسخها. لن يتم التواصل مع أي مورد تلقائياً.',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _language,
            decoration: const InputDecoration(
              labelText: 'لغة مسودة طلب السعر',
              helperText: 'تُترجم صياغة الطلب؛ تبقى بيانات المنتج والكميات كما أدخلتها.',
              border: OutlineInputBorder(),
            ),
            items: _languages.entries
                .map((entry) => DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _language = value;
                _draft = null;
              });
            },
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _productController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'المنتج أو الخدمة *',
                    hintText: 'مثال: أقمشة قطنية أو معدات تعبئة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'اكتب اسم المنتج أو الخدمة'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'الكمية المطلوبة *',
                    hintText: 'مثال: 500 قطعة',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل الكمية المطلوبة'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _destinationController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'مدينة وبلد التسليم *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'حدد وجهة التسليم'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specificationsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'المواصفات المطلوبة (اختياري)',
                    hintText: 'المقاس، المادة، الجودة، الموديل، الشهادات...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _delivery,
                  decoration: const InputDecoration(
                    labelText: 'طريقة التسليم',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'شحن إلى العنوان',
                      child: Text('شحن إلى العنوان'),
                    ),
                    DropdownMenuItem(
                      value: 'استلام من المورد',
                      child: Text('استلام من المورد'),
                    ),
                    DropdownMenuItem(
                      value: 'يُحدّد لاحقاً',
                      child: Text('يُحدّد لاحقاً'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _delivery = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _budgetController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'الميزانية (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: const InputDecoration(
                          labelText: 'العملة',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                          DropdownMenuItem(value: 'SDG', child: Text('SDG')),
                          DropdownMenuItem(value: 'KES', child: Text('KES')),
                          DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _currency = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'وسيلة التواصل التي ستستخدمها (اختياري)',
                    hintText: 'بريد عمل أو رقم هاتف مخصص',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _draft = _buildDraft());
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('إنشاء مسودة طلب السعر'),
                ),
              ],
            ),
          ),
          if (_draft != null) ...[
            const SizedBox(height: 24),
            Text('راجع المسودة', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            SelectableText(_draft!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyDraft,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('نسخ المسودة'),
            ),
            const SizedBox(height: 8),
            const Text(
              'قبل الإرسال، تحقق من هوية المورد وسجله وشروط الدفع والشحن. لا ترسل مستندات حساسة أو دفعات قبل التحقق.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
