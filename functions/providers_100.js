'use strict';

/**
 * AUREN 100-provider catalog.
 * 
 * IMPORTANT: this is a provider catalog, not 100 live integrations.
 * Only providers with an adapter/credentials are allowed to execute jobs.
 * freeTier means a free tier/open-source path may exist; it does NOT mean
 * unlimited free compute or unlimited production generation.
 */

const PROVIDERS_100 = Object.freeze([
  {rank:1, id:"local_open_source", label:"Self-hosted Open Models", capabilities:["text","image","video","audio","music","qc"], freeTier:true, integration:'catalog_only'},
  {rank:2, id:"huggingface", label:"Hugging Face Inference", capabilities:["text","image","audio","qc"], freeTier:true, integration:'catalog_only'},
  {rank:3, id:"fal_ai", label:"fal.ai", capabilities:["image","video","audio"], freeTier:false, integration:'catalog_only'},
  {rank:4, id:"replicate", label:"Replicate", capabilities:["image","video","audio"], freeTier:false, integration:'catalog_only'},
  {rank:5, id:"together_ai", label:"Together AI", capabilities:["text","image","video","audio"], freeTier:true, integration:'catalog_only'},
  {rank:6, id:"fireworks_ai", label:"Fireworks AI", capabilities:["text","vision","audio"], freeTier:false, integration:'catalog_only'},
  {rank:7, id:"groq", label:"Groq", capabilities:["text","vision","audio"], freeTier:true, integration:'catalog_only'},
  {rank:8, id:"cerebras", label:"Cerebras", capabilities:["text"], freeTier:true, integration:'catalog_only'},
  {rank:9, id:"deepinfra", label:"DeepInfra", capabilities:["text","image","audio"], freeTier:false, integration:'catalog_only'},
  {rank:10, id:"novita_ai", label:"Novita AI", capabilities:["text","image","video"], freeTier:false, integration:'catalog_only'},
  {rank:11, id:"nscale", label:"Nscale", capabilities:["text","image"], freeTier:false, integration:'catalog_only'},
  {rank:12, id:"ovhcloud_ai", label:"OVHcloud AI Endpoints", capabilities:["text","vision"], freeTier:false, integration:'catalog_only'},
  {rank:13, id:"public_ai", label:"Public AI", capabilities:["text"], freeTier:true, integration:'catalog_only'},
  {rank:14, id:"scaleway", label:"Scaleway AI", capabilities:["text","embedding"], freeTier:false, integration:'catalog_only'},
  {rank:15, id:"baseten", label:"Baseten", capabilities:["text","vision"], freeTier:false, integration:'catalog_only'},
  {rank:16, id:"cohere", label:"Cohere", capabilities:["text","vision","embedding","rerank"], freeTier:true, integration:'catalog_only'},
  {rank:17, id:"featherless_ai", label:"Featherless AI", capabilities:["text","vision"], freeTier:false, integration:'catalog_only'},
  {rank:18, id:"z_ai", label:"Z.ai", capabilities:["text","vision"], freeTier:true, integration:'catalog_only'},
  {rank:19, id:"wavespeed_ai", label:"WaveSpeedAI", capabilities:["image","video"], freeTier:false, integration:'catalog_only'},
  {rank:20, id:"google_gemini", label:"Google Gemini API", capabilities:["text","vision","image","audio","qc"], freeTier:true, integration:'catalog_only'},
  {rank:21, id:"google_veo", label:"Google Veo", capabilities:["video"], freeTier:false, integration:'catalog_only'},
  {rank:22, id:"google_imagen", label:"Google Imagen", capabilities:["image"], freeTier:false, integration:'catalog_only'},
  {rank:23, id:"openai", label:"OpenAI", capabilities:["text","vision","image","audio","qc"], freeTier:false, integration:'catalog_only'},
  {rank:24, id:"anthropic", label:"Anthropic Claude", capabilities:["text","vision"], freeTier:false, integration:'catalog_only'},
  {rank:25, id:"xai", label:"xAI", capabilities:["text","vision"], freeTier:false, integration:'catalog_only'},
  {rank:26, id:"mistral", label:"Mistral AI", capabilities:["text","vision","embedding"], freeTier:true, integration:'catalog_only'},
  {rank:27, id:"ai21", label:"AI21 Labs", capabilities:["text"], freeTier:false, integration:'catalog_only'},
  {rank:28, id:"amazon_bedrock", label:"Amazon Bedrock", capabilities:["text","vision","image","audio"], freeTier:true, integration:'catalog_only'},
  {rank:29, id:"azure_ai", label:"Microsoft Azure AI", capabilities:["text","vision","image","audio"], freeTier:true, integration:'catalog_only'},
  {rank:30, id:"ibm_watsonx", label:"IBM watsonx", capabilities:["text","vision","embedding"], freeTier:false, integration:'catalog_only'},
  {rank:31, id:"sambanova", label:"SambaNova", capabilities:["text","vision"], freeTier:true, integration:'catalog_only'},
  {rank:32, id:"nvidia_nim", label:"NVIDIA NIM", capabilities:["text","vision","image","audio"], freeTier:false, integration:'catalog_only'},
  {rank:33, id:"modal", label:"Modal", capabilities:["text","image","video","audio"], freeTier:false, integration:'catalog_only'},
  {rank:34, id:"runpod", label:"RunPod", capabilities:["text","image","video","audio"], freeTier:false, integration:'catalog_only'},
  {rank:35, id:"lambda_cloud", label:"Lambda Cloud", capabilities:["text","image","video"], freeTier:false, integration:'catalog_only'},
  {rank:36, id:"vast_ai", label:"Vast.ai", capabilities:["text","image","video"], freeTier:false, integration:'catalog_only'},
  {rank:37, id:"paperspace", label:"Paperspace", capabilities:["text","image","video"], freeTier:false, integration:'catalog_only'},
  {rank:38, id:"beam", label:"Beam Cloud", capabilities:["text","image","video"], freeTier:false, integration:'catalog_only'},
  {rank:39, id:"replicate_hardware", label:"Replicate Deployments", capabilities:["text","image","video"], freeTier:false, integration:'catalog_only'},
  {rank:40, id:"lepton_ai", label:"Lepton AI", capabilities:["text","image"], freeTier:false, integration:'catalog_only'},
  {rank:41, id:"friendli_ai", label:"FriendliAI", capabilities:["text","vision"], freeTier:true, integration:'catalog_only'},
  {rank:42, id:"predibase", label:"Predibase", capabilities:["text","vision"], freeTier:false, integration:'catalog_only'},
  {rank:43, id:"baseten_serverless", label:"Baseten Serverless", capabilities:["text","vision"], freeTier:false, integration:'catalog_only'},
  {rank:44, id:"octoai", label:"OctoAI", capabilities:["text","image"], freeTier:false, integration:'catalog_only'},
  {rank:45, id:"databricks_mosaic", label:"Databricks Mosaic AI", capabilities:["text","vision","embedding"], freeTier:false, integration:'catalog_only'},
  {rank:46, id:"snowflake_cortex", label:"Snowflake Cortex", capabilities:["text","vision","embedding"], freeTier:false, integration:'catalog_only'},
  {rank:47, id:"vertex_ai", label:"Google Vertex AI", capabilities:["text","vision","image","audio","video"], freeTier:true, integration:'catalog_only'},
  {rank:48, id:"cloudflare_workers_ai", label:"Cloudflare Workers AI", capabilities:["text","image","embedding","qc"], freeTier:true, integration:'catalog_only'},
  {rank:49, id:"openrouter", label:"OpenRouter", capabilities:["text","vision","qc"], freeTier:true, integration:'catalog_only'},
  {rank:50, id:"perplexity", label:"Perplexity API", capabilities:["text","search"], freeTier:false, integration:'catalog_only'},
  {rank:51, id:"you_com", label:"You.com API", capabilities:["text","search"], freeTier:true, integration:'catalog_only'},
  {rank:52, id:"exa", label:"Exa AI", capabilities:["search","text"], freeTier:true, integration:'catalog_only'},
  {rank:53, id:"tavily", label:"Tavily", capabilities:["search"], freeTier:true, integration:'catalog_only'},
  {rank:54, id:"serper", label:"Serper", capabilities:["search"], freeTier:false, integration:'catalog_only'},
  {rank:55, id:"firecrawl", label:"Firecrawl", capabilities:["search","text"], freeTier:true, integration:'catalog_only'},
  {rank:56, id:"brave_search", label:"Brave Search API", capabilities:["search"], freeTier:true, integration:'catalog_only'},
  {rank:57, id:"jina_ai", label:"Jina AI", capabilities:["text","embedding","rerank"], freeTier:true, integration:'catalog_only'},
  {rank:58, id:"voyage_ai", label:"Voyage AI", capabilities:["embedding","rerank"], freeTier:false, integration:'catalog_only'},
  {rank:59, id:"pinecone", label:"Pinecone", capabilities:["embedding","search"], freeTier:false, integration:'catalog_only'},
  {rank:60, id:"weaviate", label:"Weaviate", capabilities:["embedding","search"], freeTier:true, integration:'catalog_only'},
  {rank:61, id:"qdrant", label:"Qdrant", capabilities:["embedding","search"], freeTier:true, integration:'catalog_only'},
  {rank:62, id:"milvus", label:"Milvus", capabilities:["embedding","search"], freeTier:true, integration:'catalog_only'},
  {rank:63, id:"elevenlabs", label:"ElevenLabs", capabilities:["audio","voice"], freeTier:true, integration:'catalog_only'},
  {rank:64, id:"cartesia", label:"Cartesia", capabilities:["audio","voice"], freeTier:true, integration:'catalog_only'},
  {rank:65, id:"playht", label:"PlayHT", capabilities:["audio","voice"], freeTier:false, integration:'catalog_only'},
  {rank:66, id:"deepgram", label:"Deepgram", capabilities:["audio","stt","tts"], freeTier:true, integration:'catalog_only'},
  {rank:67, id:"assemblyai", label:"AssemblyAI", capabilities:["audio","stt"], freeTier:true, integration:'catalog_only'},
  {rank:68, id:"speechmatics", label:"Speechmatics", capabilities:["audio","stt"], freeTier:false, integration:'catalog_only'},
  {rank:69, id:"soniox", label:"Soniox", capabilities:["audio","stt"], freeTier:true, integration:'catalog_only'},
  {rank:70, id:"gladia", label:"Gladia", capabilities:["audio","stt"], freeTier:true, integration:'catalog_only'},
  {rank:71, id:"sarvam_ai", label:"Sarvam AI", capabilities:["text","audio","stt"], freeTier:true, integration:'catalog_only'},
  {rank:72, id:"whisper_api", label:"Whisper-compatible providers", capabilities:["audio","stt"], freeTier:true, integration:'catalog_only'},
  {rank:73, id:"stability_ai", label:"Stability AI", capabilities:["image","audio"], freeTier:false, integration:'catalog_only'},
  {rank:74, id:"black_forest_labs", label:"Black Forest Labs", capabilities:["image"], freeTier:false, integration:'catalog_only'},
  {rank:75, id:"ideogram", label:"Ideogram", capabilities:["image"], freeTier:false, integration:'catalog_only'},
  {rank:76, id:"leonardo_ai", label:"Leonardo AI", capabilities:["image","video"], freeTier:false, integration:'catalog_only'},
  {rank:77, id:"getimg_ai", label:"getimg.ai", capabilities:["image"], freeTier:false, integration:'catalog_only'},
  {rank:78, id:"clipdrop", label:"Clipdrop", capabilities:["image"], freeTier:false, integration:'catalog_only'},
  {rank:79, id:"recraft", label:"Recraft", capabilities:["image"], freeTier:false, integration:'catalog_only'},
  {rank:80, id:"fal_flux", label:"FLUX via fal.ai", capabilities:["image","video"], freeTier:false, integration:'catalog_only'},
  {rank:81, id:"krea_ai", label:"Krea", capabilities:["image","video"], freeTier:false, integration:'catalog_only'},
  {rank:82, id:"runway", label:"Runway", capabilities:["video","image"], freeTier:false, integration:'catalog_only'},
  {rank:83, id:"luma", label:"Luma Dream Machine", capabilities:["video","image"], freeTier:false, integration:'catalog_only'},
  {rank:84, id:"kling_ai", label:"Kling AI", capabilities:["video","image"], freeTier:false, integration:'catalog_only'},
  {rank:85, id:"pixverse", label:"PixVerse", capabilities:["video","image"], freeTier:false, integration:'catalog_only'},
  {rank:86, id:"pika", label:"Pika", capabilities:["video"], freeTier:false, integration:'catalog_only'},
  {rank:87, id:"hailuo", label:"Hailuo AI", capabilities:["video"], freeTier:false, integration:'catalog_only'},
  {rank:88, id:"vidu", label:"Vidu", capabilities:["video"], freeTier:false, integration:'catalog_only'},
  {rank:89, id:"minimax", label:"MiniMax", capabilities:["text","video","audio"], freeTier:false, integration:'catalog_only'},
  {rank:90, id:"wan_ai", label:"Wan AI open models", capabilities:["video","image"], freeTier:true, integration:'catalog_only'},
  {rank:91, id:"ltx_video", label:"LTX-Video", capabilities:["video"], freeTier:true, integration:'catalog_only'},
  {rank:92, id:"hunyuan_video", label:"HunyuanVideo", capabilities:["video"], freeTier:true, integration:'catalog_only'},
  {rank:93, id:"cogvideox", label:"CogVideoX", capabilities:["video"], freeTier:true, integration:'catalog_only'},
  {rank:94, id:"mochi", label:"Mochi", capabilities:["video"], freeTier:true, integration:'catalog_only'},
  {rank:95, id:"stable_video", label:"Stable Video", capabilities:["video"], freeTier:true, integration:'catalog_only'},
  {rank:96, id:"musicgen", label:"MusicGen", capabilities:["music","audio"], freeTier:true, integration:'catalog_only'},
  {rank:97, id:"suno", label:"Suno", capabilities:["music","audio"], freeTier:false, integration:'catalog_only'},
  {rank:98, id:"udio", label:"Udio", capabilities:["music","audio"], freeTier:false, integration:'catalog_only'},
  {rank:99, id:"audiocraft", label:"Meta AudioCraft", capabilities:["music","audio"], freeTier:true, integration:'catalog_only'},
  {rank:100, id:"demucs", label:"Meta Demucs", capabilities:["audio","music"], freeTier:true, integration:'catalog_only'},
  {rank:101, id:"descript", label:"Descript", capabilities:["audio","video"], freeTier:false, integration:'catalog_only'},
  {rank:102, id:"kapwing", label:"Kapwing", capabilities:["video","image"], freeTier:true, integration:'catalog_only'},
  {rank:103, id:"veed", label:"VEED", capabilities:["video","audio"], freeTier:false, integration:'catalog_only'},
  {rank:104, id:"heygen", label:"HeyGen", capabilities:["video","avatar","voice"], freeTier:false, integration:'catalog_only'},
  {rank:105, id:"synthesia", label:"Synthesia", capabilities:["video","avatar","voice"], freeTier:false, integration:'catalog_only'},
  {rank:106, id:"d_id", label:"D-ID", capabilities:["video","avatar","voice"], freeTier:false, integration:'catalog_only'},
  {rank:107, id:"twelve_labs", label:"Twelve Labs", capabilities:["video","search","vision"], freeTier:true, integration:'catalog_only'},
  {rank:108, id:"assembly_video", label:"AssemblyAI Video Intelligence", capabilities:["video","audio","stt"], freeTier:true, integration:'catalog_only'},
  {rank:109, id:"aws_transcribe", label:"AWS Transcribe", capabilities:["audio","stt"], freeTier:true, integration:'catalog_only'},
  {rank:110, id:"aws_polly", label:"AWS Polly", capabilities:["audio","tts"], freeTier:true, integration:'catalog_only'},
  {rank:111, id:"azure_speech", label:"Azure Speech", capabilities:["audio","stt","tts"], freeTier:true, integration:'catalog_only'},
  {rank:112, id:"google_cloud_speech", label:"Google Cloud Speech", capabilities:["audio","stt","tts"], freeTier:true, integration:'catalog_only'},
  {rank:113, id:"google_cloud_tts", label:"Google Cloud TTS", capabilities:["audio","tts"], freeTier:true, integration:'catalog_only'},
  {rank:114, id:"elevenlabs_music", label:"ElevenLabs Music", capabilities:["music","audio"], freeTier:false, integration:'catalog_only'},
]);

const PROVIDER_MAP = new Map(PROVIDERS_100.map((p) => [p.id, p]));

function listAuren100Providers(capability) {
  const wanted = String(capability || '').trim().toLowerCase();
  return PROVIDERS_100.filter((p) => !wanted || p.capabilities.includes(wanted))
    .map((p) => ({...p, capabilities:[...p.capabilities]}));
}

function getAuren100Provider(id) {
  return PROVIDER_MAP.get(String(id || '')) || null;
}

function getAuren100FreeFirst(capability) {
  return listAuren100Providers(capability)
    .sort((a,b) => Number(b.freeTier) - Number(a.freeTier) || a.rank - b.rank);
}

module.exports = {PROVIDERS_100, listAuren100Providers, getAuren100Provider, getAuren100FreeFirst};
