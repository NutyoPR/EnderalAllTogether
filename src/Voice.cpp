#include "Voice.h"

#include <algorithm>
#include <cctype>
#include <charconv>
#include <chrono>
#include <deque>
#include <format>
#include <mutex>
#include <optional>
#include <unordered_map>
#include <vector>

#include "Net.h"

namespace EAT::Voice
{
    namespace
    {
        using clock = std::chrono::steady_clock;

        // The same line played here moments ago (both games run the scene): don't play the partner's copy too.
        constexpr auto kSameLineWindow = std::chrono::seconds(20);
        // Subtitles stay at least this long, plus a little per character, when the voice is shorter or missing.
        constexpr auto kMinLine = std::chrono::milliseconds(1500);
        constexpr auto kPerCharacter = std::chrono::milliseconds(60);

        struct Line
        {
            RE::FormID  speaker;
            RE::FormID  info;
            std::string text;
            std::string voice;
        };

        struct LocalLine
        {
            RE::FormID        info;
            clock::time_point at;
        };

        std::mutex                                g_localLock;
        std::unordered_map<RE::FormID, LocalLine> g_localLines;  // speaker -> the last line this game spoke itself

        // main thread
        std::deque<Line>    g_queue;
        std::optional<Line> g_current;
        RE::BSSoundHandle   g_sound;
        clock::time_point   g_lineEnds{};
        bool                g_loggedVoicePath = false;

        // Static references from the game files only: their form IDs are the same on every game.
        bool IsTalkingActivator(const RE::TESObjectREFR* a_ref)
        {
            if (!a_ref || (a_ref->GetFormID() >> 24) == 0xFF)
                return false;
            const auto base = a_ref->GetBaseObject();
            return base && base->Is(RE::FormType::TalkingActivator);
        }

        bool SpokeHereRecently(RE::FormID a_speaker, RE::FormID a_info)
        {
            std::scoped_lock l(g_localLock);
            const auto       it = g_localLines.find(a_speaker);
            return it != g_localLines.end() && it->second.info == a_info && clock::now() - it->second.at < kSameLineWindow;
        }

        // SubtitleManager's show/hide (the ones Skyrim Together hooks for actors' subtitles).
        void ShowSubtitle(RE::TESObjectREFR* a_speaker, const char* a_text)
        {
            using func_t = void (*)(RE::SubtitleManager*, RE::TESObjectREFR*, const char*, bool);
            static REL::Relocation<func_t> func{ RELOCATION_ID(51753, 52626) };
            if (const auto manager = RE::SubtitleManager::GetSingleton(); manager && a_text && *a_text)
                func(manager, a_speaker, a_text, false);
        }

        void HideSubtitle(RE::TESObjectREFR* a_speaker)
        {
            using func_t = void* (*)(RE::SubtitleManager*, RE::TESObjectREFR*);
            static REL::Relocation<func_t> func{ RELOCATION_ID(51754, 52627) };
            if (const auto manager = RE::SubtitleManager::GetSingleton())
                func(manager, a_speaker);
        }

