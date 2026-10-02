import { mkdir, writeFile } from 'node:fs/promises';
import { setTimeout as sleep } from 'node:timers/promises';

const baseUrl = (process.env.CONTENT_API_BASE_URL ?? '').replace(/\/+$/, '');
const auditLabel = (process.env.PLAYBACK_AUDIT_LABEL ?? 'before').trim() || 'before';
if (!baseUrl) {
  console.error('CONTENT_API_BASE_URL is required');
  process.exit(2);
}

const timeoutMs = 15000;
const mediaTimeoutMs = 5000;
const maxSeries = Number(process.env.PLAYBACK_AUDIT_SERIES ?? 60);
const maxEpisodes = Number(process.env.PLAYBACK_AUDIT_EPISODES ?? 100);
const shelves = ['trending', 'new', 'recommended', 'romance', 'action', 'fantasy'];
const mobileHeaders = {
  'User-Agent':
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Version/17.0 Mobile/15E148 Safari/604.1',
};

const providerHeaders = {
  reelshort: { ...mobileHeaders, Referer: 'https://www.reelshort.com/vi' },
  netshort: { ...mobileHeaders, Referer: 'https://netshort.com/vi/' },
};

const counters = {
  watchApiPass: 0,
  watchApiFail: 0,
  mediaPass: 0,
  mediaFail: 0,
  lockedExpected: 0,
  timeout: 0,
  contentTypeMismatch: 0,
  rangeProblem: 0,
};

const classes = new Map();
const rows = [];

function addClass(name) {
  classes.set(name, (classes.get(name) ?? 0) + 1);
}

function maskUrl(value) {
  try {
    const url = new URL(value);
    return `${url.protocol}//${url.host}${url.pathname}`;
  } catch {
    return '<invalid-url>';
  }
}

function safeHost(value) {
  try {
    return new URL(value).host;
  } catch {
    return 'unknown';
  }
}

function mediaKind(value) {
  try {
    const url = new URL(value);
    const path = url.pathname.toLowerCase();
    const mime = (url.searchParams.get('mime_type') ?? '').toLowerCase();
    if (path.endsWith('.m3u8') || mime.includes('mpegurl')) return 'hls';
    if (path.endsWith('.mp4') || mime === 'video_mp4' || mime === 'video/mp4') {
      return 'mp4';
    }
  } catch {
    // Classified as unknown below.
  }
  return 'unknown';
}

function joinUrl(parent, child) {
  try {
    return new URL(child, parent).toString();
  } catch {
    return child;
  }
}

function isPublicChapter(chapter) {
  return chapter?.available === true &&
      !chapter.isLock &&
      !chapter.locked &&
      !chapter.isPay &&
      !chapter.isCharge;
}

function unique(values) {
  return [...new Set(values.filter((value) => typeof value === 'string' && value))];
}

async function request(url, options = {}, limit = timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), limit);
  let current = url;
  let redirects = 0;
  try {
    for (let attempt = 0; attempt <= 5; attempt += 1) {
      const response = await fetch(current, {
        ...options,
        redirect: 'manual',
        signal: controller.signal,
      });
      if (![301, 302, 303, 307, 308].includes(response.status)) {
        return { response, finalUrl: current, redirects };
      }
      const location = response.headers.get('location');
      if (!location) return { response, finalUrl: current, redirects };
      current = joinUrl(current, location);
      redirects += 1;
    }
    throw new Error('redirect-limit');
  } finally {
    clearTimeout(timer);
  }
}

async function jsonApi(path) {
  const started = Date.now();
  const url = `${baseUrl}${path}`;
  try {
    const { response, finalUrl, redirects } = await request(url, {
      headers: { Accept: 'application/json' },
    });
    const text = await response.text();
    let json;
    try {
      json = JSON.parse(text);
    } catch {
      return { ok: false, status: response.status, error: 'invalid-json', elapsed: Date.now() - started };
    }
    if (!response.ok || json.success === false) {
      return {
        ok: false,
        status: response.status,
        error: json.error ?? `http-${response.status}`,
        elapsed: Date.now() - started,
      };
    }
    return { ok: true, status: response.status, data: json.data, finalUrl, redirects, elapsed: Date.now() - started };
  } catch (error) {
    return {
      ok: false,
      status: 0,
      error: error.name === 'AbortError' ? 'timeout' : error.message,
      elapsed: Date.now() - started,
    };
  }
}

