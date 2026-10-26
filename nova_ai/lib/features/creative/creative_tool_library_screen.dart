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
    _Tool('MoneyPrinterTurbo','https://github.com/harry0703/MoneyPrinterTurbo','فيديو','كمبيوتر / خادم','تجميع فيديو قصير آلياً؛ بعض مزودات الصوت والذكاء قد تتطلب مفاتيح أو تكلفة'),
    _Tool('Wan Video','https://github.com/Wan-Video/Wan2.1','فيديو','كمبيوتر / GPU','توليد فيديو؛ يتطلب نماذج وموارد GPU مناسبة'),
    _Tool('LTX-Video','https://github.com/Lightricks/LTX-Video','فيديو','كمبيوتر / GPU','توليد فيديو؛ افحص متطلبات الذاكرة وترخيص النموذج'),
    _Tool('AnimateDiff','https://github.com/guoyww/AnimateDiff','فيديو','كمبيوتر / GPU','تحريك عبر نماذج diffusion متوافقة'),
    _Tool('VideoCrafter','https://github.com/AILab-CVC/VideoCrafter','فيديو','كمبيوتر / GPU','مشروع بحثي لتوليد الفيديو؛ تحقق من الصيانة والترخيص'),
    _Tool('Open-Sora','https://github.com/hpcaitech/Open-Sora','فيديو','كمبيوتر / GPU','مشروع بحثي لتوليد الفيديو؛ يحتاج موارد كبيرة'),
    _Tool('HunyuanVideo','https://github.com/Tencent-Hunyuan/HunyuanVideo','فيديو','كمبيوتر / GPU','توليد فيديو متقدم؛ يتطلب عتاداً قوياً'),
    _Tool('MoviePy','https://github.com/Zulko/moviepy','فيديو','كمبيوتر / خادم','مونتاج وتجميع مقاطع وترجمات وصوت عبر Python'),
    _Tool('Open-Sora Plan','https://github.com/PKU-YuanGroup/Open-Sora-Plan','فيديو','كمبيوتر / GPU','بحث مفتوح لتوليد الفيديو؛ راجع متطلبات الإصدار'),

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
    _Tool('Stable Diffusion WebUI Forge','https://github.com/lllyasviel/stable-diffusion-webui-forge','صور','كمبيوتر / GPU','واجهة توليد صور محلية؛ تحقق من ترخيص كل نموذج'),
    _Tool('Fooocus','https://github.com/lllyasviel/Fooocus','صور','كمبيوتر / GPU','توليد صور محلي؛ راجع حالة الصيانة ومتطلبات النماذج'),
    _Tool('Kandinsky','https://github.com/ai-forever/Kandinsky-3','صور','كمبيوتر / GPU','نموذج توليد صور؛ افحص الترخيص والذاكرة قبل الاستخدام'),
    _Tool('Upscayl','https://upscayl.org','صور','كمبيوتر','تحسين دقة الصور محلياً ومفتوح المصدر'),

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

    // AI image control, restoration, and character illustration
    _Tool('ControlNet','https://github.com/lllyasviel/ControlNet','صور','كمبيوتر / GPU','تحكم في التكوين والوضعيات؛ يحتاج نماذج وموارد مناسبة'),
    _Tool('IC-Light','https://github.com/lllyasviel/IC-Light','صور','كمبيوتر / GPU','إعادة إضاءة الصور بالذكاء الاصطناعي؛ راجع متطلبات النموذج'),
    _Tool('Real-ESRGAN','https://github.com/xinntao/Real-ESRGAN','صور','كمبيوتر / GPU','رفع دقة الصور واستعادتها؛ تحقق من الترخيص'),
    _Tool('Krita AI Diffusion','https://github.com/Acly/krita-ai-diffusion','صور','كمبيوتر / GPU','إنشاء وتعديل الصور داخل Krita عبر محرك متوافق مثل ComfyUI'),

    // Talking characters, facial animation, and lip synchronization
    _Tool('SadTalker','https://github.com/OpenTalker/SadTalker','تحريك الوجه والشفاه','كمبيوتر / GPU','تحريك صورة وجه باستخدام الصوت؛ استخدم صوراً مصرحاً بها'),
    _Tool('Wav2Lip','https://github.com/Rudrabha/Wav2Lip','تحريك الوجه والشفاه','كمبيوتر / GPU','مزامنة حركة الشفاه مع الكلام؛ تحقق من قيود الترخيص التجاري'),
    _Tool('LivePortrait','https://github.com/KwaiVGI/LivePortrait','تحريك الوجه والشفاه','كمبيوتر / GPU','تحريك صورة شخصية؛ افحص ترخيص الكود والأوزان'),
    _Tool('MuseTalk','https://github.com/TMElyralab/MuseTalk','تحريك الوجه والشفاه','كمبيوتر / GPU','مزامنة شفاه مع الصوت؛ يتطلب إعداد نموذج مناسب'),
    _Tool('Mixamo','https://www.mixamo.com','كرتون وشخصيات','ويب','تحريك هياكل شخصيات 3D؛ تحقق من شروط الأصول'),

    // Additional voice and sound-generation engines
    _Tool('F5-TTS','https://github.com/SWivid/F5-TTS','صوت وصوت آلي','كمبيوتر / GPU','تحويل النص إلى كلام؛ افحص ترخيص النموذج والصوت'),
    _Tool('AudioLDM 2','https://github.com/haoheliu/AudioLDM2','توليد الموسيقى والمؤثرات','كمبيوتر / GPU','توليد أصوات ومقاطع من وصف نصي؛ يتطلب موارد نموذجية'),
    _Tool('Real-Time Voice Cloning','https://github.com/CorentinJ/Real-Time-Voice-Cloning','صوت وصوت آلي','كمبيوتر / GPU','بحث في استنساخ الصوت؛ استخدم صوتك أو موافقة صريحة فقط'),

    // Character, cartoon, and animation tools
    _Tool('OpenToonz','https://opentoonz.github.io/e/','كرتون وشخصيات','كمبيوتر','برنامج 2D animation مفتوح المصدر'),
    _Tool('Pencil2D','https://www.pencil2d.org','كرتون وشخصيات','كمبيوتر','رسم وتحريك ثنائي الأبعاد مفتوح المصدر'),
    _Tool('Synfig Studio','https://www.synfig.org','كرتون وشخصيات','كمبيوتر','تحريك 2D مفتوح المصدر'),
    _Tool('Tahoma2D','https://tahoma2d.org','كرتون وشخصيات','كمبيوتر','رسم وتحريك ثنائي الأبعاد'),
    _Tool('Blender Grease Pencil','https://www.blender.org','كرتون وشخصيات','كمبيوتر','رسم وتحريك 2D/3D داخل Blender'),
    _Tool('Krita Animation','https://krita.org','كرتون وشخصيات','كمبيوتر','رسم إطارات وتحريك 2D'),
    _Tool('Wick Editor','https://www.wickeditor.com','كرتون وشخصيات','ويب','رسوم متحركة ومشاهد تفاعلية'),
    _Tool('Live2D Cubism','https://www.live2d.com/en/','كرتون وشخصيات','كمبيوتر','تحريك شخصيات مرسومة؛ الخطة والترخيص حسب الاستخدام'),
    _Tool('VRoid Studio','https://vroid.com/en/studio','كرتون وشخصيات','كمبيوتر','إنشاء شخصيات 3D بأسلوب anime'),
    _Tool('Mixamo','https://www.mixamo.com','كرتون وشخصيات','ويب','تحريك هياكل شخصيات 3D؛ تحقق من شروط الأصول'),
    _Tool('AccuRIG','https://actorcore.reallusion.com/auto-rig','كرتون وشخصيات','كمبيوتر / ويب','تجهيز هيكل لشخصيات 3D؛ راجع الشروط'),
    _Tool('Cascadeur','https://cascadeur.com','كرتون وشخصيات','كمبيوتر','تحريك شخصيات 3D بخطة مجانية محدودة'),
    _Tool('Blockbench','https://www.blockbench.net','كرتون وشخصيات','ويب / كمبيوتر','إنشاء شخصيات ونماذج 3D منخفضة التفاصيل'),
    _Tool('MakeHuman','https://www.makehumancommunity.org','كرتون وشخصيات','كمبيوتر','إنشاء شخصيات بشرية 3D مفتوح المصدر'),
    _Tool('Nerfstudio','https://github.com/nerfstudio-project/nerfstudio','كرتون وشخصيات','كمبيوتر / GPU','إعادة بناء مشاهد 3D؛ مسار متخصص وليس مولد كرتون تلقائياً'),

    // Audio, voice, music, and sound effects
    _Tool('Audacity','https://www.audacityteam.org','صوت وموسيقى','كمبيوتر','تسجيل وتنظيف ومونتاج صوت مفتوح المصدر'),
    _Tool('Ardour','https://ardour.org','صوت وموسيقى','كمبيوتر','محطة عمل صوتية للتسجيل والمكساج'),
    _Tool('LMMS','https://lmms.io','صوت وموسيقى','كمبيوتر','تأليف موسيقى وإيقاعات مفتوح المصدر'),
    _Tool('MuseScore','https://musescore.org','صوت وموسيقى','كمبيوتر / ويب','تدوين موسيقي وكتابة النوتة'),
    _Tool('BandLab','https://www.bandlab.com','صوت وموسيقى','ويب / موبايل','استوديو موسيقى تعاوني؛ الميزات حسب الخدمة'),
    _Tool('Suno','https://suno.com','صوت وموسيقى','ويب / موبايل','توليد أغاني؛ تحقق من حدود المجاني وحقوق الاستخدام'),
    _Tool('Udio','https://www.udio.com','صوت وموسيقى','ويب','توليد موسيقى؛ تحقق من الشروط الحالية'),
    _Tool('Stable Audio Open','https://github.com/Stability-AI/stable-audio-tools','صوت وموسيقى','كمبيوتر / GPU','توليد أصوات ومقاطع موسيقية؛ افحص ترخيص النموذج'),
    _Tool('AudioCraft / MusicGen','https://github.com/facebookresearch/audiocraft','صوت وموسيقى','كمبيوتر / GPU','نماذج بحثية لتوليد الموسيقى؛ راجع ترخيص الكود والأوزان'),
    _Tool('Piper TTS','https://github.com/rhasspy/piper','صوت وصوت آلي','كمبيوتر / خادم','تحويل النص إلى كلام محلياً؛ الترخيص يختلف حسب الصوت'),
    _Tool('Coqui TTS','https://github.com/coqui-ai/TTS','صوت وصوت آلي','كمبيوتر / خادم','أدوات تحويل النص إلى كلام؛ تحقق من حالة المشروع والترخيص'),
    _Tool('OpenVoice','https://github.com/myshell-ai/OpenVoice','صوت وصوت آلي','كمبيوتر / GPU','استنساخ/تحويل صوت؛ استخدم أصواتاً بموافقة أصحابها'),
    _Tool('Whisper','https://github.com/openai/whisper','صوت وصوت آلي','كمبيوتر / خادم','تحويل الكلام إلى نص والتفريغ الصوتي'),
    _Tool('whisper.cpp','https://github.com/ggml-org/whisper.cpp','صوت وصوت آلي','كمبيوتر / أجهزة مدعومة','تشغيل تفريغ صوتي محلي بكفاءة نسبية'),
    _Tool('RVC WebUI','https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI','صوت وصوت آلي','كمبيوتر / GPU','تحويل صوت؛ استخدم فقط صوتك أو صوتاً لديك إذن صريح له'),
    _Tool('Bark','https://github.com/suno-ai/bark','صوت وصوت آلي','كمبيوتر / GPU','توليد صوت تجريبي؛ راجع متطلبات النموذج والترخيص'),
    _Tool('Freesound','https://freesound.org','مؤثرات صوتية','ويب','مكتبة مؤثرات؛ افحص ترخيص كل ملف ونسبته'),
    _Tool('Pixabay Music & SFX','https://pixabay.com/music/','مؤثرات صوتية','ويب','موسيقى ومؤثرات؛ تحقق من الترخيص لكل أصل'),
    _Tool('BBC Sound Effects','https://sound-effects.bbcrewind.co.uk','مؤثرات صوتية','ويب','أرشيف صوتي؛ الاستخدام التجاري قد يكون مقيداً'),
  ];

  Future<void> _openTool(_Tool tool) async {
    final ok = await launchUrl(Uri.parse(tool.url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح رابط الأداة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['الكل', 'فيديو', 'صور', 'ألعاب', 'كرتون وشخصيات', 'صوت وموسيقى', 'صوت وصوت آلي', 'مؤثرات صوتية', 'تحريك الوجه والشفاه', 'توليد الموسيقى والمؤثرات'];
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
              Text('مكتبة متوسعة للفيديو والصور والألعاب والكرتون والشخصيات والصوت والموسيقى والمؤثرات. روابط رسمية؛ ليست كل أداة متصلة آلياً أو مجانية بلا حدود.'),
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
            child: Text('الأدوات المطابقة: ${filtered.length} / ${_tools.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
