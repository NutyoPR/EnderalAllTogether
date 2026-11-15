#!/usr/bin/env python3
"""Builds mod/EnderalAllTogether.esp from the player's own Enderal SE plugins.

Turns Second Breath (ranks I-V) and the Staff of Healing into channeled spells with a visible
beam, like Flames. In co-op the old version was a charged, invisible hit on the target actor:
on the partner's game the remote caster's aim never quite matches, so heals kept missing.
A beam is simulated on every game, so the healed player's own game sees it land.

Heal per magicka stays the same: half the old heal per second for half the old cost per second,
so a 2 second channel equals one old cast. Arcane fever follows the same rule: it builds up while the
beam heals (_EAT_ChanneledArcaneFever.psc) with one message when you let go. Elixir and the NPC
versions are left alone.

Usage: python3 tools/make_esp.py "<path to the Enderal SE folder with Skyrim.esm>"
"""
import os
import struct
import sys
import zlib

MASTERS = ["Skyrim.esm", "Update.esm", "Enderal - Forgotten Stories.esm"]
FS = "Enderal - Forgotten Stories.esm"

BEAM = 0x000ABF04  # AbsorbGreenBeam01, a flame-type (spray) projectile, same 768 range as Flames
CONCENTRATION, AIMED = 2, 2

# Effects only these spells use: changed in place.
OVERRIDE_MGEF = [
    0x0202F1DD, 0x0202F1DE, 0x0202F1DF, 0x0202F1E0,  # RestoreHealthFFActor25..100
    0x0202F1E1, 0x0202F1E3, 0x0202F1E4, 0x0202F1E5,  # PerkRestoreStaminaFFActor25..100
]
ARCANE_FEVER = 0x0202F112  # _00E_IncreaseArcaneFeverFFTarget: fever once per cast, replaced by a channeled copy
# Effects that NPC spells (HealOther, *_SecondBreath_NPC) share: copied to new light records.
NEW_HEALTH, NEW_STAMINA, NEW_FEVER = 0x03000800, 0x03000801, 0x03000802
COPY_MGEF = {0x0001CEA7: (NEW_HEALTH, "_EAT_RestoreHealthConcAimed"),
             0x0004E93F: (NEW_STAMINA, "_EAT_PerkRestoreStaminaConcAimed"),
             ARCANE_FEVER: (NEW_FEVER, "_EAT_ChanneledArcaneFever")}
# The channeled fever effect's script and its properties (same forms the original script uses).
FEVER_SCRIPT = "_EAT_ChanneledArcaneFever"
FEVER_PROPERTIES = [("PlayerREF", 0x00000014),
                    ("_00E_Class_Thaumaturge_P07_MentalExpert", 0x00069D07),
                    ("_00E_Player_sArcaneFeverIncreased", 0x00036F95),
                    ("_00E_FS_IncreaseArcaneFeverM", 0x0202F10B)]
SPELLS = [0x0201F0D3, 0x0201F0D5, 0x0201F0D4, 0x0201F0D6, 0x0201F0D2]  # _07E/_14E/_22E/_32E/_55E_SecondBreath
STAFF_ENCH = 0x00029B6E  # StaffEnchHealOther (both Staffs of Healing)
HALVED = {0x0001CEA7, 0x0004E93F, ARCANE_FEVER} | set(OVERRIDE_MGEF)  # per second now


def subrecords(body):
    out, o, big = [], 0, None
    while o < len(body):
        t = body[o:o + 4].decode("latin1")
        size = struct.unpack_from("<H", body, o + 4)[0]
        if t == "XXXX":
            big = struct.unpack_from("<I", body, o + 6)[0]
            o += 10
            continue
        if big is not None:
            size, big = big, None
        out.append([t, bytes(body[o + 6:o + 6 + size])])
        o += 6 + size
    return out