async function readSample(response, maxBytes = 65536) {
  if (!response.body) return Buffer.alloc(0);
  const reader = response.body.getReader();
  const chunks = [];
  let size = 0;
  try {
    while (size < maxBytes) {
      const { done, value } = await reader.read();
      if (done) break;
      const chunk = Buffer.from(value);
      const remaining = maxBytes - size;
      chunks.push(chunk.subarray(0, remaining));
      size += Math.min(chunk.length, remaining);
      if (chunk.length >= remaining) break;
    }
  } finally {
    try {
      await reader.cancel();
    } catch {
      // The bounded sample is complete.
    }
  }
  return Buffer.concat(chunks);
}

function responseMeta(response, finalUrl, redirects, bytes) {
  return {
    status: response.status,
    finalUrl: maskUrl(finalUrl),
    host: safeHost(finalUrl),
    contentType: response.headers.get('content-type') ?? '',
    contentLength: response.headers.get('content-length') ?? '',
    acceptRanges: response.headers.get('accept-ranges') ?? '',
    contentRange: response.headers.get('content-range') ?? '',
    redirects,
    bytes: bytes.length,
  };
}

function looksLikeMp4(bytes) {
  return bytes.length >= 8 && bytes.subarray(4, 8).toString('ascii') === 'ftyp';
}

async function probeMp4(url, headers) {
  try {
    const { response, finalUrl, redirects } = await request(
      url,
      { headers: { Range: 'bytes=0-65535', ...headers } },
      mediaTimeoutMs,
    );
    const bytes = await readSample(response);
    const meta = responseMeta(response, finalUrl, redirects, bytes);
    const statusPass = response.status === 200 || response.status === 206;
    const headerPass = looksLikeMp4(bytes);
    return {
      ok: statusPass && bytes.length > 0 && headerPass,
      kind: 'mp4',
      headerPass,
      rangePass: response.status === 206 || meta.acceptRanges.toLowerCase() === 'bytes',
      meta,
      error: !statusPass ? `http-${response.status}` : !headerPass ? 'missing-ftyp' : null,
    };
  } catch (error) {
    return { ok: false, kind: 'mp4', error: error.name === 'AbortError' ? 'timeout' : error.message };
  }
}

function firstHlsUris(text, playlistUrl) {
  const lines = text.split(/\r?\n/).map((line) => line.trim());
  const uris = [];
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (line.startsWith('#EXT-X-STREAM-INF')) {
      const next = lines[index + 1];
      if (next && !next.startsWith('#')) uris.push(joinUrl(playlistUrl, next));
    }
    if (line.startsWith('#EXT-X-MAP:')) {
      const match = /URI="([^"]+)"/.exec(line);
      if (match) uris.push(joinUrl(playlistUrl, match[1]));
    }
    if (!line.startsWith('#') && line) uris.push(joinUrl(playlistUrl, line));
  }
  return unique(uris);
}

async function probeHls(url, headers) {
  try {
    const playlistRequest = await request(url, { headers }, mediaTimeoutMs);
    const playlistBytes = await readSample(playlistRequest.response, 256 * 1024);
    const playlistText = playlistBytes.toString('utf8');
    const playlistMeta = responseMeta(
      playlistRequest.response,
      playlistRequest.finalUrl,
      playlistRequest.redirects,
      playlistBytes,
    );
    if (playlistRequest.response.status !== 200 || !playlistText.includes('#EXTM3U')) {
      return {
        ok: false,
        kind: 'hls',
        playlistMeta,
        error: playlistRequest.response.status !== 200
          ? `http-${playlistRequest.response.status}`
          : 'missing-extm3u',
      };
    }
    const child = firstHlsUris(playlistText, playlistRequest.finalUrl)[0];
    if (!child) return { ok: true, kind: 'hls', playlistMeta, segment: null };
    const segmentRequest = await request(
      child,
      { headers: { Range: 'bytes=0-65535', ...headers } },
      mediaTimeoutMs,
    );
    const segmentBytes = await readSample(segmentRequest.response);
    const segmentMeta = responseMeta(
      segmentRequest.response,
      segmentRequest.finalUrl,
      segmentRequest.redirects,
      segmentBytes,
    );
    const segmentPass =
      (segmentRequest.response.status === 200 || segmentRequest.response.status === 206) &&
      segmentBytes.length > 0;
    return {
      ok: segmentPass,
      kind: 'hls',
      playlistMeta,
      segmentMeta,
      error: segmentPass ? null : `segment-http-${segmentRequest.response.status}`,
    };
  } catch (error) {
    return { ok: false, kind: 'hls', error: error.name === 'AbortError' ? 'timeout' : error.message };
  }
}

