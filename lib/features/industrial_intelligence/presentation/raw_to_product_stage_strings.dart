/// Route-aware stage labels and descriptions for the illustrative planner.
class RawToProductStageStrings {
  static const _data = <String, Map<String, List<String>>>{
    'cotton-to-garment': {
      'en': ['Ginning and cleaning|Separate lint from seeds and remove foreign matter.', 'Spinning|Turn classified cotton fibres into yarn.', 'Weaving or knitting|Make fabric to the intended construction.', 'Fabric finishing and dyeing|Finish fabric to the required use and colour.', 'Cutting, sewing and packing|Turn finished fabric into inspected garments.'],
      'ar': ['الحلج والتنظيف|فصل الألياف عن البذور وإزالة الشوائب.', 'الغزل|تحويل الألياف المصنفة إلى خيوط.', 'النسيج أو الحياكة|إنتاج القماش بالتركيب المطلوب.', 'تجهيز القماش والصباغة|تجهيز القماش وفق اللون والاستخدام المستهدفين.', 'القص والخياطة والتعبئة|تحويل القماش إلى ملابس مفحوصة.'],
    },
    'sesame-to-tahini': {
      'en': ['Receive, sort and clean sesame|Inspect the seed and remove foreign matter.', 'Validated heat treatment|Apply a food-safe process validated for the product.', 'Grinding and homogenizing|Grind processed sesame to the target paste texture.', 'Quality checks and filling|Check the product and fill suitable traceable packs.'],
      'ar': ['استلام السمسم وفرزه وتنظيفه|فحص السمسم وإزالة المواد الغريبة.', 'المعالجة الحرارية المعتمدة|تطبيق عملية مناسبة لسلامة الغذاء والتحقق منها.', 'الطحن والتجانس|طحن السمسم المعالج إلى قوام الطحينة المستهدف.', 'فحص الجودة والتعبئة|فحص المنتج وتعبئته في عبوات مناسبة قابلة للتتبع.'],
    },
    'peanut-to-peanut-butter': {
      'en': ['Sort and clean peanuts|Remove damaged kernels and foreign matter.', 'Controlled roasting and cooling|Use a validated process and hygienic cooling.', 'Skin removal and grinding|Make a paste with the required texture.', 'Allergen labelling and packing|Check the product and clearly declare peanuts.'],
      'ar': ['فرز الفول السوداني وتنظيفه|إزالة الحبوب التالفة والمواد الغريبة.', 'التحميص والتبريد المنضبط|استخدام عملية متحقق منها وتبريد صحي.', 'إزالة القشرة والطحن|إنتاج معجون بالقوام المطلوب.', 'بيان مسببات الحساسية والتعبئة|فحص المنتج والتصريح بوضوح عن الفول السوداني.'],
    },
    'hides-to-leather-goods': {
      'en': ['Receive, preserve and grade hides|Assess condition and sort hides to reduce damage.', 'Treatment and tanning|Convert hides to stable leather using controlled processes.', 'Drying and finishing|Set the leather properties and surface finish.', 'Design, cutting and assembly|Make and inspect leather goods to specification.'],
      'ar': ['استلام الجلود وحفظها وفرزها|تقييم حالة الجلود وفرزها لتقليل التلف.', 'المعالجة والدباغة|تحويل الجلود إلى جلد مستقر بعمليات مضبوطة.', 'التجفيف والتشطيب|ضبط خصائص الجلد ومظهره النهائي.', 'التصميم والقص والتجميع|تصنيع المنتجات الجلدية وفحصها وفق المواصفات.'],
    },
    'iron-to-fabricated-products': {
      'en': ['Ore preparation and characterization|Assess composition and prepare feed for the selected process.', 'Iron extraction or intermediate production|Choose a suitable industrial route after engineering review.', 'Casting, rolling or shaping|Produce semi-finished stock to defined specifications.', 'Fabrication and inspection|Manufacture and inspect final metal products.'],
      'ar': ['تحضير الخام وتحليل خصائصه|تحليل التركيب وتجهيز الخام للعملية المختارة.', 'استخلاص الحديد أو إنتاج معدن وسيط|اختيار المسار الصناعي بعد مراجعة هندسية متخصصة.', 'الصب أو الدرفلة أو التشكيل|إنتاج مواد نصف مصنعة بمواصفات محددة.', 'التصنيع والفحص|تصنيع المنتجات المعدنية النهائية وفحصها.'],
    },
  };

