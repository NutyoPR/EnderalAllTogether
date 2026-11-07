// EnderalSTRPatch - engine-side isolation of Enderal personal state from Skyrim Together Reborn.
// Build against CommonLibSSE-NG (git submodule in extern/).
#include <RE/Skyrim.h>
#include <SKSE/SKSE.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <algorithm>
#include <format>
#include <fstream>
#include <string>
#include <unordered_set>
#include <vector>

using namespace std::literals;
namespace logger = SKSE::log;

// ---------------------------------------------------------------- config
struct Config {
    bool enabled = true;
    bool discover = false;  // log every effect applied, with Plugin|LocalID, to find real IDs
    std::vector<std::string> magicPrefixes, questPrefixes;
    std::vector<std::pair<std::string, std::uint32_t>> magicIds, questIds;  // plugin, local id
} g_cfg;

static std::vector<std::string> Split(const std::string& s) {
    std::vector<std::string> out; std::string cur;
    auto flush = [&] {
        auto b = cur.find_first_not_of(" \t"), e = cur.find_last_not_of(" \t");
        if (b != std::string::npos) out.push_back(cur.substr(b, e - b + 1));
        cur.clear();
    };
    for (char c : s) { if (c == ',') flush(); else cur += c; }
    flush();
    return out;
}

static void ParseIds(const std::string& v, std::vector<std::pair<std::string, std::uint32_t>>& out) {
    for (auto& tok : Split(v)) {
        auto bar = tok.rfind('|');
        if (bar == std::string::npos) continue;
        try { out.emplace_back(tok.substr(0, bar), (std::uint32_t)std::stoul(tok.substr(bar + 1), nullptr, 16)); }
        catch (...) { logger::warn("bad FormID entry: {}", tok); }
    }
}

static void LoadConfig() {
    std::ifstream f("Data/SKSE/Plugins/EnderalSTRPatch.ini");
    std::string line, sec;
    while (std::getline(f, line)) {
        if (line.empty() || line[0] == ';' || line[0] == '#') continue;
        if (line[0] == '[') { sec = line.substr(1, line.find(']') - 1); continue; }
        auto eq = line.find('='); if (eq == std::string::npos) continue;
        auto k = Split(line.substr(0, eq)).empty() ? "" : Split(line.substr(0, eq))[0];
        auto v = line.substr(eq + 1);
        if (sec == "General" && k == "Enabled") g_cfg.enabled = v.find('1') != std::string::npos;
        else if (sec == "General" && k == "Discover") g_cfg.discover = v.find('1') != std::string::npos;
        else if (sec == "Magic" && k == "BlockOnRemoteActors_Prefixes") g_cfg.magicPrefixes = Split(v);
        else if (sec == "Magic" && k == "BlockOnRemoteActors_FormIDs") ParseIds(v, g_cfg.magicIds);
        else if (sec == "Quests" && k == "BlacklistPrefixes") g_cfg.questPrefixes = Split(v);
        else if (sec == "Quests" && k == "BlacklistFormIDs") ParseIds(v, g_cfg.questIds);
    }
}

static bool Matches(RE::TESForm* form, const std::vector<std::string>& prefixes,
                    const std::vector<std::pair<std::string, std::uint32_t>>& ids) {
    if (!form) return false;
    // exact FormID: resolve plugin|local -> runtime form
    auto* dh = RE::TESDataHandler::GetSingleton();
    for (auto& [plugin, local] : ids)
        if (dh && dh->LookupFormID(local, plugin) == form->GetFormID()) return true;
    // prefix: needs EditorID in memory (po3 Tweaks). Empty string -> no match.
    std::string_view edid = form->GetFormEditorID();
    if (edid.empty()) return false;
    for (auto& p : prefixes)
        if (edid.size() >= p.size() && _strnicmp(edid.data(), p.c_str(), p.size()) == 0) return true;
    return false;
}

// ---------------------------------------------------------------- magic hook
// Verified against CommonLibSSE-NG MagicTarget.h / Actor.h:
//  - Actor inherits TESObjectREFR (4 vtables: idx 0-3) then MagicTarget -> VTABLE_Character[4]
//  - MagicTarget vfunc 0x01 is AddTarget(AddTargetData&)  (there is no AddTargetEffect)
//  - 0x03 is MagicTargetIsActor(), 0x06 is CanAddActiveEffect() (pure, no args)
// Idea: on B's client the STR puppet of A is a non-player Actor. STR applies A's potion effect to
// it, the effect's Papyrus script calls Game.GetPlayer() = B. Block listed effects on every actor
// that is not the local player. (Hypothesis - confirm with Discover=1.)
static std::string Describe(RE::TESForm* f) {
    if (!f) return "null";
    auto* file = f->GetFile(0);
    return std::format("{}|{:06X} '{}' ({})", file ? file->GetFilename() : "?", f->GetLocalFormID(),
                       f->GetFormEditorID(), f->GetName());
}