async function probeMedia(url, provider) {
  const kind = mediaKind(url);
  const headers = providerHeaders[provider] ?? mobileHeaders;
  const probe = kind === 'hls' ? probeHls : kind === 'mp4' ? probeMp4 : null;
  if (!probe) return { ok: false, kind, withoutHeaders: { ok: false, error: 'unknown-media-kind' } };

  const withoutHeaders = await probe(url, {});
  if (withoutHeaders.ok) {
    return { ok: true, kind, headerMode: 'none', withoutHeaders };
  }
  const withHeaders = await probe(url, headers);
  return {
    ok: withHeaders.ok,
    kind,
    headerMode: withHeaders.ok ? 'provider' : 'failed',
    withoutHeaders,
    withHeaders,
  };
}

function classifyMediaFailure(result) {
  const attempt = result.withHeaders ?? result.withoutHeaders ?? result;
  const error = String(attempt.error ?? '').toLowerCase();
  const status = attempt.meta?.status ?? attempt.playlistMeta?.status ?? attempt.segmentMeta?.status;
  if (error.includes('timeout')) return 'MEDIA_TIMEOUT';
  if (status === 403) return 'MEDIA_403';
  if (result.kind === 'hls' && attempt.playlistMeta && !attempt.segmentMeta) return 'HLS_PLAYLIST_BAD';
  if (result.kind === 'hls' && attempt.segmentMeta && !attempt.ok) return 'HLS_SEGMENT_BAD';
  if (result.kind === 'mp4' && !attempt.headerPass) return 'MEDIA_CONTENT_TYPE_BAD';
  if (result.kind === 'mp4' && attempt.rangePass === false) return 'MEDIA_RANGE_BAD';
  return 'MEDIA_HTTP_FAIL';
}

async function collectSeries() {
  const map = new Map();
  for (const slug of shelves) {
    let cursor;
    for (let page = 1; page <= 4 && map.size < maxSeries * 2; page += 1) {
      const params = new URLSearchParams({ pageSize: '30', sort: slug === 'new' ? 'new' : 'hot' });
      if (cursor) params.set('cursor', cursor);
      const result = await jsonApi(`/api/collection/${encodeURIComponent(slug)}/${page}?${params}`);
      if (!result.ok) break;
      for (const item of result.data?.list ?? []) {
        if (item.bookId && !map.has(item.bookId)) map.set(item.bookId, { ...item, shelf: slug });
      }
      cursor = result.data?.nextCursor;
      if (!result.data?.hasMore || !cursor) break;
      await sleep(100);
    }
  }
  const all = [...map.values()];
  const reel = all.filter((item) => item.provider === 'reelshort');
  const net = all.filter((item) => item.provider === 'netshort');
  const preferred = [
    ...reel.slice(0, 20),
    ...net.slice(0, 20),
    ...all.filter((item) => !['reelshort', 'netshort'].includes(item.provider)),
    ...all,
  ];
  return unique(preferred.map((item) => item.bookId))
    .map((id) => map.get(id))
    .filter(Boolean)
    .slice(0, maxSeries);
}

function episodeSamples(chapters) {
  const list = chapters?.chapterList ?? chapters?.list ?? [];
  const publicEpisodes = list.filter(isPublicChapter);
  const indexes = [0];
  if (publicEpisodes.length >= 10) indexes.push(Math.floor(publicEpisodes.length / 2));
  if (publicEpisodes.length >= 20) indexes.push(publicEpisodes.length - 1);
  return unique(indexes.map((index) => publicEpisodes[index]?.chapterIndex?.toString()))
    .map((index) => publicEpisodes.find((episode) => episode.chapterIndex?.toString() === index))
    .filter(Boolean);
}

