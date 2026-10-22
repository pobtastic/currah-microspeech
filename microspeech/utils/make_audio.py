#!/usr/bin/env python3
"""Build SP0256-AL2 WAV files and attach #AUDIO0 lines in the ctl.

Reads sources/allophones.js (8-bit PCM at 11025 Hz) and CURRAH.ROM.
Writes sources/audio/*.wav and patches Allophone Dictionary comments.
"""

from __future__ import annotations

import base64
import re
import struct
import wave
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
SOURCES = ROOT / "sources"
AUDIO = SOURCES / "audio"
ROM = ROOT / "CURRAH.ROM"
CTL = SOURCES / "microspeech.ctl"
JS = SOURCES / "allophones.js"

RATE = 11025
HIGH_RATIO = 1.18

AL2_NAMES = [
    "PA1", "PA2", "PA3", "PA4", "PA5",
    "OY", "AY", "EH", "KK3", "PP", "JH", "NN1", "IH", "TT2", "RR1", "AX",
    "MM", "TT1", "DH1", "IY", "EY", "DD1", "UW1", "AO", "AA", "YY2", "AE",
    "HH1", "BB1", "TH", "UH", "UW2", "AW", "DD2", "GG3", "VV", "GG1", "SH",
    "ZH", "RR2", "FF", "KK2", "KK1", "ZZ", "NG", "LL", "WW", "XR", "WH",
    "YY1", "CH", "ER1", "ER2", "OW", "DH2", "SS", "NN2", "HH2", "OR", "AR",
    "YR", "GG2", "EL", "BB2",
]

COMMENT_SLUGS = {
    "EDIT": "edit",
    "ENTER": "enter",
    "Cursor": "cursor",
    "DELETE": "delete",
    "INK": "ink",
    "PAPER": "paper",
    "Block graphics": "graphics",
    "FLASH": "flash",
    "BRIGHT": "bright",
    "INVERSE": "inverse",
    "OVER": "over",
    "AT": "at",
    "TAB": "tab",
    '"!"': "excl",
    "Quotation mark": "quot",
    '"&"': "amp",
    "\"'\"": "apos",
    '"("': "lparen",
    '"<"': "lt",
    '">"': "gt",
    ">=": "ge",
    "<=": "le",
    "<>": "ne",
    '"/"': "slash",
    '"\\"': "bslash",
    '"."': "dot",
    '","': "comma",
    '";"': "semi",
    '"_"': "und",
    '"*"': "star",
    '"`"': "grave",
    '"+"': "plus",
    '"-"': "minus",
    "Space": "space",
    '"^"': "hat",
    '"?"': "query",
    '"|"': "pipe",
    "Copyright": "copyright",
    "LET": "let",
    '":"': "colon",
    '"="': "eq",
    "NEW": "new",
    '"#"': "hash",
    '"$"': "dollar",
    '"%"': "pct",
    "RND": "rnd",
    "INKEY$": "inkey",
    "PI": "pi",
    "FN": "fn",
    "SCREEN$": "screen",
    "ATTR": "attr",
    "VAL$": "valstr",
    "CODE": "code",
    "VAL": "val",
    "LEN": "len",
    "SIN": "sin",
    "COS": "cos",
    "TAN": "tan",
    "ASN": "asn",
    "ACS": "acs",
    "ATN": "atn",
    "LN": "ln",
    "EXP": "exp",
    "INT": "int",
    "SQR": "sqr",
    "ABS": "abs",
    "PEEK": "peek",
    "IN": "in",
    "USR": "usr",
    "STR$": "str",
    "CHR$": "chr",
    "NOT": "not",
    "BIN": "bin",
    "OR": "or",
    "LINE": "line",
    "THEN": "then",
    "TO": "to",
    "STEP": "step",
    "DEF FN": "deffn",
    "CAT": "cat",
    "FORMAT": "format",
    "MOVE": "move",
    "ERASE": "erase",
    "OPEN #": "open",
    "CLOSE #": "close",
    "MERGE": "merge",
    "VERIFY": "verify",
    "BEEP": "beep",
    "CIRCLE": "circle",
    "OUT": "out",
    "LPRINT": "lprint",
    "LLIST": "llist",
    "STOP": "stop",
    "READ": "read",
    "DATA": "data",
    "RESTORE": "restore",
    "BORDER": "border",
    "CONTINUE": "continue",
    "DIM": "dim",
    "REM": "rem",
    "FOR": "for",
    "GO TO": "goto",
    "GO SUB": "gosub",
    "INPUT": "input",
    "LOAD": "load",
    "LIST": "list",
    "PAUSE": "pause",
    "NEXT": "next",
    "POKE": "poke",
    "PRINT": "print",
    "PLOT": "plot",
    "RUN": "run",
    "SAVE": "save",
    "RANDOMIZE": "randomize",
    "IF": "if",
    "DRAW": "draw",
    "CLEAR": "clear",
    "RETURN": "return",
    "COPY": "copy",
}


