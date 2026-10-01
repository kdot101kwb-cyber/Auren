function buildTournamentBracket(players) {
  const p=[...players].slice(0,8);
  // Only create playable quarterfinal slots for actual participants; preserve a single BYE for an odd final pairing.\n  // Do not pad to eight, which creates phantom BYE matches for missing players.
  const makeMatch=(id,round,p1,p2)=>{
    if(p1 && !p2)return {id,round,p1,p2:null,status:'finished',winnerId:p1,bye:true};
    return {id,round,p1:p1||null,p2:p2||null,status:'pending',winnerId:null};
  };
  return {round:'quarterfinals',matches:[
    makeMatch('qf1','quarterfinals',p[0],p[1]),
    makeMatch('qf2','quarterfinals',p[2],p[3]),
    makeMatch('qf3','quarterfinals',p[4],p[5]),
    makeMatch('qf4','quarterfinals',p[6],p[7]),
  ]};
}

function createTournamentNextRound(round, winners) {
  const nextRound=round==='quarterfinals'?'semifinals':'final';
  const generated=[];
  for(let i=0;i<winners.length;i+=2) {
    const p1=winners[i]||null, p2=winners[i+1]||null;
    generated.push({
      id:nextRound.slice(0,2)+'_'+(i/2+1),
      round:nextRound,
      p1,
      p2,
      status:p1&&!p2?'finished':'pending',
      winnerId:p1&&!p2?p1:null,
      ...(p1&&!p2?{bye:true}:{}),
    });
  }
  return generated;
}

module.exports={buildTournamentBracket,createTournamentNextRound};
