'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/scheduler');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const db = getFirestore();
const REGION = 'us-central1';
const COLLECTION = 'nova_market_intelligence';
const DEFAULT_TOPICS = ['AI automation for small business', 'Arabic AI services', 'short video editing', 'Flutter app development', 'AI data annotation'];

// Semrush-like research toolbox. These are official entry points, not claimed integrations.
// API access, country coverage and free limits can change; verify before relying on any paid feature.
const MARKET_RESEARCH_TOOLS = [
  {id:'google_trends',name:'Google Trends',role:'relative search-interest and seasonality',url:'https://trends.google.com/trends/',access:'free web tool; no stable public general-purpose API'},
  {id:'ahrefs_free',name:'Ahrefs Free SEO Tools',role:'keyword and site checks',url:'https://ahrefs.com/free-seo-tools',access:'free limited tools; paid features exist'},
  {id:'similarweb',name:'Similarweb',role:'website traffic and competitor estimates',url:'https://www.similarweb.com/',access:'limited free views; estimates are not exact analytics'},
  {id:'moz',name:'Moz',role:'domain authority and keyword research',url:'https://moz.com/free-seo-tools',access:'limited free tools; account or paid limits may apply'},
  {id:'ubersuggest',name:'Ubersuggest',role:'keyword ideas and competitor SEO',url:'https://neilpatel.com/ubersuggest/',access:'limited free usage; paid plans exist'},
  {id:'google_keyword_planner',name:'Google Keyword Planner',role:'keyword ideas and ad-planning ranges',url:'https://ads.google.com/home/tools/keyword-planner/',access:'Google Ads account; volume ranges may depend on account activity'},
  {id:'exploding_topics',name:'Exploding Topics',role:'emerging-topic discovery',url:'https://explodingtopics.com/',access:'limited free content; premium features exist'},
  {id:'answerthepublic',name:'AnswerThePublic',role:'question and search-intent discovery',url:'https://answerthepublic.com/',access:'limited free searches; paid plans exist'},
  {id:'bing_webmaster',name:'Bing Webmaster Tools',role:'site search performance and SEO diagnostics',url:'https://www.bing.com/webmasters/',access:'free for verified site owners; not a general competitor API'},
  {id:'semrush',name:'Semrush',role:'benchmark for keyword, competitor and market research',url:'https://www.semrush.com/',access:'free account limits; API access may require an eligible paid plan'}
];

const SOURCE_REGISTRY = [
  {id:'hacker_news',name:'Hacker News Algolia',kind:'developer demand discussion',url:'https://hn.algolia.com/api/v1/search'},
  {id:'github_issues',name:'GitHub Issues Search',kind:'problem statements and unmet needs',url:'https://api.github.com/search/issues'},
  {id:'stack_exchange',name:'Stack Exchange',kind:'questions and recurring pain points',url:'https://api.stackexchange.com/2.3/search/advanced'},
  {id:'gdelt',name:'GDELT',kind:'global news attention',url:'https://api.gdeltproject.org/api/v2/doc/doc'},
  {id:'openalex',name:'OpenAlex',kind:'research and emerging topic context',url:'https://api.openalex.org/works'},
  {id:'npm',name:'npm Registry',kind:'developer ecosystem activity proxy',url:'https://api.npmjs.org/downloads/point/last-week/'},
  {id:'huggingface',name:'Hugging Face',kind:'AI model and dataset ecosystem proxy',url:'https://huggingface.co/api/models'},
  {id:'gitlab',name:'GitLab Projects',kind:'open-source project activity proxy',url:'https://gitlab.com/api/v4/projects'},
  {id:'world_bank',name:'World Bank Indicators',kind:'country and sector context, not real-time demand',url:'https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD'},
  {id:'rdap',name:'Verisign RDAP',kind:'domain registry status only, not market demand',url:'https://rdap.verisign.com/com/v1/domain/'}
];

function normalizeTopic(value) {
  return String(value || '').trim().replace(/\s+/g, ' ').slice(0, 120);
}

function safeHttpsUrl(value) {
  try { const u = new URL(String(value || '')); return u.protocol === 'https:' ? u.toString() : ''; } catch (_) { return ''; }
}

