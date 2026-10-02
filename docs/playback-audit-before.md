# Playback audit before fix

- Base URL: https://drama-6qrppui46-ok-2e47.vercel.app
- Generated: 2026-10-02T02:59:53.162Z
- Series tested: 60
- Public episode probes: 100
- Episode budget: 100

## Summary

| Metric | Count |
|---|---:|
| Watch API pass | 100 |
| Watch API fail | 0 |
| Media candidate pass | 100 |
| Media candidate fail | 0 |
| Locked expected | 928 |
| Timeout | 0 |
| Content type mismatch | 0 |
| Range problem | 0 |

## Provider summary

| Provider | Series | Episodes | Watch pass | Media pass | Failed |
|---|---:|---:|---:|---:|---:|
| reelshort | 23 | 69 | 69 | 69 | 0 |
| netshort | 23 | 31 | 31 | 31 | 0 |

## Failure classes

| Class | Count |
|---|---:|
| LOCKED_EXPECTED | 23 |

## Findings

- Current Flutter source uses BetterPlayer cache for non-HLS URLs; this is a PLAYER_CONFIG_RISK for signed/opaque NetShort MP4 and is not yet fixed in this before audit.
- Provider-header fallback passed for 0 candidate(s). A non-zero value is evidence that headers are needed for those candidates.
- MP4 probes used a bounded Range request and inspected the initial bytes for an ftyp box. HLS probes fetched the playlist and one child segment/init URI.
- URLs in this report are host-only or path-only; signed query parameters are masked.

## Failure samples

| Provider | Series | Episode | Watch HTTP | Class | Media host |
|---|---|---:|---:|---|---|
| - | none | - | - | - | - |

## Sample inventory

- Exact sample selection: all available shelves: trending, new, recommended, romance, action, fantasy.
- Public episodes only were media-probed. Locked/paywalled chapters were excluded from media failure counts.
- reelshort: 36 series; netshort: 24 series
