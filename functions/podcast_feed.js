const {onCall, HttpsError} = require('firebase-functions/v2/https');

function clean(value, max = 4000) {
  return String(value || '')
    .replace(/<!\[CDATA\[/g, '')
    .replace(/\]\]>/g, '')
    .replace(/<[^>]*>/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, max);
}

function tag(block, name) {
  const re = new RegExp('<' + name + '(?:\\s[^>]*)?>([\\s\\S]*?)<\\/' + name + '>', 'i');
  return clean(block.match(re)?.[1] || '');
}

function enclosure(block) {
  const m = block.match(/<enclosure\\b[^>]*?url=["']([^"']+)["'][^>]*>/i);
  return m?.[1] || '';
}

exports.fetchAurenPodcastFeed = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Authentication is required.');
    }

    const feedUrl = String(request.data?.feedUrl || '').trim();
    if (!feedUrl.startsWith('http://')&&!feedUrl.startsWith('https://') || feedUrl.length > 2000) {
      throw new HttpsError('invalid-argument', 'A valid HTTP(S) feedUrl is required.');
    }

    let parsed;
    try { parsed = new URL(feedUrl); } catch (_) {
      throw new HttpsError('invalid-argument', 'Invalid feed URL.');
    }
    if (!['http:', 'https:'].includes(parsed.protocol)) {
      throw new HttpsError('invalid-argument', 'Only HTTP(S) feeds are supported.');
    }

    const response = await fetch(parsed.toString(), {
      headers: {'user-agent': 'AUREN-Podcast-Reader/1.0', accept: 'application/rss+xml, application/atom+xml, text/xml'},
    });
    if (!response.ok) {
      throw new HttpsError('unavailable', 'Podcast feed is temporarily unavailable.');
    }
    const contentType = response.headers.get('content-type') || '';
    if (contentType && !/(xml|rss|atom|text\\/plain|application\\/octet-stream)/i.test(contentType)) {
      throw new HttpsError('invalid-argument', 'The URL does not appear to be an RSS or Atom feed.');
    }
    const xml = await response.text();
    if (xml.length > 2_000_000) {
      throw new HttpsError('resource-exhausted', 'Podcast feed is too large.');
    }

    const blocks = xml.match(/<item\\b[\\s\\S]*?<\\/item>/gi) || [];
    const episodes = blocks.slice(0, 30).map((block, index) => ({
      id: tag(block, 'guid') || tag(block, 'link') || String(index),
      title: tag(block, 'title') || 'Episode',
      description: tag(block, 'description') || tag(block, 'summary'),
      publishedAt: tag(block, 'pubDate') || tag(block, 'published'),
      audioUrl: enclosure(block),
      pageUrl: tag(block, 'link'),
      duration: tag(block, 'itunes:duration'),
      imageUrl: block.match(/<(?:itunes:image|image)\\b[^>]*?href=["']([^"']+)["'][^>]*>/i)?.[1] || '',
    })).filter((episode) => episode.audioUrl);

    return {status: 'ok', feedUrl: parsed.toString(), episodes};
  },
);
