'use strict';

// Candidate marketplace catalog supplied for NOVA research. This is not an endorsement
// or proof of country eligibility; payout, fees, age, identity, and program rules must
// be checked against each platform's current official terms before recommending it.
const INCOME_PLATFORMS = [
  {id:1,name:'Fiverr',category:'freelance',startCost:'zero-cost profile; optional paid extras ignored',gate:'verify Sudan signup, identity and payout'},
  {id:2,name:'Upwork',category:'freelance',startCost:'free profile; proposal credits may limit zero-budget use',gate:'verify Sudan eligibility, connects and payout'},
  {id:3,name:'مستقل',category:'freelance',startCost:'free profile',gate:'verify country and withdrawal method'},
  {id:4,name:'خمسات',category:'freelance',startCost:'free profile',gate:'verify country and withdrawal method'},
  {id:5,name:'Freelancer',category:'freelance',startCost:'free tier may be limited',gate:'verify bids, fees and payout'},
  {id:6,name:'PeoplePerHour',category:'freelance',startCost:'free registration; proposal limits may apply',gate:'verify country, approval and payout'},
  {id:7,name:'LinkedIn',category:'client_acquisition',startCost:'free profile and organic outreach',gate:'no guaranteed clients; no bulk unsolicited messages'},
  {id:8,name:'Contra',category:'freelance',startCost:'free portfolio tier may be available',gate:'verify country, fees and payout'},
  {id:9,name:'Legiit',category:'freelance',startCost:'free profile',gate:'verify seller eligibility and payout'},
  {id:10,name:'Toptal',category:'freelance',startCost:'no assumed upfront spend',gate:'selective screening and proven skills required'},
  {id:11,name:'YouTube',category:'creator_monetization',startCost:'organic publishing possible',gate:'verify current YPP country eligibility and thresholds'},
  {id:12,name:'TikTok',category:'creator_monetization',startCost:'organic publishing possible',gate:'creator monetization varies by country/program; do not assume a follower threshold'},
  {id:13,name:'Instagram Reels',category:'creator_monetization',startCost:'organic publishing possible',gate:'monetization features and affiliate programs vary by country'},
  {id:14,name:'Medium',category:'creator_monetization',startCost:'writing can start free',gate:'Partner Program eligibility and payout country restrictions'},
  {id:15,name:'Substack',category:'newsletter',startCost:'free publication tier',gate:'paid subscriptions require supported payment processor/country'},
  {id:16,name:'beehiiv',category:'newsletter',startCost:'free tier limits apply',gate:'monetization tools may require plan, scale or eligibility'},
  {id:17,name:'Amazon KDP',category:'digital_products',startCost:'publishing can be free',gate:'identity, tax interview and supported royalty payment method'},
  {id:18,name:'Spotify for Podcasters',category:'podcast',startCost:'basic podcast publishing may be free',gate:'monetization availability varies by country and audience'},
  {id:19,name:'WordPress / Blogger',category:'publishing',startCost:'hosted free tier possible; avoid paid domains/hosting',gate:'AdSense eligibility and payment-country support must be checked'},
  {id:20,name:'Pinterest',category:'traffic',startCost:'organic pins possible',gate:'affiliate disclosure, destination rules and program eligibility'},
  {id:21,name:'Etsy',category:'digital_products',startCost:'not strictly zero-cost; listing fees may apply',gate:'seller-country and payout eligibility; exclude if any fee required'},
  {id:22,name:'Gumroad',category:'digital_products',startCost:'no assumed upfront subscription',gate:'country, payment processor and payout support'},
  {id:23,name:'Canva Creators',category:'digital_products',startCost:'application-based',gate:'program acceptance and payout eligibility'},
  {id:24,name:'Creative Market',category:'digital_products',startCost:'portfolio required',gate:'shop approval, fees and payout support'},
  {id:25,name:'Envato',category:'digital_products',startCost:'quality portfolio required',gate:'author acceptance, fees and payout support'},
  {id:26,name:'Payhip',category:'digital_products',startCost:'free tier may be available',gate:'payment gateway availability in seller country'},
  {id:27,name:'Udemy',category:'courses',startCost:'course creation can be free',gate:'instructor payment method and country support'},
  {id:28,name:'PromptBase',category:'digital_products',startCost:'product listing rules apply',gate:'fees, originality and payout support'},
  {id:29,name:'Adobe Stock',category:'stock_media',startCost:'contributor submission',gate:'AI-generated content labeling, review and payout eligibility'},
  {id:30,name:'Shutterstock Contributor',category:'stock_media',startCost:'contributor submission',gate:'AI-content rules, acceptance and payout eligibility'},
  {id:31,name:'Shopify',category:'ecommerce',startCost:'not zero-cost long term; paid plan likely',gate:'deprioritize under $0 budget unless verified free trial is sufficient without charge'},
  {id:32,name:'Printful / Printify',category:'print_on_demand',startCost:'production, marketplace or store costs may apply',gate:'confirm no upfront cost and payment coverage before use'},
  {id:33,name:'Redbubble',category:'print_on_demand',startCost:'uploading may be free',gate:'account fees, country and payout policies'},
  {id:34,name:'Amazon Merch on Demand',category:'print_on_demand',startCost:'application-based',gate:'acceptance, tax and payment eligibility'},
  {id:35,name:'Salla / Zid',category:'ecommerce',startCost:'plans and merchant requirements vary',gate:'country, commercial registration and payment gateway'},
  {id:36,name:'Amazon Associates',category:'affiliate',startCost:'content/traffic required',gate:'program country, website and payout eligibility; disclose links'},
  {id:37,name:'ClickBank',category:'affiliate',startCost:'traffic required',gate:'account approval, compliance and payout-country support'},
  {id:38,name:'Outlier',category:'ai_tasks',startCost:'no paid access assumed',gate:'country openings, skills assessment and payout support'},
  {id:39,name:'DataAnnotation',category:'ai_tasks',startCost:'no paid access assumed',gate:'country eligibility and task availability; do not use VPN/misrepresent location'},
  {id:40,name:'Appen',category:'ai_tasks',startCost:'no paid access assumed',gate:'current project availability and payment method'},
  {id:41,name:'Toloka',category:'microtasks',startCost:'no paid access assumed',gate:'task availability, minimum withdrawal and country payout'},
  {id:42,name:'Prolific',category:'research_tasks',startCost:'no paid access assumed',gate:'supported participant countries and payout eligibility'},
  {id:43,name:'UserTesting',category:'testing',startCost:'no paid access assumed',gate:'country, language, device and payment method'},
  {id:44,name:'Test IO',category:'testing',startCost:'no paid access assumed',gate:'tester country, skill requirements and payout'},
  {id:45,name:'Flippa',category:'asset_marketplace',startCost:'not a first choice without an asset',gate:'listing/transaction fees and proof of asset ownership'},
  {id:46,name:'Chrome Web Store',category:'software',startCost:'developer registration fee may apply',gate:'not zero-cost if registration fee is required'},
  {id:47,name:'Telegram bots',category:'software',startCost:'can prototype locally/free tiers',gate:'hosting, API and payment costs; validate a buyer first'},
  {id:48,name:'n8n / Make',category:'automation_services',startCost:'free tier or self-hosting may be possible',gate:'hosting, task limits and license terms; sell implementation not unauthorized hosted access'},
  {id:49,name:'RapidAPI / Apify',category:'software',startCost:'free tier limits vary',gate:'platform fees, usage costs, terms and payout support'},
  {id:50,name:'Product Hunt / AppSumo',category:'product_launch',startCost:'launching may be free; selling has conditions',gate:'ready product, launch acceptance, commercial and payout eligibility'},
];

function formatIncomePlatformCatalog() {
  return INCOME_PLATFORMS.map((p) => p.id + '. ' + p.name + ' [' + p.category + '] — start: ' + p.startCost + '; verify: ' + p.gate).join('\\n');
}

module.exports = {INCOME_PLATFORMS, formatIncomePlatformCatalog};