def load_pcm():
    text = JS.read_text()
    names = re.search(r"names:\[(.*?)\]", text, re.S).group(1)
    names = [n.strip().strip('"') for n in names.split(",") if n.strip()]
    lengths = [
        int(x)
        for x in re.search(r"lengths:\[(.*?)\]", text, re.S).group(1).split(",")
        if x.strip()
    ]
    blob = base64.b64decode(re.search(r'data:"([^"]+)"', text).group(1))
    pcm = []
    offset = 0
    for length in lengths:
        pcm.append(blob[offset : offset + length])
        offset += length
    if len(pcm) != 64 or names != AL2_NAMES:
        raise SystemExit("allophones.js does not match the AL2 name list")
    return pcm


def write_wav(path: Path, samples: bytes):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(1)
        wav.setframerate(RATE)
        wav.writeframes(samples)


def raise_pitch(samples: bytes, ratio: float = HIGH_RATIO) -> bytes:
    if not samples:
        return samples
    count = max(1, int(len(samples) / ratio))
    out = bytearray(count)
    last = len(samples) - 1
    for i in range(count):
        src = i * ratio
        left = int(src)
        if left >= last:
            out[i] = samples[last]
            continue
        frac = src - left
        out[i] = int(samples[left] * (1.0 - frac) + samples[left + 1] * frac)
    return bytes(out)


def parse_dictionary(rom: bytes):
    entries = []
    addr = 0x0448
    while addr < 0x075A:
        start = addr
        key = rom[addr]
        addr += 1
        ids = []
        while addr < 0x075B:
            byte = rom[addr]
            addr += 1
            ids.append(byte)
            if byte & 0x80:
                break
        entries.append((start, addr - start, key, ids))
    return entries


def slug_for(comment: str) -> str:
    text = comment.strip().rstrip(".")
    if text in COMMENT_SLUGS:
        return COMMENT_SLUGS[text]
    if len(text) == 3 and text[0] == '"' and text[2] == '"':
        char = text[1]
        if char.isalnum():
            return char.lower()
    raise SystemExit(f"no slug for comment {comment!r}")


def render_entry(pcm, ids: list[int]) -> bytes:
    chunks = []
    for byte in ids:
        allo = byte & 0x3F
        sample = pcm[allo]
        if byte & 0x40:
            sample = raise_pitch(sample)
        chunks.append(sample)
    return b"".join(chunks)


def ctl_entries():
    found = []
    in_dict = False
    for line in CTL.read_text().splitlines():
        if line.startswith("b $0447 "):
            in_dict = True
            continue
        if in_dict and line.startswith("w $075B "):
            break
        if not in_dict:
            continue
        match = re.match(r"  (\$[0-9A-Fa-f]{4}),\$([0-9A-Fa-f]+) (.+)$", line)
        if not match:
            continue
        addr = int(match.group(1)[1:], 16)
        length = int(match.group(2), 16)
        comment = match.group(3)
        if "Dummy" in comment or comment == "Table end.":
            continue
        comment = re.sub(r" #AUDIO0?\([^)]+\)", "", comment)
        found.append((addr, length, comment, slug_for(comment)))
    return found


