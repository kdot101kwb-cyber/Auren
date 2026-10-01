const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const db = getFirestore();

function clean(value, max = 500) { return String(value || '').trim().slice(0, max); }
const EVENT_WEIGHTS = {impression:1, open:2, play:3, pause:0.5, complete:6, like:7, save:8, share:5, search:1};

function normalizePodcast(item) {
  return {
    id: clean(item?.id || item?.collectionId || item?.trackId, 120),
    name: clean(item?.name || item?.collectionName || item?.trackName, 180),
    artist: clean(item?.artist || item?.artistName, 180),
    description: clean(item?.description, 700),
    artworkUrl: clean(item?.artworkUrl || item?.artworkUrl600 || item?.artworkUrl100, 1000),
    feedUrl: clean(item?.feedUrl, 1000),
    genre: clean(item?.genre || item?.primaryGenreName, 100),
    genres: Array.isArray(item?.genres) ? item.genres.slice(0, 8).map((x) => clean(x, 80)) : [],
    country: clean(item?.country, 80),
    language: clean(item?.language, 40),
    url: clean(item?.url || item?.collectionViewUrl || item?.trackViewUrl, 1000),
  };
}

exports.recordAurenPodcastEvent = onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const event = clean(request.data?.event, 30).toLowerCase();
    if (!Object.prototype.hasOwnProperty.call(EVENT_WEIGHTS, event)) {
      throw new HttpsError('invalid-argument', 'Unsupported podcast event.');
    }
    const item = normalizePodcast(request.data?.item || {});
    if (!item.id && !item.name) throw new HttpsError('invalid-argument', 'Podcast identity is required.');
    const itemId = item.id || item.name.toLowerCase().replace(/[^a-z0-9_-]+/g, '_').slice(0,120);
    const ref = db.collection('users').doc(uid).collection('podcastInteractions').doc(itemId);
    const eventRef = ref.collection('events').doc();
    await db.runTransaction(async (tx) => {
      tx.set(ref, {
        ...item,
        eventCount: {[event]: FieldValue.increment(1)},
        score: FieldValue.increment(EVENT_WEIGHTS[event]),
        lastEventAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge:true});
      tx.set(eventRef, {event, weight:EVENT_WEIGHTS[event], itemId, createdAt:FieldValue.serverTimestamp()});
    });
    return {status:'ok'};
  }
);

exports.getAurenPodcastPersonalizedFeed = onCall(
  {region:'us-central1', timeoutSeconds:35, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const limit = Math.min(Math.max(Number(request.data?.limit || 12), 4), 24);
    const snap = await db.collection('users').doc(uid).collection('podcastInteractions').orderBy('score','desc').limit(30).get();
    const history = snap.docs.map((doc) => ({id:doc.id, ...doc.data()}));
    if (!history.length) return {status:'cold_start', forYou:[], becauseYouListened:[], explore:[], trending:[], newForYou:[], interests:[]};

    const genreScores = new Map();
    const interestScores = new Map();
    for (const item of history) {
      const weight = Math.max(1, Number(item.score || 1));
      for (const genre of [item.genre, ...(Array.isArray(item.genres) ? item.genres : [])]) {
        const key = clean(genre,80).toLowerCase();
        if (key) genreScores.set(key,(genreScores.get(key)||0)+weight);
      }
      for (const token of (String(item.name||'')+' '+String(item.artist||'')+' '+String(item.description||'')).toLowerCase().split(/[^\p{L}\p{N}]+/u)) {
        if (token.length >= 5) interestScores.set(token,(interestScores.get(token)||0)+weight);
      }
    }
    const topGenres = [...genreScores.entries()].sort((a,b)=>b[1]-a[1]).slice(0,3).map(([x])=>x);
    const topWords = [...interestScores.entries()].sort((a,b)=>b[1]-a[1]).slice(0,8).map(([x])=>x);
    const source = history.map(normalizePodcast);
    const existing = new Set(history.map((x)=>x.id));
    let candidates = [];
    let trending = [];
    try {
      const terms = [...topGenres,...topWords.slice(0,3)].filter(Boolean).slice(0,5);
      for (const term of terms) {
        const response = await fetch('https://itunes.apple.com/search?media=podcast&entity=podcast&limit=20&country=US&term='+encodeURIComponent(term), {headers:{'user-agent':'AUREN-Podcast-Personalization/1.0'}});
        if (!response.ok) continue;
        const data = await response.json().catch(()=>({}));
        if (Array.isArray(data?.results)) candidates.push(...data.results.map(normalizePodcast));
      }
    } catch (_) {}

    // Lightweight global discovery: Apple Podcasts charts provide a public, non-personalized trending pool.
    try {
      const countries = ['us','gb','ae','eg','sa'];
      const chartResponses = await Promise.all(countries.map(async (country) => {
        const response = await fetch('https://itunes.apple.com/'+country+'/rss/toppodcasts/limit=50/podcast.json', {headers:{'user-agent':'AUREN-Podcast-Personalization/1.0'}});
        if (!response.ok) return [];
        const data = await response.json().catch(()=>({}));
        return Array.isArray(data?.feed?.entry) ? data.feed.entry.map((entry)=>normalizePodcast({
          id:entry?.id?.attributes?.['im:id'], name:entry?.['im:name']?.label, artist:entry?.['im:artist']?.label,
          artworkUrl:Array.isArray(entry?.['im:image']) ? entry['im:image'].at(-1)?.label : '',
          genre:entry?.category?.attributes?.label, url:entry?.link?.attributes?.href, country:country.toUpperCase()
        })) : [];
      }));
      trending = chartResponses.flat();
    } catch (_) {}

    const seen = new Set();
    const scored = candidates.filter((item)=>item.id&&!existing.has(item.id)&&!seen.has(item.id)&&seen.add(item.id)).map((item)=>{
      const hay = [item.name,item.artist,item.description,item.genre,...(item.genres||[])].join(' ').toLowerCase();
      let score = 0;
      const matches = [];
      for (const genre of topGenres) if (hay.includes(genre)) {score += 8; matches.push(genre);}
      for (const word of topWords) if (hay.includes(word)) {score += 2; if (matches.length<5) matches.push(word);}
      return {...item, personalizationScore:score, matchedInterests:[...new Set(matches)].slice(0,5)};
    }).sort((a,b)=>b.personalizationScore-a.personalizationScore||a.name.localeCompare(b.name));

    const trendingSeen = new Set();
    const trendingClean = trending
      .filter((item)=>item.id&&!existing.has(item.id)&&!trendingSeen.has(item.id)&&trendingSeen.add(item.id))
      .slice(0, Math.max(limit, 12));

    return {
      status:'ok',
      forYou:scored.slice(0,limit),
      becauseYouListened:source.slice(0,Math.min(8,limit)).map((item)=>({...item,reason:'بناءً على استماعك'})),
      explore:scored.slice(limit,limit*2),
      trending:trendingClean,
      newForYou:scored.slice(0,limit),
      interests:topGenres,
    };
  }
);