function scoreMarketOpportunity(row) {
  const signals = Number(row.signalCount || 0);
  const sourceCount = Number(row.sourceCount || 0);
  const trend = Number(row.trendScore || 0);
  const pain = Number(row.painScore || 0);
  const build = Number(row.zeroCostBuildScore || 0);
  const payment = Number(row.paymentFeasibilityScore || 0);
  const competition = Number(row.competitionScore || 0);
  const evidence = Number(row.evidenceStrength || 0);
  const bounded = (n) => Math.max(0, Math.min(100, Number.isFinite(n) ? n : 0));
  const score = Math.round((
    bounded(trend) * .20 + bounded(pain) * .20 + bounded(build) * .20 +
    bounded(payment) * .15 + bounded(competition) * .10 + bounded(evidence) * .15
  ) * 10) / 10;
  // A numeric payment score is only a placeholder until country/payment checks are verified.
  // Never label an opportunity ready for validation unless both checks are explicitly confirmed.
  const paymentVerified = row.paymentVerified === true;
  const zeroCostValidated = row.zeroCostValidated === true;
  const ready = score >= 70 && sourceCount >= 2 && evidence >= 55 && build >= 60 && payment >= 50 && paymentVerified && zeroCostValidated;
  return {score, readiness:ready ? 'ready_to_validate' : score >= 50 ? 'research_more' : 'weak_signal',
    eligibleForZeroCostTest:ready, paymentVerified, zeroCostValidated};
}

async function fetchJson(url, timeoutMs = 8000) {
  const response = await fetch(url, {headers:{accept:'application/json','user-agent':'NOVA-Market-Intelligence/1.0'}, signal:AbortSignal.timeout(timeoutMs)});
  if (!response.ok) throw new Error('HTTP ' + response.status);
  return response.json();
}

function buildUrl(base, params) {
  const url = new URL(base);
  for (const [key, value] of Object.entries(params)) if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, String(value));
  return url.toString();
}

async function collectTopicEvidence(topic) {
  const q = encodeURIComponent(topic);
  const tasks = [
    async () => { const d = await fetchJson(buildUrl('https://hn.algolia.com/api/v1/search', {query:topic,tags:'story',hitsPerPage:0})); return {source:'hacker_news',count:Number(d.nbHits||0),url:'https://hn.algolia.com/?q='+q}; },
    async () => { const d = await fetchJson(buildUrl('https://api.github.com/search/issues', {q:topic+' is:issue',per_page:1})); return {source:'github_issues',count:Number(d.total_count||0),url:'https://github.com/search?q='+q+'+is%3Aissue&type=issues'}; },
    async () => { const d = await fetchJson(buildUrl('https://api.stackexchange.com/2.3/search/advanced', {q:topic,site:'stackoverflow',pagesize:1,filter:'total'})); return {source:'stack_exchange',count:Number(d.total||0),url:'https://stackoverflow.com/search?q='+q}; },
    async () => { const d = await fetchJson(buildUrl('https://api.gdeltproject.org/api/v2/doc/doc', {query:topic,mode:'TimelineVolRaw',format:'json',timespan:'7d'})); const points=Array.isArray(d.timeline)?d.timeline.flatMap(x=>x.data||[]):[]; return {source:'gdelt',count:points.reduce((n,x)=>n+Number(x.value||0),0),url:'https://www.gdeltproject.org/'}; },
    async () => { const d = await fetchJson(buildUrl('https://api.openalex.org/works', {search:topic,per_page:1})); return {source:'openalex',count:Number(d.meta?.count||0),url:'https://openalex.org/works?search='+q}; },
    async () => { const packageName = topic.toLowerCase().includes('flutter')?'flutter':topic.toLowerCase().includes('video')?'remotion':topic.toLowerCase().includes('ai')?'langchain':'typescript'; const d = await fetchJson('https://api.npmjs.org/downloads/point/last-week/'+encodeURIComponent(packageName)); return {source:'npm',count:Number(d.downloads||0),url:'https://www.npmjs.com/package/'+encodeURIComponent(packageName),note:'proxy package downloads, not proof of customer demand'}; },
    async () => { const d = await fetchJson(buildUrl('https://huggingface.co/api/models', {search:topic,limit:1})); return {source:'huggingface',count:Array.isArray(d)?d.length:0,url:'https://huggingface.co/models?search='+q}; },
    async () => { const d = await fetchJson(buildUrl('https://gitlab.com/api/v4/projects', {search:topic,per_page:1,order_by:'last_activity_at'})); return {source:'gitlab',count:Array.isArray(d)?d.length:0,url:'https://gitlab.com/explore/projects?name='+q}; },
    async () => { const d = await fetchJson('https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?format=json&per_page=1'); return {source:'world_bank',count:Array.isArray(d?.[1])?d[1].length:0,url:'https://data.worldbank.org/indicator/NY.GDP.MKTP.CD',note:'macro context only; not demand evidence'}; },
    async () => { const domain = topic.toLowerCase().includes('flutter')?'flutter.dev':topic.toLowerCase().includes('video')?'remotion.dev':'huggingface.co'; const response = await fetch('https://rdap.verisign.com/com/v1/domain/'+encodeURIComponent(domain.replace(/\\.(dev|co|io)$/,'' )+'.com'),{headers:{accept:'application/rdap+json'},signal:AbortSignal.timeout(6000)}); return {source:'rdap',count:response.status===404?0:response.status===200?1:null,url:'https://lookup.icann.org/'}; }
  ];
  const results = await Promise.all(tasks.map(async (task, index) => { try { return await task(); } catch (e) { return {source:SOURCE_REGISTRY[index]?.id || 'unknown',count:null,status:'unavailable',error:String(e?.message||e).slice(0,100)}; } }));
  const evidence = results.filter(x=>x.source!=='unknown');
  const available = evidence.filter(x=>x.count !== null);
  const demand = available.filter(x=>!['world_bank','rdap'].includes(x.source));
  const totalSignals = demand.reduce((n,x)=>n+Math.min(100, Math.log10(Math.max(0,Number(x.count)||0)+1)*20),0);
  const trendScore = Math.round(Math.min(100,totalSignals / Math.max(1,demand.length)));
  const sourceCount = demand.filter(x=>Number(x.count)>0).length;
  const row = {
    id:topic.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'').slice(0,80),
    title:topic,
    query:topic,
    observedAt:new Date().toISOString(),
    sources:results.map(x=>({...x,source:x.source==='unknown'?'unavailable':x.source})),
    sourceCount,
    signalCount:demand.reduce((n,x)=>n+Math.max(0,Number(x.count)||0),0),
    trendScore,
    painScore:Math.min(100,sourceCount*12),
    zeroCostBuildScore:65,
    paymentFeasibilityScore:50,
    paymentVerified:false,
    paymentVerificationNote:'لم يتم التحقق من قبول السودان أو وسيلة استلام الأرباح؛ تحقق يدوياً قبل التنفيذ.',
    zeroCostValidated:false,
    competitionScore:50,
    evidenceStrength:Math.min(100,sourceCount*12),
    recommendedAction:'افحص 3 عروض حقيقية من العملاء المحتملين، أنشئ نموذجاً مجانياً صغيراً، ولا تدفع أو تشترِ أدوات قبل إثبات الطلب.',
    limitations:'هذه إشارات أولية من واجهات عامة؛ المقاييس غير قابلة للمقارنة مباشرة، ولا تثبت نية الشراء أو توفر الدفع في بلدك.'
  };
  return {...row,...scoreMarketOpportunity(row)};
}