  // Route-specific labels for every other supported offline locale.
  static const _names = <String, Map<String, List<String>>>{
    'fr': {
      'cotton-to-garment': ['Égrenage et nettoyage du coton', 'Filage du coton', 'Tissage ou tricotage', 'Finition et teinture du tissu', 'Coupe, couture et emballage'],
      'sesame-to-tahini': ['Réception et nettoyage du sésame', 'Traitement thermique validé', 'Broyage et homogénéisation', 'Contrôle qualité et remplissage'],
      'peanut-to-peanut-butter': ['Tri et nettoyage des arachides', 'Torréfaction contrôlée et refroidissement', 'Retrait des peaux et broyage', 'Étiquetage des allergènes et emballage'],
      'hides-to-leather-goods': ['Réception et tri des peaux', 'Traitement et tannage', 'Séchage et finition du cuir', 'Conception, coupe et assemblage'],
      'iron-to-fabricated-products': ['Préparation et analyse du minerai', 'Extraction du fer ou production intermédiaire', 'Coulée, laminage ou mise en forme', 'Fabrication et inspection'],
    },
    'es': {
      'cotton-to-garment': ['Desmotado y limpieza del algodón', 'Hilado del algodón', 'Tejido o punto', 'Acabado y teñido de la tela', 'Corte, costura y embalaje'],
      'sesame-to-tahini': ['Recepción y limpieza del sésamo', 'Tratamiento térmico validado', 'Molienda y homogeneización', 'Control de calidad y envasado'],
      'peanut-to-peanut-butter': ['Selección y limpieza de cacahuetes', 'Tostado controlado y enfriamiento', 'Retirada de piel y molienda', 'Etiquetado de alérgenos y envasado'],
      'hides-to-leather-goods': ['Recepción y clasificación de pieles', 'Tratamiento y curtido', 'Secado y acabado del cuero', 'Diseño, corte y montaje'],
      'iron-to-fabricated-products': ['Preparación y análisis del mineral', 'Extracción de hierro o producción intermedia', 'Fundición, laminado o conformado', 'Fabricación e inspección'],
    },
    'pt': {
      'cotton-to-garment': ['Descaroçamento e limpeza do algodão', 'Fiação do algodão', 'Tecelagem ou malharia', 'Acabamento e tingimento do tecido', 'Corte, costura e embalagem'],
      'sesame-to-tahini': ['Receção e limpeza do sésamo', 'Tratamento térmico validado', 'Moagem e homogeneização', 'Controlo de qualidade e enchimento'],
      'peanut-to-peanut-butter': ['Seleção e limpeza do amendoim', 'Torrefação controlada e arrefecimento', 'Remoção da pele e moagem', 'Rotulagem de alergénios e embalagem'],
      'hides-to-leather-goods': ['Receção e classificação das peles', 'Tratamento e curtimenta', 'Secagem e acabamento do couro', 'Conceção, corte e montagem'],
      'iron-to-fabricated-products': ['Preparação e análise do minério', 'Extração de ferro ou produção intermédia', 'Fundição, laminagem ou conformação', 'Fabrico e inspeção'],
    },
    'tr': {
      'cotton-to-garment': ['Pamuk çırçırlama ve temizleme', 'Pamuk ipliği eğirme', 'Dokuma veya örme', 'Kumaş bitirme ve boyama', 'Kesim, dikim ve paketleme'],
      'sesame-to-tahini': ['Susamı kabul etme ve temizleme', 'Doğrulanmış ısıl işlem', 'Öğütme ve homojenleştirme', 'Kalite kontrolü ve dolum'],
      'peanut-to-peanut-butter': ['Yer fıstığını ayıklama ve temizleme', 'Kontrollü kavurma ve soğutma', 'Kabuk çıkarma ve öğütme', 'Alerjen etiketi ve paketleme'],
      'hides-to-leather-goods': ['Derileri kabul etme ve sınıflandırma', 'İşleme ve tabaklama', 'Kurutma ve deri bitirme', 'Tasarım, kesim ve birleştirme'],
      'iron-to-fabricated-products': ['Cevheri hazırlama ve analiz', 'Demir çıkarma veya ara ürün üretimi', 'Döküm, haddeleme veya şekillendirme', 'İmalat ve denetim'],
    },
    'zh': {
      'cotton-to-garment': ['轧花与清洁', '棉纤维纺纱', '织布或针织', '织物整理与染色', '裁剪、缝制与包装'],
      'sesame-to-tahini': ['芝麻接收、分选与清洁', '经验证的热处理', '研磨与均质', '质量检查与灌装'],
      'peanut-to-peanut-butter': ['花生分选与清洁', '受控烘烤与冷却', '去皮与研磨', '过敏原标识与包装'],
      'hides-to-leather-goods': ['生皮接收与分级', '处理与鞣制', '皮革干燥与整理', '设计、裁切与组装'],
      'iron-to-fabricated-products': ['矿石准备与成分分析', '炼铁或中间产品生产', '铸造、轧制或成形', '制造与检验'],
    },
    'hi': {
      'cotton-to-garment': ['कपास की ओटाई और सफाई', 'कपास से सूत कातना', 'बुनाई या निटिंग', 'कपड़े की फिनिशिंग और रंगाई', 'कटाई, सिलाई और पैकिंग'],
      'sesame-to-tahini': ['तिल प्राप्त करना और साफ करना', 'सत्यापित ताप उपचार', 'पीसना और समरूप बनाना', 'गुणवत्ता जाँच और भराई'],
      'peanut-to-peanut-butter': ['मूंगफली छाँटना और साफ करना', 'नियंत्रित भूनना और ठंडा करना', 'छिलका हटाना और पीसना', 'एलर्जेन लेबल और पैकिंग'],
      'hides-to-leather-goods': ['खाल प्राप्त करना और वर्गीकृत करना', 'प्रसंस्करण और चमड़ा पकाना', 'चमड़ा सुखाना और फिनिशिंग', 'डिज़ाइन, कटाई और जोड़ना'],
      'iron-to-fabricated-products': ['अयस्क तैयार करना और विश्लेषण', 'लोहा निकालना या मध्यवर्ती उत्पादन', 'ढलाई, रोलिंग या आकार देना', 'निर्माण और निरीक्षण'],
    },
    'ur': {
      'cotton-to-garment': ['روئی سے بیج الگ کرنا اور صفائی', 'روئی سے دھاگا بنانا', 'بُنائی یا نِٹِنگ', 'کپڑے کی تکمیل اور رنگائی', 'کٹائی، سلائی اور پیکنگ'],
      'sesame-to-tahini': ['تل وصول کرنا اور صاف کرنا', 'تصدیق شدہ حرارتی عمل', 'پیسنا اور یکجان کرنا', 'معیار کی جانچ اور بھرائی'],
      'peanut-to-peanut-butter': ['مونگ پھلی چھانٹنا اور صاف کرنا', 'قابو شدہ بھونائی اور ٹھنڈا کرنا', 'چھلکا اتارنا اور پیسنا', 'الرجی کی تنبیہ اور پیکنگ'],
      'hides-to-leather-goods': ['کھال وصول کرنا اور درجہ بندی', 'عمل کاری اور دباغت', 'چمڑا خشک کرنا اور تکمیل', 'ڈیزائن، کٹائی اور جوڑائی'],
      'iron-to-fabricated-products': ['خام دھات کی تیاری اور تجزیہ', 'لوہا نکالنا یا درمیانی پیداوار', 'ڈھلائی، رولنگ یا شکل دینا', 'تیاری اور معائنہ'],
    },
    'id': {
      'cotton-to-garment': ['Pemintalan awal dan pembersihan kapas', 'Pemintalan serat menjadi benang', 'Penenunan atau perajutan', 'Penyelesaian dan pewarnaan kain', 'Pemotongan, penjahitan, dan pengemasan'],
      'sesame-to-tahini': ['Penerimaan dan pembersihan wijen', 'Perlakuan panas tervalidasi', 'Penggilingan dan homogenisasi', 'Pemeriksaan mutu dan pengisian'],
      'peanut-to-peanut-butter': ['Sortir dan pembersihan kacang', 'Pemanggangan terkendali dan pendinginan', 'Pengupasan dan penggilingan', 'Label alergen dan pengemasan'],
      'hides-to-leather-goods': ['Penerimaan dan penilaian kulit mentah', 'Pengolahan dan penyamakan', 'Pengeringan dan penyelesaian kulit', 'Desain, pemotongan, dan perakitan'],
      'iron-to-fabricated-products': ['Persiapan dan analisis bijih', 'Ekstraksi besi atau produksi antara', 'Pengecoran, penggulungan, atau pembentukan', 'Fabrikasi dan pemeriksaan'],
    },
    'sw': {
      'cotton-to-garment': ['Kutenganisha nyuzi na kusafisha pamba', 'Kusokota pamba kuwa uzi', 'Kufuma au kusuka kitambaa', 'Kumalizia na kupaka rangi kitambaa', 'Kukata, kushona na kufungasha'],
      'sesame-to-tahini': ['Kupokea na kusafisha ufuta', 'Matibabu ya joto yaliyothibitishwa', 'Kusaga na kuchanganya sawasawa', 'Ukaguzi wa ubora na kujaza'],
      'peanut-to-peanut-butter': ['Kuchambua na kusafisha karanga', 'Kuchoma na kupoza kwa udhibiti', 'Kuondoa maganda na kusaga', 'Lebo ya mzio na ufungashaji'],
      'hides-to-leather-goods': ['Kupokea na kupanga ngozi mbichi', 'Usindikaji na kutia ngozi dawa', 'Kukausha na kumalizia ngozi', 'Kubuni, kukata na kuunganisha'],
      'iron-to-fabricated-products': ['Kuandaa na kuchambua madini', 'Kutoa chuma au kutengeneza bidhaa ya kati', 'Kumimina, kukunja au kuunda', 'Utengenezaji na ukaguzi'],
    },
    'ha': {
      'cotton-to-garment': ['Ware auduga da tsaftacewa', 'Juya auduga zuwa zare', 'Saƙa ko saka masana’anta', 'Gyaran masana’anta da rini', 'Yanka, ɗinki da marufi'],
      'sesame-to-tahini': ['Karɓa da tsaftace ridi', 'Maganin zafi da aka tabbatar', 'Niƙa da haɗa shi daidai', 'Duba inganci da cikawa'],
      'peanut-to-peanut-butter': ['Ware gyada da tsaftacewa', 'Gasa da sanyaya cikin kulawa', 'Cire bawo da niƙa', 'Alamar abin da ke jawo rashin lafiya da marufi'],
      'hides-to-leather-goods': ['Karɓa da tantance fatar dabba', 'Sarrafawa da yin fata', 'Busarwa da gyaran fata', 'Zane, yanka da haɗawa'],
      'iron-to-fabricated-products': ['Shirya da nazarin dutsen ƙarfe', 'Ciro ƙarfe ko samar da matsakaici', 'Zubawa, mirgina ko tsara siffa', 'Ƙerawa da dubawa'],
    },
    'de': {
      'cotton-to-garment': ['Entkörnung und Reinigung der Baumwolle', 'Verspinnen der Baumwollfasern', 'Weben oder Stricken', 'Veredelung und Färben des Stoffes', 'Zuschneiden, Nähen und Verpacken'],
      'sesame-to-tahini': ['Sesamannahme und Reinigung', 'Validierte Wärmebehandlung', 'Mahlen und Homogenisieren', 'Qualitätsprüfung und Abfüllung'],
      'peanut-to-peanut-butter': ['Erdnüsse sortieren und reinigen', 'Kontrolliertes Rösten und Kühlen', 'Häuten und Mahlen', 'Allergenkennzeichnung und Verpackung'],
      'hides-to-leather-goods': ['Rohhäute annehmen und sortieren', 'Behandlung und Gerbung', 'Trocknung und Lederveredelung', 'Entwurf, Zuschnitt und Montage'],
      'iron-to-fabricated-products': ['Erz vorbereiten und analysieren', 'Eisengewinnung oder Zwischenproduktion', 'Gießen, Walzen oder Formen', 'Fertigung und Prüfung'],
    },
  };

