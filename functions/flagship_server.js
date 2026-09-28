
const crypto = require('crypto');

const GAME_NAMES = {
  53: 'Crime Files',
  54: 'Football Pro',
  55: 'Basketball Pro',
  56: 'Boxing Champion',
  57: 'Ancient & Modern Wars',
  58: 'Samurai Legacy',
  59: 'Street Racing',
};

function rand(max) {
  return crypto.randomInt(0, max);
}

function cleanText(value, max = 180) {
  return String(value || '').slice(0, max);
}

function createInitialFlagshipState(gameIndex, hostId, guestId) {
  if (!GAME_NAMES[gameIndex]) throw new Error('Unsupported flagship game.');
  const players = [String(hostId), String(guestId || '')].filter(Boolean);
  return {
    gameIndex,
    players,
    score: 0,
    round: 0,
    hp: 100,
    streak: 0,
    energy: 100,
    distance: 0,
    wins: 0,
    message: 'ابدأ الجولة',
    matchFinished: false,
    crimeCase: 1,
    crimePhase: 0,
    crimeEvidence: 0,
    crimeScore: 0,
    crimeCollected: [],
    crimeSuspect: '',
  };
}

function requireInteger(value, min, max, name) {
  if (!Number.isInteger(value) || value < min || value > max) {
    throw new Error('Invalid ' + name + '.');
  }
  return value;
}