async function scanNovaMarketIntelligence(topics = DEFAULT_TOPICS) {
  const cleaned = [...new Set((Array.isArray(topics)?topics:DEFAULT_TOPICS).map(normalizeTopic).filter(Boolean))].slice(0,8);
  const rows = [];
  for (const topic of cleaned) rows.push(await collectTopicEvidence(topic));
  rows.sort((a,b)=>b.score-a.score);
  return {generatedAt:new Date().toISOString(),tools:MARKET_RESEARCH_TOOLS,sources:SOURCE_REGISTRY,opportunities:rows,
    policy:'Ranked candidates are hypotheses for a zero-cost validation test, not confirmed jobs, guaranteed income, or financial advice. Verify payment availability and eligibility before investing time.',
    readyCount:rows.filter(x=>x.eligibleForZeroCostTest).length};
}

exports.getNovaMarketIntelligence = onCall({region:REGION,timeoutSeconds:120,memory:'512MiB',enforceAppCheck:true},async request=>{
  if(!request.auth?.uid) throw new HttpsError('unauthenticated','Sign in to use NOVA market intelligence.');
  const topics = Array.isArray(request.data?.topics)?request.data.topics:DEFAULT_TOPICS;
  try {
    const result=await scanNovaMarketIntelligence(topics);
    await db.collection(COLLECTION).doc('latest').set({...result,updatedAt:FieldValue.serverTimestamp()});
    return result;
  } catch(error) {
    throw new HttpsError('unavailable','Market scan failed: '+String(error?.message||error).slice(0,160));
  }
});

exports.runNovaMarketIntelligenceDaily = onSchedule({schedule:'every day 08:45',timeZone:'Africa/Khartoum',region:REGION,timeoutSeconds:300,memory:'512MiB',maxInstances:1},async()=>{
  const result=await scanNovaMarketIntelligence();
  await db.collection(COLLECTION).doc('latest').set({...result,updatedAt:FieldValue.serverTimestamp()});
});

exports.scanNovaMarketIntelligenceForTest=scanNovaMarketIntelligence;
exports.scoreMarketOpportunityForTest=scoreMarketOpportunity;
exports.marketResearchToolsForTest=MARKET_RESEARCH_TOOLS;
exports.marketSourceRegistryForTest=SOURCE_REGISTRY;
exports.normalizeTopicForTest=normalizeTopic;