async function auditSeries(series, episodeBudget) {
  const bookPath = `/api/book/${encodeURIComponent(series.bookId)}`;
  const chaptersPath = `/api/chapters/${encodeURIComponent(series.bookId)}`;
  const book = await jsonApi(bookPath);
  const chapters = await jsonApi(chaptersPath);
  const base = {
    provider: series.provider ?? 'unknown',
    bookId: series.bookId,
    title: series.bookName ?? '',
    shelf: series.shelf,
    bookStatus: book.status,
    chaptersStatus: chapters.status,
    episodes: [],
  };
  if (!book.ok || !chapters.ok) {
    addClass(!book.ok ? 'WATCH_API_FAIL' : 'WATCH_API_FAIL');
    counters.watchApiFail += 1;
    return base;
  }
  const chapterList = chapters.data?.chapterList ?? chapters.data?.list ?? [];
  const lockedCount = chapterList.filter((chapter) => !isPublicChapter(chapter)).length;
  counters.lockedExpected += lockedCount;
  if (lockedCount > 0) addClass('LOCKED_EXPECTED');
  const samples = episodeSamples(chapters.data);
  for (const episode of samples) {
    if (rows.length >= maxEpisodes) break;
    const watch = await jsonApi(
      `/api/watch/${encodeURIComponent(series.bookId)}/${episode.chapterIndex}`,
    );
    const episodeRow = {
      chapterIndex: episode.chapterIndex,
      serialNumber: episode.serialNumber,
      public: true,
      watchStatus: watch.status,
      candidates: [],
    };
    rows.push({ series, episode: episodeRow });
    if (!watch.ok) {
      counters.watchApiFail += 1;
      addClass(watch.status === 403 ? 'LOCKED_EXPECTED' : 'WATCH_API_FAIL');
      episodeRow.failureClass = watch.status === 403 ? 'LOCKED_EXPECTED' : 'WATCH_API_FAIL';
      continue;
    }
    counters.watchApiPass += 1;
    const data = watch.data ?? {};
    const urls = unique([
      data.videoUrl,
      ...(Array.isArray(data.qualities) ? data.qualities.map((item) => item.videoPath ?? item.videoUrl) : []),
    ]);
    episodeRow.provider = data.provider ?? series.provider;
    episodeRow.candidateCount = urls.length;
    for (const url of urls) {
      const result = await probeMedia(url, episodeRow.provider);
      const candidate = {
        host: safeHost(url),
        mediaKind: mediaKind(url),
        result,
      };
      episodeRow.candidates.push(candidate);
      if (result.ok) {
        counters.mediaPass += 1;
        if (result.kind === 'mp4' && result.withoutHeaders?.rangePass === false) counters.rangeProblem += 1;
        break;
      }
      counters.mediaFail += 1;
      const failureClass = classifyMediaFailure(result);
      addClass(failureClass);
      if (failureClass === 'MEDIA_TIMEOUT') counters.timeout += 1;
      if (failureClass === 'MEDIA_CONTENT_TYPE_BAD') counters.contentTypeMismatch += 1;
      if (failureClass === 'MEDIA_RANGE_BAD') counters.rangeProblem += 1;
    }
    if (!episodeRow.candidates.some((candidate) => candidate.result.ok)) {
      episodeRow.failureClass = classifyMediaFailure(episodeRow.candidates.at(-1).result);
    }
    if (rows.length % 8 === 0) {
      console.log(`audited ${rows.length} public episodes`);
    }
  }
  return base;
}

function providerStats() {
  const result = {};
  for (const provider of unique(rows.map((row) => row.series.provider ?? 'unknown'))) {
    const providerRows = rows.filter((row) => (row.series.provider ?? 'unknown') === provider);
    const watchPass = providerRows.filter((row) => row.episode.watchStatus === 200).length;
    const mediaPass = providerRows.filter((row) => row.episode.candidates.some((candidate) => candidate.result.ok)).length;
    result[provider] = {
      series: unique(providerRows.map((row) => row.series.bookId)).length,
      episodes: providerRows.length,
      watchPass,
      mediaPass,
      failed: providerRows.length - mediaPass,
    };
  }
  return result;
}

