export async function loadTrust(db,agentId){const s=await db.collection('agent_trust').doc(agentId).get();if(!s.exists)return{score:100,completed:0,disputes:0,failures:0};return s.data();}
export function assertTrust(trust,minScore=0){if((trust.score||0)<minScore)throw Object.assign(new Error('Agent trust requirement not met.'),{code:403});}