        std::string Lower(std::string_view a_s)
        {
            std::string s(a_s);
            std::ranges::transform(s, s.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
            return s;
        }

        // The voice file of a response, played from the speaker. Voice files ship as .fuz (voice + lip) or .xwm, and the
        // path may start with "Data\": try what's there.
        bool PlayVoice(RE::TESObjectREFR* a_speaker, const std::string& a_voice)
        {
            const auto audio = RE::BSAudioManager::GetSingleton();
            if (!audio || a_voice.empty())
                return false;
            if (!g_loggedVoicePath) {
                g_loggedVoicePath = true;
                SKSE::log::info("voice relay: first voice path {}", a_voice);
            }
            std::string path = a_voice;
            if (Lower(path).starts_with("data\\") || Lower(path).starts_with("data/"))
                path = path.substr(5);
            std::vector<std::string> candidates{ path };
            const auto               dot = path.find_last_of('.');
            const auto               stem = dot == std::string::npos ? path : path.substr(0, dot);
            for (const auto ext : { ".fuz", ".xwm", ".wav" })
                if (Lower(path) != Lower(stem + ext))
                    candidates.push_back(stem + ext);
            for (const auto& candidate : candidates) {
                RE::BSResource::ID id;
                id.GenerateFromPath(candidate.c_str());
                RE::BSSoundHandle handle;
                audio->GetSoundHandleByFile(handle, id, 128, 1);
                if (!handle.IsValid())
                    continue;
                if (const auto node = a_speaker->Get3D())
                    handle.SetObjectToFollow(node);
                else
                    handle.SetPosition(a_speaker->GetPosition());
                if (handle.Play()) {
                    g_sound = handle;
                    return true;
                }
            }
            SKSE::log::warn("voice relay: could not play {}", a_voice);
            return false;
        }

        void Finish()
        {
            if (!g_current)
                return;
            if (g_sound.IsValid())
                g_sound.Stop();
            g_sound = RE::BSSoundHandle{};
            if (const auto speaker = RE::TESForm::LookupByID<RE::TESObjectREFR>(g_current->speaker))
                HideSubtitle(speaker);
            g_current.reset();
        }

        void Start(Line a_line)
        {
            const auto speaker = RE::TESForm::LookupByID<RE::TESObjectREFR>(a_line.speaker);
            if (!speaker || !speaker->Get3D())  // not loaded here: the partner isn't near it, nothing to hear
                return;
            const bool voiced = PlayVoice(speaker, a_line.voice);
            ShowSubtitle(speaker, a_line.text.c_str());
            g_lineEnds = clock::now() + kMinLine + kPerCharacter * static_cast<int>(a_line.text.size());
            if (voiced)
                g_lineEnds = clock::now() + kMinLine;  // the voice decides how long; this is only the minimum
            g_current = std::move(a_line);
        }

        class TopicSink : public RE::BSTEventSink<RE::TESTopicInfoEvent>
        {
        public:
            static TopicSink* Get()
            {
                static TopicSink sink;
                return &sink;
            }

            RE::BSEventNotifyControl ProcessEvent(const RE::TESTopicInfoEvent* a_event, RE::BSTEventSource<RE::TESTopicInfoEvent>*) override
            {
                if (!a_event || a_event->type.get() != RE::TESTopicInfoEvent::TopicInfoEventType::kTopicBegin)
                    return RE::BSEventNotifyControl::kContinue;
                const auto speaker = a_event->speakerRef.get();
                if (!IsTalkingActivator(speaker))
                    return RE::BSEventNotifyControl::kContinue;
                {
                    std::scoped_lock l(g_localLock);
                    g_localLines[speaker->GetFormID()] = { a_event->topicInfoFormID, clock::now() };
                }
                if (Net::HasPeers()) {
                    SKSE::log::info("voice relay: {:X} says {:X}, sharing", speaker->GetFormID(), a_event->topicInfoFormID);
                    Net::Queue(std::format("V|{:X}|{:X}", speaker->GetFormID(), a_event->topicInfoFormID));
                }
                return RE::BSEventNotifyControl::kContinue;
            }
        };
    }

    void Install()
    {
        if (const auto events = RE::ScriptEventSourceHolder::GetSingleton())
            events->AddEventSink<RE::TESTopicInfoEvent>(TopicSink::Get());
    }

    void Apply(const std::string& a_message)
    {
        // V|speaker|info
        const auto body = std::string_view(a_message).substr(2);
        const auto bar = body.find('|');
        if (bar == std::string_view::npos)
            return;
        RE::FormID speakerId = 0, infoId = 0;
        const auto speakerText = body.substr(0, bar);
        const auto infoText = body.substr(bar + 1);
        if (std::from_chars(speakerText.data(), speakerText.data() + speakerText.size(), speakerId, 16).ec != std::errc{} ||
            std::from_chars(infoText.data(), infoText.data() + infoText.size(), infoId, 16).ec != std::errc{})
            return;
        const auto speaker = RE::TESForm::LookupByID<RE::TESObjectREFR>(speakerId);
        const auto info = RE::TESForm::LookupByID<RE::TESTopicInfo>(infoId);
        if (!IsTalkingActivator(speaker) || !info || SpokeHereRecently(speakerId, infoId))
            return;
        if (!speaker->Get3D())
            return;
        const auto topic = info->parentTopic;
        // Builds the line's responses (text and voice file for this speaker's voice type), like the game does before
        // speaking it, without running anything.
        RE::BSTSmartPointer<RE::DialogueItem> item{ new RE::DialogueItem(topic ? topic->ownerQuest : nullptr, topic, info, speaker) };
        int                                   count = 0;
        for (const auto response : item->responses) {
            if (!response)
                continue;
            g_queue.push_back({ speakerId, infoId, response->text.c_str() ? response->text.c_str() : "",
                response->voice.c_str() ? response->voice.c_str() : "" });
            ++count;
        }
        SKSE::log::info("voice relay: partner's {:X} says {:X} ({} response(s))", speakerId, infoId, count);
    }

    void OnGameUnloaded()
    {
        Finish();  // a line still playing belongs to the old game
        g_queue.clear();
        std::scoped_lock l(g_localLock);
        g_localLines.clear();
    }

    void Tick()
    {
        if (g_current) {
            // This game started speaking the same line itself (it runs the scene too): let it.
            if (SpokeHereRecently(g_current->speaker, g_current->info)) {
                Finish();
                std::erase_if(g_queue, [](const Line& a_line) { return SpokeHereRecently(a_line.speaker, a_line.info); });
            } else if ((g_sound.IsValid() && g_sound.IsPlaying()) || clock::now() < g_lineEnds) {
                return;
            } else {
                Finish();
            }
        }
        while (!g_current && !g_queue.empty()) {
            auto line = std::move(g_queue.front());
            g_queue.pop_front();
            Start(std::move(line));
        }
    }
}
