const crypto = require('crypto');

const COLORS=['R','B','G','Y'];
function makeDeck(){
  const d=[];
  for(const c of COLORS) for(let n=0;n<=9;n++) d.push(c+n);
  for(const c of COLORS) for(const x of ['+2','+2','S','S','R','R']) d.push(c+x);
  d.push('W','W','W+4','W+4');
  for(let i=d.length-1;i>0;i--){const j=crypto.randomInt(i+1);[d[i],d[j]]=[d[j],d[i]];}
  return d;
}
const color=c=>c.startsWith('W')?'W':c[0];
const rank=c=>c.startsWith('W')?c:c.slice(1);
function playable(c,current,top){return color(c)===current||rank(c)===rank(top)||c.startsWith('W');}
function initialUno(hostId,guestId){
  const d=makeDeck(),host=d.splice(0,7),guest=d.splice(0,7); let top=d.pop();
  while(top.startsWith('W+4')){d.unshift(top);top=d.pop();}
  return {gameIndex:52,unoHostId:hostId,unoGuestId:guestId,unoHands:{[hostId]:host,[guestId]:guest},
    unoDeck:d,unoDiscard:[top],unoColor:color(top),unoPendingDraw:0,unoSkipNext:false,
    unoWinnerId:null,matchFinished:false,score:0,round:0,message:'🃏 UNO جاهزة — دور اللاعب الأول'};
}
function applyUno(input,action,uid){
  const s=JSON.parse(JSON.stringify(input||{})), players=[s.unoHostId,s.unoGuestId];
  if(!players.includes(uid)||s.matchFinished) throw new Error('Invalid UNO match.');
  const hand=s.unoHands?.[uid], other=players.find(p=>p!==uid);
  if(!Array.isArray(hand)) throw new Error('UNO hand missing.');
  const type=String(action?.type||''), top=s.unoDiscard[s.unoDiscard.length-1];
  if(type==='draw'){
    const count=s.unoPendingDraw>0?s.unoPendingDraw:1;
    if(s.unoPendingDraw>0){
      if(s.unoDeck.length<count) throw new Error('Not enough cards to draw penalty.');
      for(let i=0;i<count;i++) hand.push(s.unoDeck.pop());
      s.unoPendingDraw=0;s.unoSkipNext=false;s.nextTurnPlayerId=other;s.message='🃏 تم سحب العقوبة — دور الخصم';return s;
    }
    if(!s.unoDeck.length) throw new Error('UNO deck is empty.');
    hand.push(s.unoDeck.pop());s.message='🃏 تم سحب بطاقة — دورك';s.nextTurnPlayerId=uid;return s;
  }
  if(type==='play'){
    const card=String(action?.card||''),i=hand.indexOf(card);
    if(i<0) throw new Error('Card is not in your hand.');
    if(!playable(card,s.unoColor,top)) throw new Error('Card is not playable.');
    if(card==='W+4' && hand.some(c=>color(c)===s.unoColor && !c.startsWith('W'))) throw new Error('Wild +4 is not allowed while a color card is playable.');
    hand.splice(i,1);s.unoDiscard.push(card);s.unoColor=card.startsWith('W')?(COLORS[crypto.randomInt(4)]):color(card);
    const r=rank(card);s.round=(s.round||0)+1;s.score=(s.score||0)+25;
    if(!hand.length){s.matchFinished=true;s.unoWinnerId=uid;s.score+=300;s.message='🏆 فوز UNO!';s.nextTurnPlayerId=null;return s;}
    s.unoPendingDraw=r==='+2'?2:r==='W+4'?4:0;s.unoSkipNext=(r==='S'||r==='R');
    if(s.unoPendingDraw>0||s.unoSkipNext){s.nextTurnPlayerId=other;}else{s.nextTurnPlayerId=other;}
    s.message='🃏 تم لعب '+card+' — دور الخصم';return s;
  }
  throw new Error('Unsupported UNO action.');
}
module.exports={initialUno,applyUno};
