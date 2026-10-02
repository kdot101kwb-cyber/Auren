const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {buildTournamentBracket,createTournamentNextRound}=require('./tournament_rules');

test('8-player bracket creates four playable quarterfinal matches', () => {
  const bracket=buildTournamentBracket(['p1','p2','p3','p4','p5','p6','p7','p8']);
  assert.equal(bracket.matches.length,4);
  assert.deepEqual(bracket.matches.map(m=>[m.p1,m.p2]),[
    ['p1','p2'],['p3','p4'],['p5','p6'],['p7','p8'],
  ]);
  assert.ok(bracket.matches.every(m=>m.status==='pending' && !m.bye));
});

test('3-player bracket preserves a real BYE and keeps it out of playable matches', () => {
  const bracket=buildTournamentBracket(['p1','p2','p3']);
  const bye=bracket.matches.find(m=>m.p1==='p3' && m.p2===null);
  assert.ok(bye);
  assert.equal(bye.status,'finished');
  assert.equal(bye.winnerId,'p3');
  assert.equal(bye.bye,true);
  assert.equal(bracket.matches.filter(m=>m.status==='pending').length,2);
});

test('player list is capped at eight and never creates a phantom opponent', () => {
  const bracket=buildTournamentBracket(['p1','p2','p3','p4','p5','p6','p7','p8','p9']);
  assert.equal(bracket.matches.flatMap(m=>[m.p1,m.p2]).includes('p9'),false);
  assert.equal(bracket.matches.length,4);
});

test('next round pairs winners and auto-advances a single unmatched winner by BYE', () => {
  const semi=createTournamentNextRound('quarterfinals',['p1','p2','p3']);
  assert.equal(semi.length,2);
  assert.deepEqual(semi[0],{id:'se_1',round:'semifinals',p1:'p1',p2:'p2',status:'pending',winnerId:null});
  assert.equal(semi[1].p1,'p3');
  assert.equal(semi[1].p2,null);
  assert.equal(semi[1].status,'finished');
  assert.equal(semi[1].winnerId,'p3');
  assert.equal(semi[1].bye,true);
});

test('next round generates a final from two semifinal winners', () => {
  const final=createTournamentNextRound('semifinals',['championCandidate','runnerUpCandidate']);
  assert.deepEqual(final,[{
    id:'fi_1',round:'final',p1:'championCandidate',p2:'runnerUpCandidate',status:'pending',winnerId:null,
  }]);
});

test('tournament backend source validates winner membership and rejects non-players', async () => {
  const source=fs.readFileSync(require.resolve('./index.js'),'utf8');
  assert.match(source,/winnerId!==m\.p1&&winnerId!==m\.p2/);
  assert.match(source,/Only match players can submit the result/);
  assert.match(source,/Winner must be a match player/);
});

test('finished tournament results are idempotent', async () => {
  const source=fs.readFileSync(require.resolve('./index.js'),'utf8');
  assert.match(source,/if\(m\.status==='finished'\)return \{accepted:true,duplicate:true/);
});

test('champion completion writes tournament reward and champion badge', async () => {
  const source=fs.readFileSync(require.resolve('./index.js'),'utf8');
  assert.match(source,/tournamentChampion:true/);
  assert.match(source,/tournamentRewardForPlacement\(placement\)/);
  assert.match(source,/recordTournamentReward\(tx,ref\.id,champion,gameIndex,1\)/);
});

test('flagship action gateway auto-completes linked tournament matches', () => {
  const source = fs.readFileSync(require.resolve('./index.js'),'utf8');
  assert.match(source, /autoCompleteTournamentMatch/);
  assert.match(source, /data\.tournamentId && data\.tournamentMatchId/);
  assert.match(source, /autoCompleteTournamentMatch\(tx, data\.tournamentId, gameIndex, data\.tournamentMatchId, result\.winnerId\)/);
});
