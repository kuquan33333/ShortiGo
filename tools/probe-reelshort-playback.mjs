const baseUrl = (process.env.CONTENT_API_BASE_URL ?? '').replace(/\/$/, '');
const bookId =
  process.env.REELSHORT_BOOK_ID ??
  'rs.69d49b125ab01618b60b7cdc.xJHDoW0tdGFuZy1zaW5oLXJhLcO0bmctY2jhu6c';

if (!baseUrl) {
  throw new Error('CONTENT_API_BASE_URL is required');
}

async function getJson(path) {
  const response = await fetch(`${baseUrl}${path}`);
  const text = await response.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    throw new Error(`${path}: expected JSON, got HTTP ${response.status}`);
  }
  if (!response.ok || body.success !== true) {
    throw new Error(`${path}: HTTP ${response.status}`);
  }
  return body.data;
}

const chapters = await getJson(`/api/chapters/${encodeURIComponent(bookId)}`);
const list = chapters.chapterList ?? chapters.chapters ?? chapters.list ?? chapters;
if (!Array.isArray(list) || list.length < 70) {
  throw new Error(`expected at least 70 chapters, got ${list?.length ?? 0}`);
}

const first = list.find((chapter) => chapter.chapterIndex === 0) ?? list[0];
if (first.available !== true) {
  throw new Error('chapter 0 is not available');
}

const chapterIndex = first.chapterIndex ?? 0;
const watch = await getJson(
  `/api/watch/${encodeURIComponent(bookId)}/${chapterIndex}`,
);
if (watch.provider !== 'reelshort') {
  throw new Error(`expected ReelShort provider, got ${watch.provider}`);
}
if (typeof watch.videoUrl !== 'string' || !watch.videoUrl.endsWith('.m3u8')) {
  throw new Error('expected an HLS .m3u8 videoUrl');
}

console.log(
  JSON.stringify(
    {
      baseUrl,
      bookId,
      chapters: list.length,
      chapterIndex,
      available: first.available,
      provider: watch.provider,
      videoUrlKind: 'hls',
      qualityCount: Array.isArray(watch.qualities) ? watch.qualities.length : 0,
    },
    null,
    2,
  ),
);
