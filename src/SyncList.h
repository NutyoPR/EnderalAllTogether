#pragma once

#include <array>
#include <string_view>

// The story state Skyrim Together does not sync, from the variable sort (see README). Generated from the review list;
// names are the editor IDs of Enderal's global variables. Anything not listed is deliberately left alone.
namespace EAT
{
    enum class SyncMode
    {
        kRelationship,  // changes only in dialogue: share the difference; a check-up copies the reference's value
        kCounter,       // goes up on one machine (pickups, reading, talking): share the difference; check-up keeps the max
        kSet,           // story choices and one-time flags: share the new value
        kMax            // counters that may count on both machines (boss deaths): keep the higher value
    };

    struct SyncEntry
    {
        std::string_view name;
        SyncMode         mode;
    };

    inline constexpr std::array<SyncEntry, 141> kSyncList{ {
        // Relationships
        { "_00E_FS_NQR_RhalataMistrust", SyncMode::kRelationship },  // Rhalata's mistrust (relationship-like)
        { "CaliaFlirtCounter", SyncMode::kRelationship },  // flirt counter (dialogue)
        { "DijaamFlirtCounter", SyncMode::kRelationship },  // flirt counter (dialogue)
        { "JesparFlirtCounter", SyncMode::kRelationship },  // flirt counter (dialogue)
        { "SympathyCalia", SyncMode::kRelationship },  // relationship (changed only in dialogue)
        { "SympathyDijaam", SyncMode::kRelationship },  // relationship (changed only in dialogue)
        { "SympathyEsme", SyncMode::kRelationship },  // relationship (changed only in dialogue)
        { "SympathyJespar", SyncMode::kRelationship },  // relationship (changed only in dialogue)
        { "SympathyMaelGroschenfuerst", SyncMode::kRelationship },  // relationship (changed only in dialogue)
        { "SympathyRyneus", SyncMode::kRelationship },  // relationship (changed only in dialogue)
        { "SympathyTharael", SyncMode::kRelationship },  // relationship (changed only in dialogue)
        { "SympathyYuslan", SyncMode::kRelationship },  // relationship (changed only in dialogue)
        { "TharaelFlirtCounter", SyncMode::kRelationship },  // flirt counter (dialogue)
        // Quest counters
        { "_00E_Ark_NQ_Kor_NotesFound", SyncMode::kCounter },  // notes found
        { "_00E_FS_MysticalSymbolsGlobalCollected", SyncMode::kCounter },  // mystical symbols collected
        { "_00E_FS_NQ03_SecretCounterVar", SyncMode::kCounter },  // secrets found
        { "_00E_FS_NQ06_CluesFound", SyncMode::kCounter },  // clues found
        { "_00E_MagicalSymbolsGlobalCollected", SyncMode::kCounter },  // magical symbols collected
        { "_00E_MQ01_GourdsFound", SyncMode::kCounter },  // gourds found
        { "_00E_MQ01_MushroomFound", SyncMode::kCounter },  // mushrooms found
        { "_00E_MQ11a_TavernGuestsTalkedTo", SyncMode::kCounter },  // tavern guests talked to
        { "_00E_MQ11c_ButterfliesGlobal", SyncMode::kCounter },  // butterflies
        { "_00E_NQ02_KnowledgeGathered", SyncMode::kCounter },  // knowledge gathered
        { "_00E_NQ13_MushroomsFound", SyncMode::kCounter },  // mushrooms found
        { "_00E_NQ25_BooksRead", SyncMode::kCounter },  // Butcher of Ark books read
        { "FS_NQ09_SoulsCollected", SyncMode::kCounter },  // souls collected
        { "FS_NQR03_NessahPageCounter", SyncMode::kCounter },  // Nessah's pages
        { "FS_NQR04_SecretSlotsFound", SyncMode::kCounter },  // secret slots found
        { "MQ12a_BlackStonesInserted", SyncMode::kCounter },  // black stones inserted
        { "MQ13a_SakkabakkuAlloysCollected", SyncMode::kCounter },  // alloys collected
        { "MQ16_EchoCluesFound", SyncMode::kCounter },  // echo clues
        { "NQ07_MedaillionsFound", SyncMode::kCounter },  // medallions found
        { "NQ19_ArtifactsCollected", SyncMode::kCounter },  // artifacts handed in
        { "NQ22_PagesFound", SyncMode::kCounter },  // pages found
        { "NQ36_WishWellsCompleted", SyncMode::kCounter },  // wishing wells completed
        // Story choices, one-time flags, shared house and mounts
        { "_00E_BergpassSkelettSpawnDone", SyncMode::kSet },  // spawn once (else per player)
        { "_00E_CaliaDialogue_AloneDialogueGlobal", SyncMode::kSet },  // one-time dialogue
        { "_00E_Duenenhaim_GuardFG_Done", SyncMode::kSet },  // one-time scene
        { "_00E_FathersShadowOwned", SyncMode::kSet },  // shared horse (Father's Shadow)
        { "_00E_FS_NQ01_RespectedYuslansWish", SyncMode::kSet },  // story choice
        { "_00E_FS_NQ01_YuslanSecretEnding", SyncMode::kSet },  // story outcome
        { "_00E_FS_NQ02_MuseumVar", SyncMode::kSet },  // Esme: museum yes/no
        { "_00E_FS_NQ03_FinishedVar", SyncMode::kSet },  // quest finished
        { "_00E_FS_NQ06_KarymeaVar", SyncMode::kSet },  // story choice
        { "_00E_FS_NQ07_DoorOwned", SyncMode::kSet },  // world state
        { "_00E_FS_NQ07_DoorRepaired", SyncMode::kSet },  // world state
        { "_00E_FS_NQR02_SparedQalian", SyncMode::kSet },  // story choice
        { "_00E_FS_NQR05_D24_PossibleRefuges", SyncMode::kSet },  // story state
        { "_00E_FS_NQR05_RhalataMistrustTooHight", SyncMode::kSet },  // story state
        { "_00E_FS_NQR05_SecretRewardTaken", SyncMode::kSet },  // reward taken once
        { "_00E_FS_NQR05_SpokenToTharael", SyncMode::kSet },  // story flag
        { "_00E_FS_NQR05_TharaelInFrostCliff", SyncMode::kSet },  // story state
        { "_00E_FS_NQR05_TharaelLoyalToPlayer", SyncMode::kSet },  // story choice
        { "_00E_FS_NQR05_TharaelTrickedByFather", SyncMode::kSet },  // story choice
        { "_00E_FS_NQR_SQ_01_GaveSpecialGreeting", SyncMode::kSet },  // one-time dialogue
        { "_00E_FS_NQR_SQ_01_UnlockedAdvancedOptions", SyncMode::kSet },  // dialogue unlocked
        { "_00E_FurniturePurchased", SyncMode::kSet },  // shared house furniture level (furniture itself: see bridge)
        { "_00E_GaborGaboff_HadFlavourDialogue", SyncMode::kSet },  // one-time dialogue
        { "_00E_GolfurDialogueGlobal", SyncMode::kSet },  // dialogue state
        { "_00E_HorseOwned", SyncMode::kSet },  // shared horse
        { "_00E_MQ04_SavedSevf", SyncMode::kSet },  // story outcome
        { "_00E_MQ06_SunTempleArmoryGlobal", SyncMode::kSet },  // shop unlocked by story
        { "_00E_MQ07b_HallysFree", SyncMode::kSet },  // story outcome
        { "_00E_MQ09a_FogvilleHist_SayOnce", SyncMode::kSet },  // one-time line
        { "_00E_MQ09a_TIJ_SayOnce2", SyncMode::kSet },  // one-time line
        { "_00E_MQ09Liar", SyncMode::kSet },  // story choice
        { "_00E_MQ11c_D2_SayOnce", SyncMode::kSet },  // one-time line
        { "_00E_MQ11c_RyneusBuried", SyncMode::kSet },  // story choice
        { "_00E_MQ11c_RyneusPeacefulSolution", SyncMode::kSet },  // story choice
        { "_00E_MQ12a_MQ11aCleared", SyncMode::kSet },  // story progress
        { "_00E_MQ12a_MQ11cCleared", SyncMode::kSet },  // story progress
        { "_00E_MQ12b_MQ11cCleared", SyncMode::kSet },  // story progress
        { "_00E_MQ13a_CaliaDump", SyncMode::kSet },  // romance outcome
        { "_00E_MQ13a_JesparDump", SyncMode::kSet },  // romance outcome
        { "_00E_MQ14_Readyfor10", SyncMode::kSet },  // story progress
        { "_00E_MuleOwned", SyncMode::kSet },  // shared mule
        { "_00E_NQ01FeuervogelDone", SyncMode::kSet },  // quest part done
        { "_00E_NQ01GipfenstuermerDone", SyncMode::kSet },  // quest part done
        { "_00E_NQ01LaubmoeveneierDone", SyncMode::kSet },  // quest part done
        { "_00E_NQ21_VynrootPurchased", SyncMode::kSet },  // quest item bought
        { "_00E_NQ24_PlayerHouseOwned", SyncMode::kSet },  // shared house
        { "_00E_NQ25_TalkedToMarius", SyncMode::kSet },  // story flag
        { "_00E_NQ_G_03_BroochHandedIn", SyncMode::kSet },  // quest item handed in
        { "_00E_NQ_G_05_TalkedAboutRodas", SyncMode::kSet },  // story flag
        { "_00E_NQ_G_05_ToldDijaam", SyncMode::kSet },  // story choice
        { "_00E_NQ_G_SidedDijaam", SyncMode::kSet },  // faction choice
        { "_00E_NQ_G_SidedMael", SyncMode::kSet },  // faction choice
        { "_00E_NQG07_DijaamDeclinedSale", SyncMode::kSet },  // story outcome
        { "_00E_NQG07_DijaamKnockedOut", SyncMode::kSet },  // story outcome
        { "_00E_WishWell_Done_DeadForest", SyncMode::kSet },  // well used
        { "_00E_WishWell_Done_Frostcliff", SyncMode::kSet },  // well used
        { "_00E_WishWell_Done_PowderDesert", SyncMode::kSet },  // well used
        { "_00E_WishWell_Done_Suncoast", SyncMode::kSet },  // well used
        { "CaliaRomance", SyncMode::kSet },  // romance
        { "CapitalCityUajaanVuulGlobal", SyncMode::kSet },  // story state (NQ33)
        { "CQC04_AcceptItCalia", SyncMode::kSet },  // story choice
        { "CQJ03PlayerAskedAboutAdila", SyncMode::kSet },  // story flag
        { "FlusshaimMitumialRiddlePlayerGotHint", SyncMode::kSet },  // hint given once
        { "FS_EnvironmentScene03_KnowsAboutDebt", SyncMode::kSet },  // story flag
        { "FS_NQ07_ChickenCooked", SyncMode::kSet },  // quest progress
        { "FS_NQ07_HoneyWineBought", SyncMode::kSet },  // quest progress
        { "FS_NQ07_ManfredReady", SyncMode::kSet },  // quest progress
        { "FS_NQ07_SoupBrewed", SyncMode::kSet },  // quest progress
        { "FS_NQR03_GivenFakeHeart", SyncMode::kSet },  // story choice
        { "FS_NQR05_SC19_LethoKilled", SyncMode::kSet },  // story outcome
        { "FS_NQR05_SidedWithFather", SyncMode::kSet },  // story choice
        { "FS_NQR05_SidedWithTharael", SyncMode::kSet },  // story choice
        { "FS_SisterEnvyFirstBarterDone", SyncMode::kSet },  // one-time barter
        { "JesparDialogue_ProfessionTopic_Said", SyncMode::kSet },  // one-time dialogue
        { "JesparRomance", SyncMode::kSet },  // romance
        { "MQ07a_Failsave_Completed", SyncMode::kSet },  // quest progress
        { "MQ07a_PlatformActivated", SyncMode::kSet },  // quest progress
        { "MQ07b_LishariUglyFailsaveGlobal", SyncMode::kSet },  // quest progress
        { "MQ11a_Anomaly", SyncMode::kSet },  // story flag
        { "MQ11a_CaliaCamp", SyncMode::kSet },  // story state
        { "MQ11a_LeftTower", SyncMode::kSet },  // tower state
        { "MQ11a_LeftTowerExplore", SyncMode::kSet },  // quest progress
        { "MQ11a_RightTower", SyncMode::kSet },  // tower state
        { "MQ11a_TruthTold", SyncMode::kSet },  // story choice
        { "MQ12b_ArkUnderAttack", SyncMode::kSet },  // story state
        { "MQ15_SC4_ChopHeadFailsave", SyncMode::kSet },  // quest progress
        { "MQ17_JesparFinalCompanion", SyncMode::kSet },  // final companion choice
        { "NQ05_BribedCileo", SyncMode::kSet },  // story choice
        { "NQ17_DefiedAndrasta", SyncMode::kSet },  // story choice
        { "NQ17_FreedRyz", SyncMode::kSet },  // story choice
        { "NQ17_SidedWithAndrasta", SyncMode::kSet },  // story choice
        { "NQ17_ToldTruthToErika", SyncMode::kSet },  // story choice
        { "RomanceLockedCalia", SyncMode::kSet },  // romance
        { "RomanceLockedJespar", SyncMode::kSet },  // romance
        { "_00E_MQ04_SavedSevf", SyncMode::kSet },  // Taming the Waves: Sevf saved
        { "_00E_ButcherOfArk01Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        { "_00E_ButcherOfArk02Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        { "_00E_ButcherOfArk03Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        { "_00E_ButcherOfArk04Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        { "_00E_ButcherOfArk05Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        { "_00E_ButcherOfArk06Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        { "_00E_ButcherOfArk07Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        { "_00E_ButcherOfArk08Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        { "_00E_ButcherOfArk09Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        { "_00E_ButcherOfArk10Read", SyncMode::kSet },  // Butcher of Ark volume read (stops double counting)
        // Counted on every machine
        { "NQ29_MythicalCreaturesSlain", SyncMode::kMax },  // mythical creatures slain (boss deaths can count on both machines)
    } };
}