  static const _purpose = <String, List<String>>{
    'fr': ['Préparer et trier la matière première en retirant les impuretés.', 'Appliquer un procédé adapté et validé par des spécialistes.', 'Transformer la matière en respectant les spécifications du produit.', 'Contrôler la qualité et documenter les résultats.', 'Vérifier le produit fini et utiliser un emballage adapté.'],
    'es': ['Preparar y clasificar la materia prima retirando impurezas.', 'Aplicar un proceso adecuado y validado por especialistas.', 'Transformar el material según las especificaciones del producto.', 'Comprobar la calidad y documentar los resultados.', 'Inspeccionar el producto final y usar un envase adecuado.'],
    'pt': ['Preparar e classificar a matéria-prima, removendo impurezas.', 'Aplicar um processo adequado e validado por especialistas.', 'Transformar o material conforme as especificações do produto.', 'Verificar a qualidade e registar os resultados.', 'Inspecionar o produto final e usar embalagem adequada.'],
    'tr': ['Yabancı maddeleri gidererek ham maddeyi hazırlayın ve ayırın.', 'Uzmanlarca doğrulanmış uygun bir süreç uygulayın.', 'Malzemeyi ürün özelliklerine uygun şekilde dönüştürün.', 'Kaliteyi kontrol edin ve sonuçları kaydedin.', 'Son ürünü inceleyin ve uygun ambalaj kullanın.'],
    'zh': ['清理杂质并对原料进行准备和分选。', '采用经过专业验证且适合产品的工艺。', '按照产品规格将材料转化为目标产品。', '检查质量并记录检验结果。', '检查最终产品并使用合适的包装。'],
    'hi': ['अशुद्धियाँ हटाकर कच्चे माल को तैयार और छाँटें।', 'विशेषज्ञों द्वारा सत्यापित उपयुक्त प्रक्रिया अपनाएँ।', 'उत्पाद विनिर्देशों के अनुसार सामग्री का रूपांतरण करें।', 'गुणवत्ता जाँचें और परिणाम दर्ज करें।', 'अंतिम उत्पाद की जाँच करें और उपयुक्त पैकेजिंग चुनें।'],
    'ur': ['ناپاکیاں دور کرکے خام مال تیار کریں اور چھانٹیں۔', 'ماہرین سے تصدیق شدہ موزوں طریقہ اپنائیں۔', 'مصنوعات کی خصوصیات کے مطابق مواد تبدیل کریں۔', 'معیار جانچیں اور نتائج درج کریں۔', 'آخری مصنوعات کا معائنہ کریں اور مناسب پیکنگ استعمال کریں۔'],
    'id': ['Siapkan dan sortir bahan baku sambil membuang kotoran.', 'Gunakan proses yang sesuai dan telah divalidasi ahli.', 'Ubah bahan sesuai spesifikasi produk yang dituju.', 'Periksa mutu dan catat hasil pemeriksaan.', 'Periksa produk akhir dan gunakan kemasan yang sesuai.'],
    'sw': ['Andaa na chambua malighafi huku ukiondoa uchafu.', 'Tumia mchakato unaofaa uliothibitishwa na wataalamu.', 'Badilisha malighafi kulingana na vipimo vya bidhaa.', 'Kagua ubora na uandike matokeo.', 'Kagua bidhaa ya mwisho na utumie kifungashio kinachofaa.'],
    'ha': ['Shirya ɗanyen kaya kuma cire datti da abubuwan da ba a so.', 'Yi amfani da hanyar da ƙwararru suka tabbatar.', 'Sauya kayan bisa ƙa’idar samfurin da ake so.', 'Duba inganci kuma rubuta sakamakon dubawa.', 'Duba samfurin ƙarshe kuma yi amfani da marufi mai dacewa.'],
    'de': ['Bereiten und sortieren Sie den Rohstoff und entfernen Sie Fremdstoffe.', 'Verwenden Sie ein geeignetes, fachlich validiertes Verfahren.', 'Verarbeiten Sie das Material gemäß den Produktspezifikationen.', 'Prüfen Sie die Qualität und dokumentieren Sie die Ergebnisse.', 'Prüfen Sie das Endprodukt und verwenden Sie geeignete Verpackung.'],
  };

  static String name(String routeId, int index, String languageCode, String fallback) {
    final routeEntries = _data[routeId]?[languageCode];
    if (routeEntries != null && index >= 0 && index < routeEntries.length) {
      return routeEntries[index].split('|').first;
    }
    final localized = _names[languageCode]?[routeId];
    if (localized != null && index >= 0 && index < localized.length) {
      return localized[index];
    }
    return fallback;
  }

  static String purpose(String routeId, int index, String languageCode, String fallback) {
    final routeEntries = _data[routeId]?[languageCode];
    if (routeEntries != null && index >= 0 && index < routeEntries.length) {
      return routeEntries[index].split('|').skip(1).join('|');
    }
    final localized = _purpose[languageCode];
    if (localized != null && index >= 0 && index < localized.length) {
      return localized[index];
    }
    return fallback;
  }
}