def patch_ctl(slugs: dict[int, str]):
    lines = CTL.read_text().splitlines(keepends=True)
    out = []
    in_dict = False
    for line in lines:
        raw = line.rstrip("\n")
        if raw.startswith("b $0447 "):
            in_dict = True
        elif raw.startswith("w $075B "):
            in_dict = False
        audio_n = (
            re.match(r"N (\$[0-9A-Fa-f]{4}) #AUDIO0\([^)]+\)\s*$", raw)
            if in_dict
            else None
        )
        if audio_n:
            addr = int(audio_n.group(1)[1:], 16)
            if addr in slugs:
                continue
        match = (
            re.match(r"(  \$[0-9A-Fa-f]{4},\$[0-9A-Fa-f]+ )(.+)$", raw)
            if in_dict
            else None
        )
        if match:
            prefix, comment = match.group(1), match.group(2)
            addr = int(prefix[3:7], 16)
            comment = re.sub(r" #AUDIO0?\([^)]+\)", "", comment)
            raw = prefix + comment
            if addr in slugs:
                nline = f"N ${addr:04X} #AUDIO0(key-{slugs[addr]}.wav)"
                if len(nline) > 80 or len(raw) > 80:
                    raise SystemExit(f"line exceeds 80 characters: {nline}")
                out.append(nline + "\n")
        out.append(raw + ("\n" if line.endswith("\n") else ""))
    CTL.write_text("".join(out))


def write_sound_ref():
    rows = []
    for index, name in enumerate(AL2_NAMES):
        slug = name.lower()
        rows.append(
            f"{{ #N${index:02X} | {name} | #AUDIO0(al2-{slug}.wav) }}"
        )
    body = "\n".join(rows)
    text = f"""; Copyright 2026 Paul Maddern (paul@arcadegeek.co.uk)

[Page:Sound]
SectionPrefix=Audio

[Audio:allophones:AL2 Allophones]
The #FACT(sp0256,SP0256-AL2) set, as written by #R$0166. These
are recordings of a real chip, not a simulated core. Bit 6
(high intonation) is not applied here; the
#R$0447 entries play it where the ROM sets that bit.

#TABLE(default,centre,centre,centre)
{{ =h ID | =h Name | =h Sample }}
{body}
TABLE#
"""
    (SOURCES / "sound.ref").write_text(text)


def main():
    pcm = load_pcm()
    AUDIO.mkdir(exist_ok=True)
    for name, sample in zip(AL2_NAMES, pcm):
        write_wav(AUDIO / f"al2-{name.lower()}.wav", sample)

    rom = ROM.read_bytes()
    dictionary = {addr: (length, ids) for addr, length, _key, ids in parse_dictionary(rom)}
    ctl = ctl_entries()
    slugs = {}
    for addr, length, comment, slug in ctl:
        if addr not in dictionary:
            raise SystemExit(f"{comment} at ${addr:04X} is not a dictionary entry")
        rom_len, ids = dictionary[addr]
        if rom_len != length:
            raise SystemExit(
                f"${addr:04X} ctl length ${length:02X} != ROM ${rom_len:02X}"
            )
        write_wav(AUDIO / f"key-{slug}.wav", render_entry(pcm, ids))
        slugs[addr] = slug

    extra = set(dictionary) - set(slugs)
    extra.discard(0x075A)
    if extra:
        raise SystemExit(
            "ROM entries missing from ctl: "
            + ", ".join(f"${addr:04X}" for addr in sorted(extra))
        )

    patch_ctl(slugs)
    write_sound_ref()
    print(f"wrote {len(list(AUDIO.glob('*.wav')))} wav files")


if __name__ == "__main__":
    main()
