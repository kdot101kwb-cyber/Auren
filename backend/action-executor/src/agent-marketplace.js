export const AGENT_LISTING_STATES=Object.freeze(['draft','published','paused','revoked']);
export const PRICING_MODELS=Object.freeze(['free','per_action','subscription']);
export function normalizeListing(input,agent){
  const capabilities=Array.isArray(input?.capabilities)?[...new Set(input.capabilities.filter(v=>typeof v==='string'))].slice(0,50):[];
  return {agentId:agent.agentId,name:String(input?.name||agent.name).trim().slice(0,120),description:String(input?.description||'').trim().slice(0,1000),capabilities,version:String(input?.version||agent.version).slice(0,30),state:AGENT_LISTING_STATES.includes(input?.state)?input.state:'draft',pricing:{model:PRICING_MODELS.includes(input?.pricing?.model)?input.pricing.model:'free',currency:typeof input?.pricing?.currency==='string'?input.pricing.currency.slice(0,3).toUpperCase():'USD',amountMinor:Number.isInteger(input?.pricing?.amountMinor)?Math.max(0,input.pricing.amountMinor):0}};
}
export function validateListingForPublish(listing){if(!listing||!listing.name||!listing.version)return false;if(!AGENT_LISTING_STATES.includes(listing.state))return false;if(!PRICING_MODELS.includes(listing.pricing?.model))return false;if(listing.pricing?.amountMinor<0)return false;return true;}
export function listingVersionKey(agentId,version){return `${agentId}@${version}`;}