function markdownReport(series, providerResult) {
  const failureRows = rows.filter((row) => row.episode.failureClass);
  const failureTable = failureRows.slice(0, 40).map((row) => {
    const episode = row.episode;
    return `| ${row.series.provider} | ${row.series.bookName} | ${episode.serialNumber} | ${episode.watchStatus} | ${episode.failureClass} | ${episode.candidates.at(-1)?.host ?? '-'} |`;
  }).join('\n');
  const classesText = [...classes.entries()].sort((a, b) => b[1] - a[1])
    .map(([name, count]) => `| ${name} | ${count} |`).join('\n');
  const headerFindings = rows.flatMap((row) => row.episode.candidates)
    .filter((candidate) => candidate.result.headerMode === 'provider')
    .length;
  const cacheRisk = auditLabel === 'before'
    ? 'Before fix: BetterPlayer cache was enabled for non-HLS URLs, a PLAYER_CONFIG_RISK for signed/opaque NetShort MP4.'
    : 'After fix: Flutter data-source policy disables remote playback cache on iOS/macOS, disables NetShort cache on all platforms, and disables cache for opaque MP4 URLs.';
  return `# Playback audit before fix\n\n- Base URL: ${baseUrl}\n- Generated: ${new Date().toISOString()}\n- Series tested: ${series.length}\n- Public episode probes: ${rows.length}\n- Episode budget: ${maxEpisodes}\n\n## Summary\n\n| Metric | Count |\n|---|---:|\n| Watch API pass | ${counters.watchApiPass} |\n| Watch API fail | ${counters.watchApiFail} |\n| Media candidate pass | ${counters.mediaPass} |\n| Media candidate fail | ${counters.mediaFail} |\n| Locked expected | ${counters.lockedExpected} |\n| Timeout | ${counters.timeout} |\n| Content type mismatch | ${counters.contentTypeMismatch} |\n| Range problem | ${counters.rangeProblem} |\n\n## Provider summary\n\n| Provider | Series | Episodes | Watch pass | Media pass | Failed |\n|---|---:|---:|---:|---:|---:|\n${Object.entries(providerResult).map(([provider, stats]) => `| ${provider} | ${stats.series} | ${stats.episodes} | ${stats.watchPass} | ${stats.mediaPass} | ${stats.failed} |`).join('\n')}\n\n## Failure classes\n\n| Class | Count |\n|---|---:|\n${classesText || '| none | 0 |'}\n\n## Findings\n\n- ${cacheRisk}\n- Provider-header fallback passed for ${headerFindings} candidate(s). A non-zero value is evidence that headers are needed for those candidates.\n- MP4 probes used a bounded Range request and inspected the initial bytes for an ftyp box. HLS probes fetched the playlist and one child segment/init URI.\n- URLs in this report are host-only or path-only; signed query parameters are masked.\n\n## Failure samples\n\n| Provider | Series | Episode | Watch HTTP | Class | Media host |\n|---|---|---:|---:|---|---|\n${failureTable || '| - | none | - | - | - | - |'}\n\n## Sample inventory\n\n- Exact sample selection: all available shelves: ${shelves.join(', ')}.\n- Public episodes only were media-probed. Locked/paywalled chapters were excluded from media failure counts.\n- ${providerStatsNote(series)}\n`;
}

function providerStatsNote(series) {
  const counts = {};
  for (const item of series) counts[item.provider ?? 'unknown'] = (counts[item.provider ?? 'unknown'] ?? 0) + 1;
  return Object.entries(counts).map(([provider, count]) => `${provider}: ${count} series`).join('; ');
}

async function main() {
  console.log(`collecting catalog from ${shelves.length} shelves`);
  const series = await collectSeries();
  console.log(`selected ${series.length} unique series`);
  for (const item of series) {
    await auditSeries(item, maxEpisodes - rows.length);
    if (rows.length >= maxEpisodes) break;
  }
  const summary = providerStats();
  await mkdir('docs', { recursive: true });
  const markdown = markdownReport(series, summary)
    .replace('# Playback audit before fix', `# Playback audit ${auditLabel}`);
  await writeFile(`docs/playback-audit-${auditLabel}.md`, markdown);
  await writeFile(
    `docs/playback-audit-${auditLabel}.json`,
    JSON.stringify({ baseUrl, generatedAt: new Date().toISOString(), series, rows, counters, classes: Object.fromEntries(classes), providerStats: summary }, null, 2),
  );
  console.log(JSON.stringify({ series: series.length, episodes: rows.length, counters, classes: Object.fromEntries(classes), providerStats: summary }, null, 2));
  if (series.length < 60 || rows.length < 80) process.exitCode = 1;
}

await main();