struct MagicHook {
    using AddTargetData = RE::MagicTarget::AddTargetData;
    static constexpr std::size_t kVtableSlot = 4;  // MagicTarget in Actor-derived vtable
    static constexpr std::size_t kVfuncIdx = 0x1;  // AddTarget
    static inline REL::Relocation<bool(RE::MagicTarget*, AddTargetData&)> _orig;

    static bool Thunk(RE::MagicTarget* self, AddTargetData& d) {
        RE::Actor* actor = nullptr;
        if (g_cfg.enabled && self && self->MagicTargetIsActor()) {
            // GetTargetStatsObject() returns the owning reference for Actors; avoids a raw downcast.
            auto* ref = self->GetTargetStatsObject();
            actor = ref ? ref->As<RE::Actor>() : nullptr;
        }
        if (actor) {
            RE::TESForm* base = d.effect ? d.effect->baseEffect : nullptr;
            const bool remote = !actor->IsPlayerRef();
            if (g_cfg.discover)
                logger::info("AddTarget {} target={:08X} effect={} item={}", remote ? "REMOTE" : "LOCAL",
                             actor->GetFormID(), Describe(base), Describe(d.magicItem));
            if (remote && (Matches(base, g_cfg.magicPrefixes, g_cfg.magicIds) ||
                           Matches(d.magicItem, g_cfg.magicPrefixes, g_cfg.magicIds))) {
                logger::info("blocked on remote actor {:08X}: {}", actor->GetFormID(), Describe(base));
                return false;
            }
        }
        return _orig(self, d);
    }
    static void Install() {
        REL::Relocation<std::uintptr_t> vtbl{ RE::VTABLE_Character[kVtableSlot] };
        _orig = vtbl.write_vfunc(kVfuncIdx, Thunk);
    }
};

// ---------------------------------------------------------------- quest isolation (scaffold)
// Observation only for now: log blacklisted stage changes so we can see exactly when/where STR
// picks them up. Actual suppression needs STR's quest-sync entry point (unknown to me) - either
// hook it by Address-Library-independent signature, or hook TESQuest stage-set and set a
// thread-local "local only" flag that STR's own hook reads. Pick after the log tells us the call order.
struct QuestWatcher : RE::BSTEventSink<RE::TESQuestStageEvent> {
    RE::BSEventNotifyControl ProcessEvent(const RE::TESQuestStageEvent* e, RE::BSTEventSource<RE::TESQuestStageEvent>*) override {
        if (g_cfg.enabled && e) {
            auto* q = RE::TESForm::LookupByID<RE::TESQuest>(e->formID);
            if (q && Matches(q, g_cfg.questPrefixes, g_cfg.questIds))
                logger::info("blacklisted quest {:08X} '{}' stage {}", q->GetFormID(), q->GetFormEditorID(), e->stage);
        }
        return RE::BSEventNotifyControl::kContinue;
    }
    static QuestWatcher* Get() { static QuestWatcher s; return &s; }
};

// ---------------------------------------------------------------- entry
// Plugin version/info export is generated by add_commonlibsse_plugin() in CMake.

SKSEPluginLoad(const SKSE::LoadInterface* skse) {
    SKSE::Init(skse);
    if (auto dir = logger::log_directory()) {
        auto sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>((*dir / "EnderalSTRPatch.log").string(), true);
        spdlog::set_default_logger(std::make_shared<spdlog::logger>("g", sink));
        spdlog::flush_on(spdlog::level::info);
    }
    LoadConfig();
    SKSE::GetMessagingInterface()->RegisterListener([](SKSE::MessagingInterface::Message* m) {
        if (m->type == SKSE::MessagingInterface::kDataLoaded) {
            MagicHook::Install();
            RE::ScriptEventSourceHolder::GetSingleton()->AddEventSink<RE::TESQuestStageEvent>(QuestWatcher::Get());
            logger::info("installed (enabled={})", g_cfg.enabled);
        }
    });
    return true;
}