def read_records(path, want):
    data = open(path, "rb").read()
    found = {}

    def walk(off, end):
        while off < end:
            typ = data[off:off + 4]
            size = struct.unpack_from("<I", data, off + 4)[0]
            if typ == b"GRUP":
                walk(off + 24, off + size)
                off += size
                continue
            flags, fid = struct.unpack_from("<II", data, off + 8)
            if fid in want:
                body = data[off + 24:off + 24 + size]
                if flags & 0x40000:
                    body = zlib.decompress(body[4:])
                found[fid] = (typ.decode(), flags & ~0x40000, subrecords(body))
            off += 24 + size

    header = struct.unpack_from("<I", data, 4)[0]
    walk(24 + header, len(data))
    return found


def read_strings(folder, plugin):
    """English string tables of a localized plugin, by id."""
    table = {}
    base = os.path.splitext(plugin)[0].lower() + "_english."
    for name in os.listdir(os.path.join(folder, "Strings")):
        lower = name.lower()
        if not lower.startswith(base):
            continue
        blob = open(os.path.join(folder, "Strings", name), "rb").read()
        count = struct.unpack_from("<I", blob, 0)[0]
        start = 8 + count * 8
        for i in range(count):
            sid, off = struct.unpack_from("<II", blob, 8 + i * 8)
            pos = start + off
            if lower.endswith(".strings"):
                text = blob[pos:blob.index(b"\0", pos)]
            else:
                length = struct.unpack_from("<I", blob, pos)[0]
                text = blob[pos + 4:pos + 4 + length].rstrip(b"\0")
            table[sid] = text
    return table


def delocalize(subs, strings, fields):
    """This plugin isn't localized, so string ids become the English text."""
    for sub in subs:
        if sub[0] in fields and len(sub[1]) == 4:
            sub[1] = strings.get(struct.unpack("<I", sub[1])[0], b"") + b"\0"


def set_u32(blob, offset, value):
    b = bytearray(blob)
    struct.pack_into("<I", b, offset, value)
    return bytes(b)


def channel_effect(subs, edid=None):
    for sub in subs:
        if sub[0] == "DATA":
            d = bytearray(sub[1])
            struct.pack_into("<I", d, 72, BEAM)
            struct.pack_into("<II", d, 80, CONCENTRATION, AIMED)
            sub[1] = bytes(d)
        elif sub[0] == "DNAM" and (b" points of " in sub[1] or b" percent" in sub[1]) and b"per second" not in sub[1]:
            sub[1] = sub[1].rstrip(b"\0").rstrip(b".") + b" per second.\0"
        elif sub[0] == "EDID" and edid:
            sub[1] = edid.encode() + b"\0"


def wstring(text):
    return struct.pack("<H", len(text)) + text.encode()


def fever_vmad():
    """VMAD with one script whose properties are all objects (version 5, object format 2)."""
    blob = struct.pack("<hhH", 5, 2, 1) + wstring(FEVER_SCRIPT) + struct.pack("<BH", 0, len(FEVER_PROPERTIES))
    for name, form in FEVER_PROPERTIES:
        blob += wstring(name) + struct.pack("<BBHhI", 1, 1, 0, -1, form)
    return blob


def channel_effects_list(subs):
    """EFID/EFIT pairs: point at the channeled effects, value effects heal half per second."""
    current = None
    for sub in subs:
        if sub[0] == "EFID":
            current = struct.unpack("<I", sub[1])[0]
            if current in COPY_MGEF:
                sub[1] = struct.pack("<I", COPY_MGEF[current][0])
        elif sub[0] == "EFIT" and current in HALVED:
            magnitude, area, duration = struct.unpack("<fII", sub[1])
            # Channeled effects last as long as the beam (no duration), like Enderal's own Boon.
            sub[1] = struct.pack("<fII", magnitude / 2, area, 0)


def half_cost(cost):
    return (cost + 1) // 2


def record(typ, fid, flags, subs):
    body = b""
    for name, value in subs:
        if len(value) > 0xFFFF:
            body += b"XXXX" + struct.pack("<HI", 4, len(value)) + name.encode() + struct.pack("<H", 0)
        else:
            body += name.encode() + struct.pack("<H", len(value))
        body += value
    return typ.encode() + struct.pack("<IIIIHH", len(body), flags, fid, 0, 44, 0) + body


