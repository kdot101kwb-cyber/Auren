import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Curated discovery catalog. This catalog opens official tools; it does not
/// claim an API integration or media generation unless a live adapter exists.
class CreativeToolLibraryScreen extends StatefulWidget {
  const CreativeToolLibraryScreen({super.key, required this.onOpenAurenWorkspace});
  final VoidCallback onOpenAurenWorkspace;

  @override
  State<CreativeToolLibraryScreen> createState() => _CreativeToolLibraryScreenState();
}

class _CreativeToolLibraryScreenState extends State<CreativeToolLibraryScreen> {
  String _category = 'الكل';
  String _query = '';

  static const _tools = <_Tool>[
    // Video: 30 tools
    _Tool('Shotcut','https://shotcut.org','فيديو','كمبيوتر','محرر مجاني مفتوح المصدر'),
    _Tool('Kdenlive','https://kdenlive.org','فيديو','كمبيوتر','مفتوح المصدر'),
    _Tool('OpenShot','https://www.openshot.org','فيديو','كمبيوتر','مفتوح المصدر'),
    _Tool('DaVinci Resolve','https://www.blackmagicdesign.com/products/davinciresolve','فيديو','كمبيوتر','نسخة مجانية؛ ميزات مدفوعة'),
    _Tool('Clipchamp','https://clipchamp.com','فيديو','ويب / كمبيوتر','خطة مجانية محدودة'),
    _Tool('CapCut','https://www.capcut.com','فيديو','موبايل / ويب / كمبيوتر','مجاني بميزات وحدود متغيرة'),
    _Tool('VN Video Editor','https://www.vlognow.me','فيديو','موبايل','محرر مجاني؛ تحقق من الميزات الحالية'),
    _Tool('iMovie','https://www.apple.com/imovie','فيديو','موبايل / كمبيوتر','مجاني على أجهزة Apple'),
    _Tool('Blender VSE','https://www.blender.org','فيديو','كمبيوتر','مفتوح المصدر'),
    _Tool('VSDC Free Video Editor','https://www.videosoftdev.com','فيديو','كمبيوتر','نسخة مجانية وميزات Pro'),
    _Tool('Avidemux','https://avidemux.sourceforge.net','فيديو','كمبيوتر','مفتوح المصدر'),
    _Tool('LosslessCut','https://github.com/mifi/lossless-cut','فيديو','كمبيوتر','مفتوح المصدر'),
    _Tool('OBS Studio','https://obsproject.com','فيديو','كمبيوتر','مفتوح المصدر للتسجيل والبث'),
    _Tool('HandBrake','https://handbrake.fr','فيديو','كمبيوتر','مفتوح المصدر للتحويل'),
    _Tool('FFmpeg','https://ffmpeg.org','فيديو','كمبيوتر / خادم','أدوات سطر أوامر؛ راجع الترخيص'),
    _Tool('Aegisub','https://aegisub.org','فيديو','كمبيوتر','مفتوح المصدر للترجمة'),
    _Tool('Subtitle Edit','https://www.nikse.dk/subtitleedit','فيديو','كمبيوتر','مجاني ومفتوح المصدر'),
    _Tool('Pika','https://pika.art','فيديو','ويب','تحقق من الرصيد المجاني والترخيص قبل الاستخدام'),
    _Tool('Runway','https://runwayml.com','فيديو','ويب','خطة/رصيد محدود؛ تحقق من التجاري'),
    _Tool('Hailuo AI','https://hailuoai.video','فيديو','ويب / موبايل','توفر المجاني والحدود تتغير'),
    _Tool('Kling AI','https://klingai.com','فيديو','ويب / موبايل','رصيد محدود حسب الحساب'),
    _Tool('PixVerse','https://pixverse.ai','فيديو','ويب / موبايل','تحقق من الحصة والترخيص'),
    _Tool('Luma Dream Machine','https://lumalabs.ai/dream-machine','فيديو','ويب','الحدود والتجاري حسب الخطة'),
    _Tool('InVideo AI','https://invideo.io','فيديو','ويب','خطة مجانية محدودة/علامة مائية محتملة'),
    _Tool('HeyGen','https://www.heygen.com','فيديو','ويب','خطة محدودة؛ تحقق من الاستخدام التجاري'),
    _Tool('Descript','https://www.descript.com','فيديو','ويب / كمبيوتر','خطة مجانية محدودة'),
    _Tool('VEED','https://www.veed.io','فيديو','ويب','خطة مجانية محدودة'),
    _Tool('Canva Video','https://www.canva.com','فيديو','موبايل / ويب / كمبيوتر','خطة مجانية؛ عناصر Pro مستثناة'),
    _Tool('Olive Video Editor','https://olivevideoeditor.org','فيديو','كمبيوتر','مفتوح المصدر؛ راجع حالة الإصدار'),
    _Tool('Natron','https://natrongithub.github.io','فيديو','كمبيوتر','مفتوح المصدر للمؤثرات والتركيب'),

    // Images: 30 tools
    _Tool('GIMP','https://www.gimp.org','صور','كمبيوتر','مفتوح المصدر'),
    _Tool('Krita','https://krita.org','صور','كمبيوتر','مفتوح المصدر'),
    _Tool('Inkscape','https://inkscape.org','صور','كمبيوتر','مفتوح المصدر للرسوم المتجهة'),
    _Tool('Photopea','https://www.photopea.com','صور','ويب','مجاني مع إعلانات وميزات مدفوعة'),
    _Tool('Canva','https://www.canva.com','صور','موبايل / ويب / كمبيوتر','خطة مجانية؛ افحص ترخيص كل عنصر'),
    _Tool('Adobe Firefly','https://firefly.adobe.com','صور','ويب / موبايل','توليدات مجانية محدودة حسب الحساب'),
    _Tool('Microsoft Designer','https://designer.microsoft.com','صور','ويب / موبايل','حدود الوصول تتغير حسب الحساب'),
    _Tool('Adobe Express','https://www.adobe.com/express','صور','موبايل / ويب','خطة مجانية وبعض الميزات مدفوعة'),
    _Tool('Leonardo AI','https://leonardo.ai','صور','ويب / موبايل','حصة مجانية محدودة؛ راجع شروط التجاري'),
    _Tool('Playground AI','https://playground.com','صور','ويب','حصة مجانية محدودة؛ راجع الشروط'),
    _Tool('Ideogram','https://ideogram.ai','صور','ويب / موبايل','حصة مجانية محدودة'),
    _Tool('Craiyon','https://www.craiyon.com','صور','ويب','مجاني بحدود/إعلانات؛ تحقق من التجاري'),
    _Tool('Pixlr','https://pixlr.com','صور','ويب / موبايل','خطة مجانية محدودة'),
    _Tool('Fotor','https://www.fotor.com','صور','ويب / موبايل','ميزات AI وحصص محدودة'),
    _Tool('NightCafe','https://nightcafe.studio','صور','ويب / موبايل','نظام أرصدة؛ استخدم المجاني فقط'),
    _Tool('Tensor.Art','https://tensor.art','صور','ويب','حصة يومية/حدود تتغير؛ تحقق من الأوزان'),
    _Tool('Hugging Face Spaces','https://huggingface.co/spaces','صور','ويب','مجاني حسب المساحة والازدحام'),
    _Tool('ComfyUI','https://www.comfy.org','صور','كمبيوتر / خادم','مفتوح المصدر؛ يحتاج جهازاً مناسباً'),
    _Tool('AUTOMATIC1111','https://github.com/AUTOMATIC1111/stable-diffusion-webui','صور','كمبيوتر / خادم','مفتوح المصدر؛ راجع شروط النماذج'),
    _Tool('InvokeAI','https://invoke.ai','صور','كمبيوتر / خادم','مفتوح المصدر؛ راجع شروط النماذج'),
    _Tool('Fooocus','https://github.com/lllyasviel/Fooocus','صور','كمبيوتر','مفتوح المصدر؛ راجع حالة الصيانة والنماذج'),
    _Tool('Upscayl','https://upscayl.org','صور','كمبيوتر','مفتوح المصدر لتحسين الدقة'),
    _Tool('Paint.NET','https://www.getpaint.net','صور','كمبيوتر','مجاني للاستخدام الشخصي؛ تحقق من الترخيص'),
    _Tool('Piskel','https://www.piskelapp.com','صور','ويب / كمبيوتر','مجاني لرسوم pixel art'),
    _Tool('Blockbench','https://www.blockbench.net','صور','ويب / كمبيوتر','مجاني لإنشاء أصول 3D'),
    _Tool('PhotoScape X','https://x.photoscape.org','صور','كمبيوتر','نسخة مجانية وميزات Pro'),
    _Tool('InPixio','https://www.inpixio.com','صور','ويب / كمبيوتر','ميزات مجانية محدودة'),
    _Tool('remove.bg','https://www.remove.bg','صور','ويب / موبايل','معاينات مجانية محدودة'),
    _Tool('Clipdrop','https://clipdrop.co','صور','ويب / موبايل','أدوات مجانية بحدود'),
    _Tool('Excalidraw','https://excalidraw.com','صور','ويب','مفتوح المصدر للرسوم التوضيحية'),

    // Games: 30 tools
    _Tool('Godot','https://godotengine.org','ألعاب','كمبيوتر','مفتوح المصدر MIT'),
    _Tool('GDevelop','https://gdevelop.io','ألعاب','ويب / كمبيوتر / موبايل','خطة مجانية بحدود لبعض الخدمات'),
    _Tool('Defold','https://defold.com','ألعاب','كمبيوتر','مجاني مع شروط ترخيصه'),
    _Tool('Unreal Engine','https://www.unrealengine.com','ألعاب','كمبيوتر','مجاني بشروط وإتاوات محتملة'),
    _Tool('Unity','https://unity.com','ألعاب','كمبيوتر','خطة مجانية بشروط أهلية'),
    _Tool('GameMaker','https://gamemaker.io','ألعاب','كمبيوتر','قيود على التصدير/البيع في الخطة المجانية'),
    _Tool('Scratch','https://scratch.mit.edu','ألعاب','ويب / كمبيوتر','مجاني للتعلم والألعاب البسيطة'),
    _Tool('Pygame','https://www.pygame.org','ألعاب','كمبيوتر','مفتوح المصدر'),
    _Tool('Panda3D','https://www.panda3d.org','ألعاب','كمبيوتر','مفتوح المصدر'),
    _Tool('Ren’Py','https://www.renpy.org','ألعاب','كمبيوتر','مفتوح المصدر للروايات التفاعلية'),
    _Tool('Phaser','https://phaser.io','ألعاب','ويب / كمبيوتر','إطار عمل مفتوح المصدر'),
    _Tool('Three.js','https://threejs.org','ألعاب','ويب','مكتبة مفتوحة المصدر للـ 3D'),
    _Tool('Babylon.js','https://www.babylonjs.com','ألعاب','ويب','محرك ويب مفتوح المصدر'),
    _Tool('Bevy','https://bevy.org','ألعاب','كمبيوتر','محرك مفتوح المصدر بلغة Rust'),
    _Tool('MonoGame','https://monogame.net','ألعاب','كمبيوتر','مفتوح المصدر'),
    _Tool('libGDX','https://libgdx.com','ألعاب','كمبيوتر','إطار عمل مفتوح المصدر'),
    _Tool('LÖVE','https://love2d.org','ألعاب','كمبيوتر','محرك 2D مفتوح المصدر'),
    _Tool('HaxeFlixel','https://haxeflixel.com','ألعاب','كمبيوتر','مفتوح المصدر'),
    _Tool('GB Studio','https://www.gbstudio.dev','ألعاب','كمبيوتر','مجاني لإنشاء ألعاب retro'),
    _Tool('Twine','https://twinery.org','ألعاب','ويب / كمبيوتر','مفتوح المصدر للقصص التفاعلية'),
    _Tool('Bitsy','https://bitsy.org','ألعاب','ويب','مجاني لألعاب صغيرة'),
    _Tool('Tiled','https://www.mapeditor.org','ألعاب','كمبيوتر','محرر خرائط؛ تحقق من الترخيص التجاري'),
    _Tool('LDtk','https://ldtk.io','ألعاب','كمبيوتر','محرر مستويات مجاني'),
    _Tool('Blender','https://www.blender.org','ألعاب','كمبيوتر','مفتوح المصدر لإنشاء الأصول'),
    _Tool('Blockbench','https://www.blockbench.net','ألعاب','ويب / كمبيوتر','مجاني لإنشاء نماذج وأصول'),
    _Tool('Pixelorama','https://orama-interactive.itch.io/pixelorama','ألعاب','كمبيوتر','مفتوح المصدر لرسوم pixel art'),
    _Tool('Audacity','https://www.audacityteam.org','ألعاب','كمبيوتر','مفتوح المصدر للصوت'),
    _Tool('LMMS','https://lmms.io','ألعاب','كمبيوتر','مفتوح المصدر للموسيقى'),
    _Tool('Castle Game Engine','https://castle-engine.io','ألعاب','كمبيوتر','محرك مفتوح المصدر'),
    _Tool('Open 3D Engine','https://o3de.org','ألعاب','كمبيوتر','محرك مفتوح المصدر؛ يحتاج عتاداً مناسباً'),
  ];

