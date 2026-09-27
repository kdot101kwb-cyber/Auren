import 'package:flutter/foundation.dart';

enum AurenProviderTier { freeFirst, freeQuota, lowCost, premium }

class AurenAiProviderInfo {
  final String id;
  final String name;
  final AurenProviderTier tier;
  final Set<String> capabilities;
  final bool enabled;
  final String role;

  const AurenAiProviderInfo({
    required this.id,
    required this.name,
    required this.tier,
    required this.capabilities,
    required this.enabled,
    required this.role,
  });
}

/// Central catalog for AUREN's multi-provider strategy.
///
/// enabled=true means the provider has an implemented server adapter.
/// The remaining providers are catalogued but deliberately disabled until
/// their current API, pricing, auth and output contract are integrated.
class AurenAiProviderCatalog {
  static const providers = <AurenAiProviderInfo>[
    AurenAiProviderInfo(id:'pollinations',name:'Pollinations',tier:AurenProviderTier.freeFirst,capabilities:{'text','image','video','audio'},enabled:true,role:'Free-first media'),
    AurenAiProviderInfo(id:'gemini',name:'Gemini',tier:AurenProviderTier.freeQuota,capabilities:{'text','image','video','audio'},enabled:true,role:'General AI + media fallback'),
    AurenAiProviderInfo(id:'openrouter',name:'OpenRouter',tier:AurenProviderTier.freeQuota,capabilities:{'text'},enabled:true,role:'Multi-model text router'),
    AurenAiProviderInfo(id:'huggingface',name:'Hugging Face',tier:AurenProviderTier.freeQuota,capabilities:{'text'},enabled:true,role:'Open-model text router'),
    AurenAiProviderInfo(id:'cloudflare_workers_ai',name:'Cloudflare Workers AI',tier:AurenProviderTier.freeQuota,capabilities:{'text'},enabled:true,role:'Daily free inference'),
    AurenAiProviderInfo(id:'groq',name:'Groq',tier:AurenProviderTier.freeQuota,capabilities:{'text','audio'},enabled:false,role:'Fast inference'),
    AurenAiProviderInfo(id:'deepseek',name:'DeepSeek',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision'},enabled:false,role:'Reasoning'),
    AurenAiProviderInfo(id:'mistral',name:'Mistral AI',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision','audio'},enabled:false,role:'General AI'),
    AurenAiProviderInfo(id:'cerebras',name:'Cerebras',tier:AurenProviderTier.freeQuota,capabilities:{'text'},enabled:false,role:'Fast inference'),
    AurenAiProviderInfo(id:'nvidia_nim',name:'NVIDIA NIM',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision','image'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'cohere',name:'Cohere',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision','embeddings'},enabled:false,role:'RAG/search'),
    AurenAiProviderInfo(id:'zai_glm',name:'Z.ai / GLM',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision'},enabled:false,role:'Reasoning'),
    AurenAiProviderInfo(id:'chutes',name:'Chutes',tier:AurenProviderTier.freeQuota,capabilities:{'text','image','video','audio'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'sambanova',name:'SambaNova',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision'},enabled:false,role:'Fast inference'),
    AurenAiProviderInfo(id:'together',name:'Together AI',tier:AurenProviderTier.freeQuota,capabilities:{'text','image','video'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'fireworks',name:'Fireworks AI',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision','image'},enabled:false,role:'Generative AI'),
    AurenAiProviderInfo(id:'deepinfra',name:'DeepInfra',tier:AurenProviderTier.freeQuota,capabilities:{'text','image','audio'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'featherless',name:'Featherless AI',tier:AurenProviderTier.freeQuota,capabilities:{'text'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'public_ai',name:'Public AI',tier:AurenProviderTier.freeQuota,capabilities:{'text'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'baseten',name:'Baseten',tier:AurenProviderTier.lowCost,capabilities:{'text','vision'},enabled:false,role:'Hosted models'),
    AurenAiProviderInfo(id:'scaleway',name:'Scaleway AI',tier:AurenProviderTier.freeQuota,capabilities:{'text','embeddings'},enabled:false,role:'EU inference'),
    AurenAiProviderInfo(id:'ovhcloud',name:'OVHcloud AI',tier:AurenProviderTier.freeQuota,capabilities:{'text','embeddings'},enabled:false,role:'Cloud AI'),
    AurenAiProviderInfo(id:'fal',name:'fal.ai',tier:AurenProviderTier.freeQuota,capabilities:{'image','video','audio'},enabled:false,role:'Creative media'),
    AurenAiProviderInfo(id:'replicate',name:'Replicate',tier:AurenProviderTier.freeQuota,capabilities:{'text','image','video','audio'},enabled:false,role:'Model marketplace'),
    AurenAiProviderInfo(id:'novita',name:'Novita AI',tier:AurenProviderTier.freeQuota,capabilities:{'text','image','video'},enabled:false,role:'Creative + LLM'),
    AurenAiProviderInfo(id:'wavespeed',name:'WaveSpeedAI',tier:AurenProviderTier.freeQuota,capabilities:{'image','video'},enabled:false,role:'Media generation'),
    AurenAiProviderInfo(id:'nscale',name:'Nscale',tier:AurenProviderTier.lowCost,capabilities:{'image','video','text'},enabled:false,role:'GPU inference'),
    AurenAiProviderInfo(id:'siliconflow',name:'SiliconFlow',tier:AurenProviderTier.freeQuota,capabilities:{'text','image','video','audio'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'modelscope',name:'ModelScope',tier:AurenProviderTier.freeQuota,capabilities:{'text','image','video','audio'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'stability',name:'Stability AI',tier:AurenProviderTier.freeQuota,capabilities:{'image','video'},enabled:false,role:'Image generation'),
    AurenAiProviderInfo(id:'kling',name:'Kling',tier:AurenProviderTier.premium,capabilities:{'video'},enabled:false,role:'Video generation'),
    AurenAiProviderInfo(id:'luma',name:'Luma',tier:AurenProviderTier.premium,capabilities:{'video','image'},enabled:false,role:'Video generation'),
    AurenAiProviderInfo(id:'runway',name:'Runway',tier:AurenProviderTier.premium,capabilities:{'video','image'},enabled:false,role:'Video generation'),
    AurenAiProviderInfo(id:'deepgram',name:'Deepgram',tier:AurenProviderTier.freeQuota,capabilities:{'audio','text'},enabled:false,role:'Speech'),
    AurenAiProviderInfo(id:'elevenlabs',name:'ElevenLabs',tier:AurenProviderTier.freeQuota,capabilities:{'audio'},enabled:false,role:'Voice'),
    AurenAiProviderInfo(id:'cartesia',name:'Cartesia',tier:AurenProviderTier.freeQuota,capabilities:{'audio','text'},enabled:false,role:'Voice'),
    AurenAiProviderInfo(id:'playht',name:'PlayHT',tier:AurenProviderTier.freeQuota,capabilities:{'audio'},enabled:false,role:'Voice'),
    AurenAiProviderInfo(id:'assemblyai',name:'AssemblyAI',tier:AurenProviderTier.freeQuota,capabilities:{'audio','text'},enabled:false,role:'Transcription'),
    AurenAiProviderInfo(id:'groq_speech',name:'Groq Speech',tier:AurenProviderTier.freeQuota,capabilities:{'audio','text'},enabled:false,role:'Speech'),
    AurenAiProviderInfo(id:'fish_audio',name:'Fish Audio',tier:AurenProviderTier.freeQuota,capabilities:{'audio'},enabled:false,role:'Voice'),
    AurenAiProviderInfo(id:'audiocraft',name:'AudioCraft / MusicGen',tier:AurenProviderTier.freeFirst,capabilities:{'audio','music'},enabled:false,role:'Open music generation'),
    AurenAiProviderInfo(id:'stable_audio',name:'Stable Audio',tier:AurenProviderTier.freeQuota,capabilities:{'audio','music'},enabled:false,role:'Music generation'),
    AurenAiProviderInfo(id:'qwen',name:'Qwen',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision','audio','image'},enabled:false,role:'Open multimodal models'),
    AurenAiProviderInfo(id:'meta_llama',name:'Meta Llama',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'minimax',name:'MiniMax',tier:AurenProviderTier.freeQuota,capabilities:{'text','audio','video'},enabled:false,role:'Multimodal AI'),
    AurenAiProviderInfo(id:'moonshot_kimi',name:'Moonshot / Kimi',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision'},enabled:false,role:'Reasoning'),
    AurenAiProviderInfo(id:'xiaomi_mimo',name:'Xiaomi MiMo',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision'},enabled:false,role:'Open models'),
    AurenAiProviderInfo(id:'amazon_bedrock',name:'Amazon Bedrock',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision','audio'},enabled:false,role:'Cloud model gateway'),
    AurenAiProviderInfo(id:'azure_ai',name:'Azure AI',tier:AurenProviderTier.freeQuota,capabilities:{'text','vision','audio'},enabled:false,role:'Cloud model gateway'),
  ];

  static List<AurenAiProviderInfo> forCapability(String capability) =>
      providers.where((p) => p.capabilities.contains(capability)).toList(growable:false);

  static List<AurenAiProviderInfo> enabledFor(String capability) =>
      forCapability(capability).where((p) => p.enabled).toList(growable:false);

  static AurenAiProviderInfo? byId(String id) {
    for (final provider in providers) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  static int get total => providers.length;
  static int get enabledCount => providers.where((p) => p.enabled).length;

  static void assertCatalogSize() {
    assert(providers.length == 50, 'AUREN provider catalog must contain exactly 50 providers.');
  }
}
