#!/usr/bin/env python3
"""Builds mod/EnderalAllTogether.esp from the player's own Enderal SE plugins.

Turns Second Breath (ranks I-V) and the Staff of Healing into channeled spells with a visible
golden beam, like Lightning (Calia's healing light beam, shortened to Lightning's reach). In co-op the old version was a charged, invisible hit on the target actor:
on the partner's game the remote caster's aim never quite matches, so heals kept missing.
A beam is simulated on every game, so the healed player's own game sees it land.

Heal per second matches vanilla: a vanilla cast takes about one second (0.5 s charge plus the release),
so one second of beam heals, costs and adds fever like one old cast (VANILLA_CAST_SECONDS). Arcane fever: it builds up while the
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

# The beam: our copy of DA09BeamProjectile (Calia's golden healing light, a real beam like Lightning), with Lightning's
# 1024 reach instead of 3000 and without its quest sound loop. Hits use the beam's own light-burst impact: without an
# impact data set the game played its default punch sound on every hit.
BEAM_SOURCE, BEAM, BEAM_RANGE = 0x000D561B, 0x03000803, 1024.0
BEAM_IMPACT = 0x0002C481  # DA09LightBeam01ImpactSet (a light burst, no sound, no hazard)
# Restoration's own concentration sounds (RestoreHealthConcSelf): draw, charge, ready, release, cast loop.
HEAL_SOUNDS = [(0, 0x0003E957), (1, 0x00056622), (2, 0x0003F363), (3, 0x00057C61), (4, 0x0003E958)]

# Fast Reflexes (blocking a power attack) and Steadfast (hit below 15% health) cast PerkQuickReflexes, whose only effect
# slowed time for a second. Now it lasts 2 seconds and gives a hidden perk while it does: half damage, no stagger.
QUICK_REFLEXES_SPELL, QUICK_REFLEXES_EFFECT = 0x000D8C31, 0x000D8C32
REFLEXES_PERK, REFLEXES_SECONDS = 0x03000804, 2
FAST_REFLEXES, STEADFAST = 0x00069D6C, 0x00069D6D
PERK_TEXT = {
    FAST_REFLEXES: b"Blocking during an enemy's power attack gives you 2 seconds of half damage and no stagger.",
    STEADFAST: b"Blocking and heavy armor is 5 percent more effective when your Stamina is half-filled. Furthermore, "
               b"when your Health falls below 15 percent, enemy attacks give you 2 seconds of half damage and no stagger.",
}
MOD_INCOMING_STAGGER, MOD_INCOMING_DAMAGE, MULTIPLY = 33, 36, 3  # perk entry points (tabs: 2 and 3), function
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

# No ability may change game speed in co-op (it slows one game, or everyone, and desyncs): these Slow Time effects of
# talents and perks become inert script effects. The spells, scripts and conditions that use them stay as they are.
# Story slowdowns stay: visions and memories (_00E_Vision_TimeEffect), the MQ12b ritual, quest scenes (_00E_Game_SlowTimeME).
# Eye of the Storm stays too: it slows every player's game at once (_00E_A2_EyeOfTheStormSC.psc, ShareSlowTime).
SLOW_TIME, INERT = 37, 1  # effect archetypes
NO_SLOW_TIME_SKY = [
    0x000EEEB5,  # _00E_A2_GhostwalkFreezeTimeEffect  Ghostwalk target selection
    0x000EEF96,  # _00E_A2_EldritchBloodFreezeTimeME  Eldritch Blood target selection
    0x0010D1B1,  # _00E_A2_SkyfallSelectionME         Skyfall target selection
    0x000D8C32,  # PerkQuickReflexesEffect            Quick Reflexes perk
]
NO_SLOW_TIME_FS = [0x0202F0AA]  # _00E_FS_Theriantrophist_TransformSlow_ME  transforming into the wolf
# The target selection abilities also slowed the player to a tenth of their speed (_00E_SlowSelfMENoDisable, made to
# match the slowed world). With time no longer slowed that only cripples the player, so the effect is taken out.
SLOW_SELF = 0x000EEEEB
SELECTION_SPELLS = [
    0x000EEF95,  # _00E_A2_EldritchBloodAbSelectionSP
    0x000EEEAE,  # _00E_A2_GhostwalkAbSelectionSP
    0x0010D1B5,  # _00E_A2_SkyfallSelectionSP
]
PER_SECOND = {0x0001CEA7, 0x0004E93F, ARCANE_FEVER} | set(OVERRIDE_MGEF)  # per second now
# One vanilla cast cycle (0.5 s charge + release). Beam values per second = vanilla value / this.
VANILLA_CAST_SECONDS = 1.0


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


def channel_effect(subs, edid=None, heal_sounds=True):
    for sub in subs:
        if sub[0] == "DATA":
            d = bytearray(sub[1])
            struct.pack_into("<I", d, 72, BEAM)
            struct.pack_into("<II", d, 80, CONCENTRATION, AIMED)
            struct.pack_into("<I", d, 100, BEAM_IMPACT)
            sub[1] = bytes(d)
        elif sub[0] == "SNDD" and heal_sounds:
            sub[1] = b"".join(struct.pack("<II", kind, sound) for kind, sound in HEAL_SOUNDS)
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
    """EFID/EFIT pairs: point at the channeled effects, values become per second (vanilla HPS)."""
    current = None
    for sub in subs:
        if sub[0] == "EFID":
            current = struct.unpack("<I", sub[1])[0]
            if current in COPY_MGEF:
                sub[1] = struct.pack("<I", COPY_MGEF[current][0])
        elif sub[0] == "EFIT" and current in PER_SECOND:
            magnitude, area, duration = struct.unpack("<fII", sub[1])
            # Channeled effects last as long as the beam (no duration), like Enderal's own Boon.
            sub[1] = struct.pack("<fII", magnitude / VANILLA_CAST_SECONDS, area, 0)


def drop_effect(subs, effect):
    """Spell subrecords without one effect (its EFID, EFIT and conditions)."""
    out, skipping = [], False
    for sub in subs:
        if sub[0] == "EFID":
            skipping = struct.unpack("<I", sub[1])[0] == effect
        elif sub[0] not in ("EFIT", "CTDA", "CIS1", "CIS2"):
            skipping = False
        if not skipping:
            out.append(sub)
    if len(out) == len(subs):
        sys.exit(f"effect {effect:08X} not found")
    return out


def per_second_cost(cost):
    return max(1, round(cost / VANILLA_CAST_SECONDS))


def perk_entry(entry_point, tabs, factor):
    """Subrecords of an unconditional entry point that multiplies the value by factor."""
    return [["PRKE", bytes([2, 0, 0])],  # entry point, rank 0, priority 0
            ["DATA", bytes([entry_point, MULTIPLY, tabs])],
            ["EPFT", bytes([1])],  # float
            ["EPFD", struct.pack("<f", factor)],
            ["PRKF", b""]]


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

    want_sky = {0x0001CEA7, 0x0004E93F, STAFF_ENCH, BEAM_SOURCE, QUICK_REFLEXES_SPELL} | set(PERK_TEXT) | set(NO_SLOW_TIME_SKY) | set(SELECTION_SPELLS)
    want_fs = set(OVERRIDE_MGEF) | set(SPELLS) | {ARCANE_FEVER} | set(NO_SLOW_TIME_FS)
    sky = read_records(os.path.join(folder, "Skyrim.esm"), want_sky)
    fs = read_records(os.path.join(folder, FS), want_fs)
    missing = want_sky - set(sky) | want_fs - set(fs)
    if missing:
        sys.exit("not found: " + ", ".join(f"{m:08X}" for m in sorted(missing)))
    sky_strings = read_strings(folder, "Skyrim.esm")
    fs_strings = read_strings(folder, FS)

    effects = []
    for src, (new_id, edid) in COPY_MGEF.items():
        typ, flags, subs = sky[src] if src in sky else fs[src]
        delocalize(subs, sky_strings if src in sky else fs_strings, ("FULL", "DNAM"))
        channel_effect(subs, edid, heal_sounds=new_id != NEW_FEVER)
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

    for fid in NO_SLOW_TIME_SKY + NO_SLOW_TIME_FS:
        src, strings = (sky, sky_strings) if fid in sky else (fs, fs_strings)
        typ, flags, subs = src[fid]
        delocalize(subs, strings, ("FULL", "DNAM"))
        for sub in subs:
            if sub[0] == "DATA":
                if struct.unpack_from("<I", sub[1], 64)[0] != SLOW_TIME:
                    sys.exit(f"{fid:08X} is no longer a Slow Time effect")
                sub[1] = set_u32(sub[1], 64, INERT)
                if fid == QUICK_REFLEXES_EFFECT:
                    sub[1] = set_u32(sub[1], 132, REFLEXES_PERK)  # perk to apply while the effect lasts
        if fid == QUICK_REFLEXES_EFFECT:
            subs = [sub for sub in subs if sub[0] != "VMAD"]  # its slow-time screen blur
        effects.append(record("MGEF", fid, flags, subs))

    typ, flags, subs = sky[BEAM_SOURCE]
    for sub in subs:
        if sub[0] == "EDID":
            sub[1] = b"_EAT_HealBeamProjectile\0"
        elif sub[0] == "DATA":
            d = bytearray(sub[1])
            struct.pack_into("<f", d, 12, BEAM_RANGE)
            struct.pack_into("<I", d, 40, 0)  # no sound loop of its own: the spell's cast loop plays
            sub[1] = bytes(d)
    delocalize(subs, sky_strings, ("FULL",))
    projectiles = [record("PROJ", BEAM, flags, subs)]

    perks = [record("PERK", REFLEXES_PERK, 0, [
        ["EDID", b"_EAT_FastReflexesPerk\0"],
        ["DATA", bytes([0, 0, 1, 0, 1])],  # not playable, hidden
        *perk_entry(MOD_INCOMING_DAMAGE, 3, 0.5),
        *perk_entry(MOD_INCOMING_STAGGER, 2, 0.0),
    ])]
    for fid, text in PERK_TEXT.items():
        typ, flags, subs = sky[fid]
        delocalize(subs, sky_strings, ("FULL", "DESC"))
        for sub in subs:
            if sub[0] == "DESC":
                sub[1] = text + b"\0"
        perks.append(record("PERK", fid, flags, subs))

    typ, flags, subs = sky[QUICK_REFLEXES_SPELL]
    delocalize(subs, sky_strings, ("FULL", "DESC"))
    for sub in subs:
        if sub[0] == "EFIT":
            magnitude, area, duration = struct.unpack("<fII", sub[1])
            sub[1] = struct.pack("<fII", magnitude, area, REFLEXES_SECONDS)
    reflexes_spell = record("SPEL", QUICK_REFLEXES_SPELL, flags, subs)

    typ, flags, subs = sky[STAFF_ENCH]
    delocalize(subs, sky_strings, ("FULL",))
    for sub in subs:
        if sub[0] == "ENIT":
            d = bytearray(sub[1])
            struct.pack_into("<I", d, 0, per_second_cost(struct.unpack_from("<I", d, 0)[0]))
            struct.pack_into("<I", d, 8, CONCENTRATION)
            struct.pack_into("<I", d, 16, AIMED)
            struct.pack_into("<f", d, 24, 0.0)  # no charge time
            sub[1] = bytes(d)
    channel_effects_list(subs)
    enchantments = [record("ENCH", STAFF_ENCH, flags, subs)]

    spells = [reflexes_spell]
    for fid in SELECTION_SPELLS:
        typ, flags, subs = sky[fid]
        delocalize(subs, sky_strings, ("FULL", "DESC"))
        spells.append(record("SPEL", fid, flags, drop_effect(subs, SLOW_SELF)))
    for fid in SPELLS:
        typ, flags, subs = fs[fid]
        delocalize(subs, fs_strings, ("FULL", "DESC"))
        for sub in subs:
            if sub[0] == "SPIT":
                d = bytearray(sub[1])
                struct.pack_into("<I", d, 0, per_second_cost(struct.unpack_from("<I", d, 0)[0]))
                struct.pack_into("<f", d, 12, 0.0)  # no charge time
                struct.pack_into("<II", d, 16, CONCENTRATION, AIMED)
                sub[1] = bytes(d)
        channel_effects_list(subs)
        spells.append(record("SPEL", fid, flags, subs))

    count = len(effects) + len(enchantments) + len(spells) + len(projectiles) + len(perks) + 5
    header = [["HEDR", struct.pack("<fII", 1.71, count, 0x805)],
              ["CNAM", b"Enderal AllTogether\0"],
              ["SNAM", b"Co-op: Second Breath and the Staff of Healing are channeled golden beams; abilities don't slow time on one game only\0"]]
    for master in MASTERS:
        header += [["MAST", master.encode() + b"\0"], ["DATA", struct.pack("<Q", 0)]]
    tes4 = record("TES4", 0, 0x200, header)  # light plugin: takes no load order slot

    with open(out, "wb") as f:
        # Bethesda's group order. Spells and enchantments look up their effects while they load, so MGEF must come
        # first: with SPEL ahead of it Second Breath lost every effect ("No effects found") and crashed on cast.
        f.write(tes4 + group("MGEF", effects) + group("ENCH", enchantments) + group("SPEL", spells) +
                group("PROJ", projectiles) + group("PERK", perks))
    print(f"wrote {os.path.normpath(out)}: {len(effects)} effects, {len(enchantments)} enchantment, {len(spells)} spells, "
          f"{len(projectiles)} projectile, {len(perks)} perks")


if __name__ == "__main__":
    main()