  Future<void> _openTool(_Tool tool) async {
    final ok = await launchUrl(Uri.parse(tool.url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح رابط الأداة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['الكل', 'فيديو', 'صور', 'ألعاب'];
    final query = _query.trim().toLowerCase();
    final filtered = _tools.where((tool) =>
      (_category == 'الكل' || tool.category == _category) &&
      (query.isEmpty || tool.name.toLowerCase().contains(query) ||
        tool.platform.toLowerCase().contains(query) || tool.note.toLowerCase().contains(query))
    ).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF382B70), Color(0xFF202039)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.auto_awesome, size: 30, color: Color(0xFF9B87FF)),
              SizedBox(height: 8),
              Text('مكتبة أدوات NOVA الإبداعية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('90 أداة للاستكشاف: 30 فيديو، 30 صور، 30 ألعاب. هذه روابط رسمية؛ ليست كل أداة متصلة آلياً أو مجانية بلا حدود.'),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'ابحث عن أداة أو منصة', border: OutlineInputBorder()),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final category in categories)
              ChoiceChip(label: Text(category), selected: _category == category, onSelected: (_) => setState(() => _category = category)),
          ]),
          const SizedBox(height: 8),
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('مسار العمل إلى AUREN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('اختر الأداة ونفّذ العمل فيها أو جهّز ملفات المشروع. بعد ذلك افتح مساحة AUREN في NOVA لتسجيل مهمة البناء/الإصلاح. رفع الملفات والاختبارات الفعلية يتطلبان تكاملاً عاملاً وصلاحيات GitHub مناسبة.'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: widget.onOpenAurenWorkspace,
                icon: const Icon(Icons.account_tree),
                label: const Text('فتح مساحة تطوير AUREN'),
              ),
            ]),
          )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('الأدوات المطابقة: ${filtered.length} / 90', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final tool in filtered)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(tool.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Chip(label: Text(tool.category)),
                  ]),
                  Text('المنصة: ${tool.platform}'),
                  const SizedBox(height: 4),
                  Text(tool.note, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openTool(tool),
                      icon: const Icon(Icons.open_in_new, size: 17),
                      label: const Text('فتح الموقع الرسمي'),
                    ),
                  ),
                ]),
              ),
            ),
          const SizedBox(height: 10),
          const Text('قبل الاستخدام التجاري: تحقق من ترخيص البرنامج، وترخيص النموذج والأصول والمخرجات بشكل منفصل. NOVA لا يستخدم خططاً مدفوعة أو أرصدة مدفوعة، ولا يتجاوز حدود المجاني.'),
        ],
      ),
    );
  }
}

class _Tool {
  final String name;
  final String url;
  final String category;
  final String platform;
  final String note;
  const _Tool(this.name, this.url, this.category, this.platform, this.note);
}
