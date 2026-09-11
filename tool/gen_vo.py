#!/usr/bin/env python3
"""Generate synced ElevenLabs VO clips. Reads ELEVEN_API_KEY from the environment. Never writes the key."""

from __future__ import annotations

import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "vo"
VOICE_ID = os.environ.get("ELEVEN_VOICE_ID", "2EiwWnXFnvU8HyyO9E3N")  # Clyde
MODEL = os.environ.get("ELEVEN_MODEL", "eleven_multilingual_v2")

CLIPS: list[dict[str, str]] = [
    {
        "id": "opening",
        "text": (
            "Ravenport keeps two calendars. One for the rain. One for the names that outlast it. "
            "You inherit a chair, not a pardon. "
            "Sit with the living. Press a street. Or let the year close on you. "
            "This is the Harts' weather. Vice Dynasty."
        ),
    },
    {
        "id": "prologue_rain",
        "text": (
            "Nineteen ninety-eight. The docks smell like rust and orange peels. "
            "Silas Crowe flicks a cigarette into a puddle that already knows your last name. "
            "A crate sits unclaimed under Pier Seven. Somebody is coming for it. Somebody always is."
        ),
    },
    {
        "id": "prologue_heat",
        "text": (
            "Detective Rhea Vale finds you outside a diner that never learned to close. "
            "She puts a photograph on the wet counter. I don't need a confession, she says. "
            "I need to know if you're going to become a problem, or a person."
        ),
    },
    {
        "id": "prologue_loyalty",
        "text": (
            "Crowe asks you onto a late ferry that doesn't print tickets. "
            "Mid-channel he says a first name — not yours — and asks you not to say it. "
            "The water is black glass. Loyalty, tonight, is a sound you decide not to make."
        ),
    },
    {
        "id": "prologue_name",
        "text": (
            "A cheap cake in a walk-up. Crowe sends a note: the city has a slot for your surname. "
            "Vale's car idles half a block away and does not come in. "
            "The prologue is over. The campaign is not."
        ),
    },
    {
        "id": "war_threat_card",
        "text": (
            "A rival house sent a note that is not a note. It is a season. "
            "The docks already know. Heat is a smell. You can answer, pay, or pretend the rain is louder."
        ),
    },
    {
        "id": "war_escalate_card",
        "text": (
            "The war is hot. A street flinches. You can press back, buy the corner, or yield the night and keep the body."
        ),
    },
    {
        "id": "war_resolve_card",
        "text": (
            "The war is breaking. Someone sent coffee like it is a treaty. "
            "You can close the season clean, or leave a tooth in it for later."
        ),
    },
    {
        "id": "detective_card",
        "text": (
            "A detective leaves a card under your door. We should talk before someone else does. "
            "Rain has smudged the ink, but not the invitation."
        ),
    },
    {
        "id": "heir_rise",
        "text": (
            "Money, turf, and enemies stay with the name. You sit where they sat. "
            "The rain does not care which generation."
        ),
    },
]


def sentences(text: str) -> list[str]:
    parts: list[str] = []
    buf = ""
    for ch in text:
        buf += ch
        if ch in ".!?" and buf.strip():
            parts.append(buf.strip())
            buf = ""
    if buf.strip():
        parts.append(buf.strip())
    return parts or [text.strip()]


def lines_from_alignment(text: str, alignment: dict | None) -> list[dict]:
    sents = sentences(text)
    if not alignment:
        # ~16 chars/sec noir delivery
        t = 0.0
        out = []
        for s in sents:
            dur = max(1.6, min(7.5, len(s) / 16.0))
            out.append({"text": s, "start": round(t, 3), "end": round(t + dur, 3)})
            t += dur + 0.18
        return out

    chars = alignment.get("characters") or []
    starts = alignment.get("character_start_times_seconds") or []
    ends = alignment.get("character_end_times_seconds") or []
    if not (chars and starts and ends) or len(chars) != len(starts):
        return lines_from_alignment(text, None)

    compact = "".join(chars)
    cursor = 0
    out = []
    search_from = 0
    for s in sents:
        needle = "".join(ch for ch in s if not ch.isspace())
        hay = "".join(ch for ch in compact[search_from:] if not ch.isspace())
        # Map compacted index back is messy; walk original chars instead.
        target = s
        idx = compact.find(target[: min(24, len(target))], search_from)
        if idx < 0:
            idx = compact.find(s.split()[0], search_from) if s.split() else search_from
        if idx < 0:
            idx = search_from
        start_i = max(0, min(idx, len(starts) - 1))
        end_i = start_i
        consumed = 0
        while end_i < len(chars) and consumed < len(s):
            ch = chars[end_i]
            if not ch.isspace() or (consumed < len(s) and s[consumed].isspace()):
                consumed += 1 if ch == (s[consumed] if consumed < len(s) else "") or True else 0
            end_i += 1
            if "".join(chars[start_i:end_i]).replace("  ", " ").strip().endswith(s[-12:] if len(s) > 12 else s):
                break
            if end_i - start_i > len(s) + 8:
                break
        end_i = min(max(end_i, start_i + 1), len(ends))
        start_t = float(starts[start_i])
        end_t = float(ends[end_i - 1])
        if end_t <= start_t:
            end_t = start_t + max(1.4, len(s) / 16.0)
        out.append({"text": s, "start": round(start_t, 3), "end": round(end_t, 3)})
        search_from = end_i
        cursor = end_i
    # Guarantee monotonic
    for i in range(1, len(out)):
        if out[i]["start"] < out[i - 1]["end"]:
            out[i]["start"] = out[i - 1]["end"]
        if out[i]["end"] <= out[i]["start"]:
            out[i]["end"] = round(out[i]["start"] + 1.4, 3)
    _ = cursor
    return out


def synthesize(clip_id: str, text: str, api_key: str) -> None:
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}/with-timestamps"
    body = json.dumps(
        {
            "text": text,
            "model_id": MODEL,
            "voice_settings": {
                "stability": 0.42,
                "similarity_boost": 0.78,
                "style": 0.32,
                "use_speaker_boost": True,
            },
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "xi-api-key": api_key,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=90) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8", errors="replace")
        raise SystemExit(f"ElevenLabs {clip_id} failed HTTP {e.code}: {err}") from e

    audio_b64 = payload.get("audio_base64")
    if not audio_b64:
        raise SystemExit(f"ElevenLabs {clip_id} returned no audio")
    mp3 = OUT / f"{clip_id}.mp3"
    mp3.write_bytes(base64.b64decode(audio_b64))
    alignment = payload.get("alignment") or payload.get("normalized_alignment")
    meta = {
        "asset": f"vo/{clip_id}.mp3",
        "lines": lines_from_alignment(text, alignment),
    }
    (OUT / f"{clip_id}.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"wrote {mp3.name} ({mp3.stat().st_size} bytes), {len(meta['lines'])} lines")


def main() -> int:
    key = os.environ.get("ELEVEN_API_KEY", "").strip()
    if not key:
        print("ELEVEN_API_KEY missing", file=sys.stderr)
        return 2
    OUT.mkdir(parents=True, exist_ok=True)
    only = set(sys.argv[1:])
    for clip in CLIPS:
        if only and clip["id"] not in only:
            continue
        print(f"generating {clip['id']}...")
        synthesize(clip["id"], clip["text"], key)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