def group(label, records):
    body = b"".join(records)
    return b"GRUP" + struct.pack("<I", 24 + len(body)) + label.encode() + struct.pack("<iHHI", 0, 0, 0, 0) + body


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else "."
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "mod", "EnderalAllTogether.esp")

    sky = read_records(os.path.join(folder, "Skyrim.esm"), {0x0001CEA7, 0x0004E93F, STAFF_ENCH})
    fs = read_records(os.path.join(folder, FS), set(OVERRIDE_MGEF) | set(SPELLS) | {ARCANE_FEVER})
    missing = {0x0001CEA7, 0x0004E93F, STAFF_ENCH} - set(sky) | (set(OVERRIDE_MGEF) | set(SPELLS) | {ARCANE_FEVER}) - set(fs)
    if missing:
        sys.exit("not found: " + ", ".join(f"{m:08X}" for m in sorted(missing)))
    sky_strings = read_strings(folder, "Skyrim.esm")
    fs_strings = read_strings(folder, FS)

    effects = []
    for src, (new_id, edid) in COPY_MGEF.items():
        typ, flags, subs = sky[src] if src in sky else fs[src]
        delocalize(subs, sky_strings if src in sky else fs_strings, ("FULL", "DNAM"))
        channel_effect(subs, edid)
        if new_id == NEW_FEVER:
            for sub in subs:
                if sub[0] == "VMAD":
                    sub[1] = fever_vmad()
        effects.append(record("MGEF", new_id, flags, subs))
    for fid in OVERRIDE_MGEF:
        typ, flags, subs = fs[fid]
        delocalize(subs, fs_strings, ("FULL", "DNAM"))
        channel_effect(subs)
        effects.append(record("MGEF", fid, flags, subs))

    typ, flags, subs = sky[STAFF_ENCH]
    delocalize(subs, sky_strings, ("FULL",))
    for sub in subs:
        if sub[0] == "ENIT":
            d = bytearray(sub[1])
            struct.pack_into("<I", d, 0, half_cost(struct.unpack_from("<I", d, 0)[0]))
            struct.pack_into("<I", d, 8, CONCENTRATION)
            struct.pack_into("<I", d, 16, AIMED)
            struct.pack_into("<f", d, 24, 0.0)  # no charge time
            sub[1] = bytes(d)
    channel_effects_list(subs)
    enchantments = [record("ENCH", STAFF_ENCH, flags, subs)]

    spells = []
    for fid in SPELLS:
        typ, flags, subs = fs[fid]
        delocalize(subs, fs_strings, ("FULL", "DESC"))
        for sub in subs:
            if sub[0] == "SPIT":
                d = bytearray(sub[1])
                struct.pack_into("<I", d, 0, half_cost(struct.unpack_from("<I", d, 0)[0]))
                struct.pack_into("<f", d, 12, 0.0)  # no charge time
                struct.pack_into("<II", d, 16, CONCENTRATION, AIMED)
                sub[1] = bytes(d)
        channel_effects_list(subs)
        spells.append(record("SPEL", fid, flags, subs))

    count = len(effects) + len(enchantments) + len(spells) + 3
    header = [["HEDR", struct.pack("<fII", 1.71, count, 0x803)],
              ["CNAM", b"Enderal AllTogether\0"],
              ["SNAM", b"Co-op: Second Breath and the Staff of Healing are channeled beams, like Flames\0"]]
    for master in MASTERS:
        header += [["MAST", master.encode() + b"\0"], ["DATA", struct.pack("<Q", 0)]]
    tes4 = record("TES4", 0, 0x200, header)  # light plugin: takes no load order slot

    with open(out, "wb") as f:
        f.write(tes4 + group("MGEF", effects) + group("ENCH", enchantments) + group("SPEL", spells))
    print(f"wrote {os.path.normpath(out)}: {len(effects)} effects, {len(enchantments)} enchantment, {len(spells)} spells")


if __name__ == "__main__":
    main()