function validateAndApplyFlagshipAction(input, action, uid) {
  const state = JSON.parse(JSON.stringify(input || {}));
  const gameIndex = Number(state.gameIndex);
  if (!GAME_NAMES[gameIndex]) throw new Error('Unsupported flagship game.');
  if (!action || typeof action !== 'object' || Array.isArray(action)) {
    throw new Error('Invalid flagship action.');
  }

  const players = Array.isArray(state.players) ? state.players.map(String) : [];
  if (!players.includes(String(uid))) throw new Error('Player is not in this match.');

  const type = String(action.type || '');
  const payload = action.payload && typeof action.payload === 'object' ? action.payload : {};
  const allowed = {
    53: ['advance_case'],
    54: ['shoot'],
    55: ['shot'],
    56: ['boxing'],
    57: ['mission'],
    58: ['samurai'],
    59: ['steer'],
  };
  if (!allowed[gameIndex].includes(type)) throw new Error('Action is not allowed for this game.');

  if (gameIndex === 53) {
    const clues = [
      'بصمة على مقبض الباب',
      'كاميرا توقفت عند 03:12',
      'إيصال من متجر قريب',
      'رسالة مشفرة في الهاتف',
      'رقم لوحة ظهر في الشارع',
      'بصمة رقمية تربط الحساب بالموقع',
    ];
    const suspects = ['آدم', 'ليان', 'سامي'];
    const collected = Array.isArray(state.crimeCollected) ? state.crimeCollected.map(String) : [];
    let phase = Number(state.crimePhase) || 0;
    let evidence = Number(state.crimeEvidence) || 0;
    let crimeScore = Number(state.crimeScore) || 0;
    let score = Number(state.score) || 0;
    let hp = Number(state.hp) || 100;
    let message = '';

    if (phase === 0) {
      phase = 1;
      message = '🕵️ وصلت لمسرح الجريمة — ابحث عن الأدلة';
    } else if (phase === 1) {
      const available = clues.filter((c) => !collected.includes(c));
      if (available.length) {
        const clue = available[rand(available.length)];
        collected.push(clue);
        evidence += 1;
        crimeScore += 15;
        score += 18;
        message = '🔎 دليل: ' + clue;
        if (evidence >= 5) {
          phase = 2;
          message += ' • الأدلة الأساسية اكتملت';
        }
      }
    } else if (phase === 2) {
      const suspect = suspects[rand(suspects.length)];
      state.crimeSuspect = suspect;
      phase = 3;
      message = '🧠 التحليل يقترح مشتبهًا: ' + suspect + ' • راجع الأدلة';
    } else if (phase === 3) {
      const correct = String(state.crimeSuspect || '') === 'سامي';
      if (correct) {
        crimeScore += 150;
        score += 200;
        phase = 4;
        message = '🏆 أغلقت القضية بنجاح';
      } else {
        hp = Math.max(1, hp - 15);
        phase = 4;
        message = '⚠️ الاتهام لم يتطابق مع الأدلة';
      }
    } else {
      state.crimeCase = (Number(state.crimeCase) || 1) + 1;
      phase = 0;
      evidence = 0;
      crimeScore = 0;
      collected.length = 0;
      state.crimeSuspect = '';
      message = '📁 بدأت قضية جديدة رقم ' + state.crimeCase;
    }

    state.crimePhase = phase;
    state.crimeEvidence = Math.min(5, evidence);
    state.crimeScore = Math.max(0, crimeScore);
    state.crimeCollected = collected.slice(0, 6);
    state.score = Math.max(0, score);
    state.hp = Math.max(0, Math.min(100, hp));
    state.round = (Number(state.round) || 0) + 1;
    state.message = cleanText(message);
  }

  if (gameIndex === 54) {
    const lane = requireInteger(Number(payload.lane), 0, 2, 'lane');
    const goal = rand(100) >= 48 + lane * 4;
    state.round = (Number(state.round) || 0) + 1;
    state.streak = goal ? (Number(state.streak) || 0) + 1 : 0;
    state.score = Math.max(0, Number(state.score) || 0) + (goal ? 30 : 5);
    state.message = goal ? '⚽ GOAL! تسديدة ناجحة من المسار ' + ['اليسار','الوسط','اليمين'][lane] : '🧤 الحارس تصدى للتسديدة';
  }

  if (gameIndex === 55) {
    const shot = requireInteger(Number(payload.shot), 0, 2, 'shot');
    const chance = shot === 1 ? 55 : 72;
    const made = rand(100) < chance;
    const points = made ? (shot === 1 ? 3 : 2) : 0;
    state.round = (Number(state.round) || 0) + 1;
    state.score = Math.max(0, Number(state.score) || 0) + points * 10;
    state.streak = made ? (Number(state.streak) || 0) + 1 : 0;
    state.message = made ? '🏀 رمية ناجحة: ' + points + ' نقاط' : '🏀 ضاعت الرمية';
  }

  if (gameIndex === 56) {
    const move = requireInteger(Number(payload.move), 0, 2, 'move');
    let energy = Number(state.energy) || 100;
    let hp = Number(state.hp) || 100;
    let score = Number(state.score) || 0;
    let streak = Number(state.streak) || 0;
    energy = move === 2 ? Math.min(100, energy + 12) : Math.max(0, energy - 15);
    let message;
    if (move === 2) {
      message = '🥊 مراوغة +12 طاقة';
    } else if (energy < 0) {
      message = '🥊 طاقة منخفضة';
    } else if (rand(100) > 42) {
      const damage = 8 + rand(13);
      score += damage * 2;
      streak += 1;
      message = '🥊 لكمة ناجحة • ضرر ' + damage;
    } else {
      const damage = 5 + rand(11);
      hp = Math.max(0, hp - damage);
      streak = 0;
      message = '🥊 الخصم ردّ • -' + damage + ' HP';
    }
    state.energy = energy;
    state.hp = hp;
    state.score = score;
    state.streak = streak;
    state.round = (Number(state.round) || 0) + 1;
    state.message = message;
  }

  if (gameIndex === 57) {
    requireInteger(Number(payload.mission), 0, 4, 'mission');
    const missions = ['أمّن نقطة الإمداد','احمِ القافلة','استعد الموقع','أنقذ الفريق','أكمل الانسحاب الآمن'];
    state.round = (Number(state.round) || 0) + 1;
    state.score = Math.max(0, Number(state.score) || 0) + 22;
    state.streak = (Number(state.streak) || 0) + 1;
    state.message = '⚔️ المهمة ' + (((state.round - 1) % missions.length) + 1) + ': ' + missions[(state.round - 1) % missions.length];
  }

  if (gameIndex === 58) {
    const move = requireInteger(Number(payload.move), 0, 3, 'move');
    const names = ['سحب السيف','صدّ الضربة','خطوة جانبية','ضربة دقيقة'];
    const ok = rand(100) >= 25;
    state.round = (Number(state.round) || 0) + 1;
    if (ok) {
      state.score = Math.max(0, Number(state.score) || 0) + 25;
      state.streak = (Number(state.streak) || 0) + 1;
      state.message = '🥷 ' + names[move] + ' • ناجحة';
    } else {
      state.hp = Math.max(0, (Number(state.hp) || 100) - 8);
      state.streak = 0;
      state.message = '🥷 تم صدّ الهجمة • -8 HP';
    }
  }

  if (gameIndex === 59) {
    const lane = requireInteger(Number(payload.lane), 0, 2, 'lane');
    const speed = 60 + rand(41);
    const drift = rand(100) >= 35;
    state.distance = Math.max(0, Number(state.distance) || 0) + (lane === 1 ? 8 : 5) + Math.floor(speed / 4);
    state.energy = Math.max(0, (Number(state.energy) || 100) - (drift ? 8 : 4));
    state.round = (Number(state.round) || 0) + 1;
    state.score = Math.max(0, Number(state.score) || 0) + (drift ? 25 : 10);
    state.streak = drift ? (Number(state.streak) || 0) + 1 : 0;
    state.message = '🏎️ سرعة ' + speed + ' km/h • ' + (drift ? 'انجراف مضبوط' : 'حافظ على المسار');
  }

  state.gameIndex = gameIndex;
  // Online matches have a server-defined endpoint; the client cannot extend the match indefinitely.
  state.matchFinished = state.hp <= 0 || (Number(state.round) || 0) >= 20;
  if (state.matchFinished) state.message = cleanText(state.message + ' • انتهت المباراة');
  return state;
}

module.exports = { createInitialFlagshipState, validateAndApplyFlagshipAction };
