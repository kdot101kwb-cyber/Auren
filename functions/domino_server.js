const crypto = require('crypto');

function deck() {
  const d = [];
  for (let a = 0; a <= 6; a++) for (let b = a; b <= 6; b++) d.push(a + '|' + b);
  for (let i = d.length - 1; i > 0; i--) {
    const j = crypto.randomInt(i + 1);
    [d[i], d[j]] = [d[j], d[i]];
  }
  return d;
}
function vals(piece) {
  const p = String(piece).split('|').map(Number);
  if (p.length !== 2 || p.some(n => !Number.isInteger(n) || n < 0 || n > 6)) throw new Error('Invalid domino.');
  return p;
}
function legal(piece, left, right) {
  const [a,b] = vals(piece);
  return a === left || b === left || a === right || b === right;
}
function place(board, piece, left, right) {
  const [a,b] = vals(piece);
  if (a === left) return {board:[piece,...board],left:b,right};
  if (b === left) return {board:[piece,...board],left:a,right};
  if (a === right) return {board:[...board,piece],left,right:b};
  if (b === right) return {board:[...board,piece],left,right:a};
  throw new Error('Illegal domino move.');
}
function initialDomino(hostId, guestId) {
  const d = deck(), host = d.splice(0,7), guest = d.splice(0,7), first = d.pop();
  const [left,right] = vals(first);
  return {gameIndex:51,dominoHostId:hostId,dominoGuestId:guestId,
    dominoHands:{[hostId]:host,[guestId]:guest},dominoPool:d,dominoBoard:[first],
    dominoLeft:left,dominoRight:right,dominoPasses:0,dominoWinnerId:null,
    matchFinished:false,score:0,round:0,message:'🁫 Dominoes جاهزة — دور اللاعب الأول'};
}
function applyDomino(input, action, uid) {
  const s = JSON.parse(JSON.stringify(input || {}));
  const players=[s.dominoHostId,s.dominoGuestId];
  if (!players.includes(uid)) throw new Error('Not a Domino player.');
  if (s.matchFinished) throw new Error('Match is finished.');
  const hand=s.dominoHands?.[uid], other=players.find(p=>p!==uid);
  if (!Array.isArray(hand)) throw new Error('Player hand missing.');
  if (action?.type === 'draw') {
    if (hand.some(p=>legal(p,s.dominoLeft,s.dominoRight))) throw new Error('You have a legal piece.');
    if (s.dominoPool.length) { hand.push(s.dominoPool.pop()); s.message='🁫 سحبت قطعة — دورك'; s.nextTurnPlayerId=uid; return s; }
    s.dominoPasses=(s.dominoPasses||0)+1;
    if (s.dominoPasses >= 2) { s.matchFinished=true; s.message='⏭️ لا توجد حركات — تعادل'; s.nextTurnPlayerId=null; }
    else { s.message='⏭️ مرّرت الدور'; s.nextTurnPlayerId=other; }
    return s;
  }
  if (action?.type === 'play') {
    const i=Number(action.pieceIndex);
    if (!Number.isInteger(i) || i<0 || i>=hand.length) throw new Error('Invalid domino piece.');
    const piece=hand[i];
    if (!legal(piece,s.dominoLeft,s.dominoRight)) throw new Error('Illegal domino move.');
    const p=place(s.dominoBoard,piece,s.dominoLeft,s.dominoRight);
    s.dominoBoard=p.board; s.dominoLeft=p.left; s.dominoRight=p.right; hand.splice(i,1);
    s.dominoPasses=0; s.round=(s.round||0)+1;
    if (!hand.length) { s.matchFinished=true; s.dominoWinnerId=uid; s.score=(s.score||0)+200; s.message='🏆 فوز Dominoes!'; s.nextTurnPlayerId=null; return s; }
    s.message='🁫 تم لعب '+piece+' — دور الخصم'; s.nextTurnPlayerId=other; return s;
  }
  throw new Error('Unsupported Domino action.');
}
module.exports={initialDomino,applyDomino};
